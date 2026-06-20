import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'design_tokens.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(brightness: Brightness.light);
  static ThemeData get dark => _build(brightness: Brightness.dark);

  static ThemeData _build({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: IntelliaColors.brandIndigo,
          brightness: brightness,
        ).copyWith(
          primary: isDark
              ? const Color(0xFF9E9CFF)
              : IntelliaColors.brandIndigo,
          onPrimary: Colors.white,
          secondary: isDark
              ? const Color(0xFFDCA6FF)
              : IntelliaColors.brandPurple,
          onSecondary: Colors.white,
          surface: isDark
              ? IntelliaColors.surfaceSolidDark
              : IntelliaColors.surfaceSolid,
          onSurface: isDark
              ? IntelliaColors.textPrimaryDark
              : IntelliaColors.textPrimary,
          surfaceContainerHighest: isDark
              ? IntelliaColors.backgroundSecondaryDark
              : IntelliaColors.backgroundSecondary,
          outline: isDark
              ? const Color(0xFF2E2D44)
              : const Color(0xE0E5E5EA), // Fine border color
          error: IntelliaColors.error,
        );

    // Body text uses Montserrat
    final textTheme =
        GoogleFonts.montserratTextTheme(
          ThemeData(brightness: brightness).textTheme,
        ).copyWith(
          // Display/Titles can use Playfair Display
          headlineLarge: GoogleFonts.playfairDisplay(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isDark
                ? IntelliaColors.textPrimaryDark
                : IntelliaColors.textPrimary,
          ),
          headlineMedium: GoogleFonts.playfairDisplay(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: isDark
                ? IntelliaColors.textPrimaryDark
                : IntelliaColors.textPrimary,
          ),
          titleLarge: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark
                ? IntelliaColors.textPrimaryDark
                : IntelliaColors.textPrimary,
          ),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: isDark
          ? IntelliaColors.backgroundPrimaryDark
          : IntelliaColors.backgroundPrimary,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: isDark ? 0 : 2,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0 : 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(IntelliaRadii.large), // 22px
          side: BorderSide(color: colorScheme.outline, width: 0.8),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(IntelliaRadii.full), // Capsule
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          foregroundColor: colorScheme.primary,
          side: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.4),
            width: 1.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(IntelliaRadii.full), // Capsule
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primary.withValues(alpha: 0.15),
        secondarySelectedColor: colorScheme.secondary.withValues(alpha: 0.15),
        side: BorderSide(color: colorScheme.outline, width: 0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(IntelliaRadii.small), // 10px
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? IntelliaColors.surfaceSolidDark
            : IntelliaColors.surfaceSolid,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: IntelliaSpacing.md,
          vertical: IntelliaSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(IntelliaRadii.medium), // 16px
          borderSide: BorderSide(color: colorScheme.outline, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(IntelliaRadii.medium),
          borderSide: BorderSide(color: colorScheme.outline, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(IntelliaRadii.medium),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(IntelliaRadii.medium),
          borderSide: BorderSide(color: colorScheme.error, width: 0.8),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(IntelliaRadii.medium),
          borderSide: BorderSide(color: colorScheme.error, width: 1.2),
        ),
        hintStyle: TextStyle(
          color: isDark
              ? IntelliaColors.textTertiary
              : IntelliaColors.textTertiary,
          fontSize: 14,
        ),
        labelStyle: TextStyle(
          color: isDark
              ? IntelliaColors.textSecondaryDark
              : IntelliaColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(IntelliaRadii.large), // 22px
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(IntelliaRadii.large), // 22px
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
