import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/auth/domain/app_role.dart';

// ─────────────────────────────────────────────────────────────
// NEW INTELLIA DESIGN TOKENS
// ─────────────────────────────────────────────────────────────

abstract final class IntelliaColors {
  // Brand Colors
  static const Color brandIndigo = Color(0xFF5856D6);
  static const Color brandPurple = Color(0xFFAF52DE);
  static const Color brandBlue = Color(0xFF007AFF);

  // Light Surfaces
  static const Color backgroundPrimary = Color(0xFFFCFCFF);
  static const Color backgroundPremium = Color(0xFFFBFAF7);
  static const Color backgroundSecondary = Color(0xFFF2F2F7);
  static const Color surfaceSolid = Color(0xFFFFFFFF);
  static const Color surfaceGlass = Color(
    0xB8FFFFFF,
  ); // rgba(255, 255, 255, 0.72)
  static const Color surfaceElevated = Color(
    0xEBFFFFFF,
  ); // rgba(255, 255, 255, 0.92)

  // Dark Surfaces (Variants fallback)
  static const Color backgroundPrimaryDark = Color(0xFF0E0E1E);
  static const Color backgroundPremiumDark = Color(0xFF151421);
  static const Color backgroundSecondaryDark = Color(0xFF1C1B2E);
  static const Color surfaceSolidDark = Color(0xFF181728);
  static const Color surfaceGlassDark = Color(0x8C181728);

  // Text
  static const Color textPrimary = Color(0xFF171529);
  static const Color textSecondary = Color(0xFF68657A);
  static const Color textTertiary = Color(0xFF8E8E93);
  static const Color textPrimaryDark = Color(0xFFF5F5FA);
  static const Color textSecondaryDark = Color(0xFFA5A2B8);

  // Status & Progress
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
  static const Color xpGold = Color(0xFFFFD60A);

  // Companions Gradients Ends
  static const Color kiraLight = Color(0xFFFF9ECD);
  static const Color kiraDark = Color(0xFFAF52DE);
  static const Color leoLight = Color(0xFF5AC8FA);
  static const Color leoDark = Color(0xFF5856D6);

  // Cameroon identity accents (extremely subtle touches)
  static const Color cmVert = Color(0xFF007A5E);
  static const Color cmRouge = Color(0xFFCE1126);
  static const Color cmJaune = Color(0xFFFCD116);
}

abstract final class IntelliaGradients {
  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [IntelliaColors.brandIndigo, IntelliaColors.brandPurple],
  );

  static const LinearGradient surface = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xE6FFFFFF), Color(0xF2F2F2F7)],
  );

  static const LinearGradient math = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [IntelliaColors.brandBlue, IntelliaColors.brandIndigo],
  );

  static const LinearGradient english = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF9500), Color(0xFFFF6B6B)],
  );

  static const LinearGradient physics = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [IntelliaColors.success, Color(0xFF00C7BE)],
  );

  static const LinearGradient french = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [IntelliaColors.brandPurple, Color(0xFFFF9ECD)],
  );

  static const LinearGradient history = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF3B30), Color(0xFFFF9500)],
  );

  static const LinearGradient german = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1D1D1F), IntelliaColors.xpGold],
  );

  static const LinearGradient kira = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [IntelliaColors.kiraLight, IntelliaColors.kiraDark],
  );

  static const LinearGradient leo = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [IntelliaColors.leoLight, IntelliaColors.leoDark],
  );

  static LinearGradient forRole(AppRole role) => switch (role) {
    AppRole.student => brand,
    AppRole.parent => const LinearGradient(
      colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
    ),
    AppRole.teacher => const LinearGradient(
      colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
    ),
    AppRole.admin => const LinearGradient(
      colors: [Color(0xFFBE123C), Color(0xFFF43F5E)],
    ),
  };

  static const Map<String, LinearGradient> bySubject = {
    'math': math,
    'french': french,
    'physic': physics,
    'english': english,
    'history': history,
  };

  static LinearGradient forSubject(String? key) => bySubject[key] ?? brand;
}

abstract final class IntelliaTypography {
  static TextStyle hero({
    Color? color,
    Brightness brightness = Brightness.light,
  }) => GoogleFonts.playfairDisplay(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.15,
    color:
        color ??
        (brightness == Brightness.dark
            ? IntelliaColors.textPrimaryDark
            : IntelliaColors.textPrimary),
  );

  static TextStyle title1({
    Color? color,
    Brightness brightness = Brightness.light,
  }) => GoogleFonts.playfairDisplay(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color:
        color ??
        (brightness == Brightness.dark
            ? IntelliaColors.textPrimaryDark
            : IntelliaColors.textPrimary),
  );

  static TextStyle title2({
    Color? color,
    Brightness brightness = Brightness.light,
  }) => GoogleFonts.playfairDisplay(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color:
        color ??
        (brightness == Brightness.dark
            ? IntelliaColors.textPrimaryDark
            : IntelliaColors.textPrimary),
  );

  static TextStyle title3({
    Color? color,
    Brightness brightness = Brightness.light,
  }) => GoogleFonts.playfairDisplay(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color:
        color ??
        (brightness == Brightness.dark
            ? IntelliaColors.textPrimaryDark
            : IntelliaColors.textPrimary),
  );

  static TextStyle body({
    Color? color,
    Brightness brightness = Brightness.light,
  }) => GoogleFonts.montserrat(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color:
        color ??
        (brightness == Brightness.dark
            ? IntelliaColors.textSecondaryDark
            : IntelliaColors.textSecondary),
  );

  static TextStyle callout({
    Color? color,
    Brightness brightness = Brightness.light,
  }) => GoogleFonts.montserrat(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color:
        color ??
        (brightness == Brightness.dark
            ? IntelliaColors.textSecondaryDark
            : IntelliaColors.textSecondary),
  );

  static TextStyle caption({
    Color? color,
    Brightness brightness = Brightness.light,
  }) => GoogleFonts.montserrat(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color:
        color ??
        (brightness == Brightness.dark
            ? IntelliaColors.textTertiary
            : IntelliaColors.textTertiary),
  );

  static TextStyle micro({
    Color? color,
    Brightness brightness = Brightness.light,
  }) => GoogleFonts.montserrat(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.2,
    color:
        color ??
        (brightness == Brightness.dark
            ? IntelliaColors.textTertiary
            : IntelliaColors.textTertiary),
  );
}

abstract final class IntelliaSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
  static const double xxxl = 56;
}

abstract final class IntelliaRadii {
  static const double small = 10;
  static const double medium = 16;
  static const double large = 22;
  static const double extraLarge = 28;
  static const double full = 9999;

  @Deprecated('Use small instead')
  static const double control = 10;
  @Deprecated('Use medium instead')
  static const double card = 16;
  @Deprecated('Use large instead')
  static const double sheet = 22;
  @Deprecated('Use extraLarge instead')
  static const double hero = 28;
}

abstract final class IntelliaShadows {
  static List<BoxShadow> glow(Color color, {double intensity = 0.25}) => [
    BoxShadow(
      color: color.withValues(alpha: intensity),
      blurRadius: 24,
      spreadRadius: -4,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> card(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> premium = [
    BoxShadow(color: Color(0x0F121316), blurRadius: 38, offset: Offset(0, 14)),
  ];

  static const List<BoxShadow> brandGlow = [
    BoxShadow(color: Color(0x405856D6), blurRadius: 32, offset: Offset(0, 8)),
  ];
}

abstract final class IntelliaMotion {
  static const Duration instant = Duration(milliseconds: 80);
  static const Duration press = Duration(milliseconds: 150);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration cinematic = Duration(milliseconds: 700);
}

abstract final class IntelliaBreakpoints {
  static const double mobileSmall = 320;
  static const double mobileMedium = 360;
  static const double mobileLarge = 430;
  static const double tablet = 768;
}

// ─────────────────────────────────────────────────────────────
// DEPRECATED WRAPPERS & ALIASES (FOR BACKWARDS COMPATIBILITY)
// ─────────────────────────────────────────────────────────────

@Deprecated('Use IntelliaSpacing instead')
abstract final class AppSpacing {
  static const double xxs = IntelliaSpacing.xxs;
  static const double xs = IntelliaSpacing.xs;
  static const double sm = IntelliaSpacing.sm;
  static const double md = IntelliaSpacing.md;
  static const double lg = IntelliaSpacing.lg;
  static const double xl = IntelliaSpacing.xl;
  static const double xxl = IntelliaSpacing.xxl;
  static const double xxxl = IntelliaSpacing.xxxl;
}

@Deprecated('Use IntelliaRadii instead')
abstract final class AppRadius {
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 26;
  static const double xl = 36;
}

@Deprecated('Use IntelliaMotion instead')
abstract final class AppMotion {
  static const Duration instant = IntelliaMotion.instant;
  static const Duration fast = IntelliaMotion.fast;
  static const Duration medium = IntelliaMotion.medium;
  static const Duration slow = IntelliaMotion.slow;
  static const Duration cinematic = IntelliaMotion.cinematic;
  static const Duration epic = Duration(milliseconds: 1100);
  static const Duration onboardingSlide = Duration(seconds: 5);

  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);
  static const Curve spring = Cubic(0.175, 0.885, 0.32, 1.275);
  static const Curve swiftOut = Cubic(0.55, 0.0, 0.1, 1.0);
}

@Deprecated('Use IntelliaColors instead')
abstract final class AppColors {
  static const Color intelliaIndigo = IntelliaColors.brandIndigo;
  static const Color intelliaPurple = IntelliaColors.brandPurple;
  static const Color intelliaBlue = IntelliaColors.brandBlue;
  static const Color intelliaGold = IntelliaColors.xpGold;
  static const Color intelliaSurface = IntelliaColors.backgroundSecondary;

  static const Color brandNavy = Color(0xFF0B1F4A);
  static const Color brand = IntelliaColors.brandIndigo;
  static const Color brandDeep = Color(0xFF0A2A75);

  static const Color gold = IntelliaColors.warning;
  static const Color goldDim = Color(0xFFB87A1A);
  static const Color accent = IntelliaColors.success;
  static const Color accentDeep = Color(0xFF0D8A81);

  static const Color neutral0 = IntelliaColors.surfaceSolid;
  static const Color neutral10 = Color(0xFFF3F6FC);
  static const Color neutral20 = Color(0xFFE6ECF7);
  static const Color neutral90 = IntelliaColors.textPrimary;
  static const Color neutral95 = Color(0xFF0E0E1E);
  static const Color cream = IntelliaColors.backgroundPremium;

  static const Color student = IntelliaColors.brandIndigo;
  static const Color studentGlow = IntelliaColors.brandBlue;
  static const Color parent = IntelliaColors.brandPurple;
  static const Color parentGlow = Color(0xFFA78BFA);
  static const Color teacher = Color(0xFF0F766E);
  static const Color teacherGlow = Color(0xFF14B8A6);
  static const Color admin = Color(0xFFBE123C);
  static const Color adminGlow = Color(0xFFF43F5E);

  static const Color glassDark = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassLight = Color(0xCCFFFFFF);
}

@Deprecated('Use IntelliaGradients instead')
abstract final class AppRoleColors {
  static Color byRole(AppRole role) => switch (role) {
    AppRole.student => AppColors.student,
    AppRole.parent => AppColors.parent,
    AppRole.teacher => AppColors.teacher,
    AppRole.admin => AppColors.admin,
  };

  static Color glowByRole(AppRole role) => switch (role) {
    AppRole.student => AppColors.studentGlow,
    AppRole.parent => AppColors.parentGlow,
    AppRole.teacher => AppColors.teacherGlow,
    AppRole.admin => AppColors.adminGlow,
  };
}

@Deprecated('Use IntelliaGradients instead')
abstract final class AppGradients {
  static const LinearGradient heroNavy = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B1F4A), IntelliaColors.brandIndigo],
  );

  static const LinearGradient heroGold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [IntelliaColors.warning, Color(0xFFE8890C)],
  );

  static const LinearGradient heroTeal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D8A81), IntelliaColors.success],
  );

  static const LinearGradient heroPurple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6D28D9), Color(0xFFA78BFA)],
  );

  static const LinearGradient backgroundLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      IntelliaColors.backgroundPrimary,
      IntelliaColors.backgroundSecondary,
    ],
  );

  static const LinearGradient backgroundDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      IntelliaColors.backgroundPrimaryDark,
      IntelliaColors.backgroundSecondaryDark,
    ],
  );

  static const LinearGradient bootstrap = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF071534), IntelliaColors.brandIndigo],
  );

  static LinearGradient backgroundFor(Brightness brightness) =>
      brightness == Brightness.dark ? backgroundDark : backgroundLight;

  static const LinearGradient background = backgroundLight;

  static LinearGradient forRole(AppRole role) =>
      IntelliaGradients.forRole(role);
  static LinearGradient forSubject(String? key) =>
      IntelliaGradients.forSubject(key);
}

@Deprecated('Use IntelliaShadows instead')
abstract final class AppShadows {
  static List<BoxShadow> glow(Color color, {double intensity = 0.35}) =>
      IntelliaShadows.glow(color, intensity: intensity);

  static List<BoxShadow> card(Color color) => IntelliaShadows.card(color);
}

@Deprecated('Use IntelliaTypography instead')
abstract final class AppTypography {
  static TextStyle displayHero(BuildContext context) =>
      IntelliaTypography.hero(brightness: Theme.of(context).brightness);

  static TextStyle displayMedium(BuildContext context) =>
      IntelliaTypography.title1(brightness: Theme.of(context).brightness);

  static TextStyle numberHero({Color? color}) => GoogleFonts.montserrat(
    fontSize: 56,
    fontWeight: FontWeight.w800,
    color: color,
  );
}

abstract final class AppIcons {
  static const Map<String, IconData> subjects = {
    'math': Icons.calculate_rounded,
    'french': Icons.menu_book_rounded,
    'physic': Icons.science_rounded,
    'english': Icons.language_rounded,
    'history': Icons.public_rounded,
  };

  static IconData forSubject(String? key) =>
      subjects[key] ?? Icons.school_rounded;
}
