import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/localization/app_locale_controller.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/auth_controller.dart';
import '../application/auth_state.dart';
import '../application/phone_auth_controller.dart';
import '../domain/app_role.dart';
import '../domain/firebase_error_mapper.dart';
import 'widgets/auth_controls.dart';
import 'widgets/auth_experience_scaffold.dart';
import 'widgets/living_pass.dart';
import 'widgets/pass_otp_field.dart';

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({
    this.registrationRole,
    this.linkCurrentUser = false,
    super.key,
  });

  final AppRole? registrationRole;
  final bool linkCurrentUser;

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _codeFocus = FocusNode();
  bool _completionHandled = false;
  bool _profileChoiceRequired = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _phoneFocus.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = phoneAuthControllerProvider(widget.linkCurrentUser);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final l10n = context.l10n;
    final selectedLanguage = ref.watch(appLocaleProvider).languageCode;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    ref.listen<PhoneAuthState>(provider, (previous, next) {
      if (next.stage == PhoneAuthStage.codeEntry &&
          previous?.stage != PhoneAuthStage.codeEntry) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _codeFocus.requestFocus();
        });
      }
      if (next.stage == PhoneAuthStage.success &&
          previous?.stage != PhoneAuthStage.success &&
          !_completionHandled) {
        _completionHandled = true;
        unawaited(_finishAuthentication());
      }
    });

    return AuthExperienceScaffold(
      showBackButton: widget.linkCurrentUser || widget.registrationRole != null,
      topBar: Align(
        alignment: Alignment.centerRight,
        child: SegmentedButton<String>(
          key: const ValueKey('phone-auth-language-selector'),
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 'fr', label: Text('FR')),
            ButtonSegment(value: 'en', label: Text('EN')),
          ],
          selected: {selectedLanguage},
          onSelectionChanged: (selection) {
            unawaited(
              ref.read(appLocaleProvider.notifier).setLanguage(selection.first),
            );
          },
        ),
      ),
      pass: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _phoneController,
        builder: (context, value, _) => LivingPass(
          role: widget.registrationRole,
          detail: state.stage == PhoneAuthStage.phoneEntry
              ? (value.text.trim().isEmpty ? null : value.text.trim())
              : state.phoneNumber,
          phase: switch (state.stage) {
            PhoneAuthStage.phoneEntry => context.l10n.passYourNumber,
            PhoneAuthStage.codeEntry => context.l10n.passVerificationInProgress,
            PhoneAuthStage.success => context.l10n.passNumberVerified,
          },
          // Progression 0..1 : le numéro colore « 2 » (vert), la vérification
          // « 3 » (rouge), et la réussite « 7 » (jaune) + pulsation.
          progress: switch (state.stage) {
            PhoneAuthStage.phoneEntry =>
              (value.text.replaceAll(RegExp(r'\D'), '').length / 9).clamp(
                    0.0,
                    1.0,
                  ) *
                  0.33,
            PhoneAuthStage.codeEntry => .66,
            PhoneAuthStage.success => 1.0,
          },
          verified: state.stage == PhoneAuthStage.success,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            showBrand: false,
            eyebrow: widget.registrationRole == null
                ? context.l10n.passPhoneAccess
                : passRoleLabel(context, widget.registrationRole!),
            title: widget.linkCurrentUser
                ? l10n.phoneLinkTitle
                : state.stage == PhoneAuthStage.codeEntry
                ? context.l10n.passSixDigitsThenWeContinue
                : state.stage == PhoneAuthStage.success
                ? context.l10n.passYourNumberIsConfirmed
                : context.l10n.passYourNumberYourAccess,
            subtitle: widget.linkCurrentUser
                ? l10n.phoneLinkSubtitle
                : state.stage == PhoneAuthStage.codeEntry
                ? l10n.phoneCodeSubtitle(state.phoneNumber)
                : state.stage == PhoneAuthStage.success
                ? l10n.phoneVerificationSuccessBody
                : l10n.phoneAuthSubtitle,
          ),
          const SizedBox(height: 24),
          AuthGlassPanel(
            child: AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              child: switch (state.stage) {
                PhoneAuthStage.phoneEntry => _PhoneEntry(
                  key: const ValueKey('phone-entry-stage'),
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  isLoading: state.isLoading,
                  cooldownSeconds: state.cooldownSeconds,
                  onSubmit: () => controller.sendCode(_phoneController.text),
                ),
                PhoneAuthStage.codeEntry => _CodeEntry(
                  key: const ValueKey('phone-code-stage'),
                  controller: _codeController,
                  focusNode: _codeFocus,
                  state: state,
                  onSubmit: () {
                    if (ref.read(provider).stage != PhoneAuthStage.codeEntry ||
                        ref.read(provider).isLoading) {
                      return;
                    }
                    controller.confirmCode(_codeController.text);
                  },
                  onResend: controller.resendCode,
                  onChangePhone: () {
                    _completionHandled = false;
                    _codeController.clear();
                    controller.changePhoneNumber();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _phoneFocus.requestFocus();
                    });
                  },
                ),
                PhoneAuthStage.success => _PhoneSuccess(
                  key: const ValueKey('phone-success-stage'),
                  linking: widget.linkCurrentUser,
                  profileChoiceRequired: _profileChoiceRequired,
                  onCreateStudentProfile: () =>
                      context.go(AppRoutes.studentRegistration),
                  onCreateParentProfile: () =>
                      context.go(AppRoutes.parentRegistration),
                ),
              },
            ),
          ),
          if (state.errorCode != null) ...[
            const SizedBox(height: 14),
            AuthErrorBanner(
              key: ValueKey(state.errorCode),
              message:
                  '${_localizedPhoneError(l10n, state.errorCode!)}\n'
                  '${FirebaseErrorMapper.diagnosticId(state.errorCode)}',
              onDismiss: controller.clearError,
            ),
          ],
          if (!widget.linkCurrentUser && widget.registrationRole == null) ...[
            const SizedBox(height: 18),
            TextButton(
              onPressed: state.isLoading
                  ? null
                  : () => context.push(AppRoutes.emailLogin),
              child: Text(l10n.useEmailCompatibility),
            ),
            TextButton.icon(
              key: const ValueKey('phone-change-access'),
              onPressed: state.isLoading
                  ? null
                  : () => context.go(AppRoutes.authGateway),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: Text(context.l10n.passChooseAnotherWayIn),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _finishAuthentication() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    if (widget.linkCurrentUser) {
      context.pop(true);
      return;
    }

    final restored = await ref
        .read(authControllerProvider.notifier)
        .adoptCurrentFirebaseSession();
    if (!mounted) return;

    final auth = ref.read(authControllerProvider);
    final recoveredRole = auth.role;
    if (restored && recoveredRole != null && auth.profileCompleted) {
      context.go(recoveredRole.homePath);
      return;
    }
    if (auth.status == AuthStatus.retryableProfileFailure ||
        auth.status == AuthStatus.legacyProfileRecovery) {
      context.go(AppRoutes.authProfileRecovery);
      return;
    }
    // A real recovered role always wins over the entrance selected on a
    // shared device. An incomplete existing profile resumes its own setup.
    if (recoveredRole != null) {
      context.go(switch (recoveredRole) {
        AppRole.student => AppRoutes.studentRegistration,
        AppRole.parent => AppRoutes.parentRegistration,
        AppRole.teacher || AppRole.admin => AppRoutes.authProfileRecovery,
      });
      return;
    }

    final route = switch (widget.registrationRole) {
      AppRole.student => AppRoutes.studentRegistration,
      AppRole.parent => AppRoutes.parentRegistration,
      AppRole.teacher => AppRoutes.teacherRegistration,
      AppRole.admin || null => null,
    };
    if (route != null) {
      context.go(route);
    } else {
      setState(() => _profileChoiceRequired = true);
    }
  }
}

class _PhoneEntry extends StatelessWidget {
  const _PhoneEntry({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.cooldownSeconds,
    required this.onSubmit,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final int cooldownSeconds;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.phoneNumberLabel,
            style: const TextStyle(
              color: AuthExperienceColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                constraints: const BoxConstraints(minHeight: 58),
                padding: const EdgeInsets.symmetric(horizontal: 13),
                decoration: BoxDecoration(
                  color: AuthExperienceColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AuthExperienceColors.border),
                ),
                child: const Center(
                  child: Text(
                    '+237',
                    style: TextStyle(
                      color: AuthExperienceColors.indigo,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  key: const ValueKey('phone-number-field'),
                  controller: controller,
                  focusNode: focusNode,
                  enabled: !isLoading,
                  autofocus: false,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ()-]')),
                    LengthLimitingTextInputFormatter(20),
                  ],
                  onFieldSubmitted: (_) {
                    if (!isLoading && cooldownSeconds == 0) onSubmit();
                  },
                  style: const TextStyle(
                    fontFamily: 'CampaignBody',
                    color: AuthExperienceColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.phoneNumberLocalHint,
                    filled: true,
                    fillColor: AuthExperienceColors.surface,
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 17,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AuthExperienceColors.border,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          AuthPrimaryButton(
            key: const ValueKey('send-phone-code'),
            label: cooldownSeconds > 0
                ? l10n.phoneRequestPause(cooldownSeconds)
                : l10n.sendVerificationCode,
            onTap: isLoading || cooldownSeconds > 0 ? null : onSubmit,
            isLoading: isLoading,
            icon: Icons.sms_outlined,
          ),
        ],
      ),
    );
  }
}

class _CodeEntry extends StatelessWidget {
  const _CodeEntry({
    required this.controller,
    required this.focusNode,
    required this.state,
    required this.onSubmit,
    required this.onResend,
    required this.onChangePhone,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final PhoneAuthState state;
  final VoidCallback onSubmit;
  final VoidCallback onResend;
  final VoidCallback onChangePhone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PassOtpField(
            fieldKey: const ValueKey('phone-otp-field'),
            controller: controller,
            focusNode: focusNode,
            enabled: !state.isLoading,
            label: l10n.verificationCodeLabel,
            onSubmit: onSubmit,
          ),
          if (state.autoRetrievalTimedOut) ...[
            const SizedBox(height: 10),
            Text(
              l10n.smsAutoRetrievalTimeout,
              style: const TextStyle(
                color: AuthExperienceColors.textSecondary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 18),
          AuthPrimaryButton(
            key: const ValueKey('verify-phone-code'),
            label: l10n.verifyCode,
            onTap: state.isLoading ? null : onSubmit,
            isLoading: state.isLoading,
            icon: Icons.verified_user_outlined,
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              TextButton(
                onPressed: state.isLoading ? null : onChangePhone,
                child: Text(l10n.changePhoneNumber),
              ),
              TextButton(
                onPressed: state.cooldownSeconds == 0 && !state.isLoading
                    ? onResend
                    : null,
                child: Text(
                  state.cooldownSeconds == 0
                      ? l10n.resendCode
                      : l10n.resendCodeIn(state.cooldownSeconds),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhoneSuccess extends StatelessWidget {
  const _PhoneSuccess({
    required this.linking,
    required this.profileChoiceRequired,
    required this.onCreateStudentProfile,
    required this.onCreateParentProfile,
    super.key,
  });

  final bool linking;
  final bool profileChoiceRequired;
  final VoidCallback onCreateStudentProfile;
  final VoidCallback onCreateParentProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      liveRegion: true,
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AuthExperienceColors.success,
            size: 54,
          ),
          const SizedBox(height: 14),
          Text(
            l10n.phoneVerificationSuccess,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AuthExperienceColors.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            linking
                ? l10n.phoneLinkSuccessBody
                : l10n.phoneVerificationSuccessBody,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AuthExperienceColors.textSecondary,
              height: 1.45,
            ),
          ),
          if (profileChoiceRequired) ...[
            const SizedBox(height: 20),
            Text(
              l10n.phoneProfileChoicePrompt,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AuthExperienceColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            AuthPrimaryButton(
              key: const ValueKey('create-student-profile-after-otp'),
              label: l10n.phoneCreateStudentProfile,
              icon: Icons.school_rounded,
              onTap: onCreateStudentProfile,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const ValueKey('create-parent-profile-after-otp'),
              onPressed: onCreateParentProfile,
              icon: const Icon(Icons.family_restroom_rounded),
              label: Text(l10n.phoneCreateParentProfile),
            ),
          ],
        ],
      ),
    );
  }
}

String _localizedPhoneError(AppLocalizations l10n, String code) {
  return switch (code) {
    'invalid-phone-number' => l10n.phoneErrorInvalidNumber,
    'invalid-verification-code' ||
    'session-expired' ||
    'missing-verification-code' => l10n.phoneErrorInvalidCode,
    'too-many-requests' => l10n.phoneErrorTooManyRequests,
    'quota-exceeded' => l10n.phoneErrorQuota,
    'app-not-authorized' ||
    'invalid-app-credential' ||
    'missing-app-credential' ||
    'invalid-cert-hash' ||
    'missing-client-identifier' => l10n.phoneErrorAppVerification,
    'captcha-check-failed' => l10n.phoneErrorCaptcha,
    'network-request-failed' || 'network-error' => l10n.phoneErrorNetwork,
    'operation-not-allowed' => l10n.phoneErrorDisabled,
    'credential-already-in-use' ||
    'account-exists-with-different-credential' => l10n.phoneErrorCollision,
    'requires-recent-login' => l10n.phoneErrorRecentLogin,
    'user-profile-not-found' => l10n.phoneErrorProfileMissing,
    _ => l10n.phoneErrorGeneric,
  };
}
