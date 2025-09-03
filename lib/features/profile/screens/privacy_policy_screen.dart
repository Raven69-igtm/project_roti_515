import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roti_515/core/theme/app_theme.dart';

// Layar statis Kebijakan Privasi aplikasi Roti 515
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Kebijakan Privasi',
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
            _buildHeader("Terakhir Diperbarui: 29 April 2026"),
            const SizedBox(height: 24),
            _buildSection(
              "1. Pengumpulan Informasi",
              "Kami mengumpulkan informasi yang Anda berikan langsung kepada kami saat Anda mendaftar akun, melakukan pemesanan, atau menghubungi layanan pelanggan kami. Informasi ini mencakup nama, alamat email, dan nomor telepon untuk keperluan verifikasi saat pengambilan pesanan.",
            ),
            _buildSection(
              "2. Penggunaan Informasi",
              "Informasi yang kami kumpulkan digunakan untuk memproses pesanan Anda, mengelola akun Anda, mengirimkan notifikasi status pesanan, dan jika Anda setuju, mengirimkan informasi mengenai promo atau produk terbaru kami. Kami tidak mengumpulkan alamat pengiriman karena seluruh pesanan wajib diambil langsung di toko.",
            ),
            _buildSection(
              "3. Keamanan Data",
              "Kami berkomitmen untuk menjaga keamanan data pribadi Anda. Kami menggunakan berbagai teknologi keamanan dan prosedur untuk membantu melindungi informasi pribadi Anda dari akses, penggunaan, atau pengungkapan yang tidak sah.",
            ),
            _buildSection(
              "4. Pengungkapan kepada Pihak Ketiga",
              "Kami tidak menjual, memperdagangkan, atau menyewakan informasi pribadi Anda kepada orang lain. Kami mungkin membagikan informasi agregat yang tidak terkait dengan informasi identitas pribadi apa pun mengenai pengunjung dan pengguna dengan mitra bisnis kami.",
            ),
            _buildSection(
              "5. Hak Anda",
              "Anda memiliki hak untuk mengakses, memperbarui, atau menghapus informasi pribadi Anda kapan saja melalui pengaturan profil di aplikasi kami.",
            ),
            _buildSection(
              "6. Perubahan Kebijakan",
              "Kami dapat memperbarui Kebijakan Privasi ini dari waktu ke waktu. Kami akan memberitahu Anda tentang perubahan apa pun dengan memposting Kebijakan Privasi baru di halaman ini.",
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                "Jika Anda memiliki pertanyaan tentang Kebijakan Privasi ini, silakan hubungi kami di support@roti515.com",
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: context.colors.textHint,
                  height: 1.5,
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
        fontWeight: FontWeight.w600,
        color: const Color(0xFF64748B),
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
