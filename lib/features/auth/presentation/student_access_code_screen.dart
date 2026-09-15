import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../family_access/domain/family_access_models.dart';
import '../../family_access/domain/family_access_outcomes.dart';
import '../application/auth_controller.dart';
import '../application/auth_state.dart';
import '../domain/app_role.dart';
import 'widgets/auth_controls.dart';
import 'widgets/auth_experience_scaffold.dart';
import 'widgets/living_pass.dart';
import 'widgets/pass_auth_progress.dart';

/// Entrée d'un élève avec son code d'accès INTELLIA, sans téléphone.
///
/// Registre de décisions (mission famille) : un élève devait posséder un
/// numéro, alors que beaucoup d'élèves n'ont pas de téléphone. Le code est
/// émis par un parent lié ou par l'établissement ; le serveur l'échange contre
/// une session du même UID élève. Le code n'est jamais gardé par l'écran
/// au-delà de la saisie, ni placé dans une adresse.
class StudentAccessCodeScreen extends ConsumerStatefulWidget {
  const StudentAccessCodeScreen({super.key});

  @override
  ConsumerState<StudentAccessCodeScreen> createState() =>
      _StudentAccessCodeScreenState();
}

class _StudentAccessCodeScreenState
    extends ConsumerState<StudentAccessCodeScreen> {
  final _codeController = TextEditingController();
  final _codeFocus = FocusNode();
  bool _submitting = false;
  StudentAccessCodeSignIn? _failure;

  /// Le serveur a reconnu le code : « 3 ».
  bool _codeAccepted = false;

  /// L'espace de l'élève s'ouvre : « 7 ».
  bool _accessOpened = false;

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!StudentAccessCodeFormat.isWellFormed(_codeController.text)) {
      setState(
        () => _failure = const StudentAccessCodeRejected(
          StudentAccessCodeRejection.invalid,
        ),
      );
      _codeFocus.requestFocus();
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _submitting = true;
      _failure = null;
    });
    final outcome = await ref
        .read(authControllerProvider.notifier)
        .signInWithStudentAccessCode(
          _codeController.text,
          beforeOpening: (_) => _holdCompletedSeal(),
        );
    if (!mounted) return;
    if (outcome is StudentAccessCodeAdopted) {
      // Accès ouvert par un parent : l'enfant complète son profil scolaire à
      // sa première connexion. Un profil complet est ouvert par le routeur.
      if (ref.read(authControllerProvider).status ==
          AuthStatus.needsOnboarding) {
        context.go(AppRoutes.studentRegistration);
      }
      return;
    }
    setState(() {
      _submitting = false;
      _codeAccepted = false;
      _accessOpened = false;
      _failure = outcome;
    });
  }

  /// « 3 » reste seul lisible, puis « 7 » avant l'ouverture de l'espace : la
  /// session change d'état juste après ce délai.
  Future<void> _holdCompletedSeal() async {
    if (!mounted) return;
    setState(() => _codeAccepted = true);
    await Future<void>.delayed(PassSealTiming.stageHold);
    if (!mounted) return;
    setState(() => _accessOpened = true);
    await Future<void>.delayed(PassSealTiming.completionHold);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthExperienceScaffold(
      pass: ListenableBuilder(
        listenable: _codeController,
        builder: (context, _) => LivingPass(
          role: AppRole.student,
          phase: l10n.studentAccessCodePhase,
          seal: PassAuthProgress.studentAccessCode(
            codeInput: _codeController.text,
            codeAccepted: _codeAccepted,
            accessOpened: _accessOpened,
          ),
          progress: PassAuthProgress.accessCodeLine(
            codeInput: _codeController.text,
            codeAccepted: _codeAccepted,
            accessOpened: _accessOpened,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            showBrand: false,
            eyebrow: l10n.studentRole,
            title: l10n.studentAccessCodeTitle,
            subtitle: l10n.studentAccessCodeSubtitle,
          ),
          const SizedBox(height: 24),
          AuthGlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const ValueKey('student-access-code-field'),
                  controller: _codeController,
                  focusNode: _codeFocus,
                  enabled: !_submitting,
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: TextInputType.visiblePassword,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  inputFormatters: const [StudentAccessCodeInputFormatter()],
                  onChanged: (_) {
                    if (_failure != null) setState(() => _failure = null);
                  },
                  onSubmitted: (_) => _submit(),
                  style: const TextStyle(
                    fontFamily: 'CampaignBody',
                    color: AuthExperienceColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.studentAccessCodeLabel,
                    hintText: 'XXXX-XXXX-XXXX',
                    filled: true,
                    fillColor: AuthExperienceColors.surface,
                    prefixIcon: const Icon(
                      Icons.key_rounded,
                      color: AuthExperienceColors.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AuthExperienceColors.border,
                      ),
                    ),
                  ),
                ),
                if (_failure case final failure?) ...[
                  const SizedBox(height: 14),
                  AuthErrorBanner(
                    key: const ValueKey('student-access-code-error'),
                    message: _failureMessage(l10n, failure),
                    onDismiss: () => setState(() => _failure = null),
                  ),
                ],
                const SizedBox(height: 18),
                AuthPrimaryButton(
                  key: const ValueKey('student-access-code-submit'),
                  label: l10n.studentAccessCodeSubmit,
                  icon: Icons.login_rounded,
                  isLoading: _submitting,
                  onTap: _submitting ? null : _submit,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 15,
                  color: AuthExperienceColors.textTertiary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.studentAccessCodePrivacy,
                  style: const TextStyle(
                    fontFamily: 'CampaignBody',
                    fontSize: 12,
                    height: 1.4,
                    color: AuthExperienceColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            key: const ValueKey('student-access-code-use-phone'),
            onPressed: _submitting
                ? null
                : () => context.pushReplacement(
                    AppRoutes.phoneRegistration(AppRole.student),
                  ),
            icon: const Icon(Icons.sms_outlined, size: 16),
            label: Text(l10n.studentAccessCodeUsePhone),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _failureMessage(
    AppLocalizations l10n,
    StudentAccessCodeSignIn failure,
  ) => switch (failure) {
    StudentAccessCodeRejected(
      rejection: StudentAccessCodeRejection.tooManyAttempts,
    ) =>
      l10n.studentAccessCodeTooManyAttempts,
    StudentAccessCodeRejected(
      rejection: StudentAccessCodeRejection.unavailable,
    ) =>
      l10n.studentAccessCodeUnavailable,
    StudentAccessCodeUnresolved() => l10n.authProfileSyncFailureBody,
    _ => l10n.studentAccessCodeInvalid,
  };
}

/// Majuscules, symboles du code seulement, groupés par quatre.
class StudentAccessCodeInputFormatter extends TextInputFormatter {
  const StudentAccessCodeInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final symbols = newValue.text
        .toUpperCase()
        .split('')
        .where(StudentAccessCodeFormat.alphabet.contains)
        .take(StudentAccessCodeFormat.length)
        .join();
    final formatted = StudentAccessCodeFormat.format(symbols);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
