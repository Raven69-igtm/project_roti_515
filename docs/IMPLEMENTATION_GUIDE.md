# Implementation Guide: Arsitektur & Teknis Roti 515

Dokumen ini menjelaskan detail teknis implementasi untuk pengembang yang ingin melanjutkan atau memodifikasi proyek Roti 515.

## 1. Manajemen State (Provider)
Aplikasi menggunakan paket `provider` untuk manajemen state yang efisien dan terorganisir.
- **AuthProvider**: Mengelola status login, penyimpanan token di `shared_preferences`, dan data user profil.
- **ProductProvider**: Menangani pengambilan data produk dari API, caching lokal sementara, dan logika pemfilteran kategori.
- **CartProvider**: Mengelola *logic* keranjang belanja (tambah, kurang, hapus item) secara lokal sebelum dikirim ke server saat checkout.
- **AdminStatsProvider**: Khusus mengambil data statistik untuk dashboard admin dan memformatnya agar sesuai dengan kebutuhan `fl_chart`.

## 2. Jaringan & API (ApiService)
Semua komunikasi ke backend dipusatkan di `lib/core/network/api_service.dart`.
- **Base URL**: `http://localhost:8080/api` (Dapat diubah ke IP server atau domain produksi).
- **Resolusi Gambar**: Fungsi `getDisplayImage` memastikan URL gambar valid baik saat menggunakan path lokal server (`/static/...`) maupun URL absolut (misal: dari Google Sign-In).

## 3. Komponen UI Kustom
- **StaggeredFadeAnimation**: Digunakan untuk memberikan efek animasi masuk yang halus pada list produk.
- **PremiumSnackBar**: Sistem notifikasi kustom di bagian atas layar untuk memberikan feedback sukses/error yang modern.
- **AnimatedSalesChart**: Implementasi grafik yang mendukung skala Y-axis dinamis berdasarkan data penjualan tertinggi.

## 4. Keamanan & Sesi
- **JWT Storage**: Token disimpan secara aman menggunakan `shared_preferences`.
- **Interceptors**: Setiap request yang membutuhkan autentikasi harus menyertakan Header `Authorization: Bearer <token>`.
- **Auto-Login**: Saat aplikasi dibuka, `authProvider.loadSession()` dijalankan di `main.dart` untuk mengecek apakah sesi masih valid.

## 5. Sinkronisasi Data (Backend-Frontend)
- **Real-time Updates**: Meskipun tidak menggunakan WebSocket, aplikasi menggunakan pola "Fetch on Action". Misalnya, setelah admin mengubah status pesanan, aplikasi akan memicu refresh data di sisi admin untuk merefleksikan perubahan terbaru.
- **Role Validation**: Validasi role dilakukan di dua sisi (Frontend untuk UI, Backend untuk keamanan API).

## 6. Panduan Deployment (Railway)
Karena Anda berencana menggunakan Railway, berikut adalah poin penting untuk deployment:

### A. Backend (Go)
1. **Dockerfile/Nixpacks**: Railway biasanya mendeteksi project Go secara otomatis. Pastikan file `main.go` berada di root atau tentukan `Build Command`.
2. **Environment Variables**: Masukkan variabel berikut di Dashboard Railway:
   - `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`.
   - `PORT` (Railway akan memberikan port dinamis, pastikan aplikasi Go membaca `os.Getenv("PORT")`).
3. **Database**: Gunakan layanan MySQL di Railway dan hubungkan ke service Go Anda.

### B. Frontend (Flutter Web)
1. Build aplikasi untuk web: `flutter build web`.
2. Deploy hasil folder `build/web` ke penyedia hosting statis (Railway, Netlify, atau Vercel).
3. **PENTING**: Pastikan `baseUrl` di `api_service.dart` sudah diarahkan ke domain Backend Railway Anda.

## 7. Pengembangan Selanjutnya (Roadmap)
- [ ] Implementasi Push Notifications menggunakan Firebase.
- [ ] Integrasi Payment Gateway (Midtrans/Xendit) untuk pembayaran non-tunai.
- [ ] Optimasi performa dengan image caching yang lebih agresif.
- [ ] Penambahan fitur ulasan produk dengan lampiran foto.
