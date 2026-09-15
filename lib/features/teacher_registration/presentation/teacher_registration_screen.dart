import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../auth/domain/app_role.dart';
import '../../auth/presentation/widgets/auth_controls.dart';
import '../../auth/presentation/widgets/auth_experience_scaffold.dart';
import '../../auth/domain/auth_input_validators.dart';
import '../../auth/presentation/widgets/auth_registration_frame.dart';
import '../../auth/presentation/widgets/living_pass.dart';
import '../../auth/presentation/widgets/pass_auth_progress.dart';
import '../../role_registration/domain/teacher_catalogs.dart';
import '../../student_registration/presentation/widgets/subject_multi_selector.dart';
import '../application/teacher_registration_controller.dart';
import '../../legal/presentation/legal_links.dart';
import '../application/teacher_registration_state.dart';

class TeacherRegistrationScreen extends ConsumerStatefulWidget {
  const TeacherRegistrationScreen({super.key});

  @override
  ConsumerState<TeacherRegistrationScreen> createState() =>
      _TeacherRegistrationScreenState();
}

class _TeacherRegistrationScreenState
    extends ConsumerState<TeacherRegistrationScreen> {
  final _step1FormKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _previousStep = 0;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(teacherRegistrationControllerProvider);
    _firstNameController.text = draft.firstName;
    _lastNameController.text = draft.lastName;
    _emailController.text = draft.email;
    _passwordController.text = draft.password;
    _confirmPasswordController.text = draft.confirmPassword;
    _firstNameController.addListener(() {
      ref
          .read(teacherRegistrationControllerProvider.notifier)
          .setFirstName(_firstNameController.text);
    });
    _lastNameController.addListener(() {
      ref
          .read(teacherRegistrationControllerProvider.notifier)
          .setLastName(_lastNameController.text);
    });
    _emailController.addListener(() {
      ref
          .read(teacherRegistrationControllerProvider.notifier)
          .setEmail(_emailController.text);
    });
    _passwordController.addListener(() {
      ref
          .read(teacherRegistrationControllerProvider.notifier)
          .setPassword(_passwordController.text);
    });
    _confirmPasswordController.addListener(() {
      ref
          .read(teacherRegistrationControllerProvider.notifier)
          .setConfirmPassword(_confirmPasswordController.text);
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teacherRegistrationControllerProvider);
    final controller = ref.read(teacherRegistrationControllerProvider.notifier);
    final l10n = context.l10n;
    final labels = [
      l10n.teacherIdentityStep,
      l10n.teachingStep,
      l10n.finalReviewTitle,
    ];
    final pass = LivingPass(
      key: const ValueKey('teacher-living-pass'),
      role: AppRole.teacher,
      name: state.firstName.trim(),
      detail: state.subjects.isEmpty
          ? context.l10n.passYourTeachingSpace
          : [
              state.subjects.join(' · '),
              if (state.levels.isNotEmpty) state.levels.join(' · '),
            ].join(' / '),
      phase: state.awaitsValidation
          ? context.l10n.passValidationPending
          : labels[state.currentStep],
      progress: state.accountCreated
          ? PassAuthProgress.complete
          : PassAuthProgress.registrationLine(
              step: state.currentStep,
              steps: labels.length,
            ),
      // Registre de décisions (QA appareil, round 3) : le sceau suivait les
      // étapes du formulaire (0,20 · 0,54 · 0,88 · 0,94), jamais un chiffre
      // plein. Il suit désormais les identifiants saisis, puis le compte créé.
      seal: PassAuthProgress.accountCreation(
        email: state.email,
        password: state.password,
        confirmation: state.confirmPassword,
        accountOpened: state.accountCreated,
      ),
    );

    if (state.awaitsValidation) {
      // The router still opens the teacher's actual space immediately. This
      // truthful frame also covers the instant between saving and redirecting.
      return AuthExperienceScaffold(
        showBackButton: false,
        pass: pass,
        child: Semantics(
          liveRegion: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.passAccountCreated,
                style: passDisplay(size: 48),
              ),
              const SizedBox(height: 16),
              _InfoBanner(message: l10n.teacherValidationNotice),
            ],
          ),
        ),
      );
    }

    return AuthRegistrationFrame(
      title: l10n.teacherRegistrationTitle,
      pass: pass,
      currentStep: state.currentStep,
      labels: labels,
      onBack: state.currentStep == 0
          ? () => context.pop()
          : () {
              FocusManager.instance.primaryFocus?.unfocus();
              setState(() => _previousStep = state.currentStep);
              controller.previousStep();
            },
      errorMessage: state.errorMessage,
      onDismissError: controller.clearError,
      onRetry: state.isLastStep
          ? () => controller.submit(beforeOpening: _holdCompletedSeal)
          : null,
      content: AnimatedSwitcher(
        duration: MediaQuery.of(context).disableAnimations
            ? Duration.zero
            : IntelliaMotion.cinematic,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          final isForward = state.currentStep >= _previousStep;
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(isForward ? 0.12 : -0.12, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: AuthGlassPanel(
          key: ValueKey(state.currentStep),
          padding: const EdgeInsets.all(18),
          child: _buildStepContent(state),
        ),
      ),
      actions: _buildBottomActions(state),
    );
  }

  Widget _buildStepContent(TeacherRegistrationState state) {
    return switch (state.currentStep) {
      0 => _buildIdentityStep(),
      1 => _buildTeachingStep(state),
      2 => _buildFinalStep(state),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildIdentityStep() {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: context.l10n.teacherDetailsTitle,
            subtitle: context.l10n.teacherDetailsSubtitle,
          ),
          const SizedBox(height: IntelliaSpacing.lg),
          AuthAnimatedField(
            controller: _firstNameController,
            label: context.l10n.firstNameLabel,
            hint: context.l10n.firstNameTeacherHint,
            icon: Icons.person_outline_rounded,
            autofillHints: const [AutofillHints.givenName],
            textInputAction: TextInputAction.next,
            validator: (value) => AuthInputValidators.displayName(
              value ?? '',
              label: context.l10n.firstNameWithArticle,
            ),
          ),
          const SizedBox(height: IntelliaSpacing.md),
          AuthAnimatedField(
            controller: _lastNameController,
            label: context.l10n.lastNameLabel,
            hint: context.l10n.lastNameTeacherHint,
            icon: Icons.badge_outlined,
            autofillHints: const [AutofillHints.familyName],
            textInputAction: TextInputAction.next,
            validator: (value) => AuthInputValidators.displayName(
              value ?? '',
              label: context.l10n.lastNameWithArticle,
            ),
          ),
          const SizedBox(height: IntelliaSpacing.md),
          AuthAnimatedField(
            controller: _emailController,
            label: context.l10n.emailLabel,
            hint: context.l10n.teacherEmailHint,
            keyboardType: TextInputType.emailAddress,
            icon: Icons.email_outlined,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            validator: (value) => AuthInputValidators.email(value ?? ''),
          ),
          const SizedBox(height: IntelliaSpacing.md),
          AuthAnimatedField(
            controller: _passwordController,
            label: context.l10n.passwordLabel,
            hint: context.l10n.passwordMinEight,
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
            validator: (value) => AuthInputValidators.password(value ?? ''),
          ),
          const SizedBox(height: IntelliaSpacing.md),
          AuthAnimatedField(
            controller: _confirmPasswordController,
            label: context.l10n.confirmPasswordLabel,
            hint: context.l10n.confirmPasswordHint,
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            textInputAction: TextInputAction.done,
            validator: (value) => AuthInputValidators.confirmPassword(
              password: _passwordController.text,
              confirmation: value ?? '',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeachingStep(TeacherRegistrationState state) {
    final controller = ref.read(teacherRegistrationControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: context.l10n.teachingTitle,
          subtitle: context.l10n.teachingSubtitle,
        ),
        const SizedBox(height: IntelliaSpacing.lg),
        SubjectMultiSelector(
          title: context.l10n.taughtSubjectsTitle,
          caption: context.l10n.taughtSubjectsCaption,
          options: TeacherCatalogs.subjects,
          selected: state.subjects,
          onToggle: controller.toggleSubject,
        ),
        const SizedBox(height: IntelliaSpacing.lg),
        SubjectMultiSelector(
          title: context.l10n.taughtLevelsTitle,
          caption: context.l10n.taughtLevelsCaption,
          options: TeacherCatalogs.levels,
          selected: state.levels,
          onToggle: controller.toggleLevel,
        ),
      ],
    );
  }

  Widget _buildFinalStep(TeacherRegistrationState state) {
    final controller = ref.read(teacherRegistrationControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: context.l10n.finalReviewTitle,
          subtitle: context.l10n.teacherFinalSubtitle,
        ),
        const SizedBox(height: IntelliaSpacing.lg),
        AuthConsentTile(
          value: state.acceptedTerms,
          onChanged: controller.setAcceptedTerms,
          label: context.l10n.acceptTerms,
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        AuthConsentTile(
          value: state.acceptedPrivacy,
          onChanged: controller.setAcceptedPrivacy,
          label: context.l10n.acceptPrivacy,
        ),
        const LegalLinks(),
        const SizedBox(height: IntelliaSpacing.lg),
        _InfoBanner(message: context.l10n.teacherValidationNotice),
      ],
    );
  }

  Widget _buildBottomActions(TeacherRegistrationState state) {
    final controller = ref.read(teacherRegistrationControllerProvider.notifier);
    return Row(
      children: [
        if (!state.isFirstStep) ...[
          IconButton(
            tooltip: context.l10n.previousLabel,
            onPressed: state.isSubmitting
                ? null
                : () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    setState(() => _previousStep = state.currentStep);
                    controller.previousStep();
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
            onTap: state.isSubmitting ? null : () => _onPrimaryAction(state),
            isLoading: state.isSubmitting,
            label: state.isLastStep
                ? context.l10n.createTeacherAccount
                : context.l10n.nextLabel,
          ),
        ),
      ],
    );
  }

  /// Le compte existe : « 7 » est allumé et reste à l'écran avant que
  /// l'espace enseignant ne s'ouvre.
  Future<void> _holdCompletedSeal() =>
      Future<void>.delayed(PassSealTiming.completionHold);

  Future<void> _onPrimaryAction(TeacherRegistrationState state) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final controller = ref.read(teacherRegistrationControllerProvider.notifier);

    final isValidForm = switch (state.currentStep) {
      0 => _step1FormKey.currentState?.validate() ?? false,
      _ => true,
    };
    if (!isValidForm) return;

    final stepError = controller.validateStep(state.currentStep);
    if (stepError != null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(stepError),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(IntelliaRadii.small),
            ),
            margin: const EdgeInsets.all(IntelliaSpacing.md),
          ),
        );
      return;
    }

    if (state.isLastStep) {
      await controller.submit(beforeOpening: _holdCompletedSeal);
      return;
    }

    setState(() {
      _previousStep = state.currentStep;
    });
    controller.nextStep();
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: passDisplay(size: 34)),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: AuthExperienceColors.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuthExperienceColors.surfaceSoft,
        border: const Border(
          left: BorderSide(color: AuthExperienceColors.gold, width: 2),
        ),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 13,
          height: 1.45,
          color: AuthExperienceColors.textSecondary,
        ),
      ),
    );
  }
}
