import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../domain/chapter.dart';
import '../domain/pedagogy.dart';

/// Direction visuelle des chapitres interactifs : papier clair, encre
/// profonde, une couleur par niveau — calme pour lire, vive pour jouer.
abstract final class ContentPalette {
  static const paper = IntelliaColors.backgroundPremium;
  static const card = Colors.white;
  static const ink = IntelliaColors.textPrimary;
  static const inkSoft = IntelliaColors.textSecondary;
  static const line = Color(0xFFE6E1D8);
  static const accent = IntelliaColors.brandIndigo;
  static const success = Color(0xFF1E8F6E);
  static const error = Color(0xFFC0392B);
  static const warm = Color(0xFFE8871E);

  /// 🟢 Facile, 🟠 Intermédiaire, 🔴 Défi.
  static Color difficulty(int level) => switch (level) {
    1 => const Color(0xFF1E8F6E),
    2 => const Color(0xFFE8871E),
    _ => const Color(0xFFCE1126),
  };

  static Color mode(ExplanationMode mode) => switch (mode) {
    ExplanationMode.standard => IntelliaColors.brandIndigo,
    ExplanationMode.simple => const Color(0xFF2F7FC4),
    ExplanationMode.ultraSimple => const Color(0xFF8A3F9E),
  };
}

abstract final class ContentText {
  static TextStyle title({
    Color color = ContentPalette.ink,
    double size = 24,
  }) => GoogleFonts.playfairDisplay(
    fontSize: size,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: color,
  );

  static TextStyle eyebrow({Color color = ContentPalette.accent}) =>
      GoogleFonts.montserrat(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.9,
        color: color,
      );

  static TextStyle body({
    Color color = ContentPalette.ink,
    double size = 15.5,
    FontWeight weight = FontWeight.w500,
  }) => GoogleFonts.manrope(
    fontSize: size,
    height: 1.5,
    fontWeight: weight,
    color: color,
  );

  static TextStyle label({
    Color color = ContentPalette.ink,
    double size = 13,
  }) => GoogleFonts.manrope(
    fontSize: size,
    fontWeight: FontWeight.w800,
    color: color,
  );

  /// Chiffres et formules : lisibles, de largeur égale.
  static TextStyle math({Color color = ContentPalette.ink, double size = 20}) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}

/// Dégradé de la matière d'un pack, d'après sa clé normalisée.
LinearGradient subjectGradient(String subjectKey) {
  const prefixes = {
    'math': 'math',
    'physi': 'physic',
    'chimi': 'physic',
    'anglais': 'english',
    'english': 'english',
    'francais': 'french',
    'histoire': 'history',
  };
  for (final entry in prefixes.entries) {
    if (subjectKey.startsWith(entry.key)) {
      return AppGradients.forSubject(entry.value);
    }
  }
  return AppGradients.forSubject(null);
}

/// Libellé d'un niveau d'explication.
String explanationModeLabel(BuildContext context, ExplanationMode mode) =>
    switch (mode) {
      ExplanationMode.standard => context.l10n.ceModeStandard,
      ExplanationMode.simple => context.l10n.ceModeSimple,
      ExplanationMode.ultraSimple => context.l10n.ceModeUltra,
    };

/// Libellé d'une difficulté : celui du pack d'abord.
String difficultyLabel(BuildContext context, Chapter chapter, int level) =>
    chapter.difficulty(level).label ?? context.l10n.ceDifficultyLevel(level);

/// Carte de base des chapitres interactifs.
class ContentCard extends StatelessWidget {
  const ContentCard({
    required this.child,
    this.padding = const EdgeInsets.all(IntelliaSpacing.md),
    this.color = ContentPalette.card,
    this.borderColor = ContentPalette.line,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final Color borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(IntelliaRadii.card);
    return Material(
      color: color,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: borderColor),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Anneau de maîtrise 0–100.
class MasteryRing extends StatelessWidget {
  const MasteryRing({
    required this.score,
    this.size = 44,
    this.color = ContentPalette.accent,
    this.child,
    super.key,
  });

  final int score;
  final double size;
  final Color color;
  final Widget? child;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(end: score / 100),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => CircularProgressIndicator(
            value: value,
            strokeWidth: 4,
            strokeCap: StrokeCap.round,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        ?child,
      ],
    ),
  );
}
