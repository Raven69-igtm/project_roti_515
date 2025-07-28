import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/premium_snackbar.dart';
import '../../../routes/app_routes.dart';
import '../widgets/login_back_button.dart';
import '../widgets/login_input_field.dart';
import '../widgets/login_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 24, end: 0)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_animCtrl);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _verifyIdentity() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      PremiumSnackbar.showError(context, "Email wajib diisi");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiService.forgotPassword),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        PremiumSnackbar.showSuccess(context, "Identitas terverifikasi!");
        // Navigasi ke halaman reset password dengan email sebagai argumen
        Navigator.pushNamed(
          context,
          AppRoutes.resetPassword,
          arguments: {'email': email},
        );
      } else {
        PremiumSnackbar.showError(
          context,
          data['error'] ?? "Data tidak cocok. Periksa kembali isian Anda.",
        );
      }
    } catch (e) {
      if (mounted) {
        PremiumSnackbar.showError(context, "Gagal terhubung ke server. Cek koneksi.");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: AnimatedBuilder(
            animation: _slideAnim,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _slideAnim.value),
              child: child,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  LoginBackButton(),
                  const SizedBox(height: 32),

                  // Icon & Judul
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: context.colors.primaryOrange.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_reset_rounded,
                        color: context.colors.primaryOrange,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Center(
                    child: Text(
                      "Lupa Password?",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      "Masukkan email yang terdaftar untuk\nmereset password akun Anda.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: context.colors.textGrey,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colors.primaryOrange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.colors.primaryOrange.withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: context.colors.primaryOrange,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Pastikan email yang Anda masukkan sesuai dengan email yang terdaftar.",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: context.colors.primaryOrange,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Form Fields
                  LoginInputField(
                    controller: _emailController,
                    label: "Email",
                    hint: "Masukkan email terdaftar",
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 36),

                  // Tombol Verifikasi
                  LoginButton(
                    isLoading: _isLoading,
                    onPressed: _verifyIdentity,
                    text: "Verifikasi Identitas",
                  ),
                  const SizedBox(height: 24),

                  // Link kembali
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Kembali ke Login",
                        style: GoogleFonts.plusJakartaSans(
                          color: context.colors.primaryOrange,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
