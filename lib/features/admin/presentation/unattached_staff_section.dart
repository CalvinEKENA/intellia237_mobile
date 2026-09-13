import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../application/admin_providers.dart';
import '../domain/admin_models.dart';
import 'admin_presentation_localization.dart';
import 'attach_school_sheet.dart';

/// Le personnel approuvé avant que son école existe dans INTELLIA.
///
/// L'administration générale le rattache ici, sans passer par la console :
/// le serveur n'accepte qu'un compte approuvé sans école, et ne déplace jamais
/// un compte déjà rattaché.
class UnattachedStaffSection extends ConsumerWidget {
  const UnattachedStaffSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Column(
      key: const ValueKey('unattached-staff'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.unattachedStaffTitle,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: IntelliaSpacing.xs),
        Text(
          l10n.unattachedStaffBody,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        ref
            .watch(adminUnattachedStaffProvider)
            .when(
              loading: () => const Padding(
                padding: EdgeInsets.all(IntelliaSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Card(
                child: ListTile(
                  title: Text(l10n.accountReviewFailed),
                  trailing: TextButton(
                    onPressed: () =>
                        ref.invalidate(adminUnattachedStaffProvider),
                    child: Text(l10n.retryLabel),
                  ),
                ),
              ),
              data: (members) => members.isEmpty
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(IntelliaSpacing.md),
                        child: Text(l10n.unattachedStaffEmpty),
                      ),
                    )
                  : Column(
                      children: [
                        for (final member in members)
                          Card(
                            child: ListTile(
                              key: ValueKey('unattached-${member.id}'),
                              title: Text(member.fullName),
                              subtitle: Text(
                                [
                                  adminRoleLabel(context, member.role),
                                  if (member.email.isNotEmpty) member.email,
                                ].join(' · '),
                              ),
                              trailing: FilledButton.tonal(
                                key: ValueKey('attach-staff-${member.id}'),
                                onPressed: () => _attach(context, ref, member),
                                child: Text(l10n.attachStaffAction),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
      ],
    );
  }

  Future<void> _attach(
    BuildContext context,
    WidgetRef ref,
    UnattachedStaffMember member,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(adminActionsProvider);
    final establishmentId = await showAttachSchoolSheet(
      context,
      body: l10n.attachStaffSheetBody,
    );
    if (establishmentId == null) return;
    try {
      await actions.attachStaffToEstablishment(
        staffId: member.id,
        establishmentId: establishmentId,
      );
      messenger.showSnackBar(SnackBar(content: Text(l10n.staffAttached)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.accountReviewFailed)));
    }
  }
}
