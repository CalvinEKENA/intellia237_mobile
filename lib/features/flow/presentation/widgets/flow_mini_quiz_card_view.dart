import 'flow_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../rewards/application/reward_providers.dart';
import '../../../rewards/domain/reward_event.dart';
import '../../../rewards/domain/reward_pattern.dart';
import '../../../rewards/presentation/reward_stage.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../application/flow_controller.dart';
import '../../domain/flow_card.dart';
import 'flow_card_scaffold.dart';

/// Mini-quiz à une question, joué directement dans le Flow.
class FlowMiniQuizCardView extends ConsumerStatefulWidget {
  const FlowMiniQuizCardView({
    required this.card,
    required this.onAward,
    super.key,
  });

  final FlowMiniQuizCard card;
  final ValueChanged<FlowAward> onAward;

  @override
  ConsumerState<FlowMiniQuizCardView> createState() =>
      _FlowMiniQuizCardViewState();
}

class _FlowMiniQuizCardViewState extends ConsumerState<FlowMiniQuizCardView> {
  int? _selected;
  RewardPattern? _reward;

  bool get _locked => _selected != null;

  Future<void> _choose(int index) async {
    if (_locked) return;
    setState(() => _selected = index);
    final localCorrect = index == widget.card.correctIndex;
    // Même moteur de récompense que le reste d'INTELLIA.
    final rewards = ref.read(rewardDispatcherProvider);
    if (localCorrect) {
      _reward = rewards.correct(
        const RewardEvent.correct(source: RewardSource.feed),
      );
    } else {
      rewards.incorrect();
    }
    final award = await ref
        .read(flowControllerProvider.notifier)
        .answerMiniQuiz(widget.card, index);
    if (!mounted) return;
    widget.onAward(award);
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final accent = card.subject.accent;

    return FlowCardScaffold(
      subject: card.subject,
      kicker: card.kicker,
      footer: _locked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_reward != null) ...[
                  RewardMessageLine(pattern: _reward),
                  const SizedBox(height: IntelliaSpacing.sm),
                ],
                _explanation(card, accent),
              ],
            )
          : null,
      child: RewardStage(
        pattern: _reward,
        accent: accent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.question,
              style: FlowTypography.title(context),
            ).animate().fadeIn(duration: 420.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: IntelliaSpacing.xl),
            ...card.options.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: IntelliaSpacing.sm),
                child: _option(e.key, e.value, accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(int index, String label, Color accent) {
    final isCorrect = index == widget.card.correctIndex;
    final isSelected = index == _selected;

    Color bg = IntelliaColors.surfaceSolid.withValues(alpha: 0.7);
    Color border = Colors.black.withValues(alpha: 0.06);
    Color fg = IntelliaColors.textPrimary;
    IconData? trailing;
    Color trailingColor = accent;

    if (_locked) {
      if (isCorrect) {
        bg = IntelliaColors.success.withValues(alpha: 0.12);
        border = IntelliaColors.success.withValues(alpha: 0.5);
        trailing = Icons.check_circle_rounded;
        trailingColor = IntelliaColors.success;
      } else if (isSelected) {
        bg = IntelliaColors.error.withValues(alpha: 0.10);
        border = IntelliaColors.error.withValues(alpha: 0.45);
        trailing = Icons.cancel_rounded;
        trailingColor = IntelliaColors.error;
      } else {
        fg = IntelliaColors.textTertiary;
      }
    }

    return GestureDetector(
      onTap: () => _choose(index),
      child: AnimatedContainer(
        duration: IntelliaMotion.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: IntelliaSpacing.md,
          vertical: 15,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(IntelliaRadii.large),
          border: Border.all(color: border, width: 1.2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
            if (trailing != null)
              Icon(trailing, size: 20, color: trailingColor),
          ],
        ),
      ),
    );
  }

  Widget _explanation(FlowMiniQuizCard card, Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(IntelliaSpacing.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(IntelliaRadii.large),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_rounded, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              card.explanation,
              style: GoogleFonts.montserrat(
                fontSize: 13.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: IntelliaColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 360.ms).slideY(begin: 0.2, end: 0);
  }
}
