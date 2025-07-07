import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppStyles {
  // Gaya untuk Judul Besar
  static TextStyle titleLarge = GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  // Gaya untuk Deskripsi Biasa
  static TextStyle bodyText = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    color: AppColors.textGrey,
  );
}
