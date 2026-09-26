import 'package:flutter/foundation.dart';

/// Préférence « Vibrations pédagogiques ».
enum HapticMode {
  on,
  reduced,
  off;

  static HapticMode fromKey(String? key) => switch (key) {
    'reduced' => reduced,
    'off' => off,
    _ => on,
  };
}

/// Impulsion élémentaire. Jamais d'impulsion forte ni de vibration longue.
enum HapticImpulse { selection, light, medium }

/// Une impulsion, précédée d'une courte pause.
@immutable
class HapticStep {
  const HapticStep(this.impulse, [this.pauseBefore = Duration.zero]);

  final HapticImpulse impulse;
  final Duration pauseBefore;

  @override
  bool operator ==(Object other) =>
      other is HapticStep &&
      other.impulse == impulse &&
      other.pauseBefore == pauseBefore;

  @override
  int get hashCode => Object.hash(impulse, pauseBefore);

  @override
  String toString() => '${impulse.name}+${pauseBefore.inMilliseconds}ms';
}

/// Vocabulaire haptique : chaque motif a un sens pédagogique.
enum HapticPattern {
  none,

  /// Bonne réponse : un tap léger.
  tap,

  /// Retour doux (récupération après erreurs, réponse à revoir).
  soft,

  /// Série, niveau supérieur : deux petites impulsions.
  doubleTap,

  /// Défi réussi : une impulsion un peu plus marquée, puis une légère.
  firm,

  /// Notion maîtrisée : motif court et distinct.
  mastery,

  /// Grande étape : deux impulsions posées.
  milestone;

  static const _gap = Duration(milliseconds: 90);

  /// Impulsions réellement jouées selon la préférence de l'élève.
  ///
  /// « Réduites » : une seule impulsion légère, et seulement pour ce qui
  /// compte (série, défi, maîtrise, étape). « Désactivées » : rien.
  List<HapticStep> stepsFor(HapticMode mode) {
    if (mode == HapticMode.off || this == none) return const [];
    if (mode == HapticMode.reduced) {
      return switch (this) {
        doubleTap ||
        firm ||
        mastery ||
        milestone => const [HapticStep(HapticImpulse.light)],
        _ => const [],
      };
    }
    return switch (this) {
      none => const [],
      tap => const [HapticStep(HapticImpulse.light)],
      soft => const [HapticStep(HapticImpulse.selection)],
      doubleTap => const [
        HapticStep(HapticImpulse.light),
        HapticStep(HapticImpulse.light, _gap),
      ],
      firm => const [
        HapticStep(HapticImpulse.medium),
        HapticStep(HapticImpulse.light, _gap),
      ],
      mastery => const [
        HapticStep(HapticImpulse.medium),
        HapticStep(HapticImpulse.light, Duration(milliseconds: 70)),
        HapticStep(HapticImpulse.light, Duration(milliseconds: 70)),
      ],
      milestone => const [
        HapticStep(HapticImpulse.medium),
        HapticStep(HapticImpulse.medium, Duration(milliseconds: 140)),
      ],
    };
  }
}
