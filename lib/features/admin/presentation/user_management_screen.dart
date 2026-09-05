import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../application/admin_providers.dart';
import '../domain/admin_models.dart';
import '../../../core/widgets/intellia_async_states.dart';
import '../../../core/widgets/intellia_state_view.dart';
import 'admin_presentation_localization.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(adminPendingReviewsProvider);
    final body = reviewsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => IntelliaStateView(
        kind: stateKindForError(error),
        message: stateMessageForKind(context, stateKindForError(error)),
        primaryLabel: context.l10n.retryLabel,
        onPrimary: () => ref.invalidate(adminPendingReviewsProvider),
      ),
      data: (reviews) => ListView(
        padding: const EdgeInsets.fromLTRB(
          IntelliaSpacing.lg,
          IntelliaSpacing.lg,
          IntelliaSpacing.lg,
          IntelliaSpacing.xl,
        ),
        children: [
          Text(
            context.l10n.accountApprovalTitle,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: IntelliaSpacing.xs),
          Text(
            context.l10n.pendingRequestsCount(reviews.length),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: IntelliaSpacing.md),
          if (reviews.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(IntelliaSpacing.md),
                child: Text(context.l10n.noPendingRequest),
              ),
            ),
          for (final review in reviews) ...[
            _ReviewCard(review: review),
            const SizedBox(height: IntelliaSpacing.sm),
          ],
        ],
      ),
    );

    if (embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.userManagementTitle)),
      body: body,
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  const _ReviewCard({required this.review});

  final PendingAccountReview review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(IntelliaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              review.fullName,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: IntelliaSpacing.xxs),
            Text(review.email),
            const SizedBox(height: IntelliaSpacing.xxs),
            Text(
              '${adminRoleLabel(context, review.role)} • ${review.establishmentName}',
            ),
            const SizedBox(height: IntelliaSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref
                          .read(adminActionsProvider)
                          .validateAccount(
                            reviewId: review.id,
                            approved: false,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.l10n.accountRejected)),
                        );
                      }
                    },
                    icon: const Icon(Icons.close_rounded),
                    label: Text(context.l10n.refuseLabel),
                  ),
                ),
                const SizedBox(width: IntelliaSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      await ref
                          .read(adminActionsProvider)
                          .validateAccount(reviewId: review.id, approved: true);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.l10n.accountApproved)),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_rounded),
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
