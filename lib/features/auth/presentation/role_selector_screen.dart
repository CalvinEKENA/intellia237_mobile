import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/localization_extensions.dart';
import '../application/auth_controller.dart';
import '../domain/app_role.dart';
import 'widgets/auth_experience_scaffold.dart';
import 'widgets/intellia_237_membrane.dart';
import 'widgets/living_pass.dart';

/// Sélecteur d'espace d'un compte que le serveur autorise sur plusieurs
/// espaces (par exemple parent et enseignant).
///
/// Il s'affiche une fois quand aucun espace n'est retenu sur l'appareil, puis
/// sur demande (« Changer d'espace »). Seuls les espaces de
/// [AuthState.availableRoles] apparaissent : ce choix ne donne aucun droit,
/// il ne fait que choisir parmi ceux que le serveur a déjà accordés.
class RoleSelectorScreen extends ConsumerWidget {
  const RoleSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final auth = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);

    return AuthExperienceScaffold(
      showBackButton: !auth.spaceChoicePending,
      pass: LivingPass(
        seal: PassSealStage.neutral,
        phase: l10n.authSpaceEyebrow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            showBrand: false,
            eyebrow: l10n.authSpaceEyebrow,
            title: l10n.authSpaceTitle,
            subtitle: l10n.authSpaceBody,
          ),
          const SizedBox(height: 22),
          for (final role in auth.resolvedRoles) ...[
            _SpaceCard(
              key: ValueKey('role-select-${role.name}'),
              role: role,
              current: auth.role == role && !auth.spaceChoicePending,
              onTap: () async {
                await controller.selectActiveRole(role);
                if (context.mounted) context.go(role.homePath);
              },
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              key: const ValueKey('role-select-sign-out'),
              onPressed: controller.signOut,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: Text(l10n.authSpaceSignOut),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpaceCard extends StatelessWidget {
  const _SpaceCard({
    required this.role,
    required this.current,
    required this.onTap,
    super.key,
  });

  final AppRole role;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (icon, title, hint) = switch (role) {
      AppRole.student => (
        Icons.school_rounded,
        l10n.authSpaceStudent,
        l10n.authSpaceStudentHint,
      ),
      AppRole.parent => (
        Icons.family_restroom_rounded,
        l10n.authSpaceParent,
        l10n.authSpaceParentHint,
      ),
      AppRole.teacher => (
        Icons.cast_for_education_rounded,
        l10n.authSpaceTeacher,
        l10n.authSpaceTeacherHint,
      ),
      AppRole.admin => (
        Icons.admin_panel_settings_rounded,
        l10n.authSpaceAdmin,
        l10n.authSpaceAdminHint,
      ),
    };
    return Semantics(
      button: true,
      selected: current,
      child: Material(
        color: AuthExperienceColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: current
                ? AuthExperienceColors.indigo
                : AuthExperienceColors.border,
            width: current ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, color: AuthExperienceColors.indigo, size: 26),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'CampaignBody',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AuthExperienceColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          current ? '${l10n.authSpaceCurrent} · $hint' : hint,
                          style: const TextStyle(
                            fontFamily: 'CampaignBody',
                            fontSize: 12.5,
                            height: 1.4,
                            color: AuthExperienceColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    current
                        ? Icons.check_circle_rounded
                        : Icons.chevron_right_rounded,
                    color: current
                        ? AuthExperienceColors.indigo
                        : AuthExperienceColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
