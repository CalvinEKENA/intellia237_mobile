import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../parent/application/pending_child_link.dart';
import '../application/auth_controller.dart';
import '../data/services/google_auth_service.dart';
import 'widgets/auth_experience_scaffold.dart';
import 'widgets/google_sign_in_button.dart';
import 'widgets/intellia_237_membrane.dart';
import 'widgets/living_pass.dart';
import 'widgets/school_head_access.dart';

/// Neutral authentication gateway for Intellia237.
///
/// Follows the core architectural invariant:
/// IDENTITY FIRST, ROLE RESOLUTION SECOND.
///
/// Role cards are intentionally absent from this screen to prevent confusion
/// on shared devices and preserve universal entry:
/// 1. Primary: [ Continuer avec mon numéro ] (+237 Cameroon phone auth)
/// 2. Primary: [ Continuer avec Google ] (Official Google branding)
/// 3. Secondary: [ J'ai un code élève ] (Code-based entry for phone-less learners)
/// 4. Fallback: Staff / teacher email login.
class AuthGatewayScreen extends ConsumerStatefulWidget {
  const AuthGatewayScreen({super.key});

  @override
  ConsumerState<AuthGatewayScreen> createState() => _AuthGatewayScreenState();
}

class _AuthGatewayScreenState extends ConsumerState<AuthGatewayScreen> {
  bool _isGoogleLoading = false;

  Future<void> _handleGoogleSignIn() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isGoogleLoading = true);
    try {
      final result = await ref.read(googleAuthGatewayProvider).signIn();
      if (!mounted) return;

      switch (result) {
        case GoogleAuthSuccess():
          await ref.read(authControllerProvider.notifier).completeBootstrap();
        case GoogleAuthNewUser():
          context.push(AppRoutes.googleDiscoveryWelcome);
        case GoogleAuthCollision():
          context.push(AppRoutes.accountLinking);
        case GoogleAuthCancelled():
          // User dismissed dialog; stay silently on screen
          break;
        case GoogleAuthFailure(:final message):
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AuthExperienceColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AuthExperienceScaffold(
      showBackButton: false,
      pass: LivingPass(
        seal: PassSealStage.neutral,
        phase: l10n.passWelcomeBack,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: AuthHeader(
                  showBrand: false,
                  eyebrow: 'INTELLIA237',
                  title: 'Bienvenue sur INTELLIA237',
                  subtitle: 'Votre espace éducatif sécurisé au Cameroun',
                ),
              ),
              const Positioned(top: 0, right: 0, child: SchoolHeadShield()),
            ],
          ),
          const SizedBox(height: 28),

          // Primary action 1: Cameroon phone auth
          Semantics(
            button: true,
            label: 'Continuer avec mon numéro de téléphone Cameroun',
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                key: const ValueKey('gateway-phone-auth'),
                onPressed: _isGoogleLoading
                    ? null
                    : () {
                        ref.read(pendingChildLinkProvider.notifier).clear();
                        context.push(AppRoutes.phoneAuth);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003366),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.phone_android_rounded,
                      size: 22,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Continuer avec mon numéro',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '🇨🇲 +237',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Primary action 2: Google Sign-In button
          GoogleSignInButton(
            key: const ValueKey('gateway-google-auth'),
            isLoading: _isGoogleLoading,
            onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
          ),
          const SizedBox(height: 22),

          // Subtle divider
          Row(
            children: [
              const Expanded(
                child: Divider(
                  color: AuthExperienceColors.border,
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'ou',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    color: AuthExperienceColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Expanded(
                child: Divider(
                  color: AuthExperienceColors.border,
                  thickness: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Secondary action: Student Access Code for phone-less learners
          Semantics(
            button: true,
            label: 'J’ai un code élève, connexion sans téléphone ni e-mail',
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                key: const ValueKey('gateway-student-access-code'),
                onPressed: _isGoogleLoading
                    ? null
                    : () {
                        ref.read(pendingChildLinkProvider.notifier).clear();
                        context.push(AppRoutes.studentAccessCode);
                      },
                style: OutlinedButton.styleFrom(
                  backgroundColor: AuthExperienceColors.surface,
                  foregroundColor: AuthExperienceColors.textPrimary,
                  side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.key_rounded,
                      size: 20,
                      color: Color(0xFF80643D),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'J’ai un code élève',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AuthExperienceColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Fallback: School staff / teacher login
          Center(
            child: TextButton(
              key: const ValueKey('gateway-staff-login'),
              onPressed: _isGoogleLoading
                  ? null
                  : () => context.push(AppRoutes.emailLogin),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.mail_outline_rounded,
                    size: 16,
                    color: AuthExperienceColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Personnel scolaire, enseignant ou direction ?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AuthExperienceColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Legal links
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              TextButton(
                onPressed: () => context.push(AppRoutes.legalTerms),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                child: const Text(
                  'Conditions d’utilisation',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    color: AuthExperienceColors.textTertiary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const Text(
                '•',
                style: TextStyle(
                  fontSize: 11,
                  color: AuthExperienceColors.textTertiary,
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.legalPrivacy),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                child: const Text(
                  'Confidentialité',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    color: AuthExperienceColors.textTertiary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
