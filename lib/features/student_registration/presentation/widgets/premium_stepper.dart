import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/design_tokens.dart';

class PremiumStepper extends StatelessWidget {
  const PremiumStepper({
    required this.currentStep,
    required this.labels,
    super.key,
  });

  final int currentStep;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  for (int i = 0; i < labels.length; i++) ...[
                    _StepCircle(index: i, currentStep: currentStep),
                    if (i < labels.length - 1)
                      Expanded(
                        child: _StepConnector(
                          isCompleted: i < currentStep,
                        ),
                      ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              AnimatedSwitcher(
                duration: AppMotion.medium,
                switchInCurve: AppMotion.emphasizedDecelerate,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Text(
                  labels[currentStep],
                  key: ValueKey(currentStep),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({required this.index, required this.currentStep});

  final int index;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final isCompleted = index < currentStep;
    final isCurrent = index == currentStep;

    if (isCompleted) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: AppGradients.heroGold,
          shape: BoxShape.circle,
          boxShadow: AppShadows.glow(AppColors.gold, intensity: 0.35),
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 18,
          color: Colors.white,
        ),
      )
          .animate()
          .scale(
            begin: const Offset(0.7, 0.7),
            end: const Offset(1.0, 1.0),
            duration: AppMotion.medium,
            curve: AppMotion.spring,
          )
          .fadeIn(duration: AppMotion.fast);
    }

    return AnimatedContainer(
      duration: AppMotion.medium,
      curve: AppMotion.emphasizedDecelerate,
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCurrent
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.transparent,
        border: Border.all(
          color: isCurrent
              ? AppColors.gold
              : Colors.white.withValues(alpha: 0.25),
          width: isCurrent ? 2.0 : 1.5,
        ),
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: TextStyle(
            color: isCurrent
                ? Colors.white
                : Colors.white.withValues(alpha: 0.45),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector({required this.isCompleted});

  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1),
        color: Colors.white.withValues(alpha: 0.15),
      ),
      child: isCompleted
          ? LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedContainer(
                  duration: AppMotion.slow,
                  curve: AppMotion.emphasizedDecelerate,
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1),
                    gradient: AppGradients.heroGold,
                  ),
                );
              },
            )
          : const SizedBox.shrink(),
    );
  }
}
