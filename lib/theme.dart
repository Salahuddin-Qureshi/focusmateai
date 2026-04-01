import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFF0F172A);
  static const Color accentViolet = Color(0xFF8B5CF6);
  static const Color accentCyan = Color(0xFF22D3EE);
  static const Color glassSecondary = Color(0x1A6366F1);
  static const Color textMain = Colors.white;
  static const Color textDim = Color(0xFF94A3B8);
}

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: GoogleFonts.outfitTextTheme(
      const TextTheme(
        headlineLarge: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: AppColors.textDim),
      ),
    ),
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accentViolet,
      secondary: AppColors.accentCyan,
    ),
  );
}
