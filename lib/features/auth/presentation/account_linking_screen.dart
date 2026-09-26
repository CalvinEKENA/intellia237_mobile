import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/localization/localization_extensions.dart';
import '../application/auth_controller.dart';
import '../application/google_access_coordinator.dart';
import '../application/phone_auth_controller.dart';
import '../domain/google_access.dart';
import '../domain/repositories/auth_repository.dart';
import 'auth_error_copy.dart';
import 'widgets/auth_controls.dart';
import 'widgets/auth_experience_scaffold.dart';
import 'widgets/intellia_237_membrane.dart';
import 'widgets/living_pass.dart';

enum _RecoveryMode { phone, email }

/// Issue d'un rattachement qui ne s'est pas fait : le compte existant est
/// prouvé, mais Google n'y est pas ajouté.
enum _LinkStop { linkedElsewhere, providerTaken, failed }

/// « Oui, retrouver mon compte » : la personne se connecte RÉELLEMENT à son
/// compte existant, puis la preuve Google en attente est rattachée à cet UID.
///
/// Registre de décisions (refonte Auth V2, P0-3 de la revue de 7ea5cf0) :
/// l'ancien écran rattachait le téléphone ou l'e-mail à la session Google — le
/// mauvais sens —, et `EmailAuthProvider.credential` + `linkWithCredential`
/// créait un mot de passe au lieu de prouver un compte. Ici :
/// - téléphone : vérification SMS par le contrôleur partagé (numéro normalisé
///   par `CameroonPhoneNumber`), qui ouvre la session du compte existant ;
/// - e-mail : `signInWithEmailAndPassword`, une vraie connexion ;
/// - puis le coordinateur rattache Google à CET UID et vérifie qu'il est
///   inchangé ;
/// - Google déjà porté par un autre compte : arrêt, rien n'est fusionné.
/// Aucune session n'est adoptée — donc aucun espace ouvert — avant la fin.
class AccountLinkingScreen extends ConsumerStatefulWidget {
  const AccountLinkingScreen({this.emailInUse = false, super.key});

  /// Firebase a signalé qu'un compte utilise déjà l'adresse du compte Google.
  final bool emailInUse;

  @override
  ConsumerState<AccountLinkingScreen> createState() =>
      _AccountLinkingScreenState();
}

class _AccountLinkingScreenState extends ConsumerState<AccountLinkingScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late _RecoveryMode _mode = widget.emailInUse
      ? _RecoveryMode.email
      : _RecoveryMode.phone;
  bool _busy = false;
  String? _errorCode;
  String? _message;
  _LinkStop? _stop;

  /// UID du compte existant, prouvé à l'instant et pas encore adopté.
  String? _provenUid;

  static const _phoneProvider = false;

  @override
  void initState() {
    super.initState();
    final email = ref.read(googleAccessCoordinatorProvider).pendingEmail;
    if (widget.emailInUse && email != null) _emailController.text = email;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setMode(_RecoveryMode mode) {
    if (_busy || _provenUid != null) return;
    setState(() {
      _mode = mode;
      _errorCode = null;
      _message = null;
    });
  }

  Future<void> _signInWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorCode = 'missing-fields');
      return;
    }
    setState(() {
      _busy = true;
      _errorCode = null;
      _message = null;
    });
    final identity = ref.read(firebaseIdentityPortProvider);
    try {
      final uid = await ref
          .read(authControllerProvider.notifier)
          .holdSessionAdoption(
            () => identity.signInWithEmailPassword(email, password),
          );
      await _linkToExistingAccount(uid);
    } on IdentityFailure catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _errorCode = error.code;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _errorCode = 'unknown';
        });
      }
    }
  }

  /// Le SMS a ouvert une session. Un numéro inconnu vient de créer une
  /// identité vide : elle est supprimée aussitôt, rien d'autre n'existe.
  Future<void> _onPhoneVerified(PhoneAuthState phone) async {
    final session = phone.session;
    if (session == null || _busy) return;
    setState(() {
      _busy = true;
      _errorCode = null;
      _message = null;
    });
    if (session.isNewUser) {
      final cleaned = await ref
          .read(googleAccessCoordinatorProvider)
          .discardFreshIdentity();
      if (!mounted) return;
      final l10n = context.l10n;
      _codeController.clear();
      ref
          .read(phoneAuthControllerProvider(_phoneProvider).notifier)
          .restartWithAnotherNumber();
      setState(() {
        _busy = false;
        _message = cleaned
            ? l10n.authRecoveryNoAccountForPhone
            : l10n.authRecoveryCleanupFailed;
      });
      return;
    }
    await _linkToExistingAccount(session.uid);
  }

  Future<void> _linkToExistingAccount(String uid) async {
    final auth = ref.read(authControllerProvider.notifier);
    final repository = ref.read(authRepositoryProvider);
    if (repository is AuthSessionResolver) {
      final resolution = await (repository as AuthSessionResolver)
          .resolveCurrentSession()
          .catchError(
            (Object _) => const AuthSessionResolution(
              kind: AuthSessionResolutionKind.retryableProfileFailure,
            ),
          );
      if (!mounted) return;
      final noProfile =
          resolution.kind == AuthSessionResolutionKind.needsOnboarding &&
          resolution.user == null;
      if (noProfile ||
          resolution.kind == AuthSessionResolutionKind.unauthenticated) {
        final l10n = context.l10n;
        await auth.holdSessionAdoption(
          () => ref.read(firebaseIdentityPortProvider).signOut(),
        );
        if (!mounted) return;
        setState(() {
          _busy = false;
          _message = resolution.errorCode == 'user-disabled'
              ? l10n.authErrorUserDisabled
              : l10n.authRecoveryNoProfile;
        });
        _resetPhone();
        return;
      }
    }

    final outcome = await auth.holdSessionAdoption(
      () => ref.read(googleAccessCoordinatorProvider).linkPendingTo(uid),
    );
    if (!mounted) return;
    switch (outcome) {
      case GoogleLinked():
        // Même UID, Google en plus : l'espace existant s'ouvre.
        await auth.adoptCurrentFirebaseSession();
        return;
      case GoogleLinkedElsewhere():
        _stopWith(uid, _LinkStop.linkedElsewhere);
      case GoogleLinkProviderTaken():
        _stopWith(uid, _LinkStop.providerTaken);
      case GoogleLinkFailed(:final code):
        _stopWith(uid, _LinkStop.failed, code: code);
    }
  }

  void _stopWith(String uid, _LinkStop stop, {String? code}) {
    setState(() {
      _busy = false;
      _provenUid = uid;
      _stop = stop;
      _errorCode = code;
    });
  }

  void _resetPhone() {
    _codeController.clear();
    ref
        .read(phoneAuthControllerProvider(_phoneProvider).notifier)
        .restartWithAnotherNumber();
  }

  Future<void> _openWithoutGoogle() async {
    setState(() => _busy = true);
    await ref
        .read(authControllerProvider.notifier)
        .adoptCurrentFirebaseSession();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _cancel() async {
    setState(() => _busy = true);
    if (_provenUid != null) {
      // Le compte existant a été prouvé mais n'est pas ouvert : sa session se
      // referme, et le compte Google choisi est oublié.
      await ref.read(authControllerProvider.notifier).signOut();
    } else {
      await ref.read(googleAccessCoordinatorProvider).abandon();
    }
    if (mounted) context.go(AppRoutes.authGateway);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final coordinator = ref.watch(googleAccessCoordinatorProvider);
    final phoneProvider = phoneAuthControllerProvider(_phoneProvider);
    final phone = ref.watch(phoneProvider);
    ref.listen<PhoneAuthState>(phoneProvider, (previous, next) {
      if (next.stage == PhoneAuthStage.success &&
          previous?.stage != PhoneAuthStage.success) {
        _onPhoneVerified(next);
      }
    });
    final expired =
        !coordinator.hasPendingProof && _provenUid == null && !_busy;
    final email = coordinator.pendingEmail;
    final errorCode = _errorCode ?? phone.errorCode;

    return AuthExperienceScaffold(
      showBackButton: _provenUid == null,
      onBack: _busy ? null : () => context.pop(),
      pass: LivingPass(
        seal: PassSealStage.neutral,
        phase: l10n.authRecoveryEyebrow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            showBrand: false,
            eyebrow: l10n.authRecoveryEyebrow,
            title: l10n.authRecoveryTitle,
            subtitle: expired
                ? l10n.authGoogleStepExpired
                : l10n.authRecoveryBody,
          ),
          const SizedBox(height: 18),
          if (expired)
            AuthPrimaryButton(
              key: const ValueKey('recovery-restart'),
              label: l10n.authBackToGateway,
              icon: Icons.arrow_back_rounded,
              onTap: () => context.go(AppRoutes.authGateway),
            )
          else if (_stop != null)
            _StopPanel(
              stop: _stop!,
              errorCode: errorCode,
              busy: _busy,
              onOpenWithoutGoogle: _openWithoutGoogle,
              onCancel: _cancel,
            )
          else ...[
            if (widget.emailInUse && email != null && email.isNotEmpty) ...[
              Text(
                l10n.authRecoveryEmailInUse(email),
                key: const ValueKey('recovery-email-in-use'),
                style: const TextStyle(
                  fontFamily: 'CampaignBody',
                  fontSize: 13,
                  height: 1.45,
                  color: AuthExperienceColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
            ],
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  key: const ValueKey('recovery-mode-phone'),
                  label: Text(l10n.authRecoveryByPhone),
                  avatar: const Icon(Icons.phone_android_rounded, size: 18),
                  selected: _mode == _RecoveryMode.phone,
                  onSelected: (_) => _setMode(_RecoveryMode.phone),
                ),
                ChoiceChip(
                  key: const ValueKey('recovery-mode-email'),
                  label: Text(l10n.authRecoveryByEmail),
                  avatar: const Icon(Icons.mail_outline_rounded, size: 18),
                  selected: _mode == _RecoveryMode.email,
                  onSelected: (_) => _setMode(_RecoveryMode.email),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_mode == _RecoveryMode.phone)
              _PhoneRecovery(
                phone: phone,
                phoneController: _phoneController,
                codeController: _codeController,
                busy: _busy,
                onSend: () => ref
                    .read(phoneProvider.notifier)
                    .sendCode(_phoneController.text),
                onVerify: () => ref
                    .read(phoneProvider.notifier)
                    .confirmCode(_codeController.text),
                onResend: () => ref.read(phoneProvider.notifier).resendCode(),
                onChangeNumber: () {
                  _codeController.clear();
                  ref.read(phoneProvider.notifier).changePhoneNumber();
                },
              )
            else
              _EmailRecovery(
                emailController: _emailController,
                passwordController: _passwordController,
                busy: _busy,
                onSubmit: _signInWithEmail,
              ),
            if (_busy && _provenUid == null) ...[
              const SizedBox(height: 14),
              Text(
                l10n.authRecoveryLinking,
                key: const ValueKey('recovery-linking'),
                style: const TextStyle(
                  fontFamily: 'CampaignBody',
                  fontSize: 12.5,
                  color: AuthExperienceColors.textSecondary,
                ),
              ),
            ],
            if (_message != null) ...[
              const SizedBox(height: 14),
              AuthErrorBanner(
                key: const ValueKey('recovery-message'),
                message: _message!,
                onDismiss: () => setState(() => _message = null),
              ),
            ],
            if (errorCode != null && !isAuthCancellation(errorCode)) ...[
              const SizedBox(height: 14),
              AuthErrorBanner(
                key: const ValueKey('recovery-error'),
                message: authErrorMessage(l10n, errorCode),
                onDismiss: () {
                  setState(() => _errorCode = null);
                  ref.read(phoneProvider.notifier).clearError();
                },
              ),
            ],
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                key: const ValueKey('recovery-cancel'),
                onPressed: _busy ? null : _cancel,
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: Text(
                  l10n.authRecoveryCancel,
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

class _PhoneRecovery extends StatelessWidget {
  const _PhoneRecovery({
    required this.phone,
    required this.phoneController,
    required this.codeController,
    required this.busy,
    required this.onSend,
    required this.onVerify,
    required this.onResend,
    required this.onChangeNumber,
  });

  final PhoneAuthState phone;
  final TextEditingController phoneController;
  final TextEditingController codeController;
  final bool busy;
  final VoidCallback onSend;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final VoidCallback onChangeNumber;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final working = busy || phone.isLoading;
    if (phone.stage == PhoneAuthStage.phoneEntry) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const ValueKey('recovery-phone-field'),
            controller: phoneController,
            enabled: !working,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
            ],
            decoration: InputDecoration(
              labelText: l10n.authRecoveryPhoneLabel,
              hintText: l10n.authRecoveryPhoneHint,
              prefixText: '+237 ',
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => working ? null : onSend(),
          ),
          const SizedBox(height: 14),
          AuthPrimaryButton(
            key: const ValueKey('recovery-send-code'),
            label: l10n.authRecoverySendCode,
            icon: Icons.sms_outlined,
            isLoading: working,
            onTap: phone.cooldownSeconds > 0 ? null : onSend,
          ),
          if (phone.cooldownSeconds > 0) ...[
            const SizedBox(height: 8),
            Text(l10n.authRecoveryResendIn(phone.cooldownSeconds)),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.authRecoveryCodeSentTo(phone.phoneNumber),
          style: const TextStyle(
            fontFamily: 'CampaignBody',
            fontSize: 13,
            color: AuthExperienceColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('recovery-otp-field'),
          controller: codeController,
          enabled: !working,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: l10n.authRecoveryCodeLabel,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => working ? null : onVerify(),
        ),
        const SizedBox(height: 8),
        AuthPrimaryButton(
          key: const ValueKey('recovery-verify-code'),
          label: l10n.authRecoveryVerifyCode,
          icon: Icons.verified_user_outlined,
          isLoading: working,
          onTap: onVerify,
        ),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          children: [
            TextButton(
              key: const ValueKey('recovery-change-number'),
              onPressed: working ? null : onChangeNumber,
              child: Text(l10n.authRecoveryChangeNumber),
            ),
            TextButton(
              key: const ValueKey('recovery-resend'),
              onPressed: working || phone.cooldownSeconds > 0 ? null : onResend,
              child: Text(
                phone.cooldownSeconds > 0
                    ? l10n.authRecoveryResendIn(phone.cooldownSeconds)
                    : l10n.authRecoveryResend,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmailRecovery extends StatelessWidget {
  const _EmailRecovery({
    required this.emailController,
    required this.passwordController,
    required this.busy,
    required this.onSubmit,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool busy;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const ValueKey('recovery-email-field'),
            controller: emailController,
            enabled: !busy,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
              labelText: l10n.authRecoveryEmailLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('recovery-password-field'),
            controller: passwordController,
            enabled: !busy,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: l10n.authRecoveryPasswordLabel,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => busy ? null : onSubmit(),
          ),
          const SizedBox(height: 14),
          AuthPrimaryButton(
            key: const ValueKey('recovery-email-submit'),
            label: l10n.authRecoverySignIn,
            icon: Icons.login_rounded,
            isLoading: busy,
            onTap: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _StopPanel extends StatelessWidget {
  const _StopPanel({
    required this.stop,
    required this.errorCode,
    required this.busy,
    required this.onOpenWithoutGoogle,
    required this.onCancel,
  });

  final _LinkStop stop;
  final String? errorCode;
  final bool busy;
  final VoidCallback onOpenWithoutGoogle;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (title, help) = switch (stop) {
      _LinkStop.linkedElsewhere => (
        l10n.authRecoveryLinkedElsewhere,
        l10n.authRecoveryLinkedElsewhereHelp,
      ),
      _LinkStop.providerTaken => (
        l10n.authRecoveryProviderTaken,
        l10n.authRecoveryProviderTakenHelp,
      ),
      _LinkStop.failed => (authErrorMessage(l10n, errorCode ?? 'unknown'), ''),
    };
    return Column(
      key: ValueKey('recovery-stop-${stop.name}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthGlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'CampaignBody',
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                  color: AuthExperienceColors.textPrimary,
                ),
              ),
              if (help.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  help,
                  style: const TextStyle(
                    fontFamily: 'CampaignBody',
                    fontSize: 13,
                    height: 1.45,
                    color: AuthExperienceColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        AuthPrimaryButton(
          key: const ValueKey('recovery-open-without-google'),
          label: l10n.authRecoveryOpenWithoutGoogle,
          isLoading: busy,
          onTap: onOpenWithoutGoogle,
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            key: const ValueKey('recovery-stop-cancel'),
            onPressed: busy ? null : onCancel,
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text(l10n.authRecoveryCancel, textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }
}
