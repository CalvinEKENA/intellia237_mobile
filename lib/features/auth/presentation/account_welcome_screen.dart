import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/localization/localization_extensions.dart';
import '../application/auth_controller.dart';
import 'widgets/auth_experience_scaffold.dart';
import 'widgets/pass_auth_progress.dart';
import 'widgets/living_pass.dart';

/// Identité prouvée (numéro vérifié, ou Google), aucun profil : la personne
/// dit comment elle commence.
///
/// Registre de décisions (refonte Auth V2, P1-5 de la revue de 7ea5cf0) : un
/// nouveau numéro sans rôle choisi aboutissait, après un redémarrage, sur
/// « profil introuvable ». Ce choix vient désormais APRÈS l'identité, jamais
/// avant, et aucun écran ne propose de rôle du personnel : l'accès enseignant
/// ou direction est ouvert par l'établissement.
class AccountWelcomeScreen extends ConsumerWidget {
  const AccountWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final auth = ref.read(authControllerProvider.notifier);

    // L'identité est prouvée : le sceau reste complet, comme sur les écrans
    // d'inscription qui suivent (aucun retour en arrière du « 237 »).
    final seal = PassAuthProgress.session(ref.watch(authControllerProvider));
    return AuthExperienceScaffold(
      showBackButton: false,
      pass: LivingPass(seal: seal, phase: l10n.authWelcomeEyebrow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            showBrand: false,
            eyebrow: l10n.authWelcomeEyebrow,
            title: l10n.authWelcomeTitle,
            subtitle: l10n.authWelcomeBody,
          ),
          const SizedBox(height: 22),
          _Choice(
            key: const ValueKey('welcome-parent'),
            icon: Icons.family_restroom_rounded,
            title: l10n.authWelcomeParent,
            hint: l10n.authWelcomeParentHint,
            onTap: () => context.go(AppRoutes.parentRegistration),
          ),
          const SizedBox(height: 12),
          _Choice(
            key: const ValueKey('welcome-student'),
            icon: Icons.school_rounded,
            title: l10n.authWelcomeStudent,
            hint: l10n.authWelcomeStudentHint,
            onTap: () => context.go(AppRoutes.studentRegistration),
          ),
          const SizedBox(height: 12),
          _Choice(
            key: const ValueKey('welcome-discover'),
            icon: Icons.travel_explore_rounded,
            title: l10n.authWelcomeDiscover,
            hint: l10n.authWelcomeDiscoverHint,
            onTap: auth.enterDiscoveryMode,
          ),
          const SizedBox(height: 18),
          Text(
            l10n.authWelcomeStaffNote,
            style: const TextStyle(
              fontFamily: 'CampaignBody',
              fontSize: 12,
              height: 1.45,
              color: AuthExperienceColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              key: const ValueKey('welcome-sign-out'),
              onPressed: auth.signOut,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(
                l10n.authUseAnotherAccount,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.icon,
    required this.title,
    required this.hint,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: Material(
      color: AuthExperienceColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AuthExperienceColors.border),
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
                        hint,
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
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AuthExperienceColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
