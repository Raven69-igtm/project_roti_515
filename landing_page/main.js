// main.js – Roti 515 Landing Page

document.addEventListener('DOMContentLoaded', () => {
    const navbar    = document.getElementById('navbar');
    const hamburger = document.getElementById('hamburger');
    const btnApk    = document.getElementById('btn-apk');
    const btnWeb    = document.getElementById('btn-web');
    const btnNavCta = document.getElementById('btn-nav-cta');
    const btnHeroCta = document.getElementById('btn-hero-cta');

    // ── Navbar shadow on scroll ──
    window.addEventListener('scroll', () => {
        navbar.classList.toggle('scrolled', window.scrollY > 20);
    });

    // ── Mobile hamburger toggle ──
    hamburger.addEventListener('click', () => {
        navbar.classList.toggle('open');
    });

    // ── APK Download Button ──
    btnApk.addEventListener('click', () => {
        const mainText = btnApk.querySelector('.dl-main');
        const original = mainText.textContent;

        // Simulasi loading
        mainText.textContent = 'Menyiapkan...';
        btnApk.disabled = true;

        setTimeout(() => {
            mainText.textContent = '✓ Berhasil Diunduh!';
            // Memulai unduhan APK
            window.location.href = 'roti515.apk';
            
            setTimeout(() => {
                mainText.textContent = original;
                btnApk.disabled = false;
            }, 3000);
        }, 2000);
    });

    // ── Web App Button (Coming Soon) ──
    [btnWeb].forEach(btn => {
        if (!btn) return;
        btn.addEventListener('click', (e) => {
            e.preventDefault();
            showToast('🔧 Versi Web sedang dalam pengembangan. Segera hadir!');
        });
    });

    // Smooth scroll for navbar CTA & hero CTA
    [btnNavCta, btnHeroCta].forEach(btn => {
        if (!btn) return;
        btn.addEventListener('click', (e) => {
            const href = btn.getAttribute('href');
            if (href && href.startsWith('#')) {
                e.preventDefault();
                document.querySelector(href)?.scrollIntoView({ behavior: 'smooth' });
            }
        });
    });

    // ── Toast Notification Helper ──
    function showToast(message) {
        const existing = document.querySelector('.toast');
        if (existing) existing.remove();

        const toast = document.createElement('div');
        toast.className = 'toast';
        toast.textContent = message;
        toast.style.cssText = `
            position: fixed; bottom: 2rem; left: 50%; transform: translateX(-50%);
            background: #1A0E04; color: #fff; padding: 0.8rem 1.6rem;
            border-radius: 50px; font-family: 'Plus Jakarta Sans', sans-serif;
            font-size: 0.9rem; z-index: 9999; box-shadow: 0 8px 24px rgba(0,0,0,0.3);
            animation: fadeInUp 0.3s ease;
        `;
        document.body.appendChild(toast);

        setTimeout(() => {
            toast.style.opacity = '0';
            toast.style.transition = 'opacity 0.3s';
            setTimeout(() => toast.remove(), 300);
        }, 3500);
    }
});
