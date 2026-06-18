import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../application/admin_providers.dart';
import '../domain/admin_models.dart';

class ContentModerationScreen extends ConsumerWidget {
  const ContentModerationScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moderationAsync = ref.watch(adminModerationQueueProvider);
    final body = moderationAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: FilledButton.icon(
          onPressed: () => ref.invalidate(adminModerationQueueProvider),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Recharger'),
        ),
      ),
      data: (items) => ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          Text(
            'Modération des contenus',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Validez ou masquez les contenus signalés.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          if (items.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text('Aucun ticket de modération.'),
              ),
            ),
          for (final item in items) ...[
            _ModerationCard(item: item),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );

    if (embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Content Moderation')),
      body: body,
    );
  }
}

class _ModerationCard extends ConsumerWidget {
  const _ModerationCard({required this.item});

  final ModerationEntry item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = switch (item.status) {
      ModerationStatus.pending => const Color(0xFFF59E0B),
      ModerationStatus.approved => const Color(0xFF16A34A),
      ModerationStatus.rejected => const Color(0xFFDC2626),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.contentTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: statusColor.withValues(alpha: 0.16),
                  ),
                  child: Text(
                    item.status.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text('${item.contentType} • ${item.reportCount} signalement(s)'),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(adminActionsProvider).updateModeration(
                            moderationId: item.id,
                            status: ModerationStatus.rejected,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Contenu masqué.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.visibility_off_rounded),
                    label: const Text('Masquer'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      await ref.read(adminActionsProvider).updateModeration(
                            moderationId: item.id,
                            status: ModerationStatus.approved,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Contenu validé.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Valider'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
