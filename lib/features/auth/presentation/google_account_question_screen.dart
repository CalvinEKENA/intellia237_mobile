import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/localization/localization_extensions.dart';
import '../application/auth_controller.dart';
import '../application/google_access_coordinator.dart';
import '../domain/google_access.dart';
import 'auth_error_copy.dart';
import 'widgets/auth_controls.dart';
import 'widgets/auth_experience_scaffold.dart';
import 'widgets/intellia_237_membrane.dart';
import 'widgets/living_pass.dart';

/// « Vous utilisez déjà INTELLIA237 ? » — pour un compte Google qui n'ouvre
/// encore aucun compte.
///
/// Aucune identité Firebase n'existe tant que la personne n'a pas répondu
/// (P0-2 de la revue de 7ea5cf0) :
/// - « Oui, retrouver mon compte » : connexion réelle au compte existant, puis
///   rattachement de Google à cet UID ;
/// - « Non, continuer » : une nouvelle identité est créée, par ce choix
///   explicite, et entre dans la découverte.
class GoogleAccountQuestionScreen extends ConsumerStatefulWidget {
  const GoogleAccountQuestionScreen({super.key});

  @override
  ConsumerState<GoogleAccountQuestionScreen> createState() =>
      _GoogleAccountQuestionScreenState();
}

class _GoogleAccountQuestionScreenState
    extends ConsumerState<GoogleAccountQuestionScreen> {
  bool _busy = false;
  String? _errorCode;

  Future<void> _continueAsNew() async {
    setState(() {
      _busy = true;
      _errorCode = null;
    });
    final auth = ref.read(authControllerProvider.notifier);
    final coordinator = ref.read(googleAccessCoordinatorProvider);
    final outcome = await auth.holdSessionAdoption(
      coordinator.continueAsNewIdentity,
    );
    if (!mounted) return;
    switch (outcome) {
      case GoogleAccessSignedIn(:final isNewIdentity):
        // Le routeur ouvre la découverte, ou l'espace si Firebase a rattaché
        // ce compte Google à un compte existant.
        await auth.openGoogleSession(isNewIdentity: isNewIdentity);
        return;
      case GoogleAccessRecoveryRequired():
        context.pushReplacement(AppRoutes.accountRecovery(emailInUse: true));
        return;
      case GoogleAccessFailed(:final code):
        if (!isAuthCancellation(code)) _errorCode = code;
      case GoogleAccessNeedsDecision() || GoogleAccessCancelled():
        break;
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _useAnotherAccount() async {
    await ref.read(googleAccessCoordinatorProvider).abandon();
    if (mounted) context.go(AppRoutes.authGateway);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final coordinator = ref.watch(googleAccessCoordinatorProvider);
    final email = coordinator.pendingEmail;
    final expired = !coordinator.hasPendingProof && !_busy;
    final errorCode = _errorCode;

    return AuthExperienceScaffold(
      showBackButton: true,
      onBack: _busy ? null : _useAnotherAccount,
      pass: LivingPass(
        seal: PassSealStage.neutral,
        phase: l10n.authGoogleQuestionEyebrow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            showBrand: false,
            eyebrow: l10n.authGoogleQuestionEyebrow,
            title: l10n.authGoogleQuestionTitle,
            subtitle: expired
                ? l10n.authGoogleStepExpired
                : l10n.authGoogleQuestionBody,
          ),
          if (email != null && email.isNotEmpty && !expired) ...[
            const SizedBox(height: 14),
            Text(
              l10n.authGoogleQuestionAccount(email),
              key: const ValueKey('google-question-account'),
              style: const TextStyle(
                fontFamily: 'CampaignBody',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AuthExperienceColors.textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (expired)
            AuthPrimaryButton(
              key: const ValueKey('google-question-restart'),
              label: l10n.authBackToGateway,
              icon: Icons.arrow_back_rounded,
              onTap: () => context.go(AppRoutes.authGateway),
            )
          else ...[
            AuthPrimaryButton(
              key: const ValueKey('google-question-yes'),
              label: l10n.authGoogleQuestionYes,
              icon: Icons.manage_accounts_rounded,
              onTap: _busy
                  ? null
                  : () => context.push(AppRoutes.accountRecovery()),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const ValueKey('google-question-no'),
              onPressed: _busy ? null : _continueAsNew,
              style: OutlinedButton.styleFrom(
                foregroundColor: AuthExperienceColors.textPrimary,
                side: const BorderSide(color: AuthExperienceColors.border),
                minimumSize: const Size.fromHeight(56),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _busy
                  ? const SizedBox.square(
                      dimension: 19,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      l10n.authGoogleQuestionNo,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'CampaignBody',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.authGoogleQuestionNoHint,
              style: const TextStyle(
                fontFamily: 'CampaignBody',
                fontSize: 12,
                height: 1.45,
                color: AuthExperienceColors.textSecondary,
              ),
            ),
            if (errorCode != null) ...[
              const SizedBox(height: 14),
              AuthErrorBanner(
                key: const ValueKey('google-question-error'),
                message: authErrorMessage(l10n, errorCode),
                onDismiss: () => setState(() => _errorCode = null),
              ),
            ],
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                key: const ValueKey('google-question-other-account'),
                onPressed: _busy ? null : _useAnotherAccount,
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: Text(
                  l10n.authGoogleQuestionOtherAccount,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
