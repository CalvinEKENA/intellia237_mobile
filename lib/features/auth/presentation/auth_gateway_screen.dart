import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../parent/application/pending_child_link.dart';
import '../domain/app_role.dart';
import 'widgets/auth_choices.dart';
import 'widgets/auth_experience_scaffold.dart';
import 'widgets/intellia_237_membrane.dart';
import 'widgets/living_pass.dart';
import 'widgets/school_head_access.dart';

/// Porte d'entrée neutre après une déconnexion.
///
/// Registre de décisions : se déconnecter renvoyait directement à
/// l'authentification téléphone de l'élève. Sur un appareil partagé — le cas
/// courant d'un foyer camerounais — un parent ou un enseignant se retrouvait
/// donc devant l'écran de quelqu'un d'autre, sans moyen d'ouvrir le sien.
///
/// Cet écran ne crée aucun mécanisme d'authentification : chaque rôle rejoint
/// le parcours qui existait déjà.
class AuthGatewayScreen extends ConsumerWidget {
  const AuthGatewayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return AuthExperienceScaffold(
      showBackButton: false,
      pass: LivingPass(
        seal: PassSealStage.neutral,
        phase: context.l10n.passWelcomeBack,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Le bouclier de la direction se range sur la ligne du surtitre :
          // discret, il ne repousse aucun choix sous la ligne de flottaison.
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: AuthHeader(
                  showBrand: false,
                  eyebrow: context.l10n.passSignIn,
                  title: context.l10n.passGoodToSeeYouAgain,
                  subtitle: l10n.authGatewaySubtitle,
                ),
              ),
              const Positioned(top: 0, right: 0, child: SchoolHeadShield()),
            ],
          ),
          const SizedBox(height: 26),
          AuthChoiceCard(
            key: const ValueKey('gateway-role-student'),
            title: l10n.studentRole,
            description: l10n.studentRoleDescription,
            icon: Icons.school_rounded,
            accent: AuthExperienceColors.indigo,
            isSelected: false,
            // L'élève garde son authentification par téléphone, sous son
            // intention : un compte d'un autre rôle n'y ouvre rien. Choisir
            // l'élève abandonne tout code enfant retenu pour un parent.
            onTap: () {
              ref.read(pendingChildLinkProvider.notifier).clear();
              context.push(AppRoutes.phoneRegistration(AppRole.student));
            },
          ),
          // Un élève sans téléphone entre avec le code d'accès que son parent
          // ou son établissement lui a remis.
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('gateway-student-access-code'),
              onPressed: () {
                ref.read(pendingChildLinkProvider.notifier).clear();
                context.push(AppRoutes.studentAccessCode);
              },
              icon: const Icon(Icons.key_rounded, size: 16),
              label: Text(l10n.studentNoPhoneUseAccessCode),
            ),
          ),
          const SizedBox(height: 4),
          AuthChoiceCard(
            key: const ValueKey('gateway-role-parent'),
            title: l10n.parentRole,
            description: l10n.parentRoleDescription,
            icon: Icons.family_restroom_rounded,
            accent: AuthExperienceColors.purple,
            isSelected: false,
            // Le parent commence par le code de son enfant.
            onTap: () => context.push(AppRoutes.parentEntry),
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
