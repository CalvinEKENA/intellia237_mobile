import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationNavigationProvider = StreamProvider<String>((ref) async* {
  final pending = NotificationNavigationBus.takePending();
  if (pending != null) yield pending;
  yield* NotificationNavigationBus.routes;
});

/// Point d'entrée unique des clics provenant d'une notification système.
///
/// Le routeur de l'application reste seul responsable de valider et d'ouvrir
/// la destination. Les services natifs n'ont ainsi jamais à conserver un
/// [BuildContext] devenu invalide.
abstract final class NotificationNavigationBus {
  static final StreamController<String> _routes =
      StreamController<String>.broadcast();
  static String? _pendingRoute;

  static Stream<String> get routes => _routes.stream;

  static String? takePending() {
    final pending = _pendingRoute;
    _pendingRoute = null;
    return pending;
  }

  static void open(String? route) {
    final normalized = route?.trim();
    if (normalized == null || normalized.isEmpty) return;
    if (_routes.hasListener) {
      _routes.add(normalized);
    } else {
      _pendingRoute = normalized;
    }
  }
}
