import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../auth/application/auth_controller.dart';
import '../application/admin_providers.dart';
import '../domain/admin_models.dart';
import '../../../core/widgets/intellia_async_states.dart';
import 'admin_presentation_localization.dart';
import 'school_directory_section.dart';

/// Le personnel, les demandes d'accès et l'annuaire de l'école.
///
/// L'administration générale approuve pour toutes les écoles et rattache à
/// l'approbation un compte qui n'en a pas. Une direction d'établissement
/// approuve ses enseignants, consulte toute son école et nomme ses classes —
/// sans jamais ajouter ni retirer un élève.
class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final hasSchool = (auth.establishmentId ?? '').trim().isNotEmpty;
    final reviewsAsync = ref.watch(adminPendingReviewsProvider);

    final body = ListView(
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
        ...reviewsAsync.when(
          loading: () => const [
            Padding(
              padding: EdgeInsets.all(IntelliaSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
          error: (error, stackTrace) => [
            Card(
              child: ListTile(
                title: Text(
                  stateMessageForKind(context, stateKindForError(error)),
                ),
                trailing: TextButton(
                  onPressed: () => ref.invalidate(adminPendingReviewsProvider),
                  child: Text(context.l10n.retryLabel),
                ),
              ),
            ),
          ],
          data: (reviews) => [
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
              _ReviewCard(review: review, canAttachSchool: auth.isSuperAdmin),
              const SizedBox(height: IntelliaSpacing.sm),
            ],
          ],
        ),
        if (hasSchool) ...[
          const SizedBox(height: IntelliaSpacing.xl),
          const SchoolDirectorySection(),
          const SizedBox(height: IntelliaSpacing.xl),
          const SchoolClassesSection(),
        ],
        const SizedBox(height: IntelliaSpacing.xl),
        const _PhoneLinkCard(),
      ],
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

class _ReviewCard extends ConsumerStatefulWidget {
  const _ReviewCard({required this.review, required this.canAttachSchool});

  final PendingAccountReview review;

  /// Seule l'administration générale rattache une école à l'approbation.
  final bool canAttachSchool;

  @override
  ConsumerState<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends ConsumerState<_ReviewCard> {
  bool _busy = false;

  Future<void> _decide({required bool approved}) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    String? establishmentId;
    if (approved &&
        widget.review.establishmentId == null &&
        widget.canAttachSchool) {
      establishmentId = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const _AttachSchoolSheet(),
      );
      if (establishmentId == null) return;
    }
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(adminActionsProvider)
          .validateAccount(
            reviewId: widget.review.id,
            approved: approved,
            establishmentId: establishmentId,
          );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            approved ? l10n.accountApproved : l10n.accountRejected,
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.accountReviewFailed)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final review = widget.review;
    final school = review.establishmentId == null
        ? context.l10n.reviewNoSchool
        : review.establishmentName;
    return Card(
      key: ValueKey('review-${review.id}'),
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
            Text('${adminRoleLabel(context, review.role)} • $school'),
            const SizedBox(height: IntelliaSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: ValueKey('review-refuse-${review.id}'),
                    onPressed: _busy ? null : () => _decide(approved: false),
                    icon: const Icon(Icons.close_rounded),
                    label: Text(context.l10n.refuseLabel),
                  ),
                ),
                const SizedBox(width: IntelliaSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    key: ValueKey('review-approve-${review.id}'),
                    onPressed: _busy ? null : () => _decide(approved: true),
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

/// Choisit l'école d'un compte à l'approbation, ou l'ouvre si elle n'existe
/// pas encore. Renvoie l'identifiant de l'école retenue.
class _AttachSchoolSheet extends ConsumerStatefulWidget {
  const _AttachSchoolSheet();

  @override
  ConsumerState<_AttachSchoolSheet> createState() => _AttachSchoolSheetState();
}

class _AttachSchoolSheetState extends ConsumerState<_AttachSchoolSheet> {
  final _name = TextEditingController();
  final _city = TextEditingController();
  bool _creating = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_name.text.trim().length < 3) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final failure = context.l10n.accountReviewFailed;
    setState(() => _saving = true);
    try {
      final id = await ref
          .read(adminActionsProvider)
          .createEstablishment(name: _name.text, city: _city.text);
      navigator.pop(id);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(failure)));
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final schools = ref.watch(adminEstablishmentsProvider);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          IntelliaSpacing.lg,
          0,
          IntelliaSpacing.lg,
          IntelliaSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          key: const ValueKey('attach-school-sheet'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.reviewAttachSchoolTitle,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: IntelliaSpacing.xs),
            Text(l10n.reviewAttachSchoolBody),
            const SizedBox(height: IntelliaSpacing.md),
            schools.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(IntelliaSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Card(
                child: ListTile(
                  title: Text(l10n.accountReviewFailed),
                  trailing: TextButton(
                    onPressed: () =>
                        ref.invalidate(adminEstablishmentsProvider),
                    child: Text(l10n.retryLabel),
                  ),
                ),
              ),
              data: (options) => Column(
                children: [
                  for (final option in options)
                    Card(
                      child: ListTile(
                        key: ValueKey('attach-school-${option.id}'),
                        leading: const Icon(Icons.school_outlined),
                        title: Text(option.name),
                        subtitle: option.city.isEmpty
                            ? null
                            : Text(option.city),
                        onTap: () => Navigator.of(context).pop(option.id),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: IntelliaSpacing.md),
            if (!_creating)
              OutlinedButton.icon(
                key: const ValueKey('attach-school-create'),
                onPressed: () => setState(() => _creating = true),
                icon: const Icon(Icons.add_business_outlined),
                label: Text(l10n.reviewCreateSchool),
              )
            else ...[
              TextField(
                key: const ValueKey('attach-school-name'),
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l10n.schoolNameLabel),
              ),
              const SizedBox(height: IntelliaSpacing.sm),
              TextField(
                key: const ValueKey('attach-school-city'),
                controller: _city,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l10n.schoolCityLabel),
              ),
              const SizedBox(height: IntelliaSpacing.md),
              FilledButton(
                key: const ValueKey('attach-school-confirm'),
                onPressed: _saving ? null : _create,
                child: Text(l10n.reviewCreateSchoolAction),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Le téléphone d'un chef d'établissement n'ouvre sa session qu'une fois
/// rattaché à son compte : l'entrée reste à portée depuis son espace.
class _PhoneLinkCard extends StatelessWidget {
  const _PhoneLinkCard();

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      key: const ValueKey('admin-phone-link'),
      leading: const Icon(Icons.phone_iphone_rounded),
      title: Text(context.l10n.adminPhoneLinkTitle),
      subtitle: Text(context.l10n.adminPhoneLinkBody),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => context.push('${AppRoutes.phoneAuth}?mode=link'),
    ),
  );
}
