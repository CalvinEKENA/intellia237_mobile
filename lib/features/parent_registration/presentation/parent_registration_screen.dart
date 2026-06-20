import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/widgets/intellia_scaffold.dart';
import '../../../core/widgets/intellia_buttons.dart';
import '../../../core/widgets/intellia_text_field.dart';
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

  int _previousStep = 0;

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
              content: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: IntelliaSpacing.sm),
                  Expanded(child: Text(next.errorMessage!)),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(IntelliaRadii.small),
              ),
              margin: const EdgeInsets.all(IntelliaSpacing.md),
            ),
          );
      }
    });

    return IntelliaScaffold(
      usePremiumBackground: true,
      showTopHalo: true,
      appBar: AppBar(
        leading: IntelliaIconButton(
          icon: Icons.arrow_back_rounded,
          backgroundColor: Colors.transparent,
          onTap: state.currentStep == 0
              ? () => context.pop()
              : () {
                  setState(() {
                    _previousStep = state.currentStep;
                  });
                  controller.previousStep();
                },
        ),
        title: const Text('Inscription Parent'),
      ),
      body: Column(
        children: [
          // ── Stepper ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: IntelliaSpacing.xl),
            child: PremiumStepper(
              currentStep: state.currentStep,
              labels: _stepLabels,
            ),
          ),
          const SizedBox(height: IntelliaSpacing.md),

          // ── Step content ──────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: IntelliaMotion.cinematic,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                final isForward = state.currentStep >= _previousStep;
                final slideIn = Tween<Offset>(
                  begin: Offset(isForward ? 1.0 : -1.0, 0),
                  end: Offset.zero,
                ).animate(animation);
                final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: const Interval(0.3, 1.0),
                  ),
                );
                return FadeTransition(
                  opacity: fadeIn,
                  child: SlideTransition(position: slideIn, child: child),
                );
              },
              child: _GlassStepPanel(
                key: ValueKey(state.currentStep),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    IntelliaSpacing.xl,
                    IntelliaSpacing.md,
                    IntelliaSpacing.xl,
                    IntelliaSpacing.xs,
                  ),
                  child: _buildStepContent(state),
                ),
              ),
            ),
          ),

          // ── Bottom actions ────────────────────────────────
          _buildBottomActions(state),
        ],
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
            title: 'Coordonnées du parent',
            subtitle:
                'Renseignez votre identité, email et téléphone (optionnel).',
          ),
          const SizedBox(height: IntelliaSpacing.lg),
          IntelliaTextField(
            controller: _firstNameController,
            label: 'Prénom',
            hint: 'Ex: Clarisse',
            prefixIcon: Icons.person_rounded,
            validator: (value) =>
                (value ?? '').trim().length < 2 ? 'Minimum 2 caractères' : null,
          ),
          const SizedBox(height: IntelliaSpacing.md),
          IntelliaTextField(
            controller: _lastNameController,
            label: 'Nom',
            hint: 'Ex: Ndzi',
            prefixIcon: Icons.badge_rounded,
            validator: (value) =>
                (value ?? '').trim().length < 2 ? 'Minimum 2 caractères' : null,
          ),
          const SizedBox(height: IntelliaSpacing.md),
          IntelliaTextField(
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
          const SizedBox(height: IntelliaSpacing.md),
          IntelliaTextField(
            controller: _phoneController,
            label: 'Téléphone (optionnel)',
            hint: '+2376...',
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_rounded,
          ),
          const SizedBox(height: IntelliaSpacing.md),
          IntelliaPasswordField(
            controller: _passwordController,
            label: 'Mot de passe',
            hint: '8 caractères minimum',
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
          const SizedBox(height: IntelliaSpacing.md),
          IntelliaPasswordField(
            controller: _confirmPasswordController,
            label: 'Confirmer le mot de passe',
            hint: 'Retapez le mot de passe',
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
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Lier vos enfants',
          subtitle:
              'Ajoutez un ou plusieurs identifiants élève (code de liaison).',
        ),
        const SizedBox(height: IntelliaSpacing.lg),
        Row(
          children: [
            Expanded(
              child: IntelliaTextField(
                controller: _childCodeController,
                label: 'Code / Identifiant enfant',
                hint: 'Ex: STU-94K2',
                prefixIcon: Icons.link_rounded,
              ),
            ),
            const SizedBox(width: IntelliaSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: SizedBox(
                height: 52,
                child: IntelliaOutlineButton(
                  onTap: () {
                    if (_childCodeController.text.trim().isNotEmpty) {
                      controller.addChildIdentifier(
                        _childCodeController.text.trim(),
                      );
                      _childCodeController.clear();
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('Ajouter'),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: IntelliaSpacing.md),
        if (state.childIdentifiers.isEmpty)
          Text(
            'Aucun enfant lié pour le moment.',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? IntelliaColors.textSecondaryDark
                  : IntelliaColors.textSecondary,
            ),
          )
        else
          Wrap(
            spacing: IntelliaSpacing.xs,
            runSpacing: IntelliaSpacing.xs,
            children: [
              for (final childId in state.childIdentifiers)
                InputChip(
                  label: Text(childId),
                  selected: true,
                  onDeleted: () => controller.removeChildIdentifier(childId),
                  deleteIconColor: Colors.white,
                  selectedColor: IntelliaColors.brandIndigo,
                  labelStyle: const TextStyle(color: Colors.white),
                  checkmarkColor: Colors.white,
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
        const SizedBox(height: IntelliaSpacing.lg),
        _IntelliaCheckboxTile(
          value: state.acceptedTerms,
          onChanged: (value) => controller.setAcceptedTerms(value ?? false),
          label: 'J\'accepte les conditions d\'utilisation.',
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        _IntelliaCheckboxTile(
          value: state.acceptedPrivacy,
          onChanged: (value) => controller.setAcceptedPrivacy(value ?? false),
          label: 'J\'accepte la politique de confidentialité.',
        ),
        const SizedBox(height: IntelliaSpacing.lg),
        const _InfoBanner(
          message:
              'Vous pourrez également lier ou modifier vos enfants après la création de votre compte.',
        ),
      ],
    );
  }

  Widget _buildBottomActions(ParentRegistrationState state) {
    final controller = ref.read(parentRegistrationControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        IntelliaSpacing.xl,
        IntelliaSpacing.sm,
        IntelliaSpacing.xl,
        IntelliaSpacing.xl,
      ),
      child: Row(
        children: [
          if (!state.isFirstStep)
            Expanded(
              child: IntelliaOutlineButton(
                onTap: state.isSubmitting
                    ? null
                    : () {
                        setState(() {
                          _previousStep = state.currentStep;
                        });
                        controller.previousStep();
                      },
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Précédent', maxLines: 1, softWrap: false),
                ),
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: IntelliaSpacing.sm),
          Expanded(
            flex: 2,
            child: IntelliaPrimaryButton(
              onTap: state.isSubmitting ? null : () => _onPrimaryAction(state),
              isLoading: state.isSubmitting,
              child: Text(
                state.isLastStep ? 'Créer mon compte parent' : 'Suivant',
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: IntelliaMotion.medium);
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
      await controller.submit();
      return;
    }

    setState(() {
      _previousStep = state.currentStep;
    });
    controller.nextStep();
  }
}

class _GlassStepPanel extends StatelessWidget {
  const _GlassStepPanel({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? IntelliaColors.surfaceSolidDark
            : IntelliaColors.surfaceSolid,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(IntelliaRadii.large),
        ),
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline, width: 0.8),
          left: BorderSide(color: theme.colorScheme.outline, width: 0.8),
          right: BorderSide(color: theme.colorScheme.outline, width: 0.8),
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
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: IntelliaTypography.title2(
            brightness: theme.brightness,
          ).copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: IntelliaSpacing.xxs),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? IntelliaColors.textSecondaryDark
                : IntelliaColors.textSecondary,
            height: 1.4,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(IntelliaSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(IntelliaRadii.small),
        color: isDark
            ? IntelliaColors.backgroundSecondaryDark
            : IntelliaColors.backgroundSecondary,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 13,
          color: isDark
              ? IntelliaColors.textSecondaryDark
              : IntelliaColors.textSecondary,
        ),
      ),
    );
  }
}

class _IntelliaCheckboxTile extends StatelessWidget {
  const _IntelliaCheckboxTile({
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: IntelliaMotion.fast,
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: value ? IntelliaGradients.brand : null,
              color: value ? null : Colors.transparent,
              border: Border.all(
                color: value
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
                width: value ? 0 : 1.5,
              ),
            ),
            child: value
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: IntelliaSpacing.md),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? IntelliaColors.textSecondaryDark
                    : IntelliaColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
