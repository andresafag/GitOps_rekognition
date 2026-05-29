const apiBaseUrl = CONFIG.BASE_URL;
const socket = new WebSocket(CONFIG.SOCKET);
const wss = CONFIG.WSS;

console.log('API Base URL:', apiBaseUrl);
console.log('WebSocket URL:', CONFIG.SOCKET);
console.log('WSS URL:', CONFIG.WSS);
let intervalId;
let pingInterval;
let reducedImageFile = null;
const uploadButton = document.getElementById('uploadButton');

function startHeartBeat(){
  pingInterval = setInterval(()=>{
    if(socket.readyState === WebSocket.OPEN){
      socket.send(JSON.stringify({action:"sockets", data:"hi"}))
    }
  }, 30000)
}

function stopHeartBeat(){
  if(pingInterval){
    clearInterval(pingInterval)
    console.log("heartbeat stopped")
  }
}

let connection_id = null;
socket.onopen = (event) => {
    console.log('Connected to WebSocket API');
    socket.send(JSON.stringify({action:'ping'}))
    startHeartBeat()
    
};

 
socket.onmessage = (event) => {
  const message = JSON.parse(event.data);

  if (message.connectionId) {
    connection_id = message.connectionId;
    console.log('ID de conexión listo:', connection_id);
    console.log("live server")
    uploadButton.disabled = false
    return; 
  }
  if (message.mensaje_servidor === 'resultados') {
    console.log('Procesando resultados...');
    displayResults(message.info.items, message.info.mode, message.data, message.type);
    console.log('Resultados recibidos:', message);
  } else if (message.mensaje_servidor === 'explicit') {
    console.log('Mensaje completo:', message);
    displayResultsExplicit(message);
  }
  else {
    console.log('Mensaje omitido (no es de resultados o no tiene info)');

  }
};

socket.onerror = (error) => console.error('WebSocket Error:', error);
socket.onclose = () => {
  console.log("Disconnected")
  stopHeartBeat()
}

const navToggle = document.getElementById('navToggle');
const navContainer = document.getElementById('navContainer');
const navMenuLinks = document.querySelectorAll('.nav-links a');

// 1. Abrir y cerrar menú con el botón hamburguesa
navToggle.addEventListener('click', () => {
  navContainer.classList.toggle('nav-open');
  
  // Cambia el icono entre hamburguesa y equis
  if (navContainer.classList.contains('nav-open')) {
    navToggle.textContent = '✕';
  } else {
    navToggle.textContent = '☰';
  }
});

// 2. Acciones al hacer clic en las opciones del menú
navMenuLinks.forEach(link => {
  link.addEventListener('click', (e) => {
    // Cambiar clase activa visualmente
    document.querySelector('.nav-links a.active')?.classList.remove('active');
    link.classList.add('active');

    // Cerrar el menú automáticamente en móviles
    if (navContainer.classList.contains('nav-open')) {
      navContainer.classList.remove('nav-open');
      navToggle.textContent = '☰';
    }
  });
});

async function reducirTamanoImagen(file, maxDimension = 800, calidad = 0.6) {
  return new Promise((resolve, reject) => {
    new Compressor(file, {
      quality: calidad,
      maxWidth: maxDimension,   // Aplica la dimensión máxima que pasas por parámetro
      maxHeight: maxDimension,  // Aplica la dimensión máxima que pasas por parámetro
      convertSize: 0,      // No procesa si el archivo original ya es menor a ~200 KB
      mimeType: 'image/jpeg',
      success(result) {
        const nuevoNombre = file.name.replace(/\.[^/.]+$/, "") + ".jpg";
        const readyFile = new File([result], nuevoNombre, { type: result.type });
        
        // Resolvemos la promesa devolviendo el archivo listo
        resolve(readyFile);
      },
      error(err) {
        // Si hay un error en la compresión, rechazamos la promesa
        reject(err);
      },
    });
  });
}



function displayResultsExplicit(data) {
  resultsEl.style.display = 'block';
  analysisDataEl.innerHTML = '';
  document.querySelector('#mi-imagen')?.removeAttribute('src');

  const section = document.createElement('div');
  section.className = 'result-section';
  section.innerHTML = `<h3>📋 ${data.info}</h3>`;
  const item = document.createElement('div');
  item.innerHTML = `
  <strong>Seuxual content</strong> - Forbidden image: 
  <span class="confidence">${data.info}%</span>
  `;
  section.appendChild(item);
  analysisDataEl.appendChild(section);
}

function displayResults(data, detectionMode, filename, type) {
  let resultsEl = document.querySelector('#results');
  resultsEl.style.display = 'block';
  analysisDataEl.innerHTML = '';

  let imgElement = document.querySelector('#uploadedImage');
  
  if (!imgElement) {
    imgElement = document.createElement('img');
    imgElement.id = 'uploadedImage';
    imgElement.alt = 'Analyzed image';

    const imagePreview = resultsEl.querySelector('.image-preview');
    if (imagePreview) {
      imagePreview.appendChild(imgElement);
    } else {
      resultsEl.prepend(imgElement);
    }
  }

  imgElement.src = `data:${type};base64,${filename}`;

  const section = document.createElement('div');
  section.className = 'result-section';
  section.innerHTML = '<h3>📋 Detected Labels</h3>';

  for (const itemData of data) {
    const item = document.createElement('div');
    item.className = 'result-item';

    item.innerHTML = `
      <strong>${itemData.Text}</strong>
      <span>- Confidence: <span class="confidence">${itemData.Confidence.toFixed(2)}%</span></span>
    `;
    section.appendChild(item);
  }
  
  analysisDataEl.appendChild(section);
  clearInterval(intervalId);
  statusEl.textContent = 'Done!';
}

const fileUpload = document.querySelector('.file-upload');
const uploadText = document.querySelector('.upload-text');
const uploadIcon = document.querySelector('.upload-icon');


fileInput.addEventListener('change', async () => {
  const file = fileInput.files[0];

  if (!file) return;

  try {
    // Reduce image size here
    reducedImageFile = await reducirTamanoImagen(file);

    console.log('Original size:', file.size);
    console.log('Reduced size:', reducedImageFile.size);

    uploadIcon.textContent = '✅';
    uploadText.textContent = `Archivo cargado: ${file.name}`;
    fileUpload.classList.add('is-uploaded');

  } catch (error) {
    console.error('Error reducing image:', error);

    statusEl.textContent = '❌ Error processing image.';
    statusEl.className = 'status-message error';
  }
});

uploadButton.addEventListener('click', async () => {
  // Use reduced image instead of original
  const detectionMode = '/text';
  const file = reducedImageFile;

  if (!connection_id){
    statusEl.textContent = 'Configuring server connectivity.';
    statusEl.className = 'status-message error';
  }

  if (!file) {
    statusEl.textContent = '⚠️ Please select an image first.';
    statusEl.className = 'status-message error';
    return;
  }

  if (file.size > 128 * 1024) {  
    statusEl.textContent = '⚠️ File size exceeds 128kb limit even after compression.';
    statusEl.className = 'status-message error';
    return;
  }

  const allowedTypes = ['image/jpeg', 'image/png'];

  if (!allowedTypes.includes(file.type)) {
    statusEl.textContent = '⚠️ Only JPEG and PNG images are supported.';
    statusEl.className = 'status-message error';
    return;
  }

  const apiEndpoint = `${apiBaseUrl}${detectionMode}`;

  statusEl.textContent = `🔗 Requesting upload URL for ${detectionMode} detection...`;
  statusEl.className = 'status-message';
  console.log('Requesting presigned URL from API:', apiEndpoint, 'with detection mode:', detectionMode);
  console.log("imagen nombre " + reducedImageFile.name)
  console.log("imagen tipo " + reducedImageFile.type)
  try {
    const presignedResponse = await fetch(apiEndpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        filename: reducedImageFile.name,
        contentType: reducedImageFile.type,
        WebSocketConnectionId: connection_id,
        detectionMode: detectionMode, 
        imageId: reducedImageFile, 
        domainName: wss 
      }),
    });

    if (!presignedResponse.ok) {
      const errorText = await presignedResponse.text();
      throw new Error(`Failed to get upload URL: ${presignedResponse.status} ${errorText}`);
    }

    const data = await presignedResponse.json();
    console.log('Received presigned URL data:', data);
    const uploadUrl = data.uploadUrl;

    statusEl.textContent = '📤 Uploading image to secure storage...';
    console.log('Uploading to URL:', uploadUrl);

    const uploadResponse = await fetch(uploadUrl, {
      method: 'PUT',
      headers: {
        'Content-Type': reducedImageFile.type,
        'x-amz-meta-connection_id': encodeURIComponent(connection_id), 
        'x-amz-meta-detection_mode': encodeURIComponent(detectionMode),
        'x-amz-meta-domainName': encodeURIComponent(wss), 
        'x-amz-meta-image_id': encodeURIComponent(data.lastpart), 
        'x-amz-meta-stage': 'default'
      },
      body: file,
    });

    if (!uploadResponse.ok) {
      const errorText = await uploadResponse.text();
      throw new Error(`Upload failed: ${uploadResponse.status} ${errorText}`);
    }

    statusEl.textContent = `✅ Upload successful! Starting AI analysis.....`;
    statusEl.className = 'status-message success';
    const randomMessages = [
      '🔍 Analyzing the image...',
      '🤖 AI is working on it...',
      '⏳ This may take a moment...',
      '🔬 Examining the details...',
      '🧠 Processing with AI...',
      '🚀 Almost there...'
    ];
    intervalId = setInterval(() => {
      const randomMessage = randomMessages[Math.floor(Math.random() * randomMessages.length)];
      statusEl.textContent = randomMessage;
    }, 1900);


  } catch (error) {
    stopRandomMessages();
    statusEl.textContent = `❌ Error: ${error.message}`;
    statusEl.className = 'status-message error';
  } finally {
    // 1. Limpia el archivo seleccionado
    fileInput.value = ''; 
    reducedImageFile = null;
    
    // 2. Restaura los textos e íconos originales
    uploadIcon.textContent = '📁';
    uploadText.textContent = 'Choose an image or drag & drop';
    
    // 3. Remueve los estilos de éxito
    fileUpload.classList.remove('is-uploaded');
    
  }
});