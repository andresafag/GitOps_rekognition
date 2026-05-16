const apiBaseUrl = CONFIG.BASE_URL;
const socket = new WebSocket(CONFIG.SOCKET);
const wss = CONFIG.WSS;

console.log('API Base URL:', apiBaseUrl);
console.log('WebSocket URL:', CONFIG.SOCKET);
console.log('WSS URL:', CONFIG.WSS);
let intervalId;

socket.onopen = (event) => {
    console.log('Connected to WebSocket API');
    
    // Example: Sending a message to trigger a specific backend route named 'sendMessage'
    const payload = {
        action: 'sockets', // Matches the Route Key defined in API Gateway [8]
        data: 'Hello, world!'
    };
    socket.send(JSON.stringify(payload));
};

let connection_id = null;
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
        // handle explicit content notification here if needed
        return;
    }

    console.log('Unhandled WS message:', message);
};



socket.onerror = (error) => console.error('WebSocket Error:', error);
socket.onclose = () => console.log('Disconnected from WebSocket');

function handleVideoResults(message) {
  console.log('Handling video results:', message);

  resultsEl.style.display = 'block';
  analysisDataEl.innerHTML = '';

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
        <strong>${name}</strong> - Confidence: 
        <span class="confidence">${confidence}%</span>
      `;
      section.appendChild(item);
    });

    analysisDataEl.appendChild(section);
    statusEl.textContent = 'Video analysis complete';
    statusEl.className = 'status-message success';
    clearInterval(intervalId);
    return;
  }

  const fallback = document.createElement('pre');
  fallback.className = 'result-item';
  fallback.textContent = JSON.stringify(message, null, 2);
  analysisDataEl.appendChild(fallback);

  statusEl.textContent = 'Video analysis complete — raw payload shown.';
  statusEl.className = 'status-message';
  console.warn('Message has no labels:', message);
}

const fileUpload = document.querySelector('.file-upload');
const uploadText = document.querySelector('.upload-text');
const uploadIcon = document.querySelector('.upload-icon');


fileInput.addEventListener('change', () => {
  const file = fileInput.files[0];
  console.log('File selected:', file);
  if (file) {
    uploadIcon.textContent = '✅';
    uploadText.textContent = `Archivo cargado: ${file.name}`;
    fileUpload.classList.add('is-uploaded'); 
  }
});

uploadButton.addEventListener('click', async () => {
  const videoFile = fileInput.files[0];
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

  if (videoFile.size > 1000 * 1024 * 1024) {
    statusEl.textContent = '⚠️ Video is too large. Please select a video smaller than 1GB.';
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
  
  // 2. Restaura los textos e íconos originales
  uploadIcon.textContent = '📁';
  uploadText.textContent = 'Choose a video or drag & drop';
  
  // 3. Remueve los estilos de éxito
  fileUpload.classList.remove('is-uploaded');
  }
});