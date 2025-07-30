import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roti_515/core/theme/app_theme.dart'; // Tambahkan font agar senada

class AuthTextField extends StatelessWidget {
  final String hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onTogglePassword;
  final TextEditingController controller;

  const AuthTextField({
    super.key,
    required this.hintText,
    required this.prefixIcon,
    required this.controller,
    this.isPassword = false,
    this.obscureText = false,
    this.onTogglePassword,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? obscureText : false, // Pastikan obscureText hanya jalan jika isPassword true
      style: GoogleFonts.plusJakartaSans(color: context.colors.textDark, fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.plusJakartaSans(color: context.colors.textHint, fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: context.colors.textHint, size: 20),
        
        // Icon mata untuk password
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: context.colors.textHint, 
                  size: 20,
                ),
                onPressed: onTogglePassword,
              )
            : null,

        // Border bawah sesuai desain Figma
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: context.colors.divider, width: 1.5),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: context.colors.primary, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
