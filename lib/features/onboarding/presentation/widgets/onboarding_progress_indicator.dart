import 'package:flutter/material.dart';

class OnboardingProgressBar extends StatelessWidget {
  const OnboardingProgressBar({
    required this.totalSlides,
    required this.currentSlide,
    required this.progress,
    required this.accentColor,
    super.key,
  });

  final int totalSlides;
  final int currentSlide;
  final double progress; // 0.0 to 1.0
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.08);

    return Row(
      children: List.generate(totalSlides, (index) {
        final isCompleted = index < currentSlide;
        final isCurrent = index == currentSlide;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 4,
                child: LinearProgressIndicator(
                  value: isCompleted ? 1.0 : (isCurrent ? progress : 0.0),
                  backgroundColor: inactiveColor,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
