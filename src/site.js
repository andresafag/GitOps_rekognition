// File upload functionality
const fileInput = document.getElementById('fileInput');
const statusEl = document.getElementById('status');
const resultsEl = document.getElementById('results');
const uploadedImageEl = document.getElementById('uploadedImage');
const analysisDataEl = document.getElementById('analysisData');

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

