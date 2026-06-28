import 'package:flutter/widgets.dart';

import '../../app/theme/design_tokens.dart';

/// Mode d'affichage d'un écran utilisable à la fois en plein écran (route
/// autonome) et intégré dans le shell clair de l'accueil élève.
///
/// - [embeddedLight] : l'écran est posé sur le backdrop **clair** de l'accueil
///   (onglets Apprendre / Quiz / Compagnon / Profil). Textes sombres, surfaces
///   blanches/ivoire, pas d'effet glass conçu pour le sombre.
/// - [standaloneDark] : l'écran s'affiche seul, dans son univers **sombre**
///   d'origine (route GoRouter dédiée).
enum TabPresentationMode { embeddedLight, standaloneDark }

/// Palette résolue selon le mode — **source unique** des couleurs de texte et de
/// surface des onglets. Évite les `Colors.white` codés en dur sur fond clair.
@immutable
class TabPalette {
  const TabPalette(this.mode);

  final TabPresentationMode mode;

  bool get isLight => mode == TabPresentationMode.embeddedLight;

  // ── Fond ────────────────────────────────────────────────────────────────
  Color get background =>
      isLight ? IntelliaColors.backgroundPrimary : const Color(0xFF060E22);

  /// Indique si l'écran doit peindre lui-même un fond (faux en embedded :
  /// le backdrop clair de l'accueil est déjà présent).
  bool get paintsOwnBackground => !isLight;

  // ── Texte ───────────────────────────────────────────────────────────────
  Color get textPrimary =>
      isLight ? IntelliaColors.textPrimary : const Color(0xFFFFFFFF);
  Color get textSecondary => isLight
      ? IntelliaColors.textSecondary
      : const Color(0xFFFFFFFF).withValues(alpha: 0.72);
  Color get textTertiary => isLight
      ? IntelliaColors.textTertiary
      : const Color(0xFFFFFFFF).withValues(alpha: 0.55);

  // ── Surfaces ────────────────────────────────────────────────────────────
  Color get surface => isLight
      ? IntelliaColors.surfaceSolid
      : const Color(0xFFFFFFFF).withValues(alpha: 0.06);
  Color get surfaceMuted => isLight
      ? IntelliaColors.backgroundSecondary
      : const Color(0xFFFFFFFF).withValues(alpha: 0.04);
  Color get surfaceBorder => isLight
      ? IntelliaColors.brandIndigo.withValues(alpha: 0.10)
      : const Color(0xFFFFFFFF).withValues(alpha: 0.12);

  /// Surfaces translucides + BackdropFilter réservées au mode sombre : sur fond
  /// clair, on utilise des surfaces opaques (lisibilité + performance).
  bool get useGlass => !isLight;

  /// Couleur d'un champ (recherche, composer).
  Color get fieldFill => isLight
      ? IntelliaColors.backgroundSecondary
      : const Color(0xFFFFFFFF).withValues(alpha: 0.08);

  /// Couleur d'un squelette de chargement, visible sur le fond courant.
  Color get skeleton => isLight
      ? IntelliaColors.textPrimary.withValues(alpha: 0.06)
      : const Color(0xFFFFFFFF).withValues(alpha: 0.08);
}

/// Fournit la [TabPalette] aux descendants. L'accueil enveloppe chaque onglet
/// intégré dans un `TabSurface(palette: const TabPalette(embeddedLight))`.
/// Les routes autonomes n'ont pas besoin de l'envelopper : le défaut est sombre.
class TabSurface extends InheritedWidget {
  const TabSurface({required this.palette, required super.child, super.key});

  final TabPalette palette;

  /// Palette courante, ou **sombre autonome** par défaut (route plein écran).
  static TabPalette of(BuildContext context) =>
      maybeOf(context) ?? const TabPalette(TabPresentationMode.standaloneDark);

  static TabPalette? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TabSurface>()?.palette;

  @override
  bool updateShouldNotify(TabSurface oldWidget) =>
      oldWidget.palette.mode != palette.mode;
}
