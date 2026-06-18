import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../domain/app_role.dart';

/// Sélecteur de rôle visuel pour l'inscription
class RoleSelector extends StatelessWidget {
  const RoleSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleSelected,
  });

  final AppRole? selectedRole;
  final ValueChanged<AppRole> onRoleSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Je suis...',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.6,
          children: [
            for (final role in AppRole.values)
              _RoleTile(
                role: role,
                isSelected: selectedRole == role,
                onTap: () => onRoleSelected(role),
              ),
          ],
        ),
      ],
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  final AppRole role;
  final bool isSelected;
  final VoidCallback onTap;

  IconData get _icon => switch (role) {
    AppRole.student => Icons.school_rounded,
    AppRole.parent => Icons.family_restroom_rounded,
    AppRole.teacher => Icons.menu_book_rounded,
    AppRole.admin => Icons.admin_panel_settings_rounded,
  };

  String get _label => switch (role) {
    AppRole.student => 'Élève',
    AppRole.parent => 'Parent',
    AppRole.teacher => 'Enseignant',
    AppRole.admin => 'Admin',
  };

  @override
  Widget build(BuildContext context) {
    final color = AppRoleColors.byRole(role);
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.emphasizedDecelerate,
      decoration: BoxDecoration(
        color: isSelected
            ? color.withValues(alpha: 0.12)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: isSelected ? color : Colors.transparent,
          width: isSelected ? 1.8 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _icon,
                  size: 28,
                  color: isSelected
                      ? color
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? color : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
