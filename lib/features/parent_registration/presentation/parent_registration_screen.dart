import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/design_tokens.dart';
import '../../auth/presentation/widgets/auth_text_field.dart';
import '../../student_registration/presentation/widgets/premium_stepper.dart';
import '../application/parent_registration_controller.dart';
import '../application/parent_registration_state.dart';

class ParentRegistrationScreen extends ConsumerStatefulWidget {
  const ParentRegistrationScreen({super.key});

  @override
  ConsumerState<ParentRegistrationScreen> createState() =>
      _ParentRegistrationScreenState();
}

class _ParentRegistrationScreenState
    extends ConsumerState<ParentRegistrationScreen> {
  final _step1FormKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _childCodeController = TextEditingController();

  static const _stepLabels = <String>[
    'Identité parent',
    'Liaison enfants',
    'Validation finale',
  ];

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(() {
      ref
          .read(parentRegistrationControllerProvider.notifier)
          .setFirstName(_firstNameController.text);
    });
    _lastNameController.addListener(() {
      ref
          .read(parentRegistrationControllerProvider.notifier)
          .setLastName(_lastNameController.text);
    });
    _emailController.addListener(() {
      ref
          .read(parentRegistrationControllerProvider.notifier)
          .setEmail(_emailController.text);
    });
    _phoneController.addListener(() {
      ref
          .read(parentRegistrationControllerProvider.notifier)
          .setPhoneNumber(_phoneController.text);
    });
    _passwordController.addListener(() {
      ref
          .read(parentRegistrationControllerProvider.notifier)
          .setPassword(_passwordController.text);
    });
    _confirmPasswordController.addListener(() {
      ref
          .read(parentRegistrationControllerProvider.notifier)
          .setConfirmPassword(_confirmPasswordController.text);
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _childCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(parentRegistrationControllerProvider);
    final controller = ref.read(parentRegistrationControllerProvider.notifier);
    final theme = Theme.of(context);

    ref.listen<ParentRegistrationState>(parentRegistrationControllerProvider, (
      previous,
      next,
    ) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.backgroundFor(Theme.of(context).brightness),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: state.currentStep == 0
                          ? () => context.pop()
                          : controller.previousStep,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Text(
                        'Inscription Parent',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: PremiumStepper(
                  currentStep: state.currentStep,
                  labels: _stepLabels,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppMotion.medium,
                  switchInCurve: AppMotion.emphasizedDecelerate,
                  child: _BodyContainer(
                    key: ValueKey(state.currentStep),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: _buildStepContent(state),
                    ),
                  ),
                ),
              ),
              _buildBottomActions(state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(ParentRegistrationState state) {
    return switch (state.currentStep) {
      0 => _buildIdentityStep(),
      1 => _buildChildrenLinkStep(state),
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
          const _SectionHeader(
            title: 'Coordonnees du parent',
            subtitle:
                'Renseignez votre identité, email et téléphone (optionnel).',
          ),
          const SizedBox(height: AppSpacing.lg),
          AuthTextField(
            controller: _firstNameController,
            label: 'Prénom',
            hint: 'Ex: Clarisse',
            prefixIcon: Icons.person_rounded,
            validator: (value) =>
                (value ?? '').trim().length < 2 ? 'Minimum 2 caractères' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AuthTextField(
            controller: _lastNameController,
            label: 'Nom',
            hint: 'Ex: Ndzi',
            prefixIcon: Icons.badge_rounded,
            validator: (value) =>
                (value ?? '').trim().length < 2 ? 'Minimum 2 caractères' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AuthTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'parent@exemple.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_rounded,
            validator: (value) {
              if (!RegExp(
                r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$',
              ).hasMatch((value ?? '').trim())) {
                return 'Email invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AuthTextField(
            controller: _phoneController,
            label: 'Téléphone (optionnel)',
            hint: '+2376...',
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          AuthTextField(
            controller: _passwordController,
            label: 'Mot de passe',
            hint: '8 caractères minimum',
            obscureText: true,
            prefixIcon: Icons.lock_rounded,
            validator: (value) {
              final password = value ?? '';
              final valid =
                  password.length >= 8 &&
                  RegExp(r'[A-Z]').hasMatch(password) &&
                  RegExp(r'[0-9]').hasMatch(password);
              return valid
                  ? null
                  : '8 caractères, 1 majuscule, 1 chiffre minimum';
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AuthTextField(
            controller: _confirmPasswordController,
            label: 'Confirmer le mot de passe',
            hint: 'Retapez le mot de passe',
            obscureText: true,
            prefixIcon: Icons.verified_user_rounded,
            validator: (value) => value == _passwordController.text
                ? null
                : 'Confirmation invalide',
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenLinkStep(ParentRegistrationState state) {
    final controller = ref.read(parentRegistrationControllerProvider.notifier);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Lier vos enfants',
          subtitle:
              'Ajoutez un ou plusieurs identifiants eleve (code de liaison).',
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _childCodeController,
                decoration: const InputDecoration(
                  labelText: 'Code / Identifiant enfant',
                  hintText: 'Ex: STU-94K2',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton.tonal(
              onPressed: () {
                controller.addChildIdentifier(_childCodeController.text);
                _childCodeController.clear();
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.childIdentifiers.isEmpty)
          Text(
            'Aucun enfant lie pour le moment.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
          )
        else
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final childId in state.childIdentifiers)
                InputChip(
                  label: Text(childId),
                  selected: true,
                  onDeleted: () => controller.removeChildIdentifier(childId),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildFinalStep(ParentRegistrationState state) {
    final controller = ref.read(parentRegistrationControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Validation finale',
          subtitle:
              'Relisez vos informations et acceptez les consentements requis.',
        ),
        const SizedBox(height: AppSpacing.lg),
        CheckboxListTile(
          value: state.acceptedTerms,
          onChanged: (value) => controller.setAcceptedTerms(value ?? false),
          contentPadding: EdgeInsets.zero,
          title: const Text('J\'accepte les conditions d\'utilisation.'),
        ),
        CheckboxListTile(
          value: state.acceptedPrivacy,
          onChanged: (value) => controller.setAcceptedPrivacy(value ?? false),
          contentPadding: EdgeInsets.zero,
          title: const Text('J\'accepte la politique de confidentialité.'),
        ),
        const SizedBox(height: AppSpacing.sm),
        const _InfoBanner(
          message:
              'Vous pourrez lier vos enfants après la création de votre compte.',
        ),
      ],
    );
  }

  Widget _buildBottomActions(ParentRegistrationState state) {
    final controller = ref.read(parentRegistrationControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Row(
        children: [
          if (!state.isFirstStep)
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                ),
                onPressed: state.isSubmitting ? null : controller.previousStep,
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Précédent', maxLines: 1, softWrap: false),
                ),
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: state.isSubmitting
                  ? null
                  : () => _onPrimaryAction(state),
              child: state.isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      state.isLastStep ? 'Créer mon compte parent' : 'Suivant',
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onPrimaryAction(ParentRegistrationState state) async {
    final controller = ref.read(parentRegistrationControllerProvider.notifier);

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
          ),
        );
      return;
    }

    if (state.isLastStep) {
      await controller.submit();
      return;
    }

    controller.nextStep();
  }
}

class _BodyContainer extends StatelessWidget {
  const _BodyContainer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.88),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(message),
    );
  }
}
