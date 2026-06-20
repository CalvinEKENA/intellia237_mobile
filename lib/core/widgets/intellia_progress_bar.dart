import 'package:flutter/material.dart';
import '../../app/theme/design_tokens.dart';

class IntelliaProgressBar extends StatelessWidget {
  const IntelliaProgressBar({
    required this.value,
    this.height = 4,
    this.gradient,
    this.backgroundColor,
    super.key,
  });

  final double value; // 0.0 to 1.0
  final double height;
  final Gradient? gradient;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final targetBg =
        backgroundColor ??
        (isDark ? const Color(0xFF2E2D44) : IntelliaColors.backgroundSecondary);
    final targetGradient = gradient ?? IntelliaGradients.brand;

    final clampedValue = value.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final progressWidth = totalWidth * clampedValue;

        return Container(
          width: totalWidth,
          height: height,
          decoration: BoxDecoration(
            color: targetBg,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: IntelliaMotion.medium,
                curve: Curves.easeOutCubic,
                width: progressWidth,
                height: height,
                decoration: BoxDecoration(
                  gradient: targetGradient,
                  borderRadius: BorderRadius.circular(height / 2),
                  boxShadow: [
                    BoxShadow(
                      color: targetGradient.colors.last.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
