import 'package:go_router/go_router.dart';

import 'app_routes.dart';

/// Une sortie toujours disponible, même quand un écran n'a pas pu s'afficher.
///
/// Registre (QA appareil, 24/09/2026) : l'écran de secours d'affichage
/// n'offrait aucun bouton ; l'élève restait bloqué jusqu'à fermer
/// l'application. Le routeur courant est retenu ici pour que ce secours
/// puisse revenir en arrière, ou à l'accueil s'il n'y a rien derrière.
abstract final class RouterEscape {
  static GoRouter? _router;

  static void attach(GoRouter router) => _router = router;

  static void leave() {
    final router = _router;
    if (router == null) return;
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(AppRoutes.bootstrap);
    }
  }
}
