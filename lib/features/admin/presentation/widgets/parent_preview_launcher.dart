import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../parent/application/parent_preview.dart';
import '../../application/admin_providers.dart';
import '../../domain/admin_models.dart';

/// Ouvre le sélecteur de prévisualisation Parent : le super-administrateur y
/// choisit soit son propre compte, soit un parent existant à prévisualiser.
///
/// Aucune recherche globale d'élèves ici : seuls des comptes **parents** sont
/// listés, via le canal d'administration déjà autorisé.
Future<void> showParentPreviewLauncher(
  BuildContext context,
  WidgetRef ref,
) async {
  // Garde-fou de présentation : l'appelant ne montre l'entrée que pour le vrai
  // super-admin, mais on revérifie l'habilitation ici avant toute action.
  if (!canActivateParentPreview(ref.read(authControllerProvider))) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => const _ParentPreviewSheet(),
  );
}

class _ParentPreviewSheet extends ConsumerWidget {
  const _ParentPreviewSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final parentsAsync = ref.watch(
      schoolDirectoryProvider((
        role: AdminRoleType.parent,
        afterId: null,
        establishmentId: null,
      )),
    );

    void previewAs({String? uid, String? label}) {
      final entered = ref
          .read(parentPreviewControllerProvider.notifier)
          .enter(targetParentUid: uid, targetParentLabel: label);
      if (!entered) return;
      Navigator.of(context).pop();
      context.go(AppRoutes.parentHome);
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            IntelliaSpacing.lg,
            0,
            IntelliaSpacing.lg,
            IntelliaSpacing.lg,
          ),
          children: [
            Text(
              l10n.parentPreviewChooseParent,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: IntelliaSpacing.sm),
            Card(
              child: ListTile(
                key: const ValueKey('parent-preview-own-account'),
                leading: const Icon(Icons.shield_outlined),
                title: Text(l10n.parentPreviewOwnAccount),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => previewAs(),
              ),
            ),
            const SizedBox(height: IntelliaSpacing.sm),
            parentsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(IntelliaSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              ),
              // Un annuaire indisponible ne bloque jamais la prévisualisation de
              // son propre compte : on dégrade proprement vers un message.
              error: (_, _) => Padding(
                padding: const EdgeInsets.all(IntelliaSpacing.md),
                child: Text(l10n.parentPreviewNoParents),
              ),
              data: (page) {
                final parents = page.members
                    .where((m) => m.role == AdminRoleType.parent)
                    .toList(growable: false);
                if (parents.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(IntelliaSpacing.md),
                    child: Text(l10n.parentPreviewNoParents),
                  );
                }
                return Column(
                  children: [
                    for (final parent in parents)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.family_restroom_rounded),
                          title: Text(
                            parent.fullName.trim().isEmpty
                                ? parent.email
                                : parent.fullName,
                          ),
                          subtitle: parent.email.trim().isEmpty
                              ? null
                              : Text(parent.email),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => previewAs(
                            uid: parent.id,
                            label: parent.fullName.trim().isEmpty
                                ? parent.email
                                : parent.fullName,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
