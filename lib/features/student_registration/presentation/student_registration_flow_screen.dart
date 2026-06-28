import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/domain/auth_input_validators.dart';
import '../../auth/presentation/widgets/auth_choices.dart';
import '../../auth/presentation/widgets/auth_controls.dart';
import '../../auth/presentation/widgets/auth_experience_scaffold.dart';
import '../../auth/presentation/widgets/auth_selection_pill.dart';
import '../../auth/presentation/widgets/auth_success_screen.dart';
import '../../tutor/domain/tutor_persona.dart';
import '../application/student_registration_controller.dart';
import '../application/student_registration_state.dart';
import '../domain/academic_rules.dart';
import 'widgets/companion_discovery.dart';

class StudentRegistrationFlowScreen extends ConsumerStatefulWidget {
  const StudentRegistrationFlowScreen({super.key});

  @override
  ConsumerState<StudentRegistrationFlowScreen> createState() =>
      _StudentRegistrationFlowScreenState();
}

class _StudentRegistrationFlowScreenState
    extends ConsumerState<StudentRegistrationFlowScreen> {
  static const _stepLabels = <String>[
    'Identité',
    'Classe',
    'Compagnon',
    'Sécurité',
  ];

  final _identityFormKey = GlobalKey<FormState>();
  final _securityFormKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _localError;
  int _previousStep = 0;

  @override
  void initState() {
    super.initState();
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
    _emailController.addListener(
      () => ref
          .read(studentRegistrationControllerProvider.notifier)
          .setEmail(_emailController.text),
    );
    _passwordController.addListener(
      () => ref
          .read(studentRegistrationControllerProvider.notifier)
          .setPassword(_passwordController.text),
    );
    _confirmPasswordController.addListener(
      () => ref
          .read(studentRegistrationControllerProvider.notifier)
          .setConfirmPassword(_confirmPasswordController.text),
    );
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
    final state = ref.watch(studentRegistrationControllerProvider);
    final controller = ref.read(studentRegistrationControllerProvider.notifier);
    final companion = TutorPersona.resolve(state.selectedTutorId);

    if (state.isCompleted) {
      return AuthSuccessScreen(
        firstName: state.firstName.trim(),
        companionName: companion.name,
        companionAsset: companion.imagePath,
        onContinue: controller.completeRegistration,
      );
    }

    return AuthExperienceScaffold(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(
            eyebrow: 'Espace élève',
            title: 'Crée ton parcours\nIntellia 237.',
            subtitle:
                'Quatre étapes rapides pour préparer ton espace personnel.',
          ),
          const SizedBox(height: 24),
          AuthStepIndicator(
            currentStep: state.currentStep,
            labels: _stepLabels,
          ),
          const SizedBox(height: 18),
          PageTransitionSwitcher(
            duration: const Duration(milliseconds: 400),
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
              child: _stepContent(state),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _errorMessage(state) == null
                ? const SizedBox(height: 18)
                : Padding(
                    key: ValueKey(_errorMessage(state)),
                    padding: const EdgeInsets.only(top: 14),
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
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _stepContent(StudentRegistrationState state) {
    return switch (state.currentStep) {
      0 => _identityStep(),
      1 => _classStep(state),
      2 => _companionStep(),
      3 => _securityStep(state),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _identityStep() {
    return Form(
      key: _identityFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _StepHeading(
            title: 'Faisons connaissance',
            subtitle:
                'Ces informations permettent de personnaliser ton espace.',
          ),
          const SizedBox(height: 18),
          AuthAnimatedField(
            controller: _firstNameController,
            label: 'Prénom',
            hint: 'Ex. Marie',
            icon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.givenName],
            validator: (value) => AuthInputValidators.displayName(
              value ?? '',
              label: 'Le prénom',
            ),
          ),
          const SizedBox(height: 14),
          AuthAnimatedField(
            controller: _lastNameController,
            label: 'Nom',
            hint: 'Ex. Ndi',
            icon: Icons.badge_outlined,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.familyName],
            validator: (value) =>
                AuthInputValidators.displayName(value ?? '', label: 'Le nom'),
          ),
        ],
      ),
    );
  }

  Widget _classStep(StudentRegistrationState state) {
    final controller = ref.read(studentRegistrationControllerProvider.notifier);
    final selectedClass = state.schoolClass;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepHeading(
          title: 'Où en es-tu ?',
          subtitle:
              'Choisis ta classe. La série apparaît uniquement si nécessaire.',
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final schoolClass in SchoolClassX.ordered)
              AuthSelectionPill(
                label: schoolClass.label,
                selected: selectedClass == schoolClass,
                onTap: () => controller.setSchoolClass(schoolClass),
              ),
          ],
        ),
        if (selectedClass?.requiresSeries ?? false) ...[
          const SizedBox(height: 22),
          const Text(
            'Série',
            style: TextStyle(
              color: Colors.white,
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
      ],
    );
  }

  Widget _companionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        _StepHeading(
          title: 'Rencontre ton compagnon',
          subtitle:
              'Découvre Kira, puis Léo. Tu choisiras une fois que tu les auras vus.',
        ),
        SizedBox(height: 12),
        CompanionDiscovery(),
      ],
    );
  }

  Widget _securityStep(StudentRegistrationState state) {
    final controller = ref.read(studentRegistrationControllerProvider.notifier);
    final companion = TutorPersona.resolve(state.selectedTutorId);
    return Form(
      key: _securityFormKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _StepHeading(
              title: 'Sécurise ton compte',
              subtitle: 'Vérifie le résumé puis crée réellement ton espace.',
            ),
            const SizedBox(height: 18),
            AuthAnimatedField(
              controller: _emailController,
              label: 'Adresse e-mail',
              hint: 'prenom.nom@exemple.com',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newUsername],
              validator: (value) => AuthInputValidators.email(value ?? ''),
            ),
            const SizedBox(height: 14),
            AuthAnimatedField(
              controller: _passwordController,
              label: 'Mot de passe',
              hint: '8 caractères minimum',
              icon: Icons.lock_outline_rounded,
              isPassword: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: (value) => AuthInputValidators.password(value ?? ''),
            ),
            const SizedBox(height: 14),
            AuthAnimatedField(
              controller: _confirmPasswordController,
              label: 'Confirmer le mot de passe',
              hint: 'Retape le même mot de passe',
              icon: Icons.verified_user_outlined,
              isPassword: true,
              textInputAction: TextInputAction.done,
              validator: (value) => AuthInputValidators.confirmPassword(
                password: _passwordController.text,
                confirmation: value ?? '',
              ),
              onFieldSubmitted: (_) => _handlePrimaryAction(state),
            ),
            const SizedBox(height: 18),
            _SummaryRow(
              icon: Icons.school_outlined,
              label: state.schoolClass?.label ?? 'Classe à confirmer',
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              icon: Icons.auto_awesome_rounded,
              label: 'Compagnon : ${companion.name}',
            ),
            const SizedBox(height: 16),
            AuthConsentTile(
              value: state.acceptedTerms,
              label: 'J’accepte les conditions d’utilisation.',
              onChanged: controller.setAcceptedTerms,
            ),
            AuthConsentTile(
              value: state.acceptedPrivacy,
              label: 'J’accepte la politique de confidentialité.',
              onChanged: controller.setAcceptedPrivacy,
            ),
            AuthConsentTile(
              value: state.acceptedDataPolicy,
              label: 'J’accepte le traitement pédagogique des données.',
              onChanged: controller.setAcceptedDataPolicy,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actions(StudentRegistrationState state) {
    // CTA « Continuer » actif uniquement après un vrai choix de compagnon.
    final blockCompanion =
        state.currentStep == 2 && state.selectedTutorId == null;
    return Row(
      children: [
        if (!state.isFirstStep) ...[
          IconButton(
            tooltip: 'Étape précédente',
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
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: AuthPrimaryButton(
            label: state.isLastStep ? 'Créer mon compte' : 'Continuer',
            onTap: (state.isSubmitting || blockCompanion)
                ? null
                : () => _handlePrimaryAction(state),
            isLoading: state.isSubmitting,
            icon: state.isLastStep
                ? Icons.verified_rounded
                : Icons.arrow_forward_rounded,
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
      await _submit(state);
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
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
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
    ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.04, end: 0);
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
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
