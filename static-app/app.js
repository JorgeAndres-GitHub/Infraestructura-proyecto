// Configuración de la API - URL del Container App
const API_BASE_URL = 'https://infradm24-containerapp.mangosand-22523b0d.eastus2.azurecontainerapps.io';
const API_URL = `${API_BASE_URL}/api/chat`;

// Elementos del DOM
const chatMessages = document.getElementById('chatMessages');
const chatForm = document.getElementById('chatForm');
const userInput = document.getElementById('userInput');
const sendBtn = document.getElementById('sendBtn');
const clearBtn = document.getElementById('clearChat');

// Session ID - Persistente en el navegador del usuario
let sessionId = localStorage.getItem('chatbot_session_id');

// Formatear hora
function formatTime(date) {
  return date.toLocaleTimeString('es-ES', {
    hour: '2-digit',
    minute: '2-digit'
  });
}

// Crear elemento de mensaje
function createMessageElement(content, isUser = false, isError = false) {
  const messageDiv = document.createElement('div');
  messageDiv.className = `message ${isUser ? 'user' : 'bot'}`;

  const avatar = document.createElement('div');
  avatar.className = 'message-avatar';
  avatar.innerHTML = isUser ? '<i class="fas fa-user"></i>' : '<i class="fas fa-robot"></i>';

  const contentDiv = document.createElement('div');
  contentDiv.className = `message-content ${isError ? 'error-message' : ''}`;
  contentDiv.innerHTML = `
    <p>${escapeHtml(content)}</p>
    <span class="message-time">${formatTime(new Date())}</span>
  `;

  messageDiv.appendChild(avatar);
  messageDiv.appendChild(contentDiv);

  return messageDiv;
}

// Crear indicador de escritura
function createTypingIndicator() {
  const messageDiv = document.createElement('div');
  messageDiv.className = 'message bot';
  messageDiv.id = 'typingIndicator';

  const avatar = document.createElement('div');
  avatar.className = 'message-avatar';
  avatar.innerHTML = '<i class="fas fa-robot"></i>';

  const contentDiv = document.createElement('div');
  contentDiv.className = 'message-content';
  contentDiv.innerHTML = `
    <div class="typing-indicator">
      <span></span>
      <span></span>
      <span></span>
    </div>
  `;

  messageDiv.appendChild(avatar);
  messageDiv.appendChild(contentDiv);

  return messageDiv;
}

// Escapar HTML para prevenir XSS
function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML.replace(/\n/g, '<br>');
}

// Scroll al último mensaje
function scrollToBottom() {
  chatMessages.scrollTop = chatMessages.scrollHeight;
}

// Cargar historial desde la base de datos
async function loadConversationHistory() {
  if (!sessionId) return;

  try {
    const response = await fetch(`${API_BASE_URL}/api/conversations/${sessionId}`);
    if (response.ok) {
      const data = await response.json();

      // Mostrar mensajes anteriores
      if (data.messages && data.messages.length > 0) {
        // Limpiar mensaje de bienvenida
        chatMessages.innerHTML = '';

        // Agregar cada mensaje del historial
        data.messages.forEach(msg => {
          const element = createMessageElement(msg.content, msg.role === 'user');
          chatMessages.appendChild(element);
        });

        scrollToBottom();
        console.log(`Historial cargado: ${data.messages.length} mensajes`);
      }
    }
  } catch (error) {
    console.log('No se pudo cargar el historial:', error.message);
  }
}

// Enviar mensaje a la API
async function sendMessage(message) {
  // Mostrar indicador de escritura
  const typingIndicator = createTypingIndicator();
  chatMessages.appendChild(typingIndicator);
  scrollToBottom();

  try {
    const response = await fetch(API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        messages: [{ role: 'user', content: message }],
        session_id: sessionId  // Enviar session_id para persistencia
      })
    });

    // Remover indicador de escritura
    typingIndicator.remove();

    if (!response.ok) {
      throw new Error(`Error ${response.status}: ${response.statusText}`);
    }

    const data = await response.json();
    const botMessage = data.message || 'Sin respuesta';

    // Guardar session_id si es nuevo
    if (data.session_id && !sessionId) {
      sessionId = data.session_id;
      localStorage.setItem('chatbot_session_id', sessionId);
      console.log('Nueva sesión creada:', sessionId);
    }

    // Mostrar respuesta del bot
    const botElement = createMessageElement(botMessage, false);
    chatMessages.appendChild(botElement);
    scrollToBottom();

  } catch (error) {
    // Remover indicador de escritura
    typingIndicator.remove();

    console.error('Error:', error);

    // Mostrar mensaje de error
    const errorElement = createMessageElement(
      `Lo siento, hubo un error al procesar tu mensaje. Por favor, intenta de nuevo.\n\nDetalle: ${error.message}`,
      false,
      true
    );
    chatMessages.appendChild(errorElement);
    scrollToBottom();
  }
}

// Manejar envío del formulario
chatForm.addEventListener('submit', async (e) => {
  e.preventDefault();

  const message = userInput.value.trim();
  if (!message) return;

  // Mostrar mensaje del usuario
  const userElement = createMessageElement(message, true);
  chatMessages.appendChild(userElement);

  // Limpiar input y deshabilitar botón
  userInput.value = '';
  sendBtn.disabled = true;
  userInput.style.height = 'auto';

  // Enviar mensaje
  await sendMessage(message);
});

// Auto-resize del textarea
userInput.addEventListener('input', () => {
  // Habilitar/deshabilitar botón de envío
  sendBtn.disabled = !userInput.value.trim();

  // Auto-resize
  userInput.style.height = 'auto';
  userInput.style.height = Math.min(userInput.scrollHeight, 120) + 'px';
});

// Enviar con Enter (Shift+Enter para nueva línea)
userInput.addEventListener('keydown', (e) => {
  if (e.key === 'Enter' && !e.shiftKey) {
    e.preventDefault();
    if (userInput.value.trim()) {
      chatForm.dispatchEvent(new Event('submit'));
    }
  }
});

// Limpiar chat (inicia nueva conversación)
clearBtn.addEventListener('click', async () => {
  // Eliminar conversación de la base de datos si existe
  if (sessionId) {
    try {
      await fetch(`${API_BASE_URL}/api/conversations/${sessionId}`, { method: 'DELETE' });
    } catch (error) {
      console.log('No se pudo eliminar la conversación:', error.message);
    }
  }

  // Limpiar session_id local
  sessionId = null;
  localStorage.removeItem('chatbot_session_id');

  // Limpiar mensajes y mostrar bienvenida
  chatMessages.innerHTML = `
    <div class="message bot">
      <div class="message-avatar">
        <i class="fas fa-robot"></i>
      </div>
      <div class="message-content">
        <p>¡Hola! Soy NullBot, el asistente de IA del grupo de trabajo Null. Estoy powered by Azure OpenAI. ¿En qué puedo ayudarte hoy?</p>
        <span class="message-time">Ahora</span>
      </div>
    </div>
  `;

  console.log('Chat limpiado - Nueva sesión');
});

// Inicialización
document.addEventListener('DOMContentLoaded', () => {
  console.log('ChatBot initialized');
  if (sessionId) {
    console.log('Sesión existente encontrada:', sessionId);
    loadConversationHistory();
  } else {
    console.log('Nueva sesión - Sin historial previo');
  }
});
