import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../domain/student_home_snapshot.dart';

class RecommendationsSection extends StatelessWidget {
  const RecommendationsSection({
    required this.items,
    required this.onItemTap,
    super.key,
  });

  final List<RecommendationItem> items;
  final ValueChanged<RecommendationItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.personalizedRecommendations,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        for (final item in items) ...[
          Card(
            child: ListTile(
              onTap: () => onItemTap(item),
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(item.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.subtitle),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.lessonReadingMinutes(item.estimatedMinutes),
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
          const SizedBox(height: IntelliaSpacing.xs),
        ],
      ],
    );
  }
}
