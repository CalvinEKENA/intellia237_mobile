import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../profile/application/user_preferences_controller.dart';
import '../domain/haptic_pattern.dart';
import '../domain/reward_engine.dart';
import '../domain/reward_event.dart';
import '../domain/reward_pattern.dart';

/// Exécute une impulsion élémentaire.
abstract interface class HapticDriver {
  Future<void> impulse(HapticImpulse impulse);
}

/// Retour haptique du système. Sur Android, il respecte le réglage
/// « vibration au toucher » de l'appareil ; sans vibreur, il ne fait rien.
class SystemHapticDriver implements HapticDriver {
  const SystemHapticDriver();

  @override
  Future<void> impulse(HapticImpulse impulse) => switch (impulse) {
    HapticImpulse.selection => HapticFeedback.selectionClick(),
    HapticImpulse.light => HapticFeedback.lightImpact(),
    HapticImpulse.medium => HapticFeedback.mediumImpact(),
  };
}

/// Joue un motif haptique selon la préférence de l'élève.
class HapticPlayer {
  const HapticPlayer(this.driver, this.mode);

  final HapticDriver driver;
  final HapticMode mode;

  /// La première impulsion part tout de suite ; les suivantes, après leur
  /// courte pause. Aucun motif ne dépasse 300 ms.
  void play(HapticPattern pattern) {
    final steps = pattern.stepsFor(mode);
    if (steps.isEmpty) return;
    unawaited(_run(steps));
  }

  Future<void> _run(List<HapticStep> steps) async {
    for (final step in steps) {
      if (step.pauseBefore > Duration.zero) {
        await Future<void>.delayed(step.pauseBefore);
      }
      try {
        await driver.impulse(step.impulse);
      } catch (_) {
        // Appareil sans vibreur ou plateforme sans retour haptique.
      }
    }
  }
}

final hapticDriverProvider = Provider<HapticDriver>(
  (ref) => const SystemHapticDriver(),
);

/// Préférence « Vibrations pédagogiques ».
final hapticModeProvider = Provider<HapticMode>(
  (ref) => ref.watch(userPreferencesProvider.select((p) => p.haptics)),
);

final hapticPlayerProvider = Provider<HapticPlayer>(
  (ref) => HapticPlayer(
    ref.watch(hapticDriverProvider),
    ref.watch(hapticModeProvider),
  ),
);

/// Horloge du moteur (remplaçable pour éprouver les délais).
final rewardClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Un moteur par élève connecté : sa mémoire courte ne passe jamais d'un
/// élève à l'autre.
final rewardEngineProvider = Provider<RewardEngine>((ref) {
  ref.watch(authControllerProvider.select((auth) => auth.userId));
  return RewardEngine(clock: ref.watch(rewardClockProvider));
});

/// Point d'entrée unique pour S'entraîner, Mon Parcours, les quiz et les
/// jeux : l'événement entre, le motif sort, l'haptique est jouée.
final rewardDispatcherProvider = Provider<RewardDispatcher>(
  (ref) => RewardDispatcher(
    ref.watch(rewardEngineProvider),
    ref.watch(hapticPlayerProvider),
  ),
);

class RewardDispatcher {
  const RewardDispatcher(this.engine, this.haptics);

  final RewardEngine engine;
  final HapticPlayer haptics;

  /// Une réussite : le motif à afficher (l'haptique part aussitôt).
  RewardPattern correct(RewardEvent event) {
    final pattern = engine.onCorrect(event);
    haptics.play(pattern.haptic);
    return pattern;
  }

  /// Une réponse à revoir : la série s'arrête, un retour doux, jamais
  /// d'impulsion forte.
  void incorrect() {
    engine.recordIncorrect();
    haptics.play(HapticPattern.soft);
  }
}
