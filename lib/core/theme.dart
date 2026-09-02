import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF0E7A5F); // Deep Emerald
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primarySoft = Color(0xFFE6F4EF);
  static const Color accent = Color(0xFFE07A5F); // Warm Terracotta
  
  static const Color background = Color(0xFFF5F1E8); // Premium Beige
  static const Color surface = Color(0xFFFAF7F0);
  static const Color inputFill = Color(0xFFEFE9DD);
  
  static const Color border = Color(0xFFE6DFD3);
  static const Color textPrimary = Color(0xFF2C241B);
  static const Color textSecondary = Color(0xFF8C7B6C);
  
  static const Color success = Color(0xFF1E8E5A);
  static const Color error = Color(0xFFB3261E);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        secondary: accent,
        onSecondary: textPrimary,
        error: error,
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
      ),
      textTheme: TextTheme(
        headlineMedium: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary),
        titleLarge: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w400, color: textPrimary, height: 1.4),
        bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w400, color: textSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary, fontFamily: 'PlusJakartaSans'),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 15, color: textSecondary, fontWeight: FontWeight.w400),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary, width: 1.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}