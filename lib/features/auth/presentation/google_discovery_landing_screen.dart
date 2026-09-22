import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../application/auth_controller.dart';
import 'widgets/auth_experience_scaffold.dart';
import 'widgets/intellia_237_membrane.dart';
import 'widgets/living_pass.dart';

/// Landing screen presented to authenticated Google users who do not yet have an Intellia profile.
///
/// Gives four explicit, unforced choices:
/// 1. [ Découvrir INTELLIA237 ] -> Safe discovery mode (KIRA/LÉO showcase, no school data)
/// 2. [ J’ai déjà un compte INTELLIA237 ] -> Explicit proof-of-control account linking
/// 3. [ Rejoindre mon école ] -> Enter student access code or parent invitation code
/// 4. [ Créer un nouveau compte ] -> Standard registration
class GoogleDiscoveryLandingScreen extends ConsumerWidget {
  const GoogleDiscoveryLandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Bienvenue';
    final email = user?.email;

    return AuthExperienceScaffold(
      showBackButton: true,
      onBack: () {
        FirebaseAuth.instance.signOut();
        context.go(AppRoutes.authGateway);
      },
      pass: const LivingPass(
        seal: PassSealStage.neutral,
        phase: 'Compte Google vérifié',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: AuthHeader(
              showBrand: false,
              eyebrow: 'COMPTE GOOGLE VALIDÉ',
              title: displayName,
              subtitle: email != null
                  ? 'Connecté avec $email. Choisissez comment vous souhaitez continuer.'
                  : 'Choisissez la suite de votre parcours sur INTELLIA237.',
            ),
          ),
          const SizedBox(height: 28),

          // Choice 1: Safe Discovery
          _LandingChoiceCard(
            key: const ValueKey('google-choice-discovery'),
            icon: Icons.explore_rounded,
            accent: const Color(0xFF0099FF),
            title: 'Découvrir INTELLIA237',
            description:
                'Explorez les tuteurs IA KIRA et LÉO, les quiz et les parcours sans inscription scolaire.',
            onTap: () {
              ref
                  .read(authControllerProvider.notifier)
                  .enterDiscoveryMode(
                    userId: user?.uid,
                    email: email,
                    displayName: displayName,
                  );
              context.go(AppRoutes.googleDiscovery);
            },
          ),
          const SizedBox(height: 14),

          // Choice 2: Link existing account
          _LandingChoiceCard(
            key: const ValueKey('google-choice-link-account'),
            icon: Icons.link_rounded,
            accent: const Color(0xFFD4AF37),
            title: 'J’ai déjà un compte INTELLIA',
            description:
                'Associez ce compte Google à votre numéro de téléphone camerounais ou à votre compte enseignant.',
            onTap: () => context.push(AppRoutes.accountLinking),
          ),
          const SizedBox(height: 14),

          // Choice 3: Join school with invitation code
          _LandingChoiceCard(
            key: const ValueKey('google-choice-join-school'),
            icon: Icons.school_rounded,
            accent: const Color(0xFF5444D8),
            title: 'Rejoindre mon école',
            description:
                'Utilisez le code d’accès fourni par votre établissement ou le code de liaison parent.',
            onTap: () => context.push(AppRoutes.studentAccessCode),
          ),
          const SizedBox(height: 14),

          // Choice 4: Register new profile
          _LandingChoiceCard(
            key: const ValueKey('google-choice-register'),
            icon: Icons.person_add_alt_1_rounded,
            accent: const Color(0xFF32694C),
            title: 'Créer un nouveau profil',
            description:
                'Configurez un profil élève ou parent autonome sur INTELLIA237.',
            onTap: () => context.push(AppRoutes.register),
          ),
          const SizedBox(height: 20),

          // Disconnect Google account and return to gateway
          Center(
            child: TextButton.icon(
              key: const ValueKey('google-signout-action'),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  context.go(AppRoutes.authGateway);
                }
              },
              icon: const Icon(
                Icons.logout_rounded,
                size: 16,
                color: AuthExperienceColors.textTertiary,
              ),
              label: const Text(
                'Utiliser un autre compte',
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

class _LandingChoiceCard extends StatelessWidget {
  const _LandingChoiceCard({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AuthExperienceColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AuthExperienceColors.border.withValues(alpha: 0.8),
              width: 1.2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AuthExperienceColors.textPrimary,
                      ),
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
              const Icon(
                Icons.chevron_right_rounded,
                color: AuthExperienceColors.textTertiary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
