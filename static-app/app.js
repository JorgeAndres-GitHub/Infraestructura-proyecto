// Configuración de la API - URL del Container App
const API_BASE_URL = 'https://infradm24-containerapp.mangosand-22523b0d.eastus2.azurecontainerapps.io';
const API_URL = `${API_BASE_URL}/api/chat`;

// Elementos del DOM
const chatMessages = document.getElementById('chatMessages');
const chatForm = document.getElementById('chatForm');
const userInput = document.getElementById('userInput');
const sendBtn = document.getElementById('sendBtn');
const chatList = document.getElementById('chatList');
const newChatBtn = document.getElementById('newChatBtn');
const toggleSidebarBtn = document.getElementById('toggleSidebar');
const sidebar = document.getElementById('sidebar');
const currentChatTitle = document.getElementById('currentChatTitle');
const chatSubtitle = document.getElementById('chatSubtitle');
const renameChatBtn = document.getElementById('renameChatBtn');
const deleteChatBtn = document.getElementById('deleteChatBtn');
const renameModal = document.getElementById('renameModal');
const renameInput = document.getElementById('renameInput');
const confirmRename = document.getElementById('confirmRename');
const cancelRename = document.getElementById('cancelRename');

// Estado de la aplicación
let chats = JSON.parse(localStorage.getItem('nullbot_chats')) || [];
let currentChatId = localStorage.getItem('nullbot_current_chat');
let isFirstMessage = true;

// Inicializar la aplicación
function init() {
  if (chats.length === 0) {
    createNewChat();
  } else {
    if (!currentChatId || !chats.find(c => c.id === currentChatId)) {
      currentChatId = chats[0].id;
    }
    loadChat(currentChatId);
  }
  renderChatList();
  console.log('NullBot Chat initialized');
}

// Generar ID único
function generateId() {
  return 'chat_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
}

// Guardar chats en localStorage
function saveChats() {
  localStorage.setItem('nullbot_chats', JSON.stringify(chats));
  localStorage.setItem('nullbot_current_chat', currentChatId);
}

// Crear nuevo chat
function createNewChat() {
  const newChat = {
    id: generateId(),
    title: 'Nuevo Chat',
    messages: [],
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    sessionId: null,
    autoNamed: false
  };
  
  chats.unshift(newChat);
  currentChatId = newChat.id;
  isFirstMessage = true;
  saveChats();
  renderChatList();
  loadChat(newChat.id);
  
  // Cerrar sidebar en móvil
  if (window.innerWidth <= 768) {
    sidebar.classList.remove('open');
  }
}

// Generar nombre automático basado en el primer mensaje
function generateChatName(message) {
  // Tomar las primeras palabras del mensaje
  const words = message.trim().split(/\s+/).slice(0, 5);
  let title = words.join(' ');
  
  // Limitar longitud
  if (title.length > 30) {
    title = title.substring(0, 30) + '...';
  }
  
  return title || 'Nuevo Chat';
}

// Renderizar lista de chats
function renderChatList() {
  chatList.innerHTML = '';
  
  if (chats.length === 0) {
    chatList.innerHTML = `
      <div class="empty-state">
        <i class="fas fa-comments"></i>
        <p>No hay chats aún</p>
      </div>
    `;
    return;
  }
  
  chats.forEach(chat => {
    const chatItem = document.createElement('div');
    chatItem.className = `chat-item ${chat.id === currentChatId ? 'active' : ''}`;
    chatItem.onclick = () => loadChat(chat.id);
    
    const lastMessage = chat.messages.length > 0 
      ? chat.messages[chat.messages.length - 1].content.substring(0, 40) + '...'
      : 'Sin mensajes';
    
    const timeAgo = getTimeAgo(new Date(chat.updatedAt));
    
    chatItem.innerHTML = `
      <i class="fas fa-message chat-item-icon"></i>
      <div class="chat-item-content">
        <div class="chat-item-title">${escapeHtml(chat.title)}</div>
        <div class="chat-item-preview">${escapeHtml(lastMessage)}</div>
      </div>
      <span class="chat-item-time">${timeAgo}</span>
    `;
    
    chatList.appendChild(chatItem);
  });
}

// Obtener tiempo relativo
function getTimeAgo(date) {
  const now = new Date();
  const diffMs = now - date;
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);
  
  if (diffMins < 1) return 'Ahora';
  if (diffMins < 60) return `${diffMins}m`;
  if (diffHours < 24) return `${diffHours}h`;
  if (diffDays < 7) return `${diffDays}d`;
  return date.toLocaleDateString('es-ES', { day: '2-digit', month: 'short' });
}

// Cargar un chat
function loadChat(chatId) {
  const chat = chats.find(c => c.id === chatId);
  if (!chat) return;
  
  currentChatId = chatId;
  isFirstMessage = chat.messages.length === 0;
  saveChats();
  
  // Actualizar header
  currentChatTitle.textContent = chat.title;
  chatSubtitle.textContent = 'Grupo de trabajo Null';
  
  // Limpiar y cargar mensajes
  chatMessages.innerHTML = '';
  
  // Mensaje de bienvenida si no hay mensajes
  if (chat.messages.length === 0) {
    const welcomeMsg = createMessageElement(
      '¡Hola! Soy NullBot, el asistente de IA del grupo de trabajo Null. Estoy powered by Azure OpenAI. ¿En qué puedo ayudarte hoy?',
      false
    );
    chatMessages.appendChild(welcomeMsg);
  } else {
    // Cargar mensajes existentes
    chat.messages.forEach(msg => {
      const element = createMessageElement(msg.content, msg.role === 'user');
      chatMessages.appendChild(element);
    });
  }
  
  scrollToBottom();
  renderChatList();
}

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

// Enviar mensaje a la API
async function sendMessage(message) {
  const chat = chats.find(c => c.id === currentChatId);
  if (!chat) return;
  
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
        session_id: chat.sessionId
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
    if (data.session_id && !chat.sessionId) {
      chat.sessionId = data.session_id;
    }

    // Guardar mensaje del bot
    chat.messages.push({ role: 'assistant', content: botMessage });
    chat.updatedAt = new Date().toISOString();
    
    // Auto-nombrar el chat basado en el primer mensaje del usuario
    if (isFirstMessage && !chat.autoNamed) {
      chat.title = generateChatName(message);
      chat.autoNamed = true;
      currentChatTitle.textContent = chat.title;
    }
    
    isFirstMessage = false;
    saveChats();
    renderChatList();

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
  
  const chat = chats.find(c => c.id === currentChatId);
  if (!chat) return;

  // Si es el primer mensaje, limpiar el mensaje de bienvenida
  if (chat.messages.length === 0) {
    chatMessages.innerHTML = '';
  }

  // Guardar mensaje del usuario
  chat.messages.push({ role: 'user', content: message });
  chat.updatedAt = new Date().toISOString();
  saveChats();

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
  sendBtn.disabled = !userInput.value.trim();
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

// Nuevo chat
newChatBtn.addEventListener('click', createNewChat);

// Toggle sidebar
toggleSidebarBtn.addEventListener('click', () => {
  if (window.innerWidth <= 768) {
    sidebar.classList.toggle('open');
  } else {
    sidebar.classList.toggle('collapsed');
  }
});

// Renombrar chat
renameChatBtn.addEventListener('click', () => {
  const chat = chats.find(c => c.id === currentChatId);
  if (chat) {
    renameInput.value = chat.title;
    renameModal.classList.add('show');
    renameInput.focus();
  }
});

confirmRename.addEventListener('click', () => {
  const chat = chats.find(c => c.id === currentChatId);
  if (chat && renameInput.value.trim()) {
    chat.title = renameInput.value.trim();
    chat.autoNamed = true;
    saveChats();
    currentChatTitle.textContent = chat.title;
    renderChatList();
    renameModal.classList.remove('show');
  }
});

cancelRename.addEventListener('click', () => {
  renameModal.classList.remove('show');
});

// Cerrar modal con Escape
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && renameModal.classList.contains('show')) {
    renameModal.classList.remove('show');
  }
});

// Eliminar chat
deleteChatBtn.addEventListener('click', async () => {
  const chat = chats.find(c => c.id === currentChatId);
  if (!chat) return;
  
  if (!confirm(`¿Estás seguro de eliminar "${chat.title}"?`)) return;
  
  // Eliminar de la base de datos si tiene sessionId
  if (chat.sessionId) {
    try {
      await fetch(`${API_BASE_URL}/api/conversations/${chat.sessionId}`, { method: 'DELETE' });
    } catch (error) {
      console.log('No se pudo eliminar la conversación del servidor:', error.message);
    }
  }
  
  // Eliminar del array
  chats = chats.filter(c => c.id !== currentChatId);
  
  // Crear nuevo chat si no quedan
  if (chats.length === 0) {
    createNewChat();
  } else {
    currentChatId = chats[0].id;
    loadChat(currentChatId);
  }
  
  saveChats();
  renderChatList();
});

// Cerrar sidebar al hacer clic fuera en móvil
document.addEventListener('click', (e) => {
  if (window.innerWidth <= 768) {
    if (!sidebar.contains(e.target) && !toggleSidebarBtn.contains(e.target)) {
      sidebar.classList.remove('open');
    }
  }
});

// Inicialización
document.addEventListener('DOMContentLoaded', init);
