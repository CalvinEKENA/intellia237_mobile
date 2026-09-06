import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/localization/localization_extensions.dart';
import '../domain/app_role.dart';
import 'widgets/auth_choices.dart';
import 'widgets/auth_experience_scaffold.dart';

/// Porte d'entrée neutre après une déconnexion.
///
/// Registre de décisions : se déconnecter renvoyait directement à
/// l'authentification téléphone de l'élève. Sur un appareil partagé — le cas
/// courant d'un foyer camerounais — un parent ou un enseignant se retrouvait
/// donc devant l'écran de quelqu'un d'autre, sans moyen d'ouvrir le sien.
///
/// Cet écran ne crée aucun mécanisme d'authentification : chaque rôle rejoint
/// le parcours qui existait déjà.
class AuthGatewayScreen extends StatelessWidget {
  const AuthGatewayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AuthExperienceScaffold(
      showBackButton: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          AuthHeader(
            title: l10n.authGatewayTitle,
            subtitle: l10n.authGatewaySubtitle,
          ),
          const SizedBox(height: 26),
          AuthChoiceCard(
            key: const ValueKey('gateway-role-student'),
            title: l10n.studentRole,
            description: l10n.studentRoleDescription,
            icon: Icons.school_rounded,
            accent: AuthExperienceColors.indigo,
            isSelected: false,
            // L'élève garde son authentification par téléphone.
            onTap: () => context.push(AppRoutes.login),
          ),
          const SizedBox(height: 12),
          AuthChoiceCard(
            key: const ValueKey('gateway-role-parent'),
            title: l10n.parentRole,
            description: l10n.parentRoleDescription,
            icon: Icons.family_restroom_rounded,
            accent: AuthExperienceColors.purple,
            isSelected: false,
            onTap: () =>
                context.push(AppRoutes.phoneRegistration(AppRole.parent)),
          ),
          const SizedBox(height: 12),
          AuthChoiceCard(
            key: const ValueKey('gateway-role-teacher'),
            title: l10n.teacherRole,
            description: l10n.teacherRoleDescription,
            icon: Icons.cast_for_education_rounded,
            accent: AuthExperienceColors.blue,
            isSelected: false,
            // Les comptes enseignants s'authentifient par e-mail.
            onTap: () => context.push(AppRoutes.emailLogin),
          ),
          const SizedBox(height: 22),
          // Créer un compte reste accessible : la porte sert autant au retour
          // qu'à une première ouverture d'espace sur l'appareil.
          TextButton(
            key: const ValueKey('gateway-create-account'),
            onPressed: () => context.push(AppRoutes.register),
            child: Text(l10n.passTitle),
          ),
        ],
      ),
    );
  }
}
