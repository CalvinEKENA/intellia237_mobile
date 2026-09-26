import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_input_validators.dart';
import '../../auth/domain/app_role.dart';
import '../../auth/presentation/widgets/auth_step_guide.dart';
import '../../auth/presentation/widgets/auth_controls.dart';
import '../../auth/presentation/widgets/auth_experience_scaffold.dart';
import '../../auth/presentation/widgets/auth_selection_pill.dart';
import '../../auth/presentation/widgets/auth_success_screen.dart';
import '../../auth/presentation/widgets/living_pass.dart';
import '../../auth/presentation/widgets/pass_auth_progress.dart';
import '../../tutor/domain/tutor_persona.dart';
import '../../legal/presentation/legal_links.dart';
import '../application/student_registration_controller.dart';
import '../application/student_registration_state.dart';
import '../domain/academic_rules.dart';
import '../../../core/localization/localization_extensions.dart';
import 'widgets/companion_discovery.dart';
import 'widgets/establishment_search_field.dart';

class StudentRegistrationFlowScreen extends ConsumerStatefulWidget {
  const StudentRegistrationFlowScreen({super.key});

  @override
  ConsumerState<StudentRegistrationFlowScreen> createState() =>
      _StudentRegistrationFlowScreenState();
}

class _StudentRegistrationFlowScreenState
    extends ConsumerState<StudentRegistrationFlowScreen> {
  CompanionChoice? _companionChoice;

  final _identityFormKey = GlobalKey<FormState>();
  final _securityFormKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  String? _localError;
  int _previousStep = 0;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(studentRegistrationControllerProvider);
    _firstNameController.text = draft.firstName;
    _lastNameController.text = draft.lastName;
    _firstNameController.addListener(
      () => ref
          .read(studentRegistrationControllerProvider.notifier)
          .setFirstName(_firstNameController.text),
    );
    _lastNameController.addListener(
      () => ref
          .read(studentRegistrationControllerProvider.notifier)
          .setLastName(_lastNameController.text),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentRegistrationControllerProvider);
    final controller = ref.read(studentRegistrationControllerProvider.notifier);
    // Le sceau dit la session réellement établie, pas l'étape du formulaire.
    final seal = PassAuthProgress.session(ref.watch(authControllerProvider));
    final companion = TutorPersona.resolve(state.selectedTutorId);
    final l10n = context.l10n;
    final labels = [
      l10n.stepIdentity,
      l10n.stepClass,
      l10n.stepCompanion,
      l10n.stepSecurity,
    ];

    if (state.isCompleted) {
      return AuthSuccessScreen(
        firstName: state.firstName.trim(),
        companionName: companion.name,
        companionAsset: companion.imagePath,
        onContinue: controller.completeRegistration,
        seal: seal,
      );
    }

    return AuthExperienceScaffold(
      pass: LivingPass(
        key: const ValueKey('student-living-pass'),
        role: AppRole.student,
        name: state.firstName.trim(),
        detail: [
          if (state.schoolClass != null) state.schoolClass!.label,
          if (state.schoolSeries != null) state.schoolSeries!.label,
        ].join(' · '),
        companionAsset: state.selectedTutorId == null
            ? null
            : companion.imagePath,
        phase: labels[state.currentStep],
        progress: PassAuthProgress.registrationLine(
          step: state.currentStep,
          steps: labels.length,
        ),
        seal: seal,
      ),
      // Après la première étape, le retour vit à côté du bouton principal.
      showBackButton: state.isFirstStep,
      onBack: state.isFirstStep
          ? () => context.pop()
          : () {
              FocusManager.instance.primaryFocus?.unfocus();
              setState(() {
                _previousStep = state.currentStep;
                _localError = null;
              });
              controller.goToPreviousStep();
            },
      // L'erreur se lit juste au-dessus du bouton, jamais hors de l'écran.
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _errorMessage(state) == null
                ? const SizedBox.shrink()
                : Padding(
                    key: ValueKey(_errorMessage(state)),
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AuthErrorBanner(
                      message: _errorMessage(state)!,
                      onRetry: state.isLastStep ? () => _submit(state) : null,
                      onDismiss: () {
                        controller.clearError();
                        setState(() => _localError = null);
                      },
                    ),
                  ),
          ),
          _actions(state),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Le guide porte l'étape en cours, le conseil et la suite.
          AuthStepGuide(
            currentStep: state.currentStep,
            labels: labels,
            hints: [
              l10n.studentGuideIdentity,
              l10n.studentGuideClass,
              l10n.studentGuideCompanion,
              l10n.studentGuideSecurity,
            ],
          ),
          const SizedBox(height: 18),
          PageTransitionSwitcher(
            duration: MediaQuery.of(context).disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 400),
            reverse: state.currentStep < _previousStep,
            transitionBuilder: (child, primary, secondary) {
              return SharedAxisTransition(
                animation: primary,
                secondaryAnimation: secondary,
                transitionType: SharedAxisTransitionType.horizontal,
                fillColor: Colors.transparent,
                child: child,
              );
            },
            child: AuthGlassPanel(
              key: ValueKey(state.currentStep),
              // La scène des compagnons occupe le panneau jusqu'aux bords.
              padding: state.currentStep == 2
                  ? const EdgeInsets.fromLTRB(8, 10, 8, 10)
                  : null,
              child: _stepContent(state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepContent(StudentRegistrationState state) {
    return switch (state.currentStep) {
      0 => _identityStep(state),
      1 => _classStep(state),
      2 => _companionStep(),
      3 => _securityStep(state),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _identityStep(StudentRegistrationState state) {
    final controller = ref.read(studentRegistrationControllerProvider.notifier);
    final l10n = context.l10n;
    return Form(
      key: _identityFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepHeading(
            title: l10n.academicPassport,
            subtitle: l10n.academicPassportDescription,
          ),
          const SizedBox(height: 18),
          Text(
            l10n.interfaceLanguage,
            style: const TextStyle(
              color: AuthExperienceColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AuthSelectionPill(
                key: const ValueKey('passport-language-fr'),
                label: l10n.frenchLanguage,
                selected: state.interfaceLanguage == InterfaceLanguage.french,
                onTap: () =>
                    controller.setInterfaceLanguage(InterfaceLanguage.french),
              ),
              AuthSelectionPill(
                key: const ValueKey('passport-language-en'),
                label: l10n.englishLanguage,
                selected: state.interfaceLanguage == InterfaceLanguage.english,
                onTap: () =>
                    controller.setInterfaceLanguage(InterfaceLanguage.english),
              ),
            ],
          ),
          const SizedBox(height: 18),
          AuthAnimatedField(
            controller: _firstNameController,
            label: l10n.firstNameLabel,
            hint: l10n.firstNameHint,
            icon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.givenName],
            validator: (value) => AuthInputValidators.displayName(
              value ?? '',
              label: l10n.firstNameLabel,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.parentLinkedHelp,
            style: const TextStyle(
              color: AuthExperienceColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AuthSelectionPill(
                key: const ValueKey('passport-linkage-individual'),
                label: l10n.individualAccount,
                selected:
                    state.accountLinkage == LearnerAccountLinkage.individual,
                onTap: () => controller.setAccountLinkage(
                  LearnerAccountLinkage.individual,
                ),
              ),
              AuthSelectionPill(
                key: const ValueKey('passport-linkage-parent'),
                label: l10n.parentLinkedAccount,
                selected:
                    state.accountLinkage == LearnerAccountLinkage.parentManaged,
                onTap: () => controller.setAccountLinkage(
                  LearnerAccountLinkage.parentManaged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AuthAnimatedField(
            controller: _lastNameController,
            label: l10n.lastNameLabel,
            hint: l10n.lastNameHint,
            icon: Icons.badge_outlined,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.familyName],
            validator: (value) => AuthInputValidators.displayName(
              value ?? '',
              label: l10n.lastNameLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _classStep(StudentRegistrationState state) {
    final controller = ref.read(studentRegistrationControllerProvider.notifier);
    final selectedClass = state.schoolClass;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeading(
          title: l10n.academicPassport,
          subtitle: l10n.establishmentSecurityNote,
        ),
        const SizedBox(height: 18),
        Text(
          l10n.educationalSubsystem,
          style: const TextStyle(
            color: AuthExperienceColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AuthSelectionPill(
              key: const ValueKey('passport-subsystem-francophone'),
              label: l10n.francophoneSubsystem,
              selected:
                  state.educationalSubsystem ==
                  EducationalSubsystem.francophone,
              onTap: () => controller.setEducationalSubsystem(
                EducationalSubsystem.francophone,
              ),
            ),
            AuthSelectionPill(
              key: const ValueKey('passport-subsystem-anglophone'),
              label: l10n.anglophoneSubsystem,
              selected:
                  state.educationalSubsystem == EducationalSubsystem.anglophone,
              onTap: () => controller.setEducationalSubsystem(
                EducationalSubsystem.anglophone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          l10n.educationType,
          style: const TextStyle(
            color: AuthExperienceColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            AuthSelectionPill(
              key: const ValueKey('passport-education-general'),
              label: l10n.generalEducation,
              selected: state.educationType == EducationType.general,
              onTap: () => controller.setEducationType(EducationType.general),
            ),
            AuthSelectionPill(
              key: const ValueKey('passport-education-technical'),
              label: l10n.technicalEducation,
              selected: state.educationType == EducationType.technical,
              onTap: () => controller.setEducationType(EducationType.technical),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          l10n.schoolLevel,
          style: const TextStyle(
            color: AuthExperienceColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final schoolClass in SchoolClassX.forSubsystem(
              state.educationalSubsystem,
            ))
              AuthSelectionPill(
                label: schoolClass.label,
                selected: selectedClass == schoolClass,
                onTap: () => controller.setSchoolClass(schoolClass),
              ),
          ],
        ),
        if (selectedClass?.requiresSeries ?? false) ...[
          const SizedBox(height: 22),
          Text(
            l10n.seriesLabel,
            style: const TextStyle(
              color: AuthExperienceColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final series in selectedClass!.allowedSeries)
                AuthSelectionPill(
                  label: series.label,
                  selected: state.schoolSeries == series,
                  onTap: () => controller.setSchoolSeries(series),
                ),
            ],
          ),
        ],
        if (state.educationType == EducationType.technical) ...[
          const SizedBox(height: 18),
          TextFormField(
            key: const ValueKey('passport-speciality'),
            initialValue: state.streamOrSpeciality,
            onChanged: controller.setStreamOrSpeciality,
            style: const TextStyle(color: AuthExperienceColors.textPrimary),
            decoration: InputDecoration(
              labelText: l10n.streamOrSpeciality,
              labelStyle: const TextStyle(
                color: AuthExperienceColors.textSecondary,
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        EstablishmentSearchField(
          initialName: state.establishment?.name,
          initialId: state.establishment?.candidateId,
          onCleared: () => controller.setEstablishmentCandidate(''),
          onSelected: controller.selectEstablishment,
          onSuggestion: controller.suggestEstablishment,
        ),
      ],
    );
  }

  // Les compagnons sont le titre de cette étape : le guide explique déjà quoi
  // faire, la scène garde toute la place (QA appareil, 24/09/2026).
  Widget _companionStep() => Semantics(
    header: true,
    label: context.l10n.meetCompanionTitle,
    child: CompanionDiscovery(
      showChooseBar: false,
      onChoiceChanged: (choice) => setState(() => _companionChoice = choice),
    ),
  );

  Widget _securityStep(StudentRegistrationState state) {
    final controller = ref.read(studentRegistrationControllerProvider.notifier);
    final companion = TutorPersona.resolve(state.selectedTutorId);
    final l10n = context.l10n;
    return Form(
      key: _securityFormKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepHeading(
              title: l10n.secureAccountTitle,
              subtitle: l10n.phoneVerifiedNoExtraCredential,
            ),
            const SizedBox(height: 18),
            Container(
              key: const ValueKey('phone-primary-target'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AuthExperienceColors.surfaceSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AuthExperienceColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.phone_android_rounded,
                    color: AuthExperienceColors.success,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.phoneIdentityTarget,
                          style: const TextStyle(
                            color: AuthExperienceColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.phoneVerificationSuccessBody,
                          style: const TextStyle(
                            color: AuthExperienceColors.textSecondary,
                            fontSize: 11.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _SummaryRow(
              icon: Icons.school_outlined,
              label: state.schoolClass?.label ?? l10n.classToConfirm,
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              icon: Icons.forum_outlined,
              label: '${l10n.learningCompanion} : ${companion.name}',
            ),
            const SizedBox(height: 16),
            AuthConsentTile(
              value: state.acceptedTerms,
              label: l10n.acceptTerms,
              onChanged: controller.setAcceptedTerms,
            ),
            AuthConsentTile(
              value: state.acceptedPrivacy,
              label: l10n.acceptPrivacy,
              onChanged: controller.setAcceptedPrivacy,
            ),
            AuthConsentTile(
              value: state.acceptedDataPolicy,
              label: l10n.acceptLearningData,
              onChanged: controller.setAcceptedDataPolicy,
            ),
            const LegalLinks(showEducationalData: true),
          ],
        ),
      ),
    );
  }

  /// Étape compagnon : un seul bouton dit exactement ce qui va se passer —
  /// « Découvre Léo avant de choisir », « Choisir Léo », puis « Continuer
  /// avec Léo » (QA appareil, 24/09/2026).
  ({String label, VoidCallback? onTap, IconData icon})? _companionAction(
    StudentRegistrationState state,
  ) {
    if (state.currentStep != 2) return null;
    final l10n = context.l10n;
    final choice = _companionChoice;
    if (choice == null) {
      return (
        label: l10n.continueLabel,
        onTap: null,
        icon: Icons.arrow_forward_rounded,
      );
    }
    if (state.selectedTutorId == choice.id) {
      return (
        label: l10n.continueWithCompanion(choice.name),
        onTap: state.isSubmitting ? null : () => _handlePrimaryAction(state),
        icon: Icons.arrow_forward_rounded,
      );
    }
    return (
      label: choice.canChoose
          ? l10n.chooseCompanionA11y(choice.name)
          : l10n.discoverCompanionBeforeChoice(choice.name),
      onTap: choice.canChoose
          ? () {
              HapticFeedback.mediumImpact();
              ref
                  .read(studentRegistrationControllerProvider.notifier)
                  .setSelectedTutorId(choice.id);
            }
          : null,
      icon: Icons.favorite_rounded,
    );
  }

  Widget _actions(StudentRegistrationState state) {
    final companion = _companionAction(state);
    return Row(
      children: [
        if (!state.isFirstStep) ...[
          IconButton(
            tooltip: context.l10n.previousLabel,
            onPressed: state.isSubmitting
                ? null
                : () {
                    setState(() {
                      _previousStep = state.currentStep;
                      _localError = null;
                    });
                    ref
                        .read(studentRegistrationControllerProvider.notifier)
                        .goToPreviousStep();
                  },
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AuthExperienceColors.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: AuthPrimaryButton(
            key: const ValueKey('registration-primary-action'),
            label:
                companion?.label ??
                (state.isLastStep
                    ? state.accountLinkage ==
                              LearnerAccountLinkage.parentManaged
                          ? context.l10n.parentArea
                          : context.l10n.createAccount
                    : context.l10n.continueLabel),
            onTap: companion != null
                ? companion.onTap
                : state.isSubmitting
                ? null
                : () => _handlePrimaryAction(state),
            isLoading: state.isSubmitting,
            icon:
                companion?.icon ??
                (state.isLastStep
                    ? Icons.verified_rounded
                    : Icons.arrow_forward_rounded),
          ),
        ),
      ],
    );
  }

  Future<void> _handlePrimaryAction(StudentRegistrationState state) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final formValid = switch (state.currentStep) {
      0 => _identityFormKey.currentState?.validate() ?? false,
      3 => _securityFormKey.currentState?.validate() ?? false,
      _ => true,
    };
    if (!formValid) return;

    final controller = ref.read(studentRegistrationControllerProvider.notifier);
    final validationError = controller.validateStep(state.currentStep);
    if (validationError != null) {
      setState(() => _localError = validationError);
      return;
    }

    setState(() {
      _previousStep = state.currentStep;
      _localError = null;
    });
    if (state.isLastStep) {
      if (state.accountLinkage == LearnerAccountLinkage.parentManaged) {
        context.push(AppRoutes.parentRegistration);
      } else {
        await _submit(state);
      }
    } else {
      controller.goToNextStep();
    }
  }

  Future<void> _submit(StudentRegistrationState state) async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _localError = null);
    await ref.read(studentRegistrationControllerProvider.notifier).submit();
  }

  String? _errorMessage(StudentRegistrationState state) {
    return state.errorMessage ?? _localError;
  }
}

class _StepHeading extends StatelessWidget {
  const _StepHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: passDisplay(size: 30)),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: AuthExperienceColors.textSecondary,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AuthExperienceColors.gold, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AuthExperienceColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
