const nav = `
    <nav class="navbar">
        <div class="nav-container" id="navContainer">
            <div class="logo">
                <div class="logo-icon"></div>
                <span>VisionTag<span>AI</span></span>
            </div>
            
            <!-- Botón Hamburguesa Añadido -->
            <button class="nav-toggle" id="navToggle" aria-label="Abrir menú">☰</button>

            <ul class="nav-links" id="navLinks">
                <li><a href="index.html">Images</a></li>
                <li><a href="videolabels.html">Videos</a></li>
                <li><a href="text.html">Text</a></li>
                <li><a href="characters.html">Characters</a></li>
            </ul>
        </div>
    </nav>`;


document.getElementById('navbar-placeholder').innerHTML = nav;