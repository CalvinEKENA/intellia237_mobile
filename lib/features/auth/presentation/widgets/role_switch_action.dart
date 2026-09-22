import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/auth_controller.dart';
import '../../domain/app_role.dart';
import 'auth_experience_scaffold.dart';

/// In-app button allowing users with multiple roles to switch active space without logging out.
///
/// Only visible if [AuthState.isMultiRole] is true.
class RoleSwitchAction extends ConsumerWidget {
  const RoleSwitchAction({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    if (!authState.isMultiRole) {
      return const SizedBox.shrink();
    }

    final currentRole = authState.role;

    if (compact) {
      return IconButton(
        key: const ValueKey('role-switch-compact-action'),
        tooltip: 'Changer d’espace (${currentRole?.label})',
        icon: const Icon(Icons.swap_horiz_rounded),
        onPressed: () => _showRoleSwitchSheet(context, ref),
      );
    }

    return OutlinedButton.icon(
      key: const ValueKey('role-switch-action'),
      onPressed: () => _showRoleSwitchSheet(context, ref),
      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
      label: Text(
        'Espace ${currentRole?.label ?? ""} • Changer',
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF003366),
        side: const BorderSide(color: Color(0xFF003366), width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }

  void _showRoleSwitchSheet(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authControllerProvider);
    final roles = authState.resolvedRoles;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AuthExperienceColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AuthExperienceColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Changer d’espace de travail',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AuthExperienceColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sélectionnez l’espace dans lequel vous souhaitez basculer instantanément.',
                  style: TextStyle(
                    fontFamily: 'CampaignBody',
                    fontSize: 13,
                    color: AuthExperienceColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                for (final role in roles) ...[
                  ListTile(
                    key: ValueKey('sheet-switch-role-${role.name}'),
                    leading: CircleAvatar(
                      backgroundColor: role == authState.role
                          ? const Color(0xFF003366)
                          : const Color(0xFFF0EADB),
                      child: Icon(
                        switch (role) {
                          AppRole.student => Icons.school_rounded,
                          AppRole.parent => Icons.family_restroom_rounded,
                          AppRole.teacher => Icons.cast_for_education_rounded,
                          AppRole.admin => Icons.admin_panel_settings_rounded,
                        },
                        color: role == authState.role
                            ? Colors.white
                            : const Color(0xFF003366),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Espace ${role.label}',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: role == authState.role
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: AuthExperienceColors.textPrimary,
                      ),
                    ),
                    trailing: role == authState.role
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF003366),
                          )
                        : const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      if (role != authState.role) {
                        await ref
                            .read(authControllerProvider.notifier)
                            .selectActiveRole(role);
                        if (context.mounted) {
                          context.go(role.homePath);
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 6),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
