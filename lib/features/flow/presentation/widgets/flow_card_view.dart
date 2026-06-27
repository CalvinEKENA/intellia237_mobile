import 'package:flutter/material.dart';

import '../../application/flow_controller.dart';
import '../../domain/flow_card.dart';
import 'flow_content_card_views.dart';
import 'flow_mini_quiz_card_view.dart';
import 'flow_reward_card_view.dart';

/// Aiguille vers la vue plein écran correspondant au type de carte.
class FlowCardView extends StatelessWidget {
  const FlowCardView({required this.card, required this.onAward, super.key});

  final FlowCard card;
  final ValueChanged<FlowAward> onAward;

  @override
  Widget build(BuildContext context) {
    return switch (card) {
      FlowNotionCard c => FlowNotionCardView(card: c),
      FlowQuestionCard c => FlowQuestionCardView(card: c),
      FlowVideoCard c => FlowVideoCardView(card: c),
      FlowAnimationCard c => FlowAnimationCardView(card: c),
      FlowAnecdoteCard c => FlowAnecdoteCardView(card: c),
      FlowMiniQuizCard c => FlowMiniQuizCardView(card: c, onAward: onAward),
      FlowRewardCard c => FlowRewardCardView(card: c),
    };
  }
}
