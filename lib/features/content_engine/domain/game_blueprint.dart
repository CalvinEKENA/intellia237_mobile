import 'package:flutter/foundation.dart';

import 'visual_kind.dart';

/// Moteurs de jeu génériques. Un blueprint du pack est rattaché à l'un
/// d'eux ; les jeux eux-mêmes ne connaissent aucun chapitre.
enum GameEngineKind {
  /// Remplir des boîtes de même capacité : quotient et reste.
  grouping('grouping'),

  /// Allumer des interrupteurs pondérés pour atteindre une valeur.
  placeValue('place_value'),

  /// Prévoir la case d'arrivée sur une horloge à n positions.
  modularClock('modular_clock'),

  /// Casser un nombre en briques premières.
  factorForge('factor_forge'),

  /// Paver un rectangle, synchroniser deux rangées.
  tiling('tiling');

  const GameEngineKind(this.key);
  final String key;

  static GameEngineKind? fromKey(String? key) {
    for (final kind in values) {
      if (kind.key == key) return kind;
    }
    return null;
  }

  /// Le moteur naturel d'une primitive visuelle, s'il existe.
  static GameEngineKind? forVisual(VisualKind kind) => switch (kind) {
    VisualKind.grouping => grouping,
    VisualKind.placeValue => placeValue,
    VisualKind.modularClock => modularClock,
    VisualKind.factorBricks => factorForge,
    VisualKind.tiling => tiling,
    VisualKind.remainderBand || VisualKind.none => null,
  };
}

/// Barème d'un jeu.
@immutable
class ScoringRule {
  const ScoringRule({
    this.correct = 100,
    this.streakBonus = 25,
    this.penalty = 0,
    this.penaltyFromLevel,
  });

  /// Points d'une manche réussie.
  final int correct;

  /// Bonus par réussite consécutive au-delà de la première.
  final int streakBonus;

  /// Points retirés sur une erreur.
  final int penalty;

  /// Niveau à partir duquel la pénalité s'applique (`null` : tous).
  final int? penaltyFromLevel;

  int pointsFor({
    required bool correct,
    required int streak,
    required int level,
  }) {
    if (correct) {
      return this.correct + streakBonus * (streak > 1 ? streak - 1 : 0);
    }
    if (penaltyFromLevel != null && level < penaltyFromLevel!) return 0;
    return -penalty;
  }

  /// Lit un barème en texte libre (« 100 correct, +25 série, −20 seulement
  /// en Défi Bac »). Ce qui n'est pas reconnu garde la valeur par défaut.
  static ScoringRule parse(String? text, {required int maxLevel}) {
    if (text == null || text.trim().isEmpty) return const ScoringRule();
    final normalized = text.replaceAll('−', '-');
    int? find(RegExp pattern) {
      final match = pattern.firstMatch(normalized);
      return match == null ? null : int.tryParse(match.group(1)!);
    }

    final correct = find(
      RegExp(r'(\d+)\s*(?:correct|pts|points)', caseSensitive: false),
    );
    final streak = find(RegExp(r'\+\s*(\d+)'));
    final penalty = find(RegExp(r'-\s*(\d+)'));
    final onlyHardest = RegExp(
      r'seulement|only',
      caseSensitive: false,
    ).hasMatch(normalized);
    return ScoringRule(
      correct: correct ?? 100,
      streakBonus: streak ?? 25,
      penalty: penalty ?? 0,
      penaltyFromLevel: penalty != null && onlyHardest ? maxLevel : null,
    );
  }
}

/// Un jeu décrit par le pack.
@immutable
class GameBlueprint {
  const GameBlueprint({
    required this.id,
    required this.title,
    required this.conceptId,
    required this.mechanic,
    required this.levels,
    required this.scoring,
    this.engine,
  });

  final String id;
  final String title;

  /// Notion visée (peut ne correspondre à aucune notion du pack).
  final String conceptId;
  final String mechanic;

  /// Niveaux proposés par le pack et leur description.
  final Map<int, String> levels;
  final ScoringRule scoring;

  /// Moteur retenu ; `null` : aucun moteur ne sait encore jouer ce blueprint.
  final GameEngineKind? engine;

  bool get playable => engine != null && levels.isNotEmpty;
}
