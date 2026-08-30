import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../app/theme/design_tokens.dart';
import '../../../../../core/widgets/intellia_pressable.dart';
import '../../../domain/onboarding_act.dart';
import '../../../domain/onboarding_journey_state.dart';
import '../../../domain/onboarding_narrative.dart';
import '../onboarding_scene_frame.dart';

class ChallengeScene extends StatefulWidget {
  const ChallengeScene({
    required this.outcome,
    required this.reduceMotion,
    required this.onOutcomeChanged,
    required this.onSolved,
    super.key,
  });

  final OnboardingChallengeOutcome outcome;
  final bool reduceMotion;
  final ValueChanged<OnboardingChallengeOutcome> onOutcomeChanged;
  final VoidCallback onSolved;

  @override
  State<ChallengeScene> createState() => _ChallengeSceneState();
}

class _ChallengeSceneState extends State<ChallengeScene> {
  bool _advancing = false;

  Future<void> _answer(int index) async {
    if (_advancing) return;
    if (widget.outcome == OnboardingChallengeOutcome.solved) {
      widget.onSolved();
      return;
    }
    if (index != 2) {
      HapticFeedback.selectionClick();
      widget.onOutcomeChanged(OnboardingChallengeOutcome.needsHelp);
      return;
    }

    _advancing = true;
    widget.onOutcomeChanged(OnboardingChallengeOutcome.solved);
    HapticFeedback.lightImpact();
    await Future<void>.delayed(
      widget.reduceMotion ? Duration.zero : const Duration(milliseconds: 420),
    );
    if (mounted) widget.onSolved();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingSceneFrame(
      narrative: OnboardingNarratives.forAct(OnboardingAct.challenge),
      visualHeight: 390,
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
                    child: const Icon(
                      Icons.functions_rounded,
                      color: IntelliaColors.brandBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Résous cette équation',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '3(x + 2) = 15',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (var index = 0; index < _answers.length; index++) ...[
                _AnswerOption(
                  key: ValueKey('challenge-answer-$index'),
                  label: _answers[index],
                  solved:
                      widget.outcome == OnboardingChallengeOutcome.solved &&
                      index == 2,
                  onTap: () => _answer(index),
                ),
                if (index != _answers.length - 1) const SizedBox(height: 8),
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
                  OnboardingChallengeOutcome.needsHelp => const _Explanation(
                    key: ValueKey('challenge-help'),
                    color: IntelliaColors.warning,
                    icon: Icons.lightbulb_rounded,
                    title: 'On décompose, sans pression.',
                    body: '3(x + 2) = 15  →  x + 2 = 5  →  x = 3',
                  ),
                  OnboardingChallengeOutcome.solved => const _Explanation(
                    key: ValueKey('challenge-solved'),
                    color: IntelliaColors.success,
                    icon: Icons.check_circle_rounded,
                    title: 'Exact. Le raisonnement est en place.',
                    body: 'Cette compréhension devient l’énergie du parcours.',
                  ),
                },
              ),
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

const _answers = ['x = 7', 'x = 5', 'x = 3'];

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.label,
    required this.solved,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool solved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: solved,
      label: 'Réponse $label',
      child: IntelliaPressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: IntelliaMotion.fast,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: solved
                ? IntelliaColors.success.withValues(alpha: 0.17)
                : Colors.white.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(IntelliaRadii.medium),
            border: Border.all(
              color: solved
                  ? IntelliaColors.success
                  : Colors.white.withValues(alpha: 0.12),
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
                solved ? Icons.check_rounded : Icons.arrow_forward_rounded,
                color: solved ? IntelliaColors.success : Colors.white54,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
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
