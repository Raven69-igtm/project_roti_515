import 'package:roti_515/core/theme/app_theme.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// --- IMPORT COMPONENT WIDGETS ---
import '../widgets/login_back_button.dart';
import '../widgets/register_header.dart';
import '../widgets/register_title.dart';
import '../widgets/register_input_field.dart';
import '../widgets/register_terms_checkbox.dart';
import '../widgets/register_button.dart';
import '../widgets/register_footer.dart';

// --- IMPORT PONDASI ---
import '../../../core/utils/premium_snackbar.dart';
import '../../../core/network/api_service.dart'; 
import '../../../routes/app_routes.dart'; 

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isObscure = true;
  bool _isAgreed = false; 

  final String _apiUrl = ApiService.register;

  /// FUNGSI REGISTRASI:
  /// Menangani alur pendaftaran user baru ke backend.
  Future<void> _register() async {
    // Validasi: Pastikan user sudah mencentang Syarat & Ketentuan (S&K)
    if (!_isAgreed) {
      PremiumSnackbar.showError(context, "Harap setujui Syarat dan Ketentuan");
      return; 
    }

    // Mengaktifkan indikator loading (tombol akan berputar)
    setState(() => _isLoading = true);

    try {
      // Mengirim request POST ke server dengan data JSON
      final response = await http.post(
        Uri.parse(_apiUrl), // URL dari ApiService.register
        headers: {"Content-Type": "application/json"}, 
        body: jsonEncode({ 
          "name": _nameController.text, // Nama user dari input
          "email": _emailController.text, // Email user dari input
          "phone": _phoneController.text, // No HP dari input
          "password": _passwordController.text, // Password dari input
          "address": "", // Alamat (opsional/kosongkan dulu)
          "photo_url": "", // Foto (opsional/kosongkan dulu)
        }),
      );

      // Mendekode (Parsing) respon JSON dari server
      final data = jsonDecode(response.body);

      if (!context.mounted) return;
      final currentContext = context;

      // Cek status HTTP: 200 berarti sukses (berhasil terdaftar di DB)
      if (response.statusCode == 200) {
        PremiumSnackbar.showSuccess(currentContext, "Pendaftaran Sukses!");
        // Pindah ke halaman "Success Screen" setelah daftar
        Navigator.pushReplacementNamed(currentContext, AppRoutes.registerSuccess);
      } else {
        // Tampilkan pesan error jika gagal (misal email sudah terdaftar)
        PremiumSnackbar.showError(currentContext, data['error'] ?? "Pendaftaran Gagal");
      }
    } catch (e) {
      // Menangani error tak terduga (misal server mati/internet putus)
      if (!context.mounted) return;
      final currentContext = context;
      PremiumSnackbar.showError(currentContext, "Error koneksi: $e");
    } finally {
      // Mematikan indikator loading di akhir proses
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgColor, 
      body: Stack(
        children: [
          SingleChildScrollView( 
            child: Column(
              children: [
                RegisterHeader(),
    
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      SizedBox(height: 20), 
                      
                      RegisterTitle(),
    
                      SizedBox(height: 32),
    
                      RegisterInputField(
                        label: "Nama",
                        controller: _nameController, 
                        hint: "Masukkan Nama Pengguna", 
                        icon: Icons.person_outline_rounded,
                      ),
                      
                      SizedBox(height: 16),
                      RegisterInputField(
                        label: "Email",
                        controller: _emailController, 
                        hint: "Sawit123@gmail.com",
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress, 
                      ),
    
                      SizedBox(height: 16),
                      RegisterInputField(
                        label: "No. Handphone",
                        controller: _phoneController, 
                        hint: "(62+)8123456789",
                        icon: Icons.phone_android_outlined,
                        keyboardType: TextInputType.phone, // Mengubah tipe pop up keyboard menjadi Numpad khusus telp
                      ),
    
                      SizedBox(height: 16),
                      RegisterInputField(
                        label: "Password",
                        controller: _passwordController, // Menautkan ke input string Password
                        hint: "••••••••",
                        icon: _isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, // Ikone mata berubah menyesuaikan flag
                        isPassword: true, // Flag Khusus password agar bintang-bintang 
                        obscureText: _isObscure, // Mengaburkan input menjadi bullet point (Terikat ke Stateful nilai true/false)
                        onSuffixTap: () => setState(() => _isObscure = !_isObscure), // Membalik Boolean dari mata buta(true) menjadi awas(false) atau sebaliknya saat tombol ditekan
                      ),
    
                      SizedBox(height: 24),
    
                      // --- 4. CHECKBOX TERMS ---
                      RegisterTermsCheckbox(
                        isAgreed: _isAgreed, // Param yg menghubungkan ke UI dengan status aktif sekarang
                        onChanged: (val) => setState(() => _isAgreed = val ?? false), // Aksi ketika checkBox disentuh
                      ),
    
                      SizedBox(height: 32),
    
                      // --- 5. TOMBOL DAFTAR (WITH FIGMA SHADOW) ---
                      RegisterButton(
                        isLoading: _isLoading, // Mengubah tombol jadi progress muter jika proses network
                        isAgreed: _isAgreed, // Mengunci tombol (abu abu dan tak bisa dipencet jika pengguna belum centang s&k)
                        onPressed: _register, // Trigger menjalankan fungsi asinkron (network memanggil Backend Golang)
                      ),
    
                      SizedBox(height: 24),
    
                      // --- 6. FOOTER PENGISI DI PALING BAWAH ---
                      RegisterFooter(),
                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Back Button floating at top
          if (Navigator.canPop(context)) 
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              child: LoginBackButton(),
            ),
        ],
      ),
    );
  }
}
