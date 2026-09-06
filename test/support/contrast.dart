import 'dart:math' as math;
import 'dart:ui';

/// Outils de contraste WCAG 2.1 utilisés par les tests de lisibilité.
///
/// Une régression de contraste ne se voit pas dans un test de rendu classique :
/// un texte blanc sur fond blanc « s'affiche » parfaitement. Ces helpers
/// mesurent donc la grandeur réellement en jeu, le rapport de luminance.
abstract final class Contrast {
  /// Compose [foreground] (éventuellement translucide) au-dessus de
  /// [background] et renvoie la couleur opaque réellement perçue.
  static Color flatten(Color foreground, Color background) {
    final alpha = foreground.a;
    if (alpha >= 1) return foreground;
    return Color.from(
      alpha: 1,
      red: foreground.r * alpha + background.r * (1 - alpha),
      green: foreground.g * alpha + background.g * (1 - alpha),
      blue: foreground.b * alpha + background.b * (1 - alpha),
    );
  }

  static double _channel(double value) => value <= 0.03928
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4).toDouble();

  /// Luminance relative WCAG d'une couleur supposée opaque.
  static double luminance(Color color) =>
      0.2126 * _channel(color.r) +
      0.7152 * _channel(color.g) +
      0.0722 * _channel(color.b);

  /// Rapport de contraste (1 → 21) entre un premier plan et un fond.
  ///
  /// Le premier plan est aplati sur le fond : un blanc à 6 % d'opacité sur
  /// une toile crème vaut donc bien « crème », et non « blanc ».
  static double ratio(Color foreground, Color background) {
    final front = luminance(flatten(foreground, background));
    final back = luminance(background);
    final lighter = math.max(front, back);
    final darker = math.min(front, back);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Seuil WCAG AA pour du texte courant.
  static const double aaNormalText = 4.5;

  /// Seuil WCAG AA pour du grand texte (>= 24px, ou >= 18.66px en gras).
  static const double aaLargeText = 3.0;
}
