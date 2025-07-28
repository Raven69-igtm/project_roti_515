import 'dart:convert'; // Untuk melakukan encoding/decoding JSON saat mengirim data ke API
import 'package:flutter/material.dart'; // Library utama Flutter untuk membangun antarmuka pengguna (UI)
import 'package:http/http.dart'
    as http; // Digunakan untuk melakukan HTTP request (GET, POST, dll) ke backend

import 'package:google_fonts/google_fonts.dart'; // Library untuk menggunakan font Google secara langsung

// Mengimpor utilitas PremiumSnackbar untuk menampilkan pesan notifikasi/error
import '../../../core/utils/premium_snackbar.dart';
// Mengimpor daftar rute untuk navigasi antar halaman
import '../../../routes/app_routes.dart';
// Mengimpor file ApiService yang menyimpan alamat endpoint backend
import '../../../core/network/api_service.dart';

// Mengimpor komponen-komponen UI modular khusus untuk halaman login
import '../widgets/login_logo.dart';
import '../widgets/login_tab_selector.dart';
import '../widgets/login_input_field.dart';
import '../widgets/login_button.dart';
import '../widgets/login_footer.dart';
import 'package:roti_515/core/theme/app_theme.dart';

// Kelas utama untuk Halaman Login. Menggunakan StatefulWidget karena halamannya interaktif dan state-nya bisa berubah.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// State dari LoginScreen, menggunakan SingleTickerProviderStateMixin agar bisa menggunakan kontroler animasi seperti TabController
class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // Controller untuk menangkap dan membaca teks yang diketik di kolom input Email
  final TextEditingController _emailController = TextEditingController();
  // Controller untuk menangkap teks di kolom input Password
  final TextEditingController _passwordController = TextEditingController();
  // Controller untuk mengelola tab "User" dan "Admin"
  late TabController _tabController;

  // Variabel penanda (flag) apakah proses loading sedang berjalan
  bool _isLoading = false;
  // Variabel untuk menyembunyikan atau menampilkan password (true = sembunyi)
  bool _isObscure = true;

  // Getter singkat untuk mengambil URL endpoint login dari ApiService terpusat
  String get _apiUrl => ApiService.login;

  @override
  void initState() {
    super.initState();
    // Menginisialisasi TabController dengan 2 tab ("User" dan "Admin")
    _tabController = TabController(length: 2, vsync: this);
    // Menambahkan listener untuk membangun ulang layar saat perpindahan tab terjadi
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    // Mematikan controller untuk membersihkan memory saat halaman ditutup (mencegah memory leak)
    _emailController.dispose();
    _passwordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Fungsi asinkron yang dieksekusi saat tombol Login ditekan
  Future<void> _login() async {
    // Validasi sederhana: hentikan jika email atau password kosong
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      PremiumSnackbar.showError(context, "Email dan Password wajib diisi");
      return;
    }

    // Mengubah statur loading menjadi true agar tombol berubah jadi ikon berputar
    setState(() => _isLoading = true);

    try {
      // Mengirimkan permintaan HTTP POST ke backend
      final response = await http
          .post(
            Uri.parse(_apiUrl), // URL API dari konfigurasi network
            headers: {
              "Content-Type": "application/json",
            }, // Tipe konten berupa JSON
            body: jsonEncode({
              "email": _emailController.text
                  .trim(), // Data email, hapus spasi berlebih
              "password": _passwordController.text, // Data password
            }),
          )
          .timeout(Duration(seconds: 10)); // Diberi batas waktu 10 detik

      // Mengurai string JSON dari server menjadi objek (Map) Dart
      final data = jsonDecode(response.body);

      // Jika balasan statusnya 200 (OK/Sukses), serta widget masih terpasang (mounted)
      if (response.statusCode == 200 && mounted) {
        // Ambil token dan data user dari JSON JSON respon
        final String token = data['token'];
        final String userRole = data['user']['role'];
        final String userName = data['user']['name'];
        final String? photoUrl = data['user']['photo_url'];

        // Validasi kesesuaian tab dengan role dari database
        if (_tabController.index == 1 && userRole != 'admin') {
          PremiumSnackbar.showError(
            context,
            "Akun Pelanggan tidak bisa login di tab Admin",
          );
          return;
        }
        if (_tabController.index == 0 && userRole == 'admin') {
          PremiumSnackbar.showError(
            context,
            "Akun Admin silakan login melalui tab Admin",
          );
          return;
        }

        // Langsung pindah ke layar sukses dan bawa data auth-nya
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.loginSuccess,
          arguments: {
            'token': token,
            'role': userRole,
            'name': userName,
            'photoUrl': photoUrl,
            'isAdmin': userRole == 'admin',
          },
        );
      } else if (mounted) {
        // Tampilkan pesan error jika status code bukan 200 (misalnya salah password)
        PremiumSnackbar.showError(context, data['error'] ?? "Gagal login");
      }
    } catch (e) {
      // Cek apakah terjadi error lainnya (misal error koneksi internet)
      if (mounted) {
        PremiumSnackbar.showError(
          context,
          "Gagal terhubung ke server. Cek koneksi.",
        );
      }
    } finally {
      // Pastikan status loading dikembalikan ke false di akhir try/catch
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold merepresentasikan kerangka layar dasar dari desain material Flutter
    return Scaffold(
      backgroundColor: context.colors.authBackground, // Set warna latar layar
      body: SafeArea(
        // SafeArea menjaga agar widget tidak tertutup oleh poni/status bar layar HP
        child: SingleChildScrollView(
          // Agar seluruh isi halaman bisa di-scroll ke bawah saat keyboard muncul
          padding: EdgeInsets.symmetric(
            horizontal: 24.0,
            vertical: 16.0,
          ), // Jarak di kanan kiri
          child: Column(
            // Menata semua widget secara berurut ke bawah (vertikal)
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Widget Kustom Logo Login Aplikasi
              LoginLogo(),
              SizedBox(height: 32),

              // Menampilkan Pilihan Tab (User / Admin)
              LoginTabSelector(controller: _tabController),
              SizedBox(height: 32),

              // Widget kustom Input TextField untuk Email
              LoginInputField(
                controller: _emailController,
                label: "Email",
                hint: "Masukkan Email Atau Nama Pengguna",
                icon: Icons.mail_outline_rounded,
              ),
              SizedBox(height: 20),

              // Widget kustom Input TextField untuk Kata Sandi (Password)
              LoginInputField(
                controller: _passwordController,
                label: "Password",
                hint: "Masukkan Password",
                icon: Icons.lock_outline_rounded,
                isPassword:
                    true, // Menandakan bahwa textfield ini bertindak sebagai tempat password (termasuk menutupi teks)
                obscureText: _isObscure, // Status bool teks terlihat/sembunyi
                onSuffixTap: () => setState(
                  () => _isObscure = !_isObscure,
                ), // SetState membalikkan visibilitas
              ),

              // Bagian Lupa Password yang diletakkan rata kanan (centerRight)
              if (_tabController.index == 0) // Hanya tampil di tab User
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.forgotPassword),
                    child: Text(
                      "Lupa Password?",
                      style: GoogleFonts.plusJakartaSans(
                        color: context.colors.primaryOrange,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              SizedBox(height: 16),

              // Tombol Login Kustom yang menyematkan status memuat (loading) dan trigger fungsi _login
              LoginButton(isLoading: _isLoading, onPressed: _login),
              SizedBox(height: 32),

              // Widget tulisan "Belum punya akun? Daftar" - Hanya tampil di tab User
              if (_tabController.index == 0) LoginFooter(),

              const SizedBox(
                height: 40,
              ), // Jarak terluar agar isi tidak mepet di akhir guliran layar
            ],
          ),
        ),
      ),
    );
  }
}
