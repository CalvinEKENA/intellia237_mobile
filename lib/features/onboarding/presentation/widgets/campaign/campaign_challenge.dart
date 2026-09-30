import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/onboarding_journey_state.dart';
import '../../../domain/onboarding_micro_challenge.dart';
import 'campaign_design.dart';

const _ink = Color(0xFF25233E);
const _violet = Color(0xFF5444D8);
const _paper = Color(0xFFF8F5EE);

/// The first learning interaction, ready to sit in a scrolling campaign scene.
class CampaignChallenge extends StatefulWidget {
  const CampaignChallenge({
    required this.subject,
    required this.reduceMotion,
    required this.outcome,
    required this.onOutcomeChanged,
    required this.onContinue,
    super.key,
  });

  final String subject;
  final bool reduceMotion;
  final OnboardingChallengeOutcome outcome;
  final ValueChanged<OnboardingChallengeOutcome> onOutcomeChanged;
  final VoidCallback onContinue;

  @override
  State<CampaignChallenge> createState() => _CampaignChallengeState();
}

class _CampaignChallengeState extends State<CampaignChallenge> {
  int? _answeredIndex;

  bool get _answered => widget.outcome != OnboardingChallengeOutcome.unanswered;

  @override
  void didUpdateWidget(covariant CampaignChallenge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subject != widget.subject ||
        widget.outcome == OnboardingChallengeOutcome.unanswered) {
      _answeredIndex = null;
    }
  }

  void _answer(int index, OnboardingMicroChallenge challenge) {
    if (_answered || _answeredIndex != null) return;
    HapticFeedback.selectionClick();
    setState(() => _answeredIndex = index);
    widget.onOutcomeChanged(
      index == challenge.correctAnswerIndex
          ? OnboardingChallengeOutcome.solved
          : OnboardingChallengeOutcome.needsHelp,
    );
  }

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final challenge = OnboardingMicroChallenges.forContext(
      subject: widget.subject,
      languageCode: english ? 'en' : 'fr',
    );
    final numeric = challenge.isNumberPattern;
    // A restored outcome has no remembered wrong answer. Show the solution
    // without attributing an invented choice to the learner.
    final selectedIndex = widget.outcome == OnboardingChallengeOutcome.solved
        ? challenge.correctAnswerIndex
        : _answeredIndex;
    final roomyAnswers =
        numeric && MediaQuery.textScalerOf(context).scale(24) < 40;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(challenge.icon, color: _violet, size: 19),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                challenge.instruction,
                key: const ValueKey('challenge-instruction'),
                style: const TextStyle(
                  fontFamily: 'CampaignBody',
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (numeric)
          _NumberArchitecture(
            answered: _answered,
            reduceMotion: widget.reduceMotion,
            semanticLabel: _answered
                ? (english
                      ? '2 times 2 is 4. 4 times 2 is 8. 8 times 2 is 16.'
                      : '2 fois 2 égale 4. 4 fois 2 égale 8. 8 fois 2 égale 16.')
                : challenge.prompt,
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 24),
            child: Text(
              challenge.prompt,
              key: const ValueKey('challenge-prompt'),
              style: const TextStyle(
                fontFamily: 'BarlowCondensed',
                color: _ink,
                fontSize: 30,
                height: 1.08,
                letterSpacing: -1.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        if (roomyAnswers)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (
                var index = 0;
                index < challenge.answers.length;
                index++
              ) ...[
                if (index > 0) const SizedBox(width: 10),
                Expanded(
                  child: _option(
                    challenge,
                    index,
                    selectedIndex,
                    true,
                    english,
                  ),
                ),
              ],
            ],
          )
        else
          for (var index = 0; index < challenge.answers.length; index++) ...[
            _option(challenge, index, selectedIndex, numeric, english),
            if (index < challenge.answers.length - 1) const SizedBox(height: 9),
          ],
        _answerReveal(
          _answered
              ? Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        liveRegion: true,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEDE9F8),
                            border: Border(
                              left: BorderSide(color: _violet, width: 3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.outcome ==
                                        OnboardingChallengeOutcome.solved
                                    ? (english
                                          ? 'You found the pattern.'
                                          : 'Tu as trouvé la logique.')
                                    : (english
                                          ? 'Let’s work it out together.'
                                          : 'Regardons ensemble.'),
                                style: const TextStyle(
                                  fontFamily: 'CampaignBody',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                challenge.explanation,
                                key: const ValueKey('challenge-explanation'),
                                style: const TextStyle(
                                  fontFamily: 'CampaignBody',
                                  fontSize: 13,
                                  height: 1.5,
                                  color: _ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!numeric && !CampaignRoom.isShort(context)) ...[
                        const SizedBox(height: 16),
                        _ProgressConstruction(
                          reduceMotion: widget.reduceMotion,
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton(
                        key: const ValueKey('challenge-continue'),
                        onPressed: widget.onContinue,
                        style: FilledButton.styleFrom(
                          backgroundColor: _ink,
                          foregroundColor: _paper,
                          minimumSize: const Size(0, 56),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 17,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                english
                                    ? 'Continue the ascent'
                                    : 'Continuer l’ascension',
                                style: const TextStyle(
                                  fontFamily: 'CampaignBody',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.north_east_rounded, size: 21),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _answerReveal(Widget child) {
    // A zero-duration RenderAnimatedSize can finish its controller while its
    // own layout is running. Reduced motion should avoid that render object.
    if (widget.reduceMotion) return child;
    return AnimatedSize(
      duration: const Duration(milliseconds: 380),
      alignment: Alignment.topCenter,
      curve: Curves.easeOutCubic,
      child: child,
    );
  }

  Widget _option(
    OnboardingMicroChallenge challenge,
    int index,
    int? selectedIndex,
    bool numeric,
    bool english,
  ) {
    final selected = index == selectedIndex;
    final solution = _answered && index == challenge.correctAnswerIndex;
    final label = challenge.answers[index];
    final color = solution ? _violet : _ink;
    final suffix = solution
        ? (english ? ', correct answer' : ', bonne réponse')
        : selected
        ? (english ? ', your answer' : ', ta réponse')
        : '';
    return Semantics(
      button: true,
      enabled: !_answered,
      selected: selected,
      label: '$label$suffix',
      onTap: _answered ? null : () => _answer(index, challenge),
      excludeSemantics: true,
      child: OutlinedButton(
        key: ValueKey('challenge-answer-$index'),
        onPressed: _answered ? null : () => _answer(index, challenge),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          disabledForegroundColor: color,
          backgroundColor: solution
              ? const Color(0xFFE5DFF8)
              : selected
              ? const Color(0xFFE8E4DB)
              : Colors.white.withValues(alpha: 0.76),
          side: BorderSide(
            color: solution
                ? _violet
                : _ink.withValues(alpha: selected ? 0.48 : 0.17),
            width: solution ? 1.5 : 1,
          ),
          minimumSize: const Size(0, 58),
          padding: EdgeInsets.symmetric(
            horizontal: numeric ? 8 : 14,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: numeric
            ? Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'BarlowCondensed',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'CampaignBody',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    solution
                        ? Icons.check_rounded
                        : Icons.arrow_outward_rounded,
                    size: 18,
                  ),
                ],
              ),
      ),
    );
  }
}

class _NumberArchitecture extends StatelessWidget {
  const _NumberArchitecture({
    required this.answered,
    required this.reduceMotion,
    required this.semanticLabel,
  });

  final bool answered;
  final bool reduceMotion;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: answered ? 1 : 0),
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 1100),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) {
          return SizedBox(
            height: 166,
            child: CustomPaint(
              painter: _StepPainter(progress: progress),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var index = 0; index < 4; index++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          5,
                          0,
                          5,
                          44 + index * 16 * progress,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                index == 3
                                    ? (answered ? '16' : '?')
                                    : '${1 << (index + 1)}',
                                textScaler: TextScaler.noScaling,
                                style: TextStyle(
                                  fontFamily: 'BarlowCondensed',
                                  color: index == 3 ? _violet : _ink,
                                  fontSize: index == 3 && answered ? 45 : 56,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 7),
                            Opacity(
                              opacity: index > 0 ? progress : 0,
                              child: Text(
                                '×2',
                                textScaler: TextScaler.noScaling,
                                style: const TextStyle(
                                  fontFamily: 'CampaignBody',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: _violet,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProgressConstruction extends StatelessWidget {
  const _ProgressConstruction({required this.reduceMotion});

  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 950),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) => SizedBox(
          height: 72,
          width: double.infinity,
          child: CustomPaint(painter: _StepPainter(progress: progress)),
        ),
      ),
    );
  }
}

class _StepPainter extends CustomPainter {
  const _StepPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width / 4;
    final baseline = size.height - 12;
    for (var index = 0; index < 4; index++) {
      final localProgress = ((progress - index * .1) / .7).clamp(0.0, 1.0);
      final height = 5 + (8 + 16 * index) * localProgress;
      final left = index * width + 4;
      final right = (index + 1) * width - 4;
      canvas.drawRect(
        Rect.fromLTRB(left, baseline - height, right, baseline),
        Paint()
          ..color = index == 3
              ? _violet
              : _ink.withValues(alpha: .12 + .09 * index),
      );
      final depth = math.min(7.0, width * .09) * localProgress;
      final top = Path()
        ..moveTo(left, baseline - height)
        ..lineTo(left + depth, baseline - height - depth)
        ..lineTo(right + depth, baseline - height - depth)
        ..lineTo(right, baseline - height)
        ..close();
      canvas.drawPath(
        top,
        Paint()
          ..color = index == 3
              ? const Color(0xFF9386E5)
              : const Color(0xFFDDD6C8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StepPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
