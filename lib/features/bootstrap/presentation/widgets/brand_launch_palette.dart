import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Couleurs du lancement, dérivées de l'icône officielle
/// (`assets/branding/icone.png`) : son dégradé horizontal va du mint
/// `#CDFFD8` au pervenche `#94B9FF`, en passant par `#B0DCEB`. Le lancement
/// en garde une brume très claire, froide et lumineuse, pour que le logo
/// (bleu profond, 2 vert, 3 rouge, 7 or) reste parfaitement lisible.
abstract final class BrandLaunchPalette {
  /// Le médian de l'icône à 16 %, fondu dans le blanc. C'est la couleur du
  /// splash natif (Android, Android 12+, iOS, web), celle de la première
  /// image Flutter, et celle du centre du dégradé : aucun flash au passage.
  static const surface = Color(0xFFF2F9FC);

  /// Le mint de l'icône à 18 %.
  static const mintMist = Color(0xFFF6FFF8);

  /// Le pervenche de l'icône à 22 %.
  static const periwinkleMist = Color(0xFFE7F0FF);

  /// Lumière posée derrière le logo pendant la respiration.
  static const glow = Color(0x8CFFFFFF);

  /// Le bleu profond du wordmark, pour les rares textes du lancement
  /// (reprise après une erreur).
  static const ink = Color(0xFF0B2E4A);

  /// Dégradé diagonal dont le centre est exactement [surface].
  static const backdrop = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [mintMist, surface, periwinkleMist],
    stops: [0, 0.5, 1],
  );

  /// Barres système fondues dans la surface : icônes sombres, aucune barre
  /// blanche ou noire qui apparaîtrait d'un coup.
  static const systemBars = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: surface,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: surface,
    systemNavigationBarContrastEnforced: false,
    systemStatusBarContrastEnforced: false,
  );
}
