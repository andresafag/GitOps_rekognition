const apiBaseUrl = CONFIG.BASE_URL;
const socket = new WebSocket(CONFIG.SOCKET);
const wss = CONFIG.WSS;

console.log('API Base URL:', apiBaseUrl);
console.log('WebSocket URL:', CONFIG.SOCKET);
console.log('WSS URL:', CONFIG.WSS);

// 2. Handle connection opening
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
socket.onmessage = (event) => {
    const message = JSON.parse(event.data);

        if (message.connectionId) {
        connection_id = message.connectionId;
        console.log('ID de conexión listo:', connection_id);
        return; // Salimos de la función, no hay nada que mostrar aún
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



// 4. Handle errors and closing [2, 3]
socket.onerror = (error) => console.error('WebSocket Error:', error);
socket.onclose = () => console.log('Disconnected from WebSocket');

function getSelectedDetectionMode() {
  const selected = document.querySelector('input[name="detectionMode"]:checked');
  return selected ? selected.value : 'labels';
}

function displayResultsExplicit(data) {
  resultsEl.style.display = 'block';
  analysisDataEl.innerHTML = '';

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
  resultsEl.style.display = 'block';
  analysisDataEl.innerHTML = '';
  let imgElement = document.getElementById("mi-imagen");
  imgElement.src = ''; // Limpia la imagen antes de mostrar la nueva
    if (!imgElement) {
    imgElement = document.createElement('img');
    imgElement.id = "mi-imagen";
    imgElement.style.maxWidth = "100%"; // Ajuste básico de estilo
    resultsEl.prepend(imgElement); // Lo pone al principio del div de resultados
    }

    imgElement.src = `data:${type};base64,${filename}`;

  if (detectionMode === 'labels') {
      const section = document.createElement('div');
      section.className = 'result-section';
      section.innerHTML = '<h3>📋 Detected Labels</h3>';

  for (const itemData of data) {
      const item = document.createElement('div');
      item.className = 'result-item';

      item.innerHTML = `
        <strong>${itemData.name}</strong> - Confidence: 
        <span class="confidence">${itemData.confidence}%</span>

      `;
      section.appendChild(item);
      section.appendChild(imgElement);
  }


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
        return
      }

      for (const itemData of data) {
        const item = document.createElement('div');
        item.className = 'result-item';
        item.innerHTML = `
  <strong>${itemData.name}</strong> - Confidence: <span class="confidence">${itemData.confidence}%</span>
  ${itemData.urls && itemData.urls.length > 0 
    ? `<div class="links-section">
        ${itemData.urls.map(url => `
          <br>🔗 <a href="https://${url}" target="_blank">More info ${url}</a>
        `).join('')}
       </div>`
    : ''}
`;;
        section.appendChild(item);
      }
      analysisDataEl.appendChild(section);

  }
}

uploadButton.addEventListener('click', async () => {
  const file = fileInput.files[0];
  if (!file) {
    statusEl.textContent = '⚠️ Please select an image first.';
    statusEl.className = 'status-message error';
    return;
  }

  // Validate file type
  const allowedTypes = ['image/jpeg', 'image/png'];
  if (!allowedTypes.includes(file.type)) {
    statusEl.textContent = '⚠️ Only JPEG and PNG images are supported. Please select a valid image file.';
    statusEl.className = 'status-message error';
    return;
  }

  const detectionMode = getSelectedDetectionMode();
  const routePath = detectionMode === 'celebrity' ? '/celebrity' : '/labels';
  const apiEndpoint = `${apiBaseUrl}${routePath}`;

  statusEl.textContent = `🔗 Requesting upload URL for ${detectionMode} detection...`;
  statusEl.className = 'status-message';
  uploadButton.disabled = true;
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
        WebSocketConnectionId: connection_id, // Include connection ID in the request body
      }),
    });

    if (!presignedResponse.ok) {
      const errorText = await presignedResponse.text();
      throw new Error(`Failed to get upload URL: ${presignedResponse.status} ${errorText}`);
    }

    const data = await presignedResponse.json();
    console.log('Received presigned URL data:', data);
    const uploadUrl = data.uploadUrl;
    const resultKey = data.resultKey;

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

    statusEl.textContent = `✅ Upload successful! Starting AI analysis...`;
    statusEl.className = 'status-message success';


  } catch (error) {
    stopRandomMessages();
    statusEl.textContent = `❌ Error: ${error.message}`;
    statusEl.className = 'status-message error';
  } finally {
    uploadButton.disabled = false;
  }
});