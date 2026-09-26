import 'flow_typography.dart';
import 'package:flutter/material.dart';

import '../../application/flow_controller.dart';
import '../../domain/flow_card.dart';
import 'flow_content_card_views.dart';
import 'flow_exercise_card_views.dart';
import 'flow_learning_card_view.dart';
import 'flow_mini_quiz_card_view.dart';
import 'flow_reward_card_view.dart';

/// Aiguille vers la vue plein écran correspondant au type de carte.
class FlowCardView extends StatelessWidget {
  const FlowCardView({required this.card, required this.onAward, super.key});

  final FlowCard card;
  final ValueChanged<FlowAward> onAward;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => FlowTypographyScope(
        width: constraints.maxWidth,
        child: switch (card) {
          FlowNotionCard c => FlowNotionCardView(card: c),
          FlowQuestionCard c => FlowQuestionCardView(card: c),
          FlowVideoCard c => FlowVideoCardView(card: c),
          FlowAnimationCard c => FlowAnimationCardView(card: c),
          FlowAnecdoteCard c => FlowAnecdoteCardView(card: c),
          FlowMiniQuizCard c => FlowMiniQuizCardView(card: c, onAward: onAward),
          FlowTrueFalseCard c => FlowTrueFalseCardView(
            card: c,
            onAward: onAward,
          ),
          FlowFillBlankCard c => FlowFillBlankCardView(
            card: c,
            onAward: onAward,
          ),
          FlowOrderingCard c => FlowOrderingCardView(card: c, onAward: onAward),
          FlowRewardCard c => FlowRewardCardView(card: c),
          FlowLearningCard c => FlowLearningCardView(
            key: ValueKey(c.learning),
            card: c,
            onAward: onAward,
          ),
        },
      ),
    );
  }
}
