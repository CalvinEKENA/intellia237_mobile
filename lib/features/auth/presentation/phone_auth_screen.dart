import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/localization/app_locale_controller.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../family_access/domain/family_access_models.dart';
import '../../family_access/domain/family_access_outcomes.dart';
import '../../parent/application/pending_child_link.dart';
import '../application/auth_controller.dart';
import '../application/auth_state.dart';
import '../application/phone_auth_controller.dart';
import '../data/auth_entry_preferences.dart';
import '../domain/app_role.dart';
import '../domain/auth_entry_intent.dart';
import '../domain/firebase_error_mapper.dart';
import 'widgets/auth_controls.dart';
import 'widgets/auth_experience_scaffold.dart';
import 'widgets/living_pass.dart';
import 'widgets/pass_auth_progress.dart';
import 'widgets/pass_otp_field.dart';
import 'widgets/role_conflict_copy.dart';
import 'widgets/student_access_code_reveal.dart';

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({
    this.authIntent,
    this.linkCurrentUser = false,
    super.key,
  });

  /// Espace choisi à l'entrée pour ce parcours (« Élève », « Parent ou
  /// responsable »…), ou null pour l'accès téléphone neutre.
  ///
  /// Ce n'est jamais le rôle du compte : celui-ci est lu après la
  /// vérification du numéro, et un écart entre les deux est un conflit
  /// expliqué, pas une redirection.
  final AppRole? authIntent;
  final bool linkCurrentUser;

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  late final _passInputs = Listenable.merge([
    _phoneController,
    _codeController,
  ]);
  final _phoneFocus = FocusNode();
  final _codeFocus = FocusNode();
  bool _completionHandled = false;
  bool _profileChoiceRequired = false;

  /// Rôle du compte vérifié, quand il n'est pas celui de l'espace choisi.
  AppRole? _conflictingRole;

  /// Erreur de lecture du rôle du compte : rien n'a été ouvert.
  String? _unresolvedCode;
  bool _resolving = false;
  bool _linkingChild = false;

  /// L'espace adopté s'ouvre : « 7 » est allumé et reste à l'écran le temps
  /// de `PassSealTiming.completionHold`.
  bool _accessOpened = false;

  /// Sous l'entrée parent, le numéro vérifié ouvre l'accès d'un élève : la
  /// session reste ouverte le temps que le parent décide.
  AuthEntryFamilyPhoneInUse? _familyPhoneOffer;
  bool _migrating = false;
  FamilyPhoneMigrationFailed? _migrationFailure;

  /// Migration réussie, code d'accès de l'élève à montrer avant d'ouvrir
  /// l'espace parent.
  FamilyPhoneMigrationResult? _migrated;
  bool _openingParent = false;

  /// Notifiant retenu pour refermer, à la sortie de l'écran, une session
  /// vérifiée que le parent n'a pas cédée.
  AuthController? _authNotifier;

  @override
  void dispose() {
    final notifier = _authNotifier;
    if (_familyPhoneOffer != null && _migrated == null && notifier != null) {
      // Personne n'a confirmé : le téléphone reste à l'élève et la session
      // vérifiée se referme. L'application peut se fermer en même temps : un
      // échec ici est rattrapé au démarrage suivant.
      unawaited(
        Future<void>.microtask(() async {
          try {
            await notifier.signOut();
          } catch (_) {}
        }),
      );
    }
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
    final intent = widget.authIntent;
    final conflictingRole = _conflictingRole;
    final familyPhoneOffer = _familyPhoneOffer;
    final migrated = _migrated;
    final childCodePending =
        intent == AppRole.parent &&
        ref.watch(pendingChildLinkProvider.select((link) => link.code != null));

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
        // Le clavier se referme : le Pass reprend sa pleine taille pour la
        // fin du sceau, y compris quand Android a lu le SMS seul.
        FocusManager.instance.primaryFocus?.unfocus();
        unawaited(_finishAuthentication());
      }
    });

    return AuthExperienceScaffold(
      showBackButton: widget.linkCurrentUser || intent != null,
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
      pass: ListenableBuilder(
        listenable: _passInputs,
        builder: (context, _) => LivingPass(
          role: intent,
          detail: state.stage == PhoneAuthStage.phoneEntry
              ? (_phoneController.text.trim().isEmpty
                    ? null
                    : _phoneController.text.trim())
              : state.phoneNumber,
          phase: migrated != null
              ? context.l10n.passFamilyNumber
              : familyPhoneOffer != null || conflictingRole != null
              ? context.l10n.passNumberAlreadyUsed
              : switch (state.stage) {
                  PhoneAuthStage.phoneEntry => context.l10n.passYourNumber,
                  PhoneAuthStage.codeEntry =>
                    context.l10n.passVerificationInProgress,
                  PhoneAuthStage.success => context.l10n.passNumberVerified,
                },
          // Numéro valide : « 2 » vert. Code complet ou validé : « 3 » rouge.
          // Espace ouvert : « 7 » jaune. Un numéro vérifié qui n'ouvre pas
          // l'espace choisi s'arrête au « 3 », sans jamais rééteindre « 7 ».
          seal: PassAuthProgress.phone(
            stage: state.stage,
            phoneInput: _phoneController.text,
            codeInput: _codeController.text,
            accessOpened:
                _accessOpened &&
                conflictingRole == null &&
                (familyPhoneOffer == null || migrated != null),
          ),
          progress: PassAuthProgress.phoneLine(
            stage: state.stage,
            phoneInput: _phoneController.text,
            codeInput: _codeController.text,
            accessOpened:
                _accessOpened &&
                conflictingRole == null &&
                (familyPhoneOffer == null || migrated != null),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            showBrand: false,
            eyebrow: intent == null
                ? context.l10n.passPhoneAccess
                : passRoleLabel(context, intent),
            title: widget.linkCurrentUser
                ? l10n.phoneLinkTitle
                : migrated != null
                ? (migrated.parentUid.isEmpty
                      ? context.l10n.passNumberAlreadyUsed
                      : context.l10n.familyPhoneMigratedTitle)
                : familyPhoneOffer != null || conflictingRole != null
                ? context.l10n.passNumberAlreadyUsed
                : state.stage == PhoneAuthStage.codeEntry
                ? context.l10n.passSixDigitsThenWeContinue
                : state.stage == PhoneAuthStage.success
                ? context.l10n.passYourNumberIsConfirmed
                : context.l10n.passYourNumberYourAccess,
            subtitle: widget.linkCurrentUser
                ? l10n.phoneLinkSubtitle
                : conflictingRole != null ||
                      familyPhoneOffer != null ||
                      migrated != null
                ? ''
                : state.stage == PhoneAuthStage.codeEntry
                ? l10n.phoneCodeSubtitle(state.phoneNumber)
                : state.stage == PhoneAuthStage.success
                ? l10n.phoneVerificationSuccessBody
                : l10n.phoneAuthSubtitle,
          ),
          if (childCodePending &&
              conflictingRole == null &&
              familyPhoneOffer == null &&
              state.stage != PhoneAuthStage.success) ...[
            const SizedBox(height: 16),
            const _PendingChildCodeNote(),
          ],
          const SizedBox(height: 24),
          AuthGlassPanel(
            child: AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              child: migrated != null
                  ? Column(
                      key: const ValueKey('family-phone-migrated'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Migration confirmée mais inachevée : l'élève a déjà
                        // son code ; le numéro doit être vérifié à nouveau.
                        if (migrated.parentUid.isEmpty) ...[
                          AuthErrorBanner(
                            key: const ValueKey(
                              'family-phone-verify-to-finish',
                            ),
                            message: context
                                .l10n
                                .familyPhoneMigrationVerifyAgainToFinish,
                          ),
                          const SizedBox(height: 14),
                        ],
                        StudentAccessCodeReveal(
                          studentFirstName: migrated.studentFirstName,
                          code: migrated.studentAccessCode,
                          busy: _openingParent,
                          continueLabel: migrated.parentUid.isEmpty
                              ? context
                                    .l10n
                                    .familyPhoneMigrationVerifyAgainAction
                              : context.l10n.familyPhoneMigratedContinue,
                          onContinue: _openParentSpace,
                        ),
                      ],
                    )
                  : familyPhoneOffer != null
                  ? _FamilyPhoneMigrationPanel(
                      key: const ValueKey('family-phone-offer'),
                      busy: _migrating,
                      failure: _migrationFailure,
                      onConfirm: _migrateFamilyPhone,
                      onVerifyAgain: _verifyNumberAgain,
                      onUseAnotherNumber: _useAnotherNumber,
                      onCancel: _cancelEntry,
                    )
                  : conflictingRole != null && intent != null
                  ? _RoleConflictPanel(
                      key: const ValueKey('phone-role-conflict'),
                      intent: intent,
                      accountRole: conflictingRole,
                      childCodeKept: childCodePending,
                      onUseAnotherNumber: _useAnotherNumber,
                      onUseAccessCode: intent == AppRole.student
                          ? () => context.pushReplacement(
                              AppRoutes.studentAccessCode,
                            )
                          : null,
                      onCancel: _cancelEntry,
                    )
                  : _unresolvedCode != null
                  ? _EntryUnresolvedPanel(
                      key: const ValueKey('phone-entry-unresolved'),
                      busy: _resolving,
                      onRetry: _enterAccountSpace,
                      onCancel: _cancelEntry,
                    )
                  : switch (state.stage) {
                      PhoneAuthStage.phoneEntry => _PhoneEntry(
                        key: const ValueKey('phone-entry-stage'),
                        controller: _phoneController,
                        focusNode: _phoneFocus,
                        isLoading: state.isLoading,
                        cooldownSeconds: state.cooldownSeconds,
                        onSubmit: () =>
                            controller.sendCode(_phoneController.text),
                      ),
                      PhoneAuthStage.codeEntry => _CodeEntry(
                        key: const ValueKey('phone-code-stage'),
                        controller: _codeController,
                        focusNode: _codeFocus,
                        state: state,
                        onSubmit: () {
                          if (ref.read(provider).stage !=
                                  PhoneAuthStage.codeEntry ||
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
                        linkingChild: _linkingChild,
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
          // Les parents s'identifient par téléphone : l'e-mail n'est proposé
          // qu'aux autres entrées, et garde l'espace choisi.
          if (!widget.linkCurrentUser &&
              intent == AppRole.student &&
              conflictingRole == null &&
              state.stage == PhoneAuthStage.phoneEntry) ...[
            const SizedBox(height: 18),
            TextButton.icon(
              key: const ValueKey('phone-use-student-access-code'),
              onPressed: state.isLoading
                  ? null
                  : () => context.push(AppRoutes.studentAccessCode),
              icon: const Icon(Icons.key_rounded, size: 18),
              label: Text(l10n.studentNoPhoneUseAccessCode),
            ),
          ],
          if (!widget.linkCurrentUser &&
              intent != AppRole.parent &&
              conflictingRole == null) ...[
            const SizedBox(height: 18),
            TextButton(
              key: const ValueKey('phone-use-email'),
              onPressed: state.isLoading
                  ? null
                  : () => context.push(AppRoutes.emailSignIn(intent)),
              child: Text(l10n.useEmailCompatibility),
            ),
          ],
          if (!widget.linkCurrentUser && intent == null)
            TextButton.icon(
              key: const ValueKey('phone-change-access'),
              onPressed: state.isLoading
                  ? null
                  : () => context.go(AppRoutes.authGateway),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: Text(context.l10n.passChooseAnotherWayIn),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _finishAuthentication() async {
    // Firebase vient de valider le numéro : « 3 » est allumé. Quand le code
    // n'a pas été tapé — SMS lu par Android, validation immédiate —, ce rouge
    // apparaît à l'instant : il reste seul lisible avant que « 7 » s'allume.
    final secretHold = PassAuthProgress.isCompleteCode(_codeController.text)
        ? null
        : Future<void>.delayed(PassSealTiming.stageHold);
    if (widget.linkCurrentUser) {
      await secretHold;
      if (!mounted) return;
      await _openWithCompletedSeal();
      if (mounted) context.pop(true);
      return;
    }
    await _enterAccountSpace(secretHold: secretHold);
  }

  /// Allume « 7 » et le laisse à l'écran avant d'ouvrir l'espace.
  ///
  /// Registre de décisions (QA appareil, round 3) : l'écran partait 350 ms
  /// après la réussite Firebase, pendant que le clavier se refermait et que
  /// le panneau changeait ; sur appareil, le sceau complet vivait moins d'une
  /// seconde et le « 7 » jaune n'était pas perçu.
  Future<void> _openWithCompletedSeal() async {
    setState(() => _accessOpened = true);
    await Future<void>.delayed(PassSealTiming.completionHold);
  }

  /// Tranche la compatibilité du compte vérifié avec l'espace choisi, puis
  /// ouvre l'écran qui lui revient.
  ///
  /// Registre de décisions (QA appareil, round 2) : « le rôle réel l'emporte
  /// toujours sur l'entrée choisie » menait un parent, entré avec le numéro
  /// d'un élève, dans l'espace de cet élève. Sous une intention, un compte
  /// d'un autre rôle n'ouvre plus rien : le conflit est expliqué ici, sans
  /// quitter le parcours choisi et sans toucher au rôle enregistré.
  ///
  /// Le sceau complet est montré avant l'adoption : dès que l'état global
  /// change, le routeur peut emporter cet écran.
  Future<void> _enterAccountSpace({Future<void>? secretHold}) async {
    setState(() {
      _resolving = true;
      _unresolvedCode = null;
    });
    String? destination;
    final adoption = await ref
        .read(authControllerProvider.notifier)
        .adoptSessionForIntent(
          widget.authIntent,
          beforeOpening: (opening) async {
            destination = _destinationFor(opening);
            // Un profil illisible n'ouvre aucun espace : le sceau reste au
            // « 3 ».
            if (destination == AppRoutes.authProfileRecovery) return;
            await secretHold;
            if (mounted) await _openWithCompletedSeal();
          },
        );
    if (!mounted) return;

    switch (adoption) {
      case AuthEntryFamilyPhoneInUse():
        setState(() {
          _resolving = false;
          _familyPhoneOffer = adoption;
          _authNotifier = ref.read(authControllerProvider.notifier);
        });
        return;
      case AuthEntryRoleConflict(:final accountRole):
        setState(() {
          _resolving = false;
          _conflictingRole = accountRole;
        });
        return;
      case AuthEntryUnresolved(:final errorCode):
        setState(() {
          _resolving = false;
          _unresolvedCode = errorCode;
        });
        return;
      case AuthEntryAdopted():
        break;
    }

    final target =
        destination ?? _destinationFor(ref.read(authControllerProvider));
    if (widget.authIntent == AppRole.parent &&
        target == AppRoutes.parentRegistration) {
      // Numéro vérifié à nouveau après une migration confirmée mais
      // inachevée : le serveur relie l'enfant à cette identité parent.
      setState(() => _linkingChild = true);
      await ref
          .read(authControllerProvider.notifier)
          .resumeConfirmedFamilyPhoneMigration();
      if (!mounted) return;
    }
    if (target == AppRoutes.parentHome &&
        ref.read(pendingChildLinkProvider).code != null) {
      // Le code saisi avant l'authentification est relié maintenant, pour
      // que l'enfant soit visible dès l'arrivée dans l'espace parent.
      setState(() => _linkingChild = true);
      await ref.read(pendingChildLinkProvider.notifier).linkPending();
      if (!mounted) return;
    }
    if (target != null) {
      context.go(target);
      return;
    }
    setState(() {
      _resolving = false;
      _profileChoiceRequired = true;
    });
  }

  /// Écran qu'ouvre l'état d'authentification [auth] sous l'espace choisi.
  String? _destinationFor(AuthState auth) {
    final accountRole = auth.role;
    if (auth.isAuthenticated && accountRole != null && auth.profileCompleted) {
      return accountRole.homePath;
    }
    if (auth.status == AuthStatus.retryableProfileFailure ||
        auth.status == AuthStatus.legacyProfileRecovery) {
      return AppRoutes.authProfileRecovery;
    }
    // Un profil existant mais incomplet reprend sa propre inscription. Sous
    // une intention, ce rôle est forcément celui qui a été choisi.
    if (accountRole != null) {
      return switch (accountRole) {
        AppRole.student => AppRoutes.studentRegistration,
        AppRole.parent => AppRoutes.parentRegistration,
        AppRole.teacher || AppRole.admin => AppRoutes.authProfileRecovery,
      };
    }
    return switch (widget.authIntent) {
      AppRole.student => AppRoutes.studentRegistration,
      AppRole.parent => AppRoutes.parentRegistration,
      AppRole.teacher => AppRoutes.teacherRegistration,
      AppRole.admin || null => null,
    };
  }

  /// Le parent confirme : le numéro de la famille devient le sien, l'élève
  /// garde son profil et reçoit un code d'accès.
  Future<void> _migrateFamilyPhone() async {
    if (_migrating) return;
    setState(() {
      _migrating = true;
      _migrationFailure = null;
    });
    final outcome = await ref
        .read(authControllerProvider.notifier)
        .migrateFamilyPhoneToParent();
    if (!mounted) return;
    switch (outcome) {
      case FamilyPhoneMigrated(:final result):
        setState(() {
          _migrating = false;
          _migrated = result;
        });
      case FamilyPhoneMigrationFailed(
        failure: FamilyPhoneMigrationFailure.verifyAgainToFinish,
        :final studentAccessCode?,
      ):
        // Le code de l'élève existe déjà : il est montré avant tout, puis le
        // numéro, libre, se vérifie à nouveau pour finir l'espace parent.
        setState(() {
          _migrating = false;
          _migrationFailure = outcome;
          _migrated = FamilyPhoneMigrationResult(
            studentId: '',
            studentFirstName: _familyPhoneOffer?.studentFirstName ?? '',
            parentUid: '',
            studentAccessCode: studentAccessCode,
          );
        });
      case final FamilyPhoneMigrationFailed failed:
        setState(() {
          _migrating = false;
          _migrationFailure = failed;
        });
    }
  }

  /// Le code d'accès est noté : l'espace parent s'ouvre sous l'identité du
  /// parent, jamais celle de l'élève.
  Future<void> _openParentSpace() async {
    final result = _migrated;
    if (result == null || _openingParent) return;
    if (result.parentUid.isEmpty) {
      // Migration à terminer par une nouvelle vérification du numéro.
      await _verifyNumberAgain();
      return;
    }
    setState(() => _openingParent = true);
    String? destination;
    final adoption = await ref
        .read(authControllerProvider.notifier)
        .openParentAfterFamilyPhoneMigration(
          result,
          beforeOpening: (opening) async {
            destination = _destinationFor(opening);
            if (destination == AppRoutes.authProfileRecovery) return;
            if (mounted) await _openWithCompletedSeal();
          },
        );
    if (!mounted) return;
    if (adoption is! AuthEntryAdopted) {
      setState(() {
        _openingParent = false;
        _unresolvedCode = adoption is AuthEntryUnresolved
            ? adoption.errorCode
            : 'profile-resolution-failed';
        _familyPhoneOffer = null;
        _migrated = null;
      });
      return;
    }
    final target =
        destination ?? _destinationFor(ref.read(authControllerProvider));
    if (target != null) context.go(target);
  }

  /// La vérification SMS a expiré, ou le numéro doit être vérifié à nouveau
  /// pour finir : la session est refermée et le même numéro reproposé.
  Future<void> _verifyNumberAgain() async {
    final provider = phoneAuthControllerProvider(widget.linkCurrentUser);
    final number = ref.read(provider).phoneNumber;
    await ref.read(authControllerProvider.notifier).signOut();
    if (!mounted) return;
    _useAnotherNumber();
    final local = number.startsWith('+237') ? number.substring(4) : number;
    _phoneController.text = local;
  }

  /// Corrige l'identifiant sans quitter le parcours : le code enfant retenu
  /// reste en attente.
  void _useAnotherNumber() {
    if (_familyPhoneOffer != null && _migrated == null) {
      // Le parent garde le numéro à l'élève : la session vérifiée se referme.
      unawaited(ref.read(authControllerProvider.notifier).signOut());
    }
    setState(() {
      _familyPhoneOffer = null;
      _migrationFailure = null;
      _migrated = null;
      _openingParent = false;
      _conflictingRole = null;
      _unresolvedCode = null;
      _completionHandled = false;
      _profileChoiceRequired = false;
      _accessOpened = false;
    });
    _phoneController.clear();
    _codeController.clear();
    ref
        .read(phoneAuthControllerProvider(widget.linkCurrentUser).notifier)
        .restartWithAnotherNumber();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _phoneFocus.requestFocus();
    });
  }

  /// Abandon explicite du parcours : le code enfant retenu disparaît, et une
  /// session vérifiée mais non adoptée est refermée.
  Future<void> _cancelEntry() async {
    ref.read(pendingChildLinkProvider.notifier).clear();
    if (_unresolvedCode != null ||
        (_familyPhoneOffer != null && _migrated == null)) {
      _familyPhoneOffer = null;
      await ref.read(authControllerProvider.notifier).signOut();
    }
    if (!mounted) return;
    context.go(
      ref.read(hasAuthenticatedBeforeProvider)
          ? AppRoutes.authGateway
          : AppRoutes.register,
    );
  }
}

class _PendingChildCodeNote extends StatelessWidget {
  const _PendingChildCodeNote();

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('phone-pending-child-code'),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: AuthExperienceColors.surfaceSoft,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AuthExperienceColors.border),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.link_rounded,
          size: 18,
          color: AuthExperienceColors.indigo,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            context.l10n.phonePendingChildCode,
            style: const TextStyle(
              fontFamily: 'CampaignBody',
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: AuthExperienceColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}

class _RoleConflictPanel extends StatelessWidget {
  const _RoleConflictPanel({
    required this.intent,
    required this.accountRole,
    required this.childCodeKept,
    required this.onUseAnotherNumber,
    required this.onCancel,
    this.onUseAccessCode,
    super.key,
  });

  final AppRole intent;
  final AppRole accountRole;
  final bool childCodeKept;
  final VoidCallback onUseAnotherNumber;
  final VoidCallback onCancel;

  /// Élève sans téléphone : entrer avec son code d'accès INTELLIA.
  final VoidCallback? onUseAccessCode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.manage_accounts_outlined,
            color: AuthExperienceColors.indigo,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            roleConflictTitle(l10n, accountRole: accountRole, viaPhone: true),
            key: const ValueKey('phone-role-conflict-title'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AuthExperienceColors.textPrimary,
              fontSize: 18,
              height: 1.3,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            roleConflictGuidance(l10n, intent: intent),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AuthExperienceColors.textSecondary,
              height: 1.45,
            ),
          ),
          if (childCodeKept) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.link_rounded,
                  size: 16,
                  color: AuthExperienceColors.indigo,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    l10n.roleConflictChildCodeKept,
                    key: const ValueKey('phone-role-conflict-code-kept'),
                    style: const TextStyle(
                      color: AuthExperienceColors.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          AuthPrimaryButton(
            key: const ValueKey('phone-conflict-use-another-number'),
            label: l10n.roleConflictUseAnotherNumber,
            icon: Icons.phone_iphone_rounded,
            onTap: onUseAnotherNumber,
          ),
          if (onUseAccessCode case final useAccessCode?) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const ValueKey('phone-conflict-use-access-code'),
              onPressed: useAccessCode,
              icon: const Icon(Icons.key_rounded),
              label: Text(l10n.studentNoPhoneUseAccessCode),
            ),
          ],
          const SizedBox(height: 6),
          TextButton(
            key: const ValueKey('phone-conflict-cancel'),
            onPressed: onCancel,
            child: Text(l10n.cancelLabel),
          ),
        ],
      ),
    );
  }
}

class _FamilyPhoneMigrationPanel extends StatelessWidget {
  const _FamilyPhoneMigrationPanel({
    required this.busy,
    required this.failure,
    required this.onConfirm,
    required this.onVerifyAgain,
    required this.onUseAnotherNumber,
    required this.onCancel,
    super.key,
  });

  final bool busy;
  final FamilyPhoneMigrationFailed? failure;
  final VoidCallback onConfirm;
  final VoidCallback onVerifyAgain;
  final VoidCallback onUseAnotherNumber;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failure = this.failure?.failure;
    final verifyAgain =
        failure == FamilyPhoneMigrationFailure.verificationExpired ||
        failure == FamilyPhoneMigrationFailure.verifyAgainToFinish;
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.family_restroom_rounded,
            color: AuthExperienceColors.indigo,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.familyPhoneMigrationPrompt,
            key: const ValueKey('family-phone-offer-prompt'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AuthExperienceColors.textPrimary,
              fontSize: 15.5,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (failure != null) ...[
            const SizedBox(height: 14),
            AuthErrorBanner(
              key: ValueKey('family-phone-offer-failure-${failure.name}'),
              message: switch (failure) {
                FamilyPhoneMigrationFailure.nothingChanged =>
                  l10n.familyPhoneMigrationNothingChanged,
                FamilyPhoneMigrationFailure.verificationExpired =>
                  l10n.familyPhoneMigrationVerifyAgain,
                FamilyPhoneMigrationFailure.inProgress =>
                  l10n.familyPhoneMigrationInProgress,
                FamilyPhoneMigrationFailure.verifyAgainToFinish =>
                  l10n.familyPhoneMigrationVerifyAgainToFinish,
                FamilyPhoneMigrationFailure.refused =>
                  l10n.familyPhoneMigrationRefused,
                FamilyPhoneMigrationFailure.unavailable =>
                  l10n.familyPhoneMigrationUnavailable,
              },
            ),
          ],
          const SizedBox(height: 18),
          if (verifyAgain)
            AuthPrimaryButton(
              key: const ValueKey('family-phone-offer-verify-again'),
              label: l10n.familyPhoneMigrationVerifyAgainAction,
              icon: Icons.sms_outlined,
              onTap: busy ? null : onVerifyAgain,
            )
          else if (failure != FamilyPhoneMigrationFailure.refused)
            AuthPrimaryButton(
              key: const ValueKey('family-phone-offer-confirm'),
              label: l10n.familyPhoneMigrationConfirm,
              icon: Icons.swap_horiz_rounded,
              isLoading: busy,
              onTap: busy ? null : onConfirm,
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const ValueKey('family-phone-offer-another-number'),
            onPressed: busy ? null : onUseAnotherNumber,
            icon: const Icon(Icons.phone_iphone_rounded),
            label: Text(l10n.roleConflictUseAnotherNumber),
          ),
          const SizedBox(height: 6),
          TextButton(
            key: const ValueKey('family-phone-offer-cancel'),
            onPressed: busy ? null : onCancel,
            child: Text(l10n.cancelLabel),
          ),
        ],
      ),
    );
  }
}

class _EntryUnresolvedPanel extends StatelessWidget {
  const _EntryUnresolvedPanel({
    required this.busy,
    required this.onRetry,
    required this.onCancel,
    super.key,
  });

  final bool busy;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.sync_problem_rounded,
            color: AuthExperienceColors.error,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.authProfileSyncFailureBody,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AuthExperienceColors.textPrimary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          AuthPrimaryButton(
            key: const ValueKey('phone-entry-retry'),
            label: l10n.retryLabel,
            icon: Icons.refresh_rounded,
            isLoading: busy,
            onTap: busy ? null : onRetry,
          ),
          const SizedBox(height: 6),
          TextButton(
            key: const ValueKey('phone-entry-cancel'),
            onPressed: busy ? null : onCancel,
            child: Text(l10n.cancelLabel),
          ),
        ],
      ),
    );
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
    required this.linkingChild,
    required this.profileChoiceRequired,
    required this.onCreateStudentProfile,
    required this.onCreateParentProfile,
    super.key,
  });

  final bool linking;

  /// Le code enfant retenu est en cours de liaison, avant l'arrivée.
  final bool linkingChild;
  final bool profileChoiceRequired;
  final VoidCallback onCreateStudentProfile;
  final VoidCallback onCreateParentProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Registre de décisions (QA appareil, round 3) : une coche verte de
    // 54 px s'affichait sous le Pass à l'instant même où « 7 » devenait
    // jaune ; l'œil lisait une fin verte. Le sceau complet est le seul signe
    // de réussite.
    return Semantics(
      liveRegion: true,
      child: Column(
        children: [
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
          if (linkingChild) ...[
            const SizedBox(height: 14),
            Row(
              key: const ValueKey('phone-linking-child'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    l10n.phoneLinkingChild,
                    style: const TextStyle(
                      color: AuthExperienceColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
