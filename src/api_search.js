
import { API_KEY } from './apiKey.js';

document.addEventListener('DOMContentLoaded', () => {
    // Lógica del Carrusel
    const slides = document.querySelectorAll('.carousel-slide');
    const dots = document.querySelectorAll('.dot');
    let currentSlide = 0;

    function showSlide(n) {
        slides[currentSlide].classList.remove('active');
        dots[currentSlide].classList.remove('active');
        currentSlide = (n + slides.length) % slides.length;
        slides[currentSlide].classList.add('active');
        dots[currentSlide].classList.add('active');
    }

    document.querySelector('.next').addEventListener('click', () => showSlide(currentSlide + 1));
    document.querySelector('.prev').addEventListener('click', () => showSlide(currentSlide - 1));

    // Lógica de Búsqueda API
    const searchBtn = document.getElementById('searchButton');
    const input = document.getElementById('figureName');
    const resultsSection = document.getElementById('results');
    const resultsContent = document.getElementById('historicalData');
    const status = document.getElementById('status');

    searchBtn.addEventListener('click', async () => {
        const name = input.value.trim();
        if (!name) return;

        status.innerText = "Buscando en los anales de la historia...";
        resultsSection.style.display = 'none';

        try {
            // Asumiendo que config.API_KEY existe en config.js
            const response = await fetch(`https://api.api-ninjas.com/v1/historicalfigures?name=${name}`, {
                headers: { 'X-Api-Key': `${API_KEY}` } 
            });

            const data = await response.json();

            if (data.length > 0) {
                status.innerText = "";
                resultsSection.style.display = 'block';
                resultsContent.innerHTML = '';

                for (const person of data) {
                    // Creamos el contenedor de la tarjeta
                    const card = document.createElement('div');
                    card.className = 'figure-card';

                    // Título del personaje
                    let htmlContent = `<h3>${person.name}</h3>`;

                    const wikiSummaryResponse = await fetch(`https://en.wikipedia.org/api/rest_v1/page/summary/${encodeURIComponent(person.name)}`);
                    const wikiSummary = await wikiSummaryResponse.json();
                    const wikiImageUrl = wikiSummary?.thumbnail?.source || '';

                    if (wikiImageUrl) {
                        htmlContent += `<img src="${wikiImageUrl}" alt="Imagen de ${person.name}" class="figure-image" />`;
                    }

                    htmlContent += `<p><span class="info-label">Título/Rol:</span> ${person.title || 'N/A'}</p>`;
                    htmlContent += `<hr style="border: 0; border-top: 1px solid #ddd; margin: 10px 0;">`;
                    
                    // Ciclo FOR para recorrer el objeto 'info'
                    htmlContent += `<div>`;
                    for (const key in person.info) {
                        // Formateamos la clave (quitamos guiones bajos y ponemos mayúscula)
                        const label = key.replace(/_/g, ' ');
                        htmlContent += `
                            <p style="margin: 5px 0;">
                                <span class="info-label" style="text-transform: capitalize;">${label}:</span> 
                                ${person.info[key]}
                            </p>`;
                    }
                    htmlContent += `</div>`;

                    card.innerHTML = htmlContent;
                    resultsContent.appendChild(card);
                }
            } else {
                status.innerText = "No se encontraron personajes con ese nombre.";
            }
        } catch (error) {
            status.innerText = "Error al conectar con la biblioteca histórica.";
            console.error(error);
        }
    });
});
