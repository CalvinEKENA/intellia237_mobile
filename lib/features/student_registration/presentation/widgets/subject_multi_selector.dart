import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';

class SubjectMultiSelector extends StatelessWidget {
  const SubjectMultiSelector({
    required this.title,
    required this.caption,
    required this.options,
    required this.selected,
    required this.onToggle,
    super.key,
  });

  final String title;
  final String caption;
  final List<String> options;
  final List<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          caption,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final subject in options)
              FilterChip(
                label: Text(subject),
                selected: selected.contains(subject),
                onSelected: (_) => onToggle(subject),
              ),
          ],
        ),
      ],
    );
  }
}
