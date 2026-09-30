import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class StudioColors {
  // Brand Primary & Accent
  static const Color navyPrimary = Color(0xFF003366);
  static const Color navyDark = Color(0xFF001F3F);
  static const Color goldAccent = Color(0xFFD4AF37);
  static const Color goldBright = Color(0xFFFFD700);
  static const Color blueAccent = Color(0xFF0099FF);

  // Surfaces Light
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // Surfaces Dark
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceElevatedDark = Color(0xFF334155);
  static const Color borderDark = Color(0xFF334155);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // Status & Feedback
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
}

class StudioTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.montserratTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: StudioColors.navyPrimary,
      scaffoldBackgroundColor: StudioColors.backgroundLight,
      cardColor: StudioColors.surfaceLight,
      dividerColor: StudioColors.borderLight,
      colorScheme: const ColorScheme.light(
        primary: StudioColors.navyPrimary,
        secondary: StudioColors.goldAccent,
        tertiary: StudioColors.blueAccent,
        surface: StudioColors.surfaceLight,
        error: StudioColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: StudioColors.textPrimaryLight,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: GoogleFonts.playfairDisplay(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: StudioColors.navyPrimary,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: StudioColors.navyPrimary,
        ),
        titleLarge: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: StudioColors.textPrimaryLight,
        ),
        bodyLarge: GoogleFonts.montserrat(
          fontSize: 14,
          color: StudioColors.textPrimaryLight,
        ),
        bodyMedium: GoogleFonts.montserrat(
          fontSize: 13,
          color: StudioColors.textSecondaryLight,
        ),
        bodySmall: GoogleFonts.montserrat(
          fontSize: 11,
          color: StudioColors.textMutedLight,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: StudioColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(
          color: StudioColors.textPrimaryLight,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: StudioColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: StudioColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: StudioColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: StudioColors.navyPrimary,
            width: 1.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: StudioColors.navyPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: StudioColors.navyPrimary,
          side: const BorderSide(color: StudioColors.borderLight),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.montserratTextTheme(
      ThemeData.dark().textTheme,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: StudioColors.blueAccent,
      scaffoldBackgroundColor: StudioColors.backgroundDark,
      cardColor: StudioColors.surfaceDark,
      dividerColor: StudioColors.borderDark,
      colorScheme: const ColorScheme.dark(
        primary: StudioColors.blueAccent,
        secondary: StudioColors.goldAccent,
        surface: StudioColors.surfaceDark,
        error: StudioColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: StudioColors.textPrimaryDark,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: GoogleFonts.playfairDisplay(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: StudioColors.goldBright,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: StudioColors.textPrimaryDark,
        ),
        titleLarge: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: StudioColors.textPrimaryDark,
        ),
        bodyLarge: GoogleFonts.montserrat(
          fontSize: 14,
          color: StudioColors.textPrimaryDark,
        ),
        bodyMedium: GoogleFonts.montserrat(
          fontSize: 13,
          color: StudioColors.textSecondaryDark,
        ),
        bodySmall: GoogleFonts.montserrat(
          fontSize: 11,
          color: StudioColors.textMutedDark,
        ),
      ),
    );
  }
}
