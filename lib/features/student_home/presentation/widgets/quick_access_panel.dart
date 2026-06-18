import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';

class QuickAccessPanel extends StatelessWidget {
  const QuickAccessPanel({
    required this.onQuizTap,
    required this.onAiTap,
    this.quizKey,
    this.aiKey,
    super.key,
  });

  final VoidCallback onQuizTap;
  final VoidCallback onAiTap;
  final Key? quizKey;
  final Key? aiKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: KeyedSubtree(
            key: quizKey,
            child: _QuickAccessTile(
              label: 'Quiz rapide',
              icon: Icons.quiz_rounded,
              gradientColors: const [Color(0xFF1451E1), Color(0xFF0E2E86)],
              onTap: onQuizTap,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: KeyedSubtree(
            key: aiKey,
            child: _QuickAccessTile(
              label: 'Compagnon',
              icon: Icons.school_rounded,
              gradientColors: const [Color(0xFF0F766E), Color(0xFF065F46)],
              onTap: onAiTap,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  const _QuickAccessTile({
    required this.label,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Ink(
        height: 92,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
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
