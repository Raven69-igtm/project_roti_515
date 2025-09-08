import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roti_515/core/theme/app_theme.dart';

// Layar statis Syarat & Ketentuan aplikasi Roti 515
class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgColor,
      appBar: AppBar(
        backgroundColor: context.colors.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.colors.textDark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Syarat & Ketentuan',
          style: GoogleFonts.plusJakartaSans(
            color: context.colors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader("Selamat datang di Roti 515. Dengan menggunakan aplikasi kami, Anda menyetujui syarat dan ketentuan berikut:"),
            const SizedBox(height: 24),
            _buildSection(
              "1. Penerimaan Ketentuan",
              "Dengan mengakses atau menggunakan aplikasi Roti 515, Anda dianggap telah membaca, memahami, dan menyetujui untuk terikat oleh Syarat dan Ketentuan ini.",
            ),
            _buildSection(
              "2. Pemesanan dan Pembayaran",
              "Semua pesanan yang dilakukan melalui aplikasi bergantung pada ketersediaan stok produk. Pembayaran harus dilakukan melalui metode yang tersedia di aplikasi. Harga dapat berubah sewaktu-waktu tanpa pemberitahuan sebelumnya.",
            ),
            _buildSection(
              "3. Pengambilan Pesanan",
              "Roti 515 tidak menyediakan layanan pengiriman. Seluruh pesanan yang telah dikonfirmasi wajib diambil secara mandiri oleh pelanggan di lokasi toko kami. Pelanggan wajib datang sesuai dengan hari dan jam yang telah ditentukan saat melakukan pemesanan.",
            ),
            _buildSection(
              "4. Pembatalan dan Pengembalian",
              "Pesanan yang sudah diproses atau sudah melewati jadwal pengambilan tidak dapat dibatalkan. Pengembalian dana atau penggantian produk hanya berlaku jika terjadi kesalahan dari pihak kami (produk rusak atau salah item) yang terdeteksi saat proses pengambilan di toko.",
            ),
            _buildSection(
              "5. Akun Pengguna",
              "Anda bertanggung jawab untuk menjaga kerahasiaan informasi akun dan password Anda. Anda menyetujui untuk bertanggung jawab atas semua aktivitas yang terjadi di bawah akun Anda.",
            ),
            _buildSection(
              "6. Hak Kekayaan Intelektual",
              "Seluruh konten dalam aplikasi ini, termasuk namun tidak terbatas pada teks, grafik, logo, dan gambar adalah milik Roti 515 dan dilindungi oleh undang-undang hak cipta.",
            ),
            _buildSection(
              "7. Batasan Tanggung Jawab",
              "Roti 515 tidak bertanggung jawab atas kerugian tidak langsung, insidental, atau konsekuensial yang timbul dari penggunaan atau ketidakmampuan untuk menggunakan aplikasi kami.",
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                "© 2026 Roti 515. All Rights Reserved.",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textHint,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: const Color(0xFF64748B),
        height: 1.5,
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF475569),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
