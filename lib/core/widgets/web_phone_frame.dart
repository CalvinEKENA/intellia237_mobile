import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Application web (savoir.intellia237.com, 23/09/2026) : la même application
/// que sur Android, adaptée à chaque taille d'écran.
///
/// - Téléphones et tablettes en portrait (jusqu'à [fullBleedMaxWidth]) :
///   l'application occupe tout l'écran ; chaque écran s'adapte déjà à sa
///   largeur (grilles, largeurs de lecture maximales), comme sur Android.
/// - Ordinateurs et grands écrans : l'application occupe toute la hauteur
///   dans une colonne centrée de [columnWidth], sur le papier de la marque.
///   Les lignes restent lisibles et chaque écran garde la composition conçue
///   et testée pour le mobile.
class WebPhoneFrame extends StatelessWidget {
  const WebPhoneFrame({required this.child, this.enabled = kIsWeb, super.key});

  final Widget child;

  /// Vrai sur le web ; réglable pour les tests.
  final bool enabled;

  static const fullBleedMaxWidth = 900.0;
  static const columnWidth = 560.0;
  static const paper = Color(0xFFF4EFE5);
  static const ink = Color(0xFF25233E);

  static const frameKey = ValueKey('web-phone-frame');

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= fullBleedMaxWidth) return child;
        final media = MediaQuery.of(context);
        final column = Size(columnWidth, constraints.maxHeight);
        return ColoredBox(
          color: paper,
          child: Center(
            child: DecoratedBox(
              key: frameKey,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(color: ink.withValues(alpha: 0.10), blurRadius: 40),
                ],
              ),
              child: SizedBox.fromSize(
                size: column,
                child: ClipRect(
                  // Les écrans voient la largeur de la colonne.
                  child: MediaQuery(
                    data: media.copyWith(size: column),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
