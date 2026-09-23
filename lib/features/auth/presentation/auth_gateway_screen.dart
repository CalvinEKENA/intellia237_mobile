import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../parent/application/pending_child_link.dart';
import '../application/auth_controller.dart';
import '../application/google_access_coordinator.dart';
import '../domain/google_access.dart';
import 'auth_error_copy.dart';
import 'widgets/auth_controls.dart';
import 'widgets/auth_experience_scaffold.dart';
import 'widgets/google_sign_in_button.dart';
import 'widgets/intellia_237_membrane.dart';
import 'widgets/living_pass.dart';
import 'widgets/school_head_access.dart';

/// Porte d'entrée neutre, dès le premier lancement.
///
/// L'identité d'abord, l'espace ensuite : aucune carte de rôle ici.
/// 1. « Continuer avec mon numéro » (+237) ;
/// 2. « Continuer avec Google » ;
/// 3. « J'ai un code élève » (élève sans téléphone) ;
/// 4. accès discret du personnel scolaire.
///
/// Registre de décisions (refonte Auth V2, P1-1 de la revue de 7ea5cf0) : la
/// redirection menait un nouvel appareil vers l'ancien écran à cartes de
/// rôle ; cette porte n'apparaissait qu'après une première connexion.
class AuthGatewayScreen extends ConsumerStatefulWidget {
  const AuthGatewayScreen({super.key});

  @override
  ConsumerState<AuthGatewayScreen> createState() => _AuthGatewayScreenState();
}

class _AuthGatewayScreenState extends ConsumerState<AuthGatewayScreen> {
  bool _googleBusy = false;
  String? _errorCode;

  /// Registre de décisions (P0-1) : un succès Google appelait
  /// `completeBootstrap`, sans effet après le démarrage ; l'écran restait
  /// figé. La session établie par le coordinateur est désormais adoptée par
  /// une commande explicite, puis le routeur ouvre l'espace.
  Future<void> _continueWithGoogle() async {
    setState(() {
      _googleBusy = true;
      _errorCode = null;
    });
    final auth = ref.read(authControllerProvider.notifier);
    final coordinator = ref.read(googleAccessCoordinatorProvider);
    final outcome = await auth.holdSessionAdoption(coordinator.begin);
    if (!mounted) return;
    switch (outcome) {
      case GoogleAccessSignedIn(:final isNewIdentity):
        await auth.openGoogleSession(isNewIdentity: isNewIdentity);
      case GoogleAccessNeedsDecision():
        context.push(AppRoutes.googleAccountQuestion);
      case GoogleAccessRecoveryRequired():
        context.push(AppRoutes.accountRecovery(emailInUse: true));
      case GoogleAccessCancelled():
        break;
      case GoogleAccessFailed(:final code):
        if (!isAuthCancellation(code)) setState(() => _errorCode = code);
    }
    if (mounted) setState(() => _googleBusy = false);
  }

  void _open(String route) {
    ref.read(pendingChildLinkProvider.notifier).clear();
    setState(() => _errorCode = null);
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final suspended = ref.watch(
      authControllerProvider.select((auth) => auth.suspended),
    );
    final errorCode = _errorCode;

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
                padding: const EdgeInsets.only(top: 12, right: 48),
                child: AuthHeader(
                  showBrand: false,
                  eyebrow: 'INTELLIA237',
                  title: l10n.authGatewayTitle,
                  subtitle: l10n.authGatewaySubtitle,
                ),
              ),
              const Positioned(top: 0, right: 0, child: SchoolHeadShield()),
            ],
          ),
          if (suspended) ...[
            const SizedBox(height: 16),
            AuthErrorBanner(
              key: const ValueKey('gateway-suspended'),
              message: l10n.authAccountSuspended,
            ),
          ],
          const SizedBox(height: 28),
          Semantics(
            button: true,
            label: l10n.authGatewayPhoneSemantics,
            excludeSemantics: true,
            child: FilledButton(
              key: const ValueKey('gateway-phone-auth'),
              onPressed: _googleBusy ? null : () => _open(AppRoutes.phoneAuth),
              style: FilledButton.styleFrom(
                backgroundColor: AuthExperienceColors.indigo,
                foregroundColor: AuthExperienceColors.surface,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone_android_rounded, size: 22),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      l10n.authGatewayPhone,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'CampaignBody',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const _CountryTag(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          GoogleSignInButton(
            key: const ValueKey('gateway-google-auth'),
            isLoading: _googleBusy,
            onPressed: _continueWithGoogle,
          ),
          if (errorCode != null) ...[
            const SizedBox(height: 14),
            AuthErrorBanner(
              key: const ValueKey('gateway-google-error'),
              message: authErrorMessage(l10n, errorCode),
              onDismiss: () => setState(() => _errorCode = null),
            ),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(
                child: Divider(color: AuthExperienceColors.border),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.authGatewayOr,
                  style: const TextStyle(
                    fontFamily: 'CampaignBody',
                    fontSize: 13,
                    color: AuthExperienceColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Expanded(
                child: Divider(color: AuthExperienceColors.border),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Semantics(
            button: true,
            label: l10n.authGatewayStudentCodeSemantics,
            excludeSemantics: true,
            child: OutlinedButton(
              key: const ValueKey('gateway-student-access-code'),
              onPressed: _googleBusy
                  ? null
                  : () => _open(AppRoutes.studentAccessCode),
              style: OutlinedButton.styleFrom(
                backgroundColor: AuthExperienceColors.surface,
                foregroundColor: AuthExperienceColors.textPrimary,
                side: const BorderSide(
                  color: AuthExperienceColors.gold,
                  width: 1.5,
                ),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.key_rounded,
                    size: 20,
                    color: AuthExperienceColors.gold,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      l10n.authGatewayStudentCode,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'CampaignBody',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: TextButton.icon(
              key: const ValueKey('gateway-staff-login'),
              onPressed: _googleBusy ? null : () => _open(AppRoutes.emailLogin),
              icon: const Icon(
                Icons.mail_outline_rounded,
                size: 16,
                color: AuthExperienceColors.textSecondary,
              ),
              label: Text(
                l10n.authGatewayStaff,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'CampaignBody',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AuthExperienceColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              _LegalLink(
                label: l10n.authGatewayTerms,
                onTap: () => context.push(AppRoutes.legalTerms),
              ),
              const Text(
                '•',
                style: TextStyle(color: AuthExperienceColors.textTertiary),
              ),
              _LegalLink(
                label: l10n.authGatewayPrivacy,
                onTap: () => context.push(AppRoutes.legalPrivacy),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountryTag extends StatelessWidget {
  const _CountryTag();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: AuthExperienceColors.surface.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Text(
      '+237',
      style: TextStyle(
        fontFamily: 'CampaignBody',
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AuthExperienceColors.surface,
      ),
    ),
  );
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontFamily: 'CampaignBody',
        fontSize: 11.5,
        color: AuthExperienceColors.textSecondary,
        decoration: TextDecoration.underline,
      ),
    ),
  );
}
