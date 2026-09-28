import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Jalons du démarrage, du lancement jusqu'aux onglets utilisables.
///
/// T0 est le début de `bootstrap()` : le système ne donne pas l'heure de
/// création du processus, T0 en est la meilleure approximation côté Dart.
enum StartupMilestone {
  /// T0 — entrée dans `bootstrap()`.
  appStart('T0 app-start'),

  /// T1 — première image Flutter peinte.
  firstFrame('T1 first-frame'),

  /// T2 — session résolue, la route de l'espace est connue.
  bootstrapResolved('T2 bootstrap-resolved'),

  /// T3 — `StudentHomeScreen` monté (coquille élève visible).
  studentShell('T3 student-shell'),

  /// T4 — premier contenu utile de l'Accueil.
  homeUseful('T4 home-useful'),

  /// T5 — Apprendre montre des matières.
  learnUsable('T5 learn-usable'),

  /// T6 — Quiz montre des quiz jouables.
  quizUsable('T6 quiz-usable'),

  /// T7 — Compagnon prêt à l'échange.
  companionUsable('T7 companion-usable');

  const StartupMilestone(this.label);

  final String label;
}

/// Mesure du démarrage : jalons (une fois chacun) et durées des étapes.
///
/// Silencieux en production : les mesures restent en mémoire et dans la
/// chronologie DevTools (`Timeline`) ; les journaux lisibles ne sont écrits
/// qu'en debug et en profile (`flutter run --profile`), jamais en release.
abstract final class StartupTrace {
  static final Stopwatch _clock = Stopwatch();
  static final Map<StartupMilestone, int> _milestones = {};
  static final Map<String, int> _steps = {};

  /// Démarre l'horloge (T0). Sans effet si elle tourne déjà.
  static void start() {
    if (_clock.isRunning) return;
    _clock.start();
    mark(StartupMilestone.appStart);
  }

  /// Millisecondes écoulées depuis T0 (0 si l'horloge n'a pas démarré).
  static int get elapsedMs => _clock.elapsedMilliseconds;

  /// Enregistre un jalon ; seul le premier passage compte.
  static void mark(StartupMilestone milestone) {
    if (_milestones.containsKey(milestone)) return;
    final at = _clock.elapsedMilliseconds;
    _milestones[milestone] = at;
    developer.Timeline.instantSync(
      'startup ${milestone.label}',
      arguments: {'ms': at},
    );
    _log('${milestone.label} +$at ms');
  }

  /// Mesure une étape asynchrone (profil, catalogue, quiz…) : la durée de la
  /// première exécution est retenue, les suivantes sont journalisées.
  static Future<T> measure<T>(String step, Future<T> Function() run) async {
    final watch = Stopwatch()..start();
    final startedAt = _clock.elapsedMilliseconds;
    var outcome = 'ok';
    try {
      return await run();
    } catch (_) {
      outcome = 'failed';
      rethrow;
    } finally {
      final took = watch.elapsedMilliseconds;
      _steps.putIfAbsent(step, () => took);
      developer.Timeline.instantSync(
        'startup step $step',
        arguments: {'ms': took, 'at': startedAt, 'outcome': outcome},
      );
      _log('step $step $took ms (from +$startedAt ms, $outcome)');
    }
  }

  static Map<StartupMilestone, int> get milestones =>
      Map.unmodifiable(_milestones);

  static Map<String, int> get steps => Map.unmodifiable(_steps);

  @visibleForTesting
  static void reset() {
    _clock
      ..stop()
      ..reset();
    _milestones.clear();
    _steps.clear();
  }

  static void _log(String line) {
    if (kReleaseMode) return;
    debugPrint('[INTELLIA][STARTUP] $line');
  }
}
