import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../application/auth_controller.dart';
import 'living_pass.dart';

/// « Changer d'espace », sans se déconnecter : ouvre le sélecteur d'espaces.
///
/// Registre de décisions (refonte Auth V2, P1-3 de la revue de 7ea5cf0) :
/// cette action n'était placée dans aucun écran. Elle vit désormais dans les
/// Paramètres (élève, parent, enseignant), l'onglet Profil du parent et la
/// barre de l'administration. Invisible pour un compte à un seul espace.
class RoleSwitchAction extends ConsumerWidget {
  const RoleSwitchAction({super.key, this.compact = false});

  /// Icône de barre d'application plutôt qu'une ligne de liste.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    if (!auth.isMultiRole) return const SizedBox.shrink();
    final l10n = context.l10n;
    void open() => context.push(AppRoutes.roleChooser);

    if (compact) {
      return IconButton(
        key: const ValueKey('role-switch-compact-action'),
        tooltip: l10n.authSwitchSpace,
        icon: const Icon(Icons.swap_horiz_rounded),
        onPressed: open,
      );
    }
    return ListTile(
      key: const ValueKey('role-switch-action'),
      leading: const Icon(Icons.swap_horiz_rounded),
      title: Text(l10n.authSwitchSpace),
      subtitle: Text(
        '${l10n.authSpaceCurrent} : ${passRoleLabel(context, auth.role)}\n'
        '${l10n.authSwitchSpaceHint}',
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: open,
    );
  }
}
