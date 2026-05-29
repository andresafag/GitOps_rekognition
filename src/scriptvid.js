const apiBaseUrl = CONFIG.BASE_URL;
const socket = new WebSocket(CONFIG.SOCKET);
const wss = CONFIG.WSS;
const barra = document.getElementById('barraProgreso');
const texto = document.getElementById('textoProgreso');
let intervalId;
let pingInterval;
let connection_id = null;
let videoReducidoGlobal = null;
let intervalIdreducingVideo;
let fileToShow = null;
let URLvideo = null;
barra.value = 0;
texto.innerText = '0%';




const uploadButton = document.querySelector('#uploadButton')

function startHeartBeat(){
  pingInterval = setInterval(()=>{
    if(socket.readyState === WebSocket.OPEN){
      socket.send(JSON.stringify({action:"sockets", data:"hi"}))
    }
  }, 30000)
  const timer = 20 * 60 *1000;
  setTimeout(() => {
    clearInterval(pingInterval);
    location.reload();
  }, timer)
}

function stopHeartBeat(){
  if(pingInterval){
    clearInterval(pingInterval)
    console.log("heartbeat stopped")
  }
}

socket.onopen = (event) => {
    console.log('Connected to WebSocket API');
    socket.send(JSON.stringify({action:'ping'}))
    startHeartBeat();
};

const videoResultsFragments = {};

socket.onmessage = (event) => {
  console.log('Raw WS event:', event);
  let message;

  try {
    message = JSON.parse(event.data);
  } catch (error) {
    console.error('Failed to parse WS message:', event.data, error);
    return;
  }

  console.log('Parsed WS message:', message);

  if (message.connectionId) {
    connection_id = message.connectionId;
    console.log('ID de conexión listo:', connection_id);
    uploadButton.disabled = false
    return;
  }

  if (message.mensaje_servidor === 'video_results_fragment') {
    const { id_mensaje, indice, total, datos } = message;
    if (!id_mensaje || indice == null || total == null || datos == null) {
      console.warn('Incomplete video fragment message:', message);
      return;
    }

    if (!videoResultsFragments[id_mensaje]) {
      videoResultsFragments[id_mensaje] = {
        fragments: [],
        total,
        received: 0,
      };
    }

    const entry = videoResultsFragments[id_mensaje];
    entry.fragments[indice] = datos;
    entry.received += 1;

    console.log(`Received fragment ${indice + 1}/${total} for ${id_mensaje}`);

    if (entry.received === total) {
      const combined = entry.fragments.join('');
      delete videoResultsFragments[id_mensaje];

      try {
        const parsed = JSON.parse(combined);
        console.log('Full video results assembled:', parsed);
        handleVideoResults(parsed);
      } catch (parseError) {
        console.error('Failed to parse assembled video results:', parseError, combined);
      }
    }

    return;
  }

  if (message.mensaje_servidor === 'video_results') {
    console.log('Video results received:', message);
    handleVideoResults(message);
    return;
  }

  if (message.mensaje_servidor === 'explicit') {
    console.warn('Explicit content warning from server:', message);
    return;
  }

  console.log('Unhandled WS message:', message);
};



socket.onerror = (error) => console.error('WebSocket Error:', error);
socket.onclose = () => {
  console.log('Disconnected from WebSocket')
  stopHeartBeat()
};

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

function reducirTamanoVideo(file, originalName, onProgress) {
  return new Promise((resolve, reject) => {
    const video = document.createElement('video');
    video.src = URL.createObjectURL(file);
    video.muted = true;
    video.playsInline = true;

    video.onloadedmetadata = () => {
      // Definir nueva resolución (Ej: Máximo 720p de ancho)
      const maxAncho = 1280;
      let ancho = video.videoWidth;
      let alto = video.videoHeight;

      if (ancho > maxAncho) {
        alto = Math.round((maxAncho / ancho) * alto);
        ancho = maxAncho;
      }

      const canvas = document.createElement('canvas');
      canvas.width = ancho;
      canvas.height = alto;
      const ctx = canvas.getContext('2d');

      const stream = canvas.captureStream(30); // 30 FPS
      const mediaRecorder = new MediaRecorder(stream, { 
        mimeType: 'video/mp4;codecs=avc1.42E01E',
        videoBitsPerSecond: 1500000 
      });
      
      const chunks = [];
      mediaRecorder.ondataavailable = (e) => chunks.push(e.data);
      
      mediaRecorder.onstop = () => {
        const blob = new Blob(chunks, { type: 'video/mp4' });
        // Crear un nuevo archivo manteniendo el nombre original
        const nuevoArchivo = new File([blob], originalName, { type: 'video/mp4' });
        URL.revokeObjectURL(video.src);
        resolve(nuevoArchivo);
      };

      video.play();
      mediaRecorder.start();

      function procesarCuadro() {
        if (video.paused || video.ended) {
          if (typeof onProgress === 'function') onProgress(100);
          mediaRecorder.stop();
          return;
        }
        ctx.drawImage(video, 0, 0, ancho, alto);

        if (typeof onProgress === 'function' && video.duration) {
          const porcentaje = Math.round((video.currentTime / video.duration) * 100);
          onProgress(porcentaje);
        }

        requestAnimationFrame(procesarCuadro);
      }
      
      procesarCuadro();
    };

    video.onerror = (err) => reject(err);
  });
}


function handleVideoResults(message) {
  console.log('Handling video results:', message);

  resultsEl.style.display = 'block';
  analysisDataEl.innerHTML = '';

  const imagePreview = resultsEl.querySelector('.image-preview');

  let videoElement = document.querySelector('#uploadedVideo');
  if (!videoElement) {
    videoElement = document.createElement('video');
    videoElement.id = 'uploadedVideo';
    videoElement.className = 'video-preview-element'; 
    
    videoElement.controls = true; 
    videoElement.autoplay = true; 
    videoElement.muted = true;    
    videoElement.setAttribute('playsinline', 'true');
    
    if (imagePreview) {
      imagePreview.appendChild(videoElement); 
    } else {
      resultsEl.prepend(videoElement);
    }
  }

  if (typeof URLvideo !== 'undefined' && URLvideo) {
    videoElement.src = URLvideo;
    videoElement.load();
    videoElement.play().catch(e => console.log("Autoplay bloqueado o requiere interacción:", e));
  }

  const oldImg = document.querySelector('#uploadedImage');
  if (oldImg) oldImg.style.display = 'none';
  videoElement.style.display = 'block';


  const labels = message.labels || message.Labels || [];
  if (Array.isArray(labels) && labels.length > 0) {
    const section = document.createElement('div');
    section.className = 'result-section';
    section.innerHTML = '<h3>🎥 Video Labels</h3>';

    labels.forEach((labelItem) => {
      const label = labelItem.Label || labelItem;
      const name = label.Name || 'Unknown';
      const confidence = Math.round(label.Confidence || 0);

      const item = document.createElement('div');
      item.className = 'result-item';
      
      item.innerHTML = `
        <strong>${name}</strong>
        <span>- Confidence: <span class="confidence">${confidence}%</span></span>
      `;
      section.appendChild(item);
    });

    analysisDataEl.appendChild(section);
    
    if (typeof intervalId !== 'undefined') {
      clearInterval(intervalId);
    }
    
    statusEl.textContent = 'Done!';
    statusEl.className = 'status-message success';
    return;
  }

  const fallback = document.createElement('pre');
  fallback.className = 'result-item';
  fallback.style.whiteSpace = 'pre-wrap'; 
  fallback.style.width = '100%';
  fallback.textContent = JSON.stringify(message, null, 2);
  analysisDataEl.appendChild(fallback);

  if (typeof intervalId !== 'undefined') {
    clearInterval(intervalId);
  }
  statusEl.textContent = 'Video analysis complete — raw payload shown.';
  statusEl.className = 'status-message';
  console.warn('Message has no labels:', message);
}



const fileUpload = document.querySelector('.file-upload');
const uploadText = document.querySelector('.upload-text');
const uploadIcon = document.querySelector('.upload-icon');


fileInput.addEventListener('change', async () => {
  fileToShow = fileInput.files[0]
  const file = fileInput.files[0];
  URLvideo = URL.createObjectURL(fileInput.files[0]);
  console.log('File selected:', file);
  
  if (file) {
    uploadButton.disabled = true;
    ;
    
    const randomMessagesInterval = [
      '🔍 Downsizing the video video...',
      '🤖 Working on it...',
      '⏳ This may take a moment...',
      '🔬 It is trying...hold on...',
      '🧠 Processing it...',
      '🚀 Almost there buddy...'
    ];
    intervalIdreducingVideo = setInterval(() => {
      const randomMessagesIntervalmsg = randomMessagesInterval[Math.floor(Math.random() * randomMessagesInterval.length)];
      uploadText.textContent = randomMessagesIntervalmsg
    }, 1900);
    
    try {
      videoReducidoGlobal = await reducirTamanoVideo(file, file.name, (porcentaje) => {
        barra.hidden = false;
        texto.hidden = false;
        barra.value = porcentaje
        texto.textContent = `${porcentaje}%`;
        console.log(`Progreso: ${porcentaje}%`);
        
        // Hide progress bar when at 100%
        if (porcentaje === 100) {
          barra.hidden = true;
          texto.hidden = true;
          texto.innerText = 'Completed!';
        }
      });
      
      // Actualizar interfaz tras éxito
      uploadIcon.textContent = '✅';
      uploadText.textContent = `File reduced: ${videoReducidoGlobal.name}`;
      fileUpload.classList.add('is-uploaded'); 
      uploadButton.disabled = false;
      
      console.log('Vido ready:', videoReducidoGlobal);
      clearInterval(intervalIdreducingVideo);
    } catch (error) {
      clearInterval(intervalIdreducingVideo);
      console.error('Error processing video:', error);
      uploadText.textContent = 'Error processing video.';
    }
  }
  
});

uploadButton.addEventListener('click', async () => {
  const videoFile = videoReducidoGlobal;
  const detectionMode = '/videos';
  if (!videoFile) {
    statusEl.textContent = '⚠️ Please select a video first.';
    statusEl.className = 'status-message error';
    return;
  }
  
  if (videoFile.type !== 'video/mp4' && videoFile.type !== 'video/mov') {
    statusEl.textContent = '⚠️ This file type is not supported. Please select a video file.';
    statusEl.className = 'status-message error';
    return;
  }

  if (videoFile.size > 15 * 1024 * 1024) {
    statusEl.textContent = '⚠️ Video is too large. Please select a video smaller than 15.0 MB.';
    statusEl.className = 'status-message error';
    return;
  }
    console.log('Selected file:', videoFile.type, videoFile.size);

  // Create a FormData container
  const formData = new FormData();
  formData.append('video', videoFile);
  formData.append('detectionMode', detectionMode);
  formData.append('WebSocketConnectionId', connection_id);



  
  const apiEndpoint = `${apiBaseUrl}${detectionMode}`;

  statusEl.textContent = `🔗 Requesting upload URL for video detection...`;
  statusEl.className = 'status-message';
  uploadButton.disabled = true;
  console.log('Requesting presigned URL from API:', apiEndpoint, 'with detection mode:', detectionMode);

  try {
    const presignedResponse = await fetch(apiEndpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        filename: videoFile.name,
        contentType: videoFile.type,
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

    statusEl.textContent = '📤 Uploading video to secure storage...';
    console.log('Uploading to URL:', uploadUrl);

    const uploadResponse = await fetch(uploadUrl, {
      method: 'PUT',
      headers: {
        'Content-Type': videoFile.type,
        'x-amz-meta-connection_id': connection_id,
        'x-amz-meta-detection_mode': 'videos',
        'x-amz-meta-domainName': wss, 
        'x-amz-meta-image_id': data.lastpart, 
        'x-amz-meta-stage': 'default'
      },
      body: videoFile,
    });

    if (!uploadResponse.ok) {
      const errorText = await uploadResponse.text();
      throw new Error(`Upload failed: ${uploadResponse.status} ${errorText}`);
    }

    statusEl.textContent = `✅ Upload successful! Starting AI analysis.....`;
    statusEl.className = 'status-message success';
    const randomMessages = [
      '🔍 Analyzing the video...',
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
    uploadButton.disabled = false;
    fileInput.value = ''; 
    videoReducidoGlobal = null;  
    uploadIcon.textContent = '📁';
    uploadText.textContent = 'Choose a video or drag & drop';
    
    fileUpload.classList.remove('is-uploaded');
  }
});