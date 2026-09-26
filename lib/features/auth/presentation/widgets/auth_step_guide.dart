import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/localization/localization_extensions.dart';
import 'auth_experience_scaffold.dart';

/// Le fil de l'inscription : où l'on en est, pourquoi cette étape et ce qui
/// vient ensuite — un seul repère, pour laisser la place au contenu.
///
/// Registre (QA appareil, 23/09/2026) : l'inscription est longue ; un parent
/// doit comprendre ce qu'il fait et où il va. Direction « Encre & Tracé » :
/// un repère qui pivote d'un quart de tour à chaque étape, un trait d'encre
/// qui se dessine jusqu'à l'étape en cours, le conseil qui glisse en place.
/// Tout joue une fois ; « réduire les animations » pose tout d'emblée.
class AuthStepGuide extends StatelessWidget {
  const AuthStepGuide({
    required this.currentStep,
    required this.labels,
    required this.hints,
    super.key,
  }) : assert(labels.length == hints.length);

  final int currentStep;
  final List<String> labels;
  final List<String> hints;

  static const guideKey = ValueKey('registration-guide');

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final step = currentStep.clamp(0, hints.length - 1);
    final last = step == hints.length - 1;
    final next = last
        ? context.l10n.registrationGuideLast
        : context.l10n.registrationGuideNext(labels[step + 1]);
    final duration = reduced
        ? Duration.zero
        : const Duration(milliseconds: 420);

    return Semantics(
      container: true,
      liveRegion: true,
      label:
          '${context.l10n.stepProgressA11y(step + 1, hints.length, labels[step])}. '
          '${hints[step]} $next',
      excludeSemantics: true,
      child: Container(
        key: guideKey,
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        decoration: BoxDecoration(
          color: AuthExperienceColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AuthExperienceColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GuideMark(step: step, duration: duration),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Où l'on en est, sur la même ligne que le trait d'encre :
                  // le guide remplace le fil d'étapes (QA appareil, 24/09).
                  Row(
                    children: [
                      Flexible(
                        flex: 3,
                        child: Text(
                          '${step + 1}/${hints.length}  ${labels[step]}',
                          key: const ValueKey('registration-guide-step'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'CampaignBody',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: AuthExperienceColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: _InkProgress(
                          fraction: (step + 1) / hints.length,
                          duration: duration,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  AnimatedSwitcher(
                    duration: duration,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.topLeft,
                      children: [...previous, ?current],
                    ),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.25),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: Column(
                      key: ValueKey('registration-guide-step-$step'),
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hints[step],
                          style: const TextStyle(
                            fontFamily: 'CampaignBody',
                            fontSize: 12.5,
                            height: 1.42,
                            fontWeight: FontWeight.w600,
                            color: AuthExperienceColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Icon(
                              last ? Icons.flag_rounded : Icons.east_rounded,
                              size: 14,
                              color: AuthExperienceColors.indigo,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                next,
                                style: const TextStyle(
                                  fontFamily: 'CampaignBody',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AuthExperienceColors.indigo,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Repère circulaire : un quart de tour à chaque nouvelle étape.
class _GuideMark extends StatelessWidget {
  const _GuideMark({required this.step, required this.duration});

  final int step;
  final Duration duration;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: step.toDouble()),
    duration: duration,
    curve: Curves.easeOutBack,
    builder: (context, turns, child) =>
        Transform.rotate(angle: turns * math.pi / 2, child: child),
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AuthExperienceColors.indigo.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(
          color: AuthExperienceColors.indigo.withValues(alpha: 0.35),
        ),
      ),
      child: const Icon(
        Icons.explore_outlined,
        size: 18,
        color: AuthExperienceColors.indigo,
      ),
    ),
  );
}

/// Trait d'encre : il se dessine jusqu'à l'étape en cours.
class _InkProgress extends StatelessWidget {
  const _InkProgress({required this.fraction, required this.duration});

  final double fraction;
  final Duration duration;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Stack(
      children: [
        Container(
          height: 3,
          width: constraints.maxWidth,
          decoration: BoxDecoration(
            color: AuthExperienceColors.border.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        TweenAnimationBuilder<double>(
          tween: Tween(end: fraction),
          duration: duration,
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => Container(
            key: const ValueKey('registration-guide-ink'),
            height: 3,
            width: constraints.maxWidth * value,
            decoration: BoxDecoration(
              color: AuthExperienceColors.indigo,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    ),
  );
}
