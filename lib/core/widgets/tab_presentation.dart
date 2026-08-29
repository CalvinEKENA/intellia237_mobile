import 'package:flutter/widgets.dart';

import '../../app/theme/design_tokens.dart';

/// Mode d'affichage d'un écran utilisable à la fois en plein écran (route
/// autonome) et intégré dans le shell clair de l'accueil élève.
///
/// - [embeddedLight] : l'écran est posé sur le backdrop **clair** de l'accueil
///   (onglets Accueil / Apprendre / Quiz / Compagnon / Profil). Textes sombres,
///   surfaces blanches/ivoire, pas d'effet glass conçu pour le sombre.
/// - [standaloneDark] : l'écran s'affiche seul, dans son univers **sombre**
///   d'origine (route GoRouter dédiée).
enum TabPresentationMode { embeddedLight, standaloneDark }

/// Palette résolue selon le mode — **source unique** des couleurs de contenu
/// (texte, icône, surface, bordure, accent, statuts) d'une surface.
///
/// Contrat : un composant ne suppose JAMAIS que son fond est clair ou sombre ;
/// il lit ses couleurs ici. Toutes les couleurs de texte/icône respectent un
/// contraste WCAG AA (≥ 4.5:1 pour le texte normal, ≥ 3:1 pour les grands
/// textes et icônes porteuses de sens) sur les surfaces du même mode.
@immutable
class TabPalette {
  const TabPalette(this.mode);

  /// Palette adaptée à la luminosité d'un [Theme] Material (repli pour les
  /// écrans thémés qui ne déclarent pas de [TabSurface]).
  factory TabPalette.forBrightness(Brightness brightness) => TabPalette(
    brightness == Brightness.dark
        ? TabPresentationMode.standaloneDark
        : TabPresentationMode.embeddedLight,
  );

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

  /// Texte désactivé : atténué mais volontaire (jamais confondu avec un bug
  /// de rendu). À combiner avec un signal secondaire (barré, cadenas…).
  Color get textDisabled =>
      isLight ? const Color(0xFF97949F) : const Color(0x73FFFFFF);

  // ── Icônes ──────────────────────────────────────────────────────────────
  Color get iconPrimary => textPrimary;
  Color get iconSecondary => textSecondary;

  // ── Surfaces ────────────────────────────────────────────────────────────
  Color get surface => isLight
      ? IntelliaColors.surfaceSolid
      : const Color(0xFFFFFFFF).withValues(alpha: 0.06);
  Color get surfaceElevated => isLight
      ? IntelliaColors.surfaceSolid
      : const Color(0xFFFFFFFF).withValues(alpha: 0.10);
  Color get surfaceMuted => isLight
      ? IntelliaColors.backgroundSecondary
      : const Color(0xFFFFFFFF).withValues(alpha: 0.04);
  Color get surfaceBorder => isLight
      ? IntelliaColors.brandIndigo.withValues(alpha: 0.10)
      : const Color(0xFFFFFFFF).withValues(alpha: 0.12);

  /// Alias canonique du contrat sémantique.
  Color get border => surfaceBorder;

  // ── Accent de marque ────────────────────────────────────────────────────
  Color get accent =>
      isLight ? IntelliaColors.brandIndigo : const Color(0xFF9E9CFF);
  Color get onAccent => const Color(0xFFFFFFFF);
  Color get accentSoft => isLight
      ? IntelliaColors.brandIndigo.withValues(alpha: 0.10)
      : IntelliaColors.brandIndigo.withValues(alpha: 0.28);

  // ── Statuts (teintes lisibles en TEXTE sur la surface courante) ─────────
  Color get success =>
      isLight ? const Color(0xFF146C43) : IntelliaColors.success;
  Color get warning =>
      isLight ? const Color(0xFF8A5300) : IntelliaColors.warning;
  Color get error => isLight ? const Color(0xFFC5221F) : IntelliaColors.error;

  /// Or « donnée » (points, %, records) lisible sur la surface courante.
  /// Sur clair, l'or brut (#FFD60A / #FF9500) ne tient pas le contraste :
  /// on utilise un or profond ; sur sombre, l'or éclatant de la marque.
  Color get numberAccent =>
      isLight ? const Color(0xFF8A5300) : IntelliaColors.pointsGold;

  /// Fond doux derrière une donnée or (pastille de points, compte à rebours).
  Color get numberAccentSoft => isLight
      ? IntelliaColors.warning.withValues(alpha: 0.14)
      : IntelliaColors.pointsGold.withValues(alpha: 0.16);

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

/// Fournit la [TabPalette] aux descendants. L'accueil enveloppe l'ensemble de
/// ses onglets dans un `TabSurface(palette: const TabPalette(embeddedLight))`.
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
