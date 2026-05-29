const apiBaseUrl = CONFIG.BASE_URL;
const socket = new WebSocket(CONFIG.SOCKET);
const wss = CONFIG.WSS;
const fileUpload = document.querySelector('.file-upload');
const uploadText = document.querySelector('.upload-text');
const uploadIcon = document.querySelector('.upload-icon');
const uploadButton = document.getElementById('uploadButton');
let intervalId;
let pingInterval;
let reducedImageFile = null;

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
  console.log(event)

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
      maxWidth: maxDimension,   
      maxHeight: maxDimension,  
      convertSize: 0,      
      mimeType: 'image/jpeg',
      success(result) {
        const nuevoNombre = file.name.replace(/\.[^/.]+$/, "") + ".jpg";
        console.log("nuevoNombre",nuevoNombre)
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



function getSelectedDetectionMode() {
  const selected = document.querySelector('input[name="detectionMode"]:checked');
  return selected ? selected.value : 'labels';
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
  
  // Si la imagen no existe en el HTML, la creamos y la metemos estrictamente en .image-preview
  if (!imgElement) {
    imgElement = document.createElement('img');
    imgElement.id = 'uploadedImage';
    imgElement.alt = 'Analyzed image';

    const imagePreview = resultsEl.querySelector('.image-preview');
    if (imagePreview) {
      imagePreview.appendChild(imgElement); // La metemos en su contenedor correcto
    } else {
      resultsEl.prepend(imgElement);
    }
  }

  imgElement.src = `data:${type};base64,${filename}`;

  if (detectionMode === 'labels') {
    const section = document.createElement('div');
    section.className = 'result-section';
    section.innerHTML = '<h3>📋 Detected Labels in objects or people</h3>';

    for (const itemData of data) {
      const item = document.createElement('div');
      item.className = 'result-item';

      item.innerHTML = `
        <strong>${itemData.name}</strong>
        <span>- Confidence: <span class="confidence">${itemData.confidence}%</span></span>
      `;
      section.appendChild(item);
    }

    clearInterval(intervalId);
    statusEl.textContent = 'Done!';
    analysisDataEl.appendChild(section);

  } else if (detectionMode === 'celebrity') {
    const section = document.createElement('div');
    section.className = 'result-section';
    section.innerHTML = '<h3>⭐ Recognized Celebrities</h3>';
    
    if (data.length === 0) {
      const noResults = document.createElement('div');
      noResults.textContent = 'No celebrities recognized in the image.';
      section.appendChild(noResults);
      analysisDataEl.appendChild(section);
      clearInterval(intervalId); // Aseguramos detener el loading aquí también
      statusEl.textContent = 'Done!';
      return;
    }

    for (const itemData of data) {
      const item = document.createElement('div');
      item.className = 'result-item';
      
      item.innerHTML = `
        <strong>${itemData.name}</strong>
        <span>- Confidence: <span class="confidence">${itemData.confidence}%</span></span>
        ${itemData.urls && itemData.urls.length > 0 
          ? `<div class="links-section">
              ${itemData.urls.map(url => `
                <br>🔗 <a href="https://${url}" target="_blank">More info ${url}</a>
              `).join('')}
             </div>`
          : ''}
      `;
      section.appendChild(item);
    }
    
    analysisDataEl.appendChild(section);
    clearInterval(intervalId);
    statusEl.textContent = 'Done!';
  }
}

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

  const detectionMode = getSelectedDetectionMode();
  const routePath = detectionMode === 'celebrity' ? '/celebrity' : '/labels';
  const apiEndpoint = `${apiBaseUrl}${routePath}`;

  statusEl.textContent = `🔗 Requesting upload URL for ${detectionMode} detection...`;
  statusEl.className = 'status-message';
  console.log('Requesting presigned URL from API:', apiEndpoint, 'with detection mode:', detectionMode);

  try {
    const presignedResponse = await fetch(apiEndpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        filename: file.name,
        contentType: file.type,
        WebSocketConnectionId: connection_id,
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
        'Content-Type': file.type,
        'x-amz-meta-connection_id': connection_id, 
        'x-amz-meta-detection_mode': detectionMode,
        'x-amz-meta-domainName': wss, 
        'x-amz-meta-image_id': data.lastpart, 
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
    fileInput.value = ''; 
    reducedImageFile = null;
    
    uploadIcon.textContent = '📁';
    uploadText.textContent = 'Choose an image or drag & drop';
    
    fileUpload.classList.remove('is-uploaded');  
  }
});