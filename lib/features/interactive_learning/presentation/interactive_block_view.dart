import 'dart:math';

import 'package:flutter/material.dart';

import '../domain/interactive_block.dart';
import 'ordering_exercise_view.dart';

export 'ordering_exercise_view.dart' show ExerciseCompanion;

/// Rendu générique d'un bloc d'apprentissage, piloté par son type.
///
/// Réutilisable dans la conversation, Parcours, une leçon, une révision ou un
/// quiz : il ne dépend d'aucun fournisseur ni du réseau. Un type sans rendu
/// n'affiche rien — jamais d'interface improvisée.
class InteractiveBlockView extends StatelessWidget {
  const InteractiveBlockView({
    required this.block,
    required this.companion,
    this.onOutcome,
    this.onContinue,
    this.random,
    super.key,
  });

  final InteractiveLearningBlock block;
  final ExerciseCompanion companion;
  final ValueChanged<ActivityOutcome>? onOutcome;
  final VoidCallback? onContinue;
  final Random? random;

  @override
  Widget build(BuildContext context) {
    return switch (block) {
      final OrderingBlock ordering => OrderingExerciseView(
        key: ValueKey('ilb-${ordering.id}'),
        block: ordering,
        companion: companion,
        onOutcome: onOutcome,
        onContinue: onContinue,
        random: random,
      ),
    };
  }
}
