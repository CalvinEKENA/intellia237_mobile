import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';

class ResumeCourseCard extends StatelessWidget {
  const ResumeCourseCard({
    required this.title,
    required this.chapter,
    required this.progress,
    required this.onResume,
    super.key,
  });

  final String title;
  final String chapter;
  final double progress;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reprendre le dernier cours',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(chapter, style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(value: progress, minHeight: 8),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onResume,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Continuer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
