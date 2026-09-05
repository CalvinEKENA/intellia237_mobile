import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../app/theme/design_tokens.dart';
import '../../../../../core/localization/localization_extensions.dart';
import '../../../../../core/widgets/intellia_pressable.dart';
import '../../../domain/onboarding_journey_state.dart';
import '../../../domain/onboarding_micro_challenge.dart';
import '../../../domain/onboarding_narrative.dart';
import '../onboarding_scene_frame.dart';

class ChallengeScene extends StatefulWidget {
  const ChallengeScene({
    required this.subject,
    required this.outcome,
    required this.reduceMotion,
    required this.onOutcomeChanged,
    required this.onContinue,
    this.academicLevel,
    this.subsystem,
    super.key,
  });

  final String subject;
  final String? academicLevel;
  final String? subsystem;
  final OnboardingChallengeOutcome outcome;
  final bool reduceMotion;
  final ValueChanged<OnboardingChallengeOutcome> onOutcomeChanged;
  final VoidCallback onContinue;

  @override
  State<ChallengeScene> createState() => _ChallengeSceneState();
}

class _ChallengeSceneState extends State<ChallengeScene> {
  int? _answeredIndex;

  OnboardingMicroChallenge get _challenge =>
      OnboardingMicroChallenges.forContext(
        subject: widget.subject,
        academicLevel: widget.academicLevel,
        subsystem: widget.subsystem,
      );

  void _answer(int index) {
    if (widget.outcome != OnboardingChallengeOutcome.unanswered) return;
    final solved = index == _challenge.correctAnswerIndex;
    HapticFeedback.selectionClick();
    setState(() => _answeredIndex = index);
    widget.onOutcomeChanged(
      solved
          ? OnboardingChallengeOutcome.solved
          : OnboardingChallengeOutcome.needsHelp,
    );
  }

  @override
  Widget build(BuildContext context) {
    final challenge = _challenge;
    return OnboardingSceneFrame(
      narrative: OnboardingNarrative(
        eyebrow: context.l10n.challengeEyebrow,
        title: context.l10n.challengeTitle,
        body: context.l10n.challengeBody,
      ),
      visualHeight: 430,
      visual: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF071534).withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(IntelliaRadii.extraLarge),
            border: Border.all(color: _accent.withValues(alpha: 0.34)),
            boxShadow: IntelliaShadows.glow(_accent, intensity: 0.10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: IntelliaColors.brandIndigo.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      challenge.icon,
                      color: IntelliaColors.brandBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge.instruction,
                          key: const ValueKey('challenge-instruction'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          challenge.prompt,
                          key: const ValueKey('challenge-prompt'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (
                var index = 0;
                index < challenge.answers.length;
                index++
              ) ...[
                _AnswerOption(
                  key: ValueKey('challenge-answer-$index'),
                  label: challenge.answers[index],
                  selected: _answeredIndex == index,
                  solved:
                      _answeredIndex == index &&
                      index == challenge.correctAnswerIndex,
                  enabled:
                      widget.outcome == OnboardingChallengeOutcome.unanswered,
                  onTap: () => _answer(index),
                ),
                if (index != challenge.answers.length - 1)
                  const SizedBox(height: 8),
              ],
              AnimatedSwitcher(
                duration: widget.reduceMotion
                    ? Duration.zero
                    : IntelliaMotion.medium,
                child: switch (widget.outcome) {
                  OnboardingChallengeOutcome.unanswered => const SizedBox(
                    key: ValueKey('challenge-neutral'),
                    height: 8,
                  ),
                  OnboardingChallengeOutcome.needsHelp => _Explanation(
                    key: const ValueKey('challenge-help'),
                    color: IntelliaColors.warning,
                    icon: Icons.lightbulb_rounded,
                    title: 'On apprend aussi en essayant.',
                    body: challenge.explanation,
                  ),
                  OnboardingChallengeOutcome.solved => _Explanation(
                    key: const ValueKey('challenge-solved'),
                    color: IntelliaColors.success,
                    icon: Icons.check_circle_rounded,
                    title: 'Bien vu. Ton raisonnement est en place.',
                    body: challenge.explanation,
                  ),
                },
              ),
              if (widget.outcome != OnboardingChallengeOutcome.unanswered) ...[
                const SizedBox(height: 12),
                _ContinuePrompt(
                  reduceMotion: widget.reduceMotion,
                  label: context.l10n.onboardingTapToContinue,
                  onTap: widget.onContinue,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color get _accent => switch (widget.outcome) {
    OnboardingChallengeOutcome.needsHelp => IntelliaColors.warning,
    OnboardingChallengeOutcome.solved => IntelliaColors.success,
    OnboardingChallengeOutcome.unanswered => IntelliaColors.brandIndigo,
  };
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.label,
    required this.selected,
    required this.solved,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final bool solved;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = solved
        ? IntelliaColors.success
        : selected
        ? IntelliaColors.warning
        : Colors.white54;
    return Semantics(
      button: true,
      selected: selected,
      label: context.l10n.answerChoiceA11y(label),
      child: IntelliaPressable(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: IntelliaMotion.fast,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.17)
                : Colors.white.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(IntelliaRadii.medium),
            border: Border.all(
              color: selected ? color : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                solved
                    ? Icons.check_rounded
                    : selected
                    ? Icons.close_rounded
                    : Icons.arrow_forward_rounded,
                color: color,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinuePrompt extends StatefulWidget {
  const _ContinuePrompt({
    required this.reduceMotion,
    required this.label,
    required this.onTap,
  });

  final bool reduceMotion;
  final String label;
  final VoidCallback onTap;

  @override
  State<_ContinuePrompt> createState() => _ContinuePromptState();
}

class _ContinuePromptState extends State<_ContinuePrompt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    if (!widget.reduceMotion) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _ContinuePrompt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: IntelliaPressable(
        key: const ValueKey('challenge-continue'),
        onTap: widget.onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(IntelliaRadii.full),
            border: Border.all(color: _accent.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => Transform.translate(
                  key: const ValueKey('challenge-continue-arrow'),
                  offset: Offset(
                    widget.reduceMotion ? 0 : _controller.value * 5,
                    0,
                  ),
                  child: child,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: _accent,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color get _accent => IntelliaColors.success;
}

class _Explanation extends StatelessWidget {
  const _Explanation({
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
    super.key,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
