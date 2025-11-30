from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from openai import AzureOpenAI
import os
from typing import List, Optional
from datetime import datetime
from contextlib import asynccontextmanager
import pyodbc
from contextlib import contextmanager
import uuid

# Función para inicializar la base de datos
def init_database():
    """Inicializa las tablas de la base de datos"""
    if not SQL_PASSWORD:
        print("SQL_PASSWORD no configurado, omitiendo inicialización de BD")
        return
    try:
        conn = pyodbc.connect(get_connection_string())
        cursor = conn.cursor()

        # Crear tabla de sesiones de conversación
        cursor.execute("""
            IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='conversations' AND xtype='U')
            CREATE TABLE conversations (
                id INT IDENTITY(1,1) PRIMARY KEY,
                session_id NVARCHAR(100) NOT NULL UNIQUE,
                created_at DATETIME DEFAULT GETDATE(),
                updated_at DATETIME DEFAULT GETDATE()
            )
        """)

        # Crear tabla de mensajes
        cursor.execute("""
            IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='messages' AND xtype='U')
            CREATE TABLE messages (
                id INT IDENTITY(1,1) PRIMARY KEY,
                session_id NVARCHAR(100) NOT NULL,
                role NVARCHAR(20) NOT NULL,
                content NVARCHAR(MAX) NOT NULL,
                tokens_used INT DEFAULT 0,
                created_at DATETIME DEFAULT GETDATE(),
                FOREIGN KEY (session_id) REFERENCES conversations(session_id)
            )
        """)

        conn.commit()
        conn.close()
        print("Base de datos inicializada correctamente")
    except Exception as e:
        print(f"Error inicializando BD (puede que no haya conexión): {e}")

# Configuración de la base de datos SQL Server
SQL_SERVER = os.getenv("SQL_SERVER", "infradm24-sqlsrv.database.windows.net")
SQL_DATABASE = os.getenv("SQL_DATABASE", "dbdemo")
SQL_USER = os.getenv("SQL_USER", "sqladmin")
SQL_PASSWORD = os.getenv("SQL_PASSWORD")

# Conexión a la base de datos
def get_connection_string():
    return f"DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={SQL_SERVER};DATABASE={SQL_DATABASE};UID={SQL_USER};PWD={SQL_PASSWORD};Encrypt=yes;TrustServerCertificate=no"

# Lifespan para inicialización (reemplaza on_event deprecated)
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    print("Iniciando aplicación...")
    init_database()
    yield
    # Shutdown
    print("Cerrando aplicación...")

app = FastAPI(title="Azure OpenAI ChatBot API", version="1.0.0", lifespan=lifespan)

# Configurar CORS - permitir todas las origenes para Static Web App
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuración de Azure OpenAI desde variables de entorno
def get_openai_client():
    api_key = os.getenv("AZURE_OPENAI_API_KEY")
    endpoint = os.getenv("AZURE_OPENAI_ENDPOINT")
    if not api_key or not endpoint:
        return None
    return AzureOpenAI(
        api_key=api_key,
        api_version="2024-02-01",
        azure_endpoint=endpoint
    )

# Nombre del deployment de tu modelo en Azure OpenAI
DEPLOYMENT_NAME = os.getenv("AZURE_OPENAI_DEPLOYMENT", "gpt-4o-mini")

# Modelos Pydantic
class Message(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    messages: List[Message]
    session_id: Optional[str] = None

class ChatResponse(BaseModel):
    message: str
    session_id: str
    usage: dict | None = None

class ConversationHistory(BaseModel):
    session_id: str
    messages: List[Message]
    created_at: datetime

@contextmanager
def get_db_connection():
    conn = None
    try:
        conn = pyodbc.connect(get_connection_string())
        yield conn
    except Exception as e:
        print(f"Error de conexión a BD: {e}")
        raise
    finally:
        if conn:
            conn.close()

def save_message(session_id: str, role: str, content: str, tokens: int = 0):
    """Guarda un mensaje en la base de datos"""
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()

            # Crear sesión si no existe
            cursor.execute("""
                IF NOT EXISTS (SELECT 1 FROM conversations WHERE session_id = ?)
                INSERT INTO conversations (session_id) VALUES (?)
            """, (session_id, session_id))

            # Insertar mensaje
            cursor.execute("""
                INSERT INTO messages (session_id, role, content, tokens_used)
                VALUES (?, ?, ?, ?)
            """, (session_id, role, content, tokens))

            # Actualizar timestamp de conversación
            cursor.execute("""
                UPDATE conversations SET updated_at = GETDATE() WHERE session_id = ?
            """, (session_id,))

            conn.commit()
    except Exception as e:
        print(f"Error guardando mensaje: {e}")

def get_conversation_history(session_id: str) -> List[dict]:
    """Obtiene el historial de una conversación"""
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                SELECT role, content FROM messages
                WHERE session_id = ?
                ORDER BY created_at ASC
            """, (session_id,))

            messages = []
            for row in cursor.fetchall():
                messages.append({"role": row[0], "content": row[1]})
            return messages
    except Exception as e:
        print(f"Error obteniendo historial: {e}")
        return []

@app.get("/health")
async def health():
    """Endpoint de health check"""
    db_status = "not_configured"

    if SQL_PASSWORD:
        try:
            with get_db_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("SELECT 1")
                db_status = "connected"
        except Exception as e:
            db_status = f"error: {str(e)[:50]}"

    return {
        "status": "healthy",
        "service": "chatbot-api",
        "database": db_status,
        "sql_server": SQL_SERVER
    }

@app.post("/api/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """Endpoint principal del chatbot"""
    try:
        # Verificar que OpenAI está configurado
        client = get_openai_client()
        if not client:
            raise HTTPException(status_code=503, detail="Azure OpenAI no está configurado")

        # Generar o usar session_id existente
        session_id = request.session_id or str(uuid.uuid4())

        # Obtener historial de la BD si existe session_id
        db_messages = []
        if request.session_id and SQL_PASSWORD:
            db_messages = get_conversation_history(session_id)

        # Convertir mensajes nuevos a formato dict
        new_messages = [msg.model_dump() for msg in request.messages]

        # Agregar mensaje del sistema para contexto
        system_message = {
            "role": "system",
            "content": "Eres un asistente de IA amable y útil. Responde en español de manera clara y concisa. Ayuda a los usuarios con sus preguntas de forma profesional."
        }

        # Combinar historial con nuevos mensajes
        full_messages = [system_message] + db_messages + new_messages

        # Llamar a Azure OpenAI
        response = client.chat.completions.create(
            model=DEPLOYMENT_NAME,
            messages=full_messages,
            max_tokens=1000,
            temperature=0.7
        )

        # Extraer respuesta
        assistant_message = response.choices[0].message.content
        total_tokens = response.usage.total_tokens if response.usage else 0

        # Guardar mensajes en la base de datos
        if SQL_PASSWORD:
            # Guardar mensaje del usuario (el último de la lista)
            if new_messages:
                last_user_msg = new_messages[-1]
                save_message(session_id, last_user_msg["role"], last_user_msg["content"])

            # Guardar respuesta del asistente
            save_message(session_id, "assistant", assistant_message, total_tokens)

        return ChatResponse(
            message=assistant_message,
            session_id=session_id,
            usage={
                "prompt_tokens": response.usage.prompt_tokens,
                "completion_tokens": response.usage.completion_tokens,
                "total_tokens": response.usage.total_tokens
            } if response.usage else None
        )

    except Exception as e:
        print(f"Error en chat: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/conversations")
async def list_conversations():
    """Lista todas las conversaciones guardadas"""
    if not SQL_PASSWORD:
        return {"conversations": [], "message": "Base de datos no configurada"}

    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                SELECT c.session_id, c.created_at, c.updated_at, COUNT(m.id) as message_count
                FROM conversations c
                LEFT JOIN messages m ON c.session_id = m.session_id
                GROUP BY c.session_id, c.created_at, c.updated_at
                ORDER BY c.updated_at DESC
            """)

            conversations = []
            for row in cursor.fetchall():
                conversations.append({
                    "session_id": row[0],
                    "created_at": row[1].isoformat() if row[1] else None,
                    "updated_at": row[2].isoformat() if row[2] else None,
                    "message_count": row[3]
                })
            return {"conversations": conversations}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/conversations/{session_id}")
async def get_conversation(session_id: str):
    """Obtiene el historial de una conversación específica"""
    if not SQL_PASSWORD:
        raise HTTPException(status_code=503, detail="Base de datos no configurada")

    messages = get_conversation_history(session_id)
    if not messages:
        raise HTTPException(status_code=404, detail="Conversación no encontrada")

    return {
        "session_id": session_id,
        "messages": messages
    }

@app.delete("/api/conversations/{session_id}")
async def delete_conversation(session_id: str):
    """Elimina una conversación y sus mensajes"""
    if not SQL_PASSWORD:
        raise HTTPException(status_code=503, detail="Base de datos no configurada")

    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM messages WHERE session_id = ?", (session_id,))
            cursor.execute("DELETE FROM conversations WHERE session_id = ?", (session_id,))
            conn.commit()

            return {"message": "Conversación eliminada", "session_id": session_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/")
async def root():
    """Endpoint raíz"""
    return {
        "service": "Azure OpenAI ChatBot API",
        "version": "1.0.0",
        "database": "SQL Server (dbdemo)",
        "endpoints": {
            "chat": "POST /api/chat",
            "conversations": "GET /api/conversations",
            "conversation_detail": "GET /api/conversations/{session_id}",
            "delete_conversation": "DELETE /api/conversations/{session_id}",
            "health": "GET /health",
            "docs": "GET /docs"
        }
    }

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8080))
    uvicorn.run(app, host="0.0.0.0", port=port)
