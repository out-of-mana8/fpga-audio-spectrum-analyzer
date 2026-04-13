document.addEventListener("DOMContentLoaded", () => {
    // 1. Scroll Reveal Logic using Intersection Observer
    const reveals = document.querySelectorAll('.reveal');

    const revealObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('active');
                observer.unobserve(entry.target); 
            }
        });
    }, {
        root: null,
        threshold: 0.1,
        rootMargin: "0px 0px -50px 0px"
    });

    reveals.forEach(reveal => revealObserver.observe(reveal));

    // Force first section to appear immediately
    if (reveals.length > 0) {
        setTimeout(() => reveals[0].classList.add('active'), 100);
    }

    // 2. Dynamic Audio Visualizer Background Simulation
    const canvas = document.getElementById('bg-canvas');
    const ctx = canvas.getContext('2d', { alpha: true });

    let width, height;
    
    function resize() {
        width = window.innerWidth;
        height = window.innerHeight;
        // Adjust for high DPI displays for crisp rendering
        canvas.width = width * window.devicePixelRatio;
        canvas.height = height * window.devicePixelRatio;
        ctx.scale(window.devicePixelRatio, window.devicePixelRatio);
    }

    window.addEventListener('resize', resize);
    resize();

    // Data for fake spectrum
    const BIN_COUNT = 64; 
    const bins = new Array(BIN_COUNT).fill(0);
    const targets = new Array(BIN_COUNT).fill(0);
    
    // Smooth animation parameters
    const ATTACK = 0.5;
    const DECAY = 0.05;

    // Colormap simulation (blue -> cyan -> green -> yellow -> red)
    function getColor(value, max) {
        const ratio = value / max;
        if (ratio < 0.2) return '#2386ff';
        if (ratio < 0.4) return '#00ffff';
        if (ratio < 0.6) return '#00ff66';
        if (ratio < 0.8) return '#ffee00';
        return '#ff3333';
    }

    function animate() {
        // Clear canvas
        ctx.clearRect(0, 0, width, height);

        // Periodically update targets to simulate audio hits
        if (Math.random() < 0.15) {
            // Pick a random peak frequency area
            let peakIdx = Math.floor(Math.random() * BIN_COUNT);
            let energy = Math.random() * (height * 0.4);
            
            // Apply gaussian-like spread around peak
            for(let i=0; i<BIN_COUNT; i++) {
                let dist = Math.abs(i - peakIdx);
                let hit = energy * Math.exp(-(dist*dist)/(2*4)); // standard deviation of 2
                if (hit > targets[i]) {
                    targets[i] = hit;
                }
            }
        }

        // Draw bars
        const barWidth = (width / BIN_COUNT);
        const gap = barWidth * 0.2;
        const actualWidth = barWidth - gap;

        for(let i=0; i<BIN_COUNT; i++) {
            // Smooth easing
            if (targets[i] > bins[i]) {
                bins[i] += (targets[i] - bins[i]) * ATTACK;
            } else {
                bins[i] -= bins[i] * DECAY;
            }

            // Decay targets slowly
            targets[i] *= 0.95;

            // Draw Bar
            let barHeight = bins[i];
            
            // Baseline
            const x = i * barWidth + (gap/2);
            const y = height;

            // Draw with glow
            ctx.shadowBlur = 10;
            ctx.shadowColor = getColor(barHeight, height*0.4);
            ctx.fillStyle = getColor(barHeight, height*0.4);
            ctx.globalAlpha = 0.6;
            
            // The bar graph drawn upwards from bottom
            ctx.fillRect(x, height - barHeight, actualWidth, barHeight);
        }
        
        ctx.globalAlpha = 1.0;
        ctx.shadowBlur = 0;

        requestAnimationFrame(animate);
    }

    animate();
});
