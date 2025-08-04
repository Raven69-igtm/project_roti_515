import 'package:roti_515/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterButton extends StatelessWidget {
  final bool isLoading;
  final bool isAgreed;
  final VoidCallback onPressed;
  final String? label;

  const RegisterButton({
    super.key,
    required this.isLoading,
    required this.isAgreed,
    required this.onPressed,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9999),
        boxShadow: [
          BoxShadow(
            color: context.colors.primaryOrange.withValues(alpha: 0.20),
            blurRadius: 15,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: (isLoading || !isAgreed) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.colors.primaryOrange,
          disabledBackgroundColor:
              context.colors.primaryOrange.withValues(alpha: 0.5),
          shape: StadiumBorder(),
          elevation: 0,
        ),
        child: isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Text(
                label ?? "Daftar",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
