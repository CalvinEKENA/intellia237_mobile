import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/widgets/intellia_async_states.dart';
import '../../../core/widgets/intellia_state_view.dart';
import '../../mastery/presentation/mastery_style.dart';
import '../../mobile_money/presentation/mobile_money_parent_tab.dart';
import '../../study_reserve/presentation/study_reserve_card.dart';
import '../application/parent_providers.dart';
import '../domain/parent_child_profile.dart';
import 'widgets/parent_child_card.dart';
import 'widgets/student_access_code_sheet.dart';
import '../../family_access/presentation/guardian_link_code_sheet.dart';

/// Profil d'un enfant, vu par un parent lié.
///
/// Aucune usurpation : le parent reste connecté sous son propre UID et ne
/// lit que ce qu'un lien approuvé autorise. Le bandeau le dit sans ambiguïté.
/// Un enfant qui n'est pas lié à ce parent n'apparaît pas : l'écran ne
/// révèle même pas son existence.
class ChildProfileScreen extends ConsumerWidget {
  const ChildProfileScreen({required this.studentId, super.key});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childAsync = ref.watch(parentChildByIdProvider(studentId));
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: MasteryStyle.paper,
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(56),
        title: Text(l10n.childProfileTitle, maxLines: 3),
      ),
      body: childAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => IntelliaStateView(
          kind: stateKindForError(error),
          message: stateMessageForKind(context, stateKindForError(error)),
          primaryLabel: l10n.retryLabel,
          onPrimary: () => ref.invalidate(parentChildByIdProvider(studentId)),
        ),
        data: (child) {
          if (child == null) {
            return Center(
              key: const ValueKey('child-profile-not-found'),
              child: Text(l10n.childNotFound),
            );
          }
          return _ChildProfileBody(child: child);
        },
      ),
    );
  }
}

class _ChildProfileBody extends StatelessWidget {
  const _ChildProfileBody({required this.child});

  final ParentChildProfile child;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final subscription =
        childSubscriptionLabel(context, child.subscription) ??
        l10n.childAccessUnknown;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 768),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            Container(
              key: const ValueKey('parent-mode-banner'),
              padding: const EdgeInsets.all(IntelliaSpacing.md),
              decoration: BoxDecoration(
                color: IntelliaColors.brandIndigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(IntelliaRadii.medium),
                border: Border.all(
                  color: IntelliaColors.brandIndigo.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.parentModeProfileBanner(child.firstName.toUpperCase()),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: IntelliaColors.brandIndigo,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: IntelliaSpacing.xxs),
                  Text(
                    l10n.parentModeProfileNote,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: IntelliaSpacing.lg),
            Text(
              child.fullName.isEmpty ? child.firstName : child.fullName,
              key: const ValueKey('child-profile-name'),
              style: MasteryStyle.title,
            ),
            const SizedBox(height: IntelliaSpacing.md),
            _Line(label: l10n.childProfileClass, value: child.classLabel),
            _Line(
              label: l10n.childProfileSchool,
              value: child.establishmentName?.trim().isNotEmpty ?? false
                  ? child.establishmentName!
                  : l10n.childSchoolUnknown,
            ),
            _Line(
              label: l10n.childProfileAccess,
              value: childAccessLabel(context, child.access),
            ),
            _Line(label: l10n.childProfileSubscription, value: subscription),
            const SizedBox(height: IntelliaSpacing.md),
            StudyReserveCard(studentId: child.id),
            const SizedBox(height: IntelliaSpacing.md),
            Wrap(
              spacing: IntelliaSpacing.xs,
              runSpacing: IntelliaSpacing.xs,
              children: [
                FilledButton.tonalIcon(
                  key: const ValueKey('child-profile-activity'),
                  onPressed: () =>
                      context.push(AppRoutes.parentChild(child.id)),
                  icon: const Icon(Icons.insights_outlined),
                  label: Text(l10n.childActionViewActivity),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('child-profile-access-code'),
                  onPressed: () => showStudentAccessCodeSheet(context, child),
                  icon: const Icon(Icons.key_rounded),
                  label: Text(l10n.childActionAccessCode),
                ),
                if (!child.pendingFirstSignIn)
                  OutlinedButton.icon(
                    key: const ValueKey('child-profile-link-code'),
                    onPressed: () => showGuardianLinkCodeSheet(
                      context,
                      studentId: child.id,
                      studentName: child.firstName,
                    ),
                    icon: const Icon(Icons.link_rounded),
                    label: Text(l10n.childActionLinkCode),
                  ),
                OutlinedButton.icon(
                  key: const ValueKey('child-profile-subscription'),
                  onPressed: () =>
                      context.push(AppRoutes.parentChildSubscription(child.id)),
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

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: IntelliaSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Abonnement d'un enfant : l'enfant choisi désigne l'école, donc l'offre.
class ChildSubscriptionScreen extends StatelessWidget {
  const ChildSubscriptionScreen({required this.studentId, super.key});

  final String studentId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: MediaQuery.textScalerOf(context).scale(56),
      title: Text(context.l10n.subscriptionTitle, maxLines: 3),
    ),
    body: MobileMoneyParentTab(initialChildId: studentId),
  );
}
