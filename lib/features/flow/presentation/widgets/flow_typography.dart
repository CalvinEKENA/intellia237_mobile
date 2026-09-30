import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/design_tokens.dart';

/// Échelle typographique **éditoriale et compacte** du Flow.
///
/// Chaque rôle interpole entre une valeur compacte (≈ 320 px) et une valeur
/// large (≈ 600 px) selon la largeur disponible, puis l'échelle d'accessibilité
/// de Flutter s'applique par-dessus — elle n'est **jamais** plafonnée ni
/// remplacée par un FittedBox. Les plages suivent la charte device-QA :
/// eyebrow 12–13 · titre 18–21 · question 19–22 · corps 15–17 · choix 15–16 ·
/// explication 16–17.
class FlowTypographyScope extends InheritedWidget {
  const FlowTypographyScope({
    required this.width,
    required super.child,
    super.key,
  });
  final double width;
  @override
  bool updateShouldNotify(FlowTypographyScope oldWidget) =>
      width != oldWidget.width;
}

abstract final class FlowTypography {
  static double _size(BuildContext context, double compact, double wide) {
    final width =
        context
            .dependOnInheritedWidgetOfExactType<FlowTypographyScope>()
            ?.width ??
        MediaQuery.sizeOf(context).width;
    final fraction = ((width - 320) / 280).clamp(0.0, 1.0);
    return compact + (wide - compact) * fraction;
  }

  /// Titre éditorial d'une carte de contenu (18–21).
  static TextStyle title(BuildContext context) => GoogleFonts.playfairDisplay(
    fontSize: _size(context, 18, 21),
    fontWeight: FontWeight.w700,
    height: 1.22,
    color: IntelliaColors.textPrimary,
  );

  /// Énoncé d'un exercice / question (19–22) — légèrement plus présent que le
  /// titre, car c'est le point focal de l'interaction.
  static TextStyle question(BuildContext context) =>
      GoogleFonts.playfairDisplay(
        fontSize: _size(context, 19, 22),
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: IntelliaColors.textPrimary,
      );

  /// Corps de texte courant (15–17).
  static TextStyle body(BuildContext context) => GoogleFonts.montserrat(
    fontSize: _size(context, 15, 17),
    height: 1.5,
    fontWeight: FontWeight.w500,
    color: IntelliaColors.textSecondary,
  );

  /// Libellé d'un choix de réponse (15–16).
  static TextStyle choice(BuildContext context) => GoogleFonts.montserrat(
    fontSize: _size(context, 15, 16),
    height: 1.3,
    fontWeight: FontWeight.w800,
    color: IntelliaColors.textPrimary,
  );

  /// Explication révélée après réponse (16–17).
  static TextStyle explanation(BuildContext context) => GoogleFonts.montserrat(
    fontSize: _size(context, 16, 17),
    height: 1.5,
    fontWeight: FontWeight.w500,
    color: IntelliaColors.textSecondary,
  );

  /// Métadonnée discrète (12–13).
  static TextStyle caption(BuildContext context) =>
      body(context).copyWith(fontSize: _size(context, 12, 13));

  static TextStyle action(BuildContext context) =>
      body(context).copyWith(fontWeight: FontWeight.w700);

  /// Eyebrow / sur-titre (12–13, capitales espacées).
  static TextStyle eyebrow(BuildContext context) =>
      caption(context).copyWith(fontWeight: FontWeight.w700, letterSpacing: .5);
}
