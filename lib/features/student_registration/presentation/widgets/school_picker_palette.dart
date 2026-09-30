import 'package:flutter/material.dart';

import '../../../auth/presentation/widgets/auth_experience_scaffold.dart';

/// Couleurs du choix d'établissement, claires comme l'inscription, et
/// sombres si le thème l'est.
@immutable
class SchoolPickerPalette {
  const SchoolPickerPalette._({
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.border,
    required this.accent,
    required this.accentSoft,
    required this.gold,
    required this.success,
    required this.textPrimary,
    required this.textSecondary,
    required this.highlight,
  });

  static const light = SchoolPickerPalette._(
    canvas: AuthExperienceColors.canvas,
    surface: AuthExperienceColors.surface,
    surfaceRaised: Color(0xFFF6F1E6),
    border: AuthExperienceColors.border,
    accent: AuthExperienceColors.indigo,
    accentSoft: Color(0xFFE9E6FB),
    gold: AuthExperienceColors.gold,
    success: AuthExperienceColors.success,
    textPrimary: AuthExperienceColors.textPrimary,
    textSecondary: AuthExperienceColors.textSecondary,
    highlight: Color(0x335444D8),
  );

  static const dark = SchoolPickerPalette._(
    canvas: Color(0xFF13121C),
    surface: Color(0xFF1D1B2A),
    surfaceRaised: Color(0xFF252336),
    border: Color(0xFF3A3650),
    accent: Color(0xFFA79DFF),
    accentSoft: Color(0xFF2C2848),
    gold: Color(0xFFD9B77E),
    success: Color(0xFF86D3A6),
    textPrimary: Color(0xFFF4F0E8),
    textSecondary: Color(0xFFBDB7C9),
    highlight: Color(0x40A79DFF),
  );

  static SchoolPickerPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  final Color canvas;
  final Color surface;
  final Color surfaceRaised;
  final Color border;
  final Color accent;
  final Color accentSoft;
  final Color gold;
  final Color success;
  final Color textPrimary;
  final Color textSecondary;
  final Color highlight;
}
