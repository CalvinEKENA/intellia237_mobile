import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/auth/domain/app_role.dart';

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
  static const double xxxl = 56;
}

abstract final class AppRadius {
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 26;
  static const double xl = 36;
}

abstract final class AppMotion {
  static const Duration instant   = Duration(milliseconds: 80);
  static const Duration fast      = Duration(milliseconds: 160);
  static const Duration medium    = Duration(milliseconds: 280);
  static const Duration slow      = Duration(milliseconds: 420);
  static const Duration cinematic = Duration(milliseconds: 700);
  static const Duration epic      = Duration(milliseconds: 1100);
  static const Duration onboardingSlide = Duration(seconds: 6);

  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);
  static const Curve spring   = Cubic(0.175, 0.885, 0.32, 1.275);
  static const Curve swiftOut = Cubic(0.55, 0.0, 0.1, 1.0);
}

abstract final class AppColors {
  // Brand
  static const Color brandNavy  = Color(0xFF0B1F4A);
  static const Color brand      = Color(0xFF1451E1);
  static const Color brandDeep  = Color(0xFF0A2A75);

  // Accents
  static const Color gold       = Color(0xFFF5A623);
  static const Color goldDim    = Color(0xFFB87A1A);
  static const Color accent     = Color(0xFF11AFA5);
  static const Color accentDeep = Color(0xFF0D8A81);

  // Neutrals
  static const Color neutral0   = Color(0xFFFFFFFF);
  static const Color neutral10  = Color(0xFFF3F6FC);
  static const Color neutral20  = Color(0xFFE6ECF7);
  static const Color neutral90  = Color(0xFF121A2B);
  static const Color neutral95  = Color(0xFF0A0F1D);
  static const Color cream      = Color(0xFFF8F4ED);

  // Role colors
  static const Color student     = Color(0xFF1D4ED8);
  static const Color studentGlow = Color(0xFF3B82F6);
  static const Color parent      = Color(0xFF7C3AED);
  static const Color parentGlow  = Color(0xFFA78BFA);
  static const Color teacher     = Color(0xFF0F766E);
  static const Color teacherGlow = Color(0xFF14B8A6);
  static const Color admin       = Color(0xFFBE123C);
  static const Color adminGlow   = Color(0xFFF43F5E);

  // Glass surfaces
  static const Color glassDark   = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassLight  = Color(0xCCFFFFFF);
}

abstract final class AppRoleColors {
  static Color byRole(AppRole role) => switch (role) {
    AppRole.student => AppColors.student,
    AppRole.parent  => AppColors.parent,
    AppRole.teacher => AppColors.teacher,
    AppRole.admin   => AppColors.admin,
  };

  static Color glowByRole(AppRole role) => switch (role) {
    AppRole.student => AppColors.studentGlow,
    AppRole.parent  => AppColors.parentGlow,
    AppRole.teacher => AppColors.teacherGlow,
    AppRole.admin   => AppColors.adminGlow,
  };
}

abstract final class AppGradients {
  static const LinearGradient heroNavy = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B1F4A), Color(0xFF1451E1)],
  );

  static const LinearGradient heroGold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5A623), Color(0xFFE8890C)],
  );

  static const LinearGradient heroTeal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D8A81), Color(0xFF11AFA5)],
  );

  static const LinearGradient heroPurple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6D28D9), Color(0xFFA78BFA)],
  );

  static const LinearGradient backgroundLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF6F9FF), Color(0xFFEEF3FC)],
  );

  static const LinearGradient backgroundDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF060E22), Color(0xFF0B1835)],
  );

  static const LinearGradient bootstrap = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF071534), Color(0xFF1451E1)],
  );

  static LinearGradient backgroundFor(Brightness brightness) =>
      brightness == Brightness.dark ? backgroundDark : backgroundLight;

  @Deprecated('Utilisez backgroundFor(brightness) pour un rendu adaptatif.')
  static const LinearGradient background = backgroundLight;

  static LinearGradient forRole(AppRole role) => switch (role) {
    AppRole.student => const LinearGradient(
        colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)]),
    AppRole.parent  => const LinearGradient(
        colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)]),
    AppRole.teacher => const LinearGradient(
        colors: [Color(0xFF0F766E), Color(0xFF14B8A6)]),
    AppRole.admin   => const LinearGradient(
        colors: [Color(0xFFBE123C), Color(0xFFF43F5E)]),
  };

  static const Map<String, LinearGradient> bySubject = {
    'math':    LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF60A5FA)]),
    'french':  LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFC084FC)]),
    'physic':  LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF34D399)]),
    'english': LinearGradient(colors: [Color(0xFFF5A623), Color(0xFFFBBF24)]),
    'history': LinearGradient(colors: [Color(0xFFBE123C), Color(0xFFF87171)]),
  };

  static LinearGradient forSubject(String? key) =>
      bySubject[key] ?? heroNavy;
}

abstract final class AppShadows {
  static List<BoxShadow> glow(Color color, {double intensity = 0.35}) => [
    BoxShadow(
      color: color.withValues(alpha: intensity),
      blurRadius: 24,
      spreadRadius: -4,
    ),
    BoxShadow(
      color: color.withValues(alpha: intensity * 0.5),
      blurRadius: 48,
      spreadRadius: -8,
    ),
  ];

  static List<BoxShadow> card(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}

abstract final class AppTypography {
  static TextStyle displayHero(BuildContext context) =>
      GoogleFonts.playfairDisplay(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        height: 1.1,
        color: Theme.of(context).colorScheme.onSurface,
      );

  static TextStyle displayMedium(BuildContext context) =>
      GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.2,
        color: Theme.of(context).colorScheme.onSurface,
      );

  static TextStyle numberHero({Color? color}) => GoogleFonts.manrope(
        fontSize: 56,
        fontWeight: FontWeight.w800,
        letterSpacing: -2.0,
        color: color,
      );
}

abstract final class AppIcons {
  static const Map<String, IconData> subjects = {
    'math':    Icons.calculate_rounded,
    'french':  Icons.menu_book_rounded,
    'physic':  Icons.science_rounded,
    'english': Icons.language_rounded,
    'history': Icons.public_rounded,
  };

  static IconData forSubject(String? key) =>
      subjects[key] ?? Icons.school_rounded;
}
