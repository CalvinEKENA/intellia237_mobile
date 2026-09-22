import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/auth_controller.dart';
import '../domain/app_role.dart';
import 'widgets/auth_experience_scaffold.dart';
import 'widgets/intellia_237_membrane.dart';
import 'widgets/living_pass.dart';

/// Contextual space selector presented when an authenticated user has multiple roles.
///
/// Invariant: Only roles present in [AuthState.availableRoles] are shown.
/// Automatically remembers the selected space for future sessions.
class RoleSelectorScreen extends ConsumerWidget {
  const RoleSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final roles = authState.resolvedRoles;
    final userName = authState.firstName ?? 'Utilisateur';

    return AuthExperienceScaffold(
      showBackButton: false,
      pass: const LivingPass(
        seal: PassSealStage.neutral,
        phase: 'Choix de l’espace',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: AuthHeader(
              showBrand: false,
              eyebrow: 'COMPTE MULTI-ESPACES',
              title: 'Bienvenue, $userName',
              subtitle:
                  'Ce compte est autorisé sur plusieurs espaces. Choisissez l’espace dans lequel vous souhaitez travailler.',
            ),
          ),
          const SizedBox(height: 28),

          for (final role in roles) ...[
            _RoleCard(
              key: ValueKey('role-select-${role.name}'),
              role: role,
              isSelected: authState.role == role,
              onTap: () async {
                await ref
                    .read(authControllerProvider.notifier)
                    .selectActiveRole(role);
                if (context.mounted) {
                  context.go(role.homePath);
                }
              },
            ),
            const SizedBox(height: 14),
          ],

          const SizedBox(height: 24),
          Center(
            child: TextButton.icon(
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
              icon: const Icon(
                Icons.logout_rounded,
                size: 16,
                color: AuthExperienceColors.textTertiary,
              ),
              label: const Text(
                'Me déconnecter',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  color: AuthExperienceColors.textTertiary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    super.key,
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  final AppRole role;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, accent, description) = switch (role) {
      AppRole.student => (
        Icons.school_rounded,
        const Color(0xFF5444D8),
        'Accédez à vos cours, exercices, devoirs et tuteurs IA KIRA & LÉO.',
      ),
      AppRole.parent => (
        Icons.family_restroom_rounded,
        const Color(0xFF80643D),
        'Suivez le travail, les notes et la présence de vos enfants.',
      ),
      AppRole.teacher => (
        Icons.cast_for_education_rounded,
        const Color(0xFF003366),
        'Gérez vos classes, publiez vos évaluations et suivez vos élèves.',
      ),
      AppRole.admin => (
        Icons.admin_panel_settings_rounded,
        const Color(0xFFD4AF37),
        'Administration et pilotage pédagogique de l’établissement.',
      ),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withValues(alpha: 0.05)
                : AuthExperienceColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? accent : AuthExperienceColors.border,
              width: isSelected ? 2.0 : 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Espace ${role.label}',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? accent
                                : AuthExperienceColors.textPrimary,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ACTIF',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontFamily: 'CampaignBody',
                        fontSize: 12.5,
                        height: 1.35,
                        color: AuthExperienceColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isSelected ? accent : AuthExperienceColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
