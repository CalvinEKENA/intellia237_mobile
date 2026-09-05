import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../application/admin_providers.dart';
import '../domain/admin_models.dart';
import '../../../core/widgets/intellia_async_states.dart';
import '../../../core/widgets/intellia_state_view.dart';
import 'admin_presentation_localization.dart';

class ContentModerationScreen extends ConsumerWidget {
  const ContentModerationScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moderationAsync = ref.watch(adminModerationQueueProvider);
    final body = moderationAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => IntelliaStateView(
        kind: stateKindForError(error),
        message: stateMessageForKind(context, stateKindForError(error)),
        primaryLabel: context.l10n.retryLabel,
        onPrimary: () => ref.invalidate(adminModerationQueueProvider),
      ),
      data: (items) => ListView(
        padding: const EdgeInsets.fromLTRB(
          IntelliaSpacing.lg,
          IntelliaSpacing.lg,
          IntelliaSpacing.lg,
          IntelliaSpacing.xl,
        ),
        children: [
          Text(
            context.l10n.contentModerationTitle,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: IntelliaSpacing.xs),
          Text(
            context.l10n.contentModerationSubtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: IntelliaSpacing.md),
          if (items.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(IntelliaSpacing.md),
                child: Text(context.l10n.noModerationTicket),
              ),
            ),
          for (final item in items) ...[
            _ModerationCard(item: item),
            const SizedBox(height: IntelliaSpacing.sm),
          ],
        ],
      ),
    );

    if (embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.contentModerationTitle)),
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
        padding: const EdgeInsets.all(IntelliaSpacing.md),
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
                    horizontal: IntelliaSpacing.xs,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: statusColor.withValues(alpha: 0.16),
                  ),
                  child: Text(
                    moderationStatusLabel(context, item.status),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: IntelliaSpacing.xxs),
            Text(
              context.l10n.contentReports(item.contentType, item.reportCount),
            ),
            const SizedBox(height: IntelliaSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref
                          .read(adminActionsProvider)
                          .updateModeration(
                            moderationId: item.id,
                            status: ModerationStatus.rejected,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.l10n.contentHidden)),
                        );
                      }
                    },
                    icon: const Icon(Icons.visibility_off_rounded),
                    label: Text(context.l10n.hideLabel),
                  ),
                ),
                const SizedBox(width: IntelliaSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      await ref
                          .read(adminActionsProvider)
                          .updateModeration(
                            moderationId: item.id,
                            status: ModerationStatus.approved,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.l10n.contentApproved)),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle_rounded),
                    label: Text(context.l10n.confirmLabel),
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
