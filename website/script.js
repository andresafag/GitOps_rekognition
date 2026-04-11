const apiBaseUrl = "https://0zvrkezghi.execute-api.us-east-1.amazonaws.com";

// Carousel functionality
let currentSlide = 0;
const slides = document.querySelectorAll('.carousel-slide');
const dots = document.querySelectorAll('.dot');

function showSlide(index) {
  slides.forEach(slide => slide.classList.remove('active'));
  dots.forEach(dot => dot.classList.remove('active'));

  currentSlide = index;
  if (currentSlide >= slides.length) currentSlide = 0;
  if (currentSlide < 0) currentSlide = slides.length - 1;

  slides[currentSlide].classList.add('active');
  dots[currentSlide].classList.add('active');
}

function nextSlide() {
  showSlide(currentSlide + 1);
}

function prevSlide() {
  showSlide(currentSlide - 1);
}

// Initialize carousel
if (slides.length > 0) {
  showSlide(0);

  // Auto-play carousel
  setInterval(nextSlide, 5000);

  // Event listeners for carousel controls
  document.querySelector('.carousel-btn.next').addEventListener('click', nextSlide);
  document.querySelector('.carousel-btn.prev').addEventListener('click', prevSlide);

  dots.forEach((dot, index) => {
    dot.addEventListener('click', () => showSlide(index));
  });
}

// File upload functionality
const fileInput = document.getElementById('fileInput');
const uploadButton = document.getElementById('uploadButton');
const statusEl = document.getElementById('status');
const resultsEl = document.getElementById('results');
const uploadedImageEl = document.getElementById('uploadedImage');
const analysisDataEl = document.getElementById('analysisData');

// Random analysis messages
const analysisMessages = [
  "Analyzing your image...",
  "Cooking the pixels...",
  "Scanning for objects...",
  "Detecting faces...",
  "Processing with AI magic...",
  "Finding interesting features...",
  "Running computer vision algorithms...",
  "Examining every detail...",
  "Almost there...",
  "Finalizing analysis..."
];

let messageInterval;

function startRandomMessages() {
  let messageIndex = 0;
  messageInterval = setInterval(() => {
    statusEl.textContent = analysisMessages[messageIndex % analysisMessages.length];
    messageIndex++;
  }, 2000);
}

function stopRandomMessages() {
  if (messageInterval) {
    clearInterval(messageInterval);
    messageInterval = null;
  }
}

// File input handling
fileInput.addEventListener('change', () => {
  uploadButton.disabled = !fileInput.files.length;
  statusEl.textContent = '';
  statusEl.className = '';
  resultsEl.style.display = 'none';
});

// Drag and drop functionality
const uploadArea = document.querySelector('.upload-area');

uploadArea.addEventListener('dragover', (e) => {
  e.preventDefault();
  uploadArea.style.borderColor = '#3498db';
  uploadArea.style.background = '#ecf0f1';
});

uploadArea.addEventListener('dragleave', () => {
  uploadArea.style.borderColor = '#bdc3c7';
  uploadArea.style.background = '#f8f9fa';
});

uploadArea.addEventListener('drop', (e) => {
  e.preventDefault();
  uploadArea.style.borderColor = '#bdc3c7';
  uploadArea.style.background = '#f8f9fa';

  const files = e.dataTransfer.files;
  if (files.length > 0) {
    fileInput.files = files;
    fileInput.dispatchEvent(new Event('change'));
  }
});

// Remove the click event listener since the label already handles clicking the input
// uploadArea.addEventListener('click', () => {
//   fileInput.click();
// });

function getSelectedDetectionMode() {
  const selected = document.querySelector('input[name="detectionMode"]:checked');
  return selected ? selected.value : 'labels';
}

function displayResults(data, detectionMode) {
  resultsEl.style.display = 'block';
  uploadedImageEl.src = URL.createObjectURL(fileInput.files[0]);
  analysisDataEl.innerHTML = '';

  if (detectionMode === 'labels') {
    const labels = data.labels || [];
    if (labels.length > 0) {
      const section = document.createElement('div');
      section.className = 'result-section';
      section.innerHTML = '<h3>📋 Detected Labels</h3>';
      labels.slice(0, 10).forEach(label => { // Limit to top 10
        const item = document.createElement('div');
        item.className = 'result-item';
        item.innerHTML = `
          <strong>${label.Name}</strong> - Confidence: <span class="confidence">${label.Confidence.toFixed(1)}%</span>
        `;
        section.appendChild(item);
      });
      analysisDataEl.appendChild(section);
    } else {
      analysisDataEl.innerHTML = '<p>No labels detected in this image.</p>';
    }
  } else if (detectionMode === 'celebrity') {
    const celebrities = data.celebrities || [];
    const unrecognized = data.unrecognizedFaces || [];
    if (celebrities.length > 0) {
      const section = document.createElement('div');
      section.className = 'result-section';
      section.innerHTML = '<h3>⭐ Recognized Celebrities</h3>';
      celebrities.forEach(celeb => {
        const item = document.createElement('div');
        item.className = 'result-item';
        item.innerHTML = `
          <strong>${celeb.Name}</strong> - Confidence: <span class="confidence">${celeb.MatchConfidence.toFixed(1)}%</span>
          ${celeb.Urls ? `<br>🔗 <a href="${celeb.Urls[0]}" target="_blank">More info</a>` : ''}
        `;
        section.appendChild(item);
      });
      analysisDataEl.appendChild(section);
    }
    if (unrecognized.length > 0) {
      const section = document.createElement('div');
      section.className = 'result-section';
      section.innerHTML = `<h3>👤 Unrecognized Faces</h3><p>${unrecognized.length} face(s) detected but not recognized as celebrities.</p>`;
      analysisDataEl.appendChild(section);
    }
    if (celebrities.length === 0 && unrecognized.length === 0) {
      analysisDataEl.innerHTML = '<p>No faces detected in this image.</p>';
    }
  }
}

async function waitForResults(resultUrl, detectionMode, maxAttempts = 60) {
  startRandomMessages();

  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      const response = await fetch(resultUrl);
      if (response.ok) {
        stopRandomMessages();
        const data = await response.json();
        displayResults(data, detectionMode);
        statusEl.textContent = '✨ Analysis complete!';
        statusEl.className = 'status-message success';
        return;
      } else if (response.status === 404) {
        // Result not ready yet, continue polling
        console.log(`Attempt ${attempt + 1}: Result not ready (404)`);
      } else {
        const errorText = await response.text();
        throw new Error(`Unexpected response: ${response.status} ${response.statusText} - ${errorText}`);
      }
    } catch (error) {
      console.error('Error fetching results:', error);
      if (!error.message.includes('Unexpected response')) {
        // Network error, continue polling
        console.log(`Attempt ${attempt + 1}: Network error, retrying`);
      } else {
        stopRandomMessages();
        throw error;
      }
    }
    await new Promise(resolve => setTimeout(resolve, 3000)); // Wait 3 seconds
  }

  stopRandomMessages();
  statusEl.textContent = '⏰ Analysis timed out. Results may still be processing. Check the S3 bucket manually.';
  statusEl.className = 'status-message error';
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

  try {
    const presignedResponse = await fetch(apiEndpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        filename: file.name,
        contentType: file.type,
      }),
    });

    if (!presignedResponse.ok) {
      const errorText = await presignedResponse.text();
      throw new Error(`Failed to get upload URL: ${presignedResponse.status} ${errorText}`);
    }

    const data = await presignedResponse.json();
    const uploadUrl = data.uploadUrl;
    const resultKey = data.resultKey;

    statusEl.textContent = '📤 Uploading image to secure storage...';

    const uploadResponse = await fetch(uploadUrl, {
      method: 'PUT',
      headers: {
        'Content-Type': file.type,
        'x-amz-meta-detection-mode': detectionMode,
      },
      body: file,
    });

    if (!uploadResponse.ok) {
      const errorText = await uploadResponse.text();
      throw new Error(`Upload failed: ${uploadResponse.status} ${errorText}`);
    }

    statusEl.textContent = `✅ Upload successful! Starting AI analysis...`;
    statusEl.className = 'status-message success';

    if (resultKey) {
      const resultEndpoint = `${apiBaseUrl}/results?key=${encodeURIComponent(resultKey)}`;
      console.log('Result endpoint:', resultEndpoint);
      await waitForResults(resultEndpoint, detectionMode);
    } else {
      statusEl.textContent = '⚠️ Upload successful, but unable to retrieve results.';
      statusEl.className = 'status-message error';
    }
  } catch (error) {
    stopRandomMessages();
    statusEl.textContent = `❌ Error: ${error.message}`;
    statusEl.className = 'status-message error';
  } finally {
    uploadButton.disabled = false;
  }
});
