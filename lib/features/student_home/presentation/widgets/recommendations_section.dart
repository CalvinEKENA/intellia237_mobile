import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';
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
          'Recommandations personnalisees',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final item in items) ...[
          Card(
            child: ListTile(
              onTap: () => onItemTap(item),
              leading: const Icon(Icons.auto_awesome_rounded),
              title: Text(item.title),
              subtitle: Text(item.subtitle),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${item.estimatedMinutes} min'),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }
}
