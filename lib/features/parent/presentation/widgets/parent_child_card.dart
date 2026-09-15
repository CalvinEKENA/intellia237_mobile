import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../family_access/domain/family_access_models.dart';
import '../../../study_reserve/presentation/study_reserve_card.dart';
import '../../domain/parent_child_profile.dart';
import 'student_access_code_sheet.dart';

/// Ce qu'un parent sait de l'accès de son enfant, sans jamais le numéro ni
/// le code.
String childAccessLabel(BuildContext context, ChildAccessMethods? access) {
  final l10n = context.l10n;
  if (access == null) return l10n.childAccessUnknown;
  if (access.ownPhone) return l10n.childAccessOwnPhone;
  if (access.accessCode) return l10n.childAccessCodeOnly;
  return l10n.childAccessNone;
}

/// L'abonnement qui couvre cet enfant ; null quand il est inconnu.
String? childSubscriptionLabel(
  BuildContext context,
  ChildSubscription? subscription,
) {
  final l10n = context.l10n;
  if (subscription == null) return null;
  if (!subscription.active) return l10n.childSubscriptionInactive;
  final endsAt = subscription.endsAt;
  final active = endsAt == null
      ? l10n.subscriptionTitle
      : l10n.childSubscriptionActiveUntil(
          MaterialLocalizations.of(context).formatMediumDate(endsAt),
        );
  return subscription.paidBy == ChildSubscriptionPayer.anotherGuardian
      ? '$active · ${l10n.childSubscriptionPaidByAnotherGuardian}'
      : active;
}

/// Carte d'un enfant dans « Mes enfants ».
class ParentChildCard extends StatelessWidget {
  const ParentChildCard({
    required this.child,
    required this.onSubscription,
    super.key,
  });

  final ParentChildProfile child;
  final VoidCallback onSubscription;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final subscription = childSubscriptionLabel(context, child.subscription);
    final ownAccess = child.access?.ownPhone ?? false;
    return Card(
      key: ValueKey('parent-child-card-${child.id}'),
      child: Padding(
        padding: const EdgeInsets.all(IntelliaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              child.fullName.isEmpty ? child.firstName : child.fullName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: IntelliaSpacing.xxs),
            if (child.pendingFirstSignIn)
              Text(
                l10n.childPendingFirstSignIn,
                key: ValueKey('parent-child-pending-${child.id}'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              Text(child.classLabel),
            Text(
              child.establishmentName?.trim().isNotEmpty ?? false
                  ? child.establishmentName!
                  : l10n.childSchoolUnknown,
              key: ValueKey('parent-child-school-${child.id}'),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: IntelliaSpacing.xs),
            Row(
              children: [
                Icon(
                  ownAccess ? Icons.verified_user_outlined : Icons.key_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    childAccessLabel(context, child.access),
                    key: ValueKey('parent-child-access-${child.id}'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (subscription != null) ...[
              const SizedBox(height: IntelliaSpacing.xxs),
              Text(
                subscription,
                key: ValueKey('parent-child-subscription-${child.id}'),
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: IntelliaSpacing.sm),
            // Réserve d'étude INDÉPENDANTE de cet enfant (jamais agrégée).
            if (!child.pendingFirstSignIn)
              StudyReserveCard(studentId: child.id, compact: true),
            const SizedBox(height: IntelliaSpacing.sm),
            Wrap(
              spacing: IntelliaSpacing.xs,
              runSpacing: IntelliaSpacing.xs,
              children: [
                FilledButton.tonalIcon(
                  key: ValueKey('parent-child-profile-${child.id}'),
                  onPressed: () =>
                      context.push(AppRoutes.parentChildProfile(child.id)),
                  icon: const Icon(Icons.badge_outlined),
                  label: Text(l10n.childActionViewProfile),
                ),
                OutlinedButton.icon(
                  key: ValueKey('parent-child-activity-${child.id}'),
                  onPressed: () =>
                      context.push(AppRoutes.parentChild(child.id)),
                  icon: const Icon(Icons.insights_outlined),
                  label: Text(l10n.childActionViewActivity),
                ),
                OutlinedButton.icon(
                  key: ValueKey('parent-child-access-code-${child.id}'),
                  onPressed: () => showStudentAccessCodeSheet(context, child),
                  icon: const Icon(Icons.key_rounded),
                  label: Text(l10n.childActionAccessCode),
                ),
                OutlinedButton.icon(
                  key: ValueKey('parent-child-subscription-action-${child.id}'),
                  onPressed: onSubscription,
                  icon: const Icon(Icons.payments_outlined),
                  label: Text(l10n.childActionSubscription),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
