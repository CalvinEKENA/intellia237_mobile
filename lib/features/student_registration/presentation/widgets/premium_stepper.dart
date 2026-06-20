import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: IntelliaSpacing.md,
        vertical: IntelliaSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? IntelliaColors.surfaceSolidDark
            : IntelliaColors.surfaceSolid,
        borderRadius: BorderRadius.circular(IntelliaRadii.medium),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.15)
              : IntelliaColors.backgroundSecondary,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (int i = 0; i < labels.length; i++) ...[
                _StepCircle(index: i, currentStep: currentStep),
                if (i < labels.length - 1)
                  Expanded(child: _StepConnector(isCompleted: i < currentStep)),
              ],
            ],
          ),
          const SizedBox(height: IntelliaSpacing.xs),
          Text(
            labels[currentStep],
            style: TextStyle(
              color: isDark
                  ? IntelliaColors.textPrimaryDark
                  : IntelliaColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCompleted = index < currentStep;
    final isCurrent = index == currentStep;
    final borderSecondary = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : IntelliaColors.backgroundSecondary;
    final color = isCompleted || isCurrent
        ? IntelliaColors.brandIndigo
        : borderSecondary;
    return AnimatedContainer(
      duration: IntelliaMotion.medium,
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isCompleted
            ? IntelliaColors.brandIndigo
            : isCurrent
            ? IntelliaColors.brandIndigo.withValues(alpha: 0.1)
            : (isDark
                  ? IntelliaColors.surfaceSolidDark
                  : IntelliaColors.surfaceSolid),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
            : Text(
                '${index + 1}',
                style: TextStyle(
                  color: isCurrent
                      ? IntelliaColors.brandIndigo
                      : (isDark
                            ? IntelliaColors.textSecondaryDark
                            : IntelliaColors.textSecondary),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderSecondary = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : IntelliaColors.backgroundSecondary;

    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: IntelliaSpacing.xs),
      color: isCompleted ? IntelliaColors.brandIndigo : borderSecondary,
    );
  }
}
