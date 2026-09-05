import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/widgets/intellia_buttons.dart';
import '../../../core/widgets/intellia_text_field.dart';
import '../../auth/domain/auth_input_validators.dart';
import '../../auth/presentation/widgets/auth_registration_frame.dart';
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

    return AuthRegistrationFrame(
      title: l10n.teacherRegistrationTitle,
      currentStep: state.currentStep,
      labels: [
        l10n.teacherIdentityStep,
        l10n.teachingStep,
        l10n.finalReviewTitle,
      ],
      onBack: state.currentStep == 0
          ? () => context.pop()
          : () {
              setState(() => _previousStep = state.currentStep);
              controller.previousStep();
            },
      errorMessage: state.errorMessage,
      onDismissError: controller.clearError,
      onRetry: state.isLastStep ? () => controller.submit() : null,
      content: AnimatedSwitcher(
        duration: IntelliaMotion.cinematic,
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
        child: _GlassStepPanel(
          key: ValueKey(state.currentStep),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
          IntelliaTextField(
            controller: _firstNameController,
            label: context.l10n.firstNameLabel,
            hint: context.l10n.firstNameTeacherHint,
            prefixIcon: Icons.person_rounded,
            validator: (value) => AuthInputValidators.displayName(
              value ?? '',
              label: context.l10n.firstNameWithArticle,
            ),
          ),
          const SizedBox(height: IntelliaSpacing.md),
          IntelliaTextField(
            controller: _lastNameController,
            label: context.l10n.lastNameLabel,
            hint: context.l10n.lastNameTeacherHint,
            prefixIcon: Icons.badge_rounded,
            validator: (value) => AuthInputValidators.displayName(
              value ?? '',
              label: context.l10n.lastNameWithArticle,
            ),
          ),
          const SizedBox(height: IntelliaSpacing.md),
          IntelliaTextField(
            controller: _emailController,
            label: context.l10n.emailLabel,
            hint: context.l10n.teacherEmailHint,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_rounded,
            validator: (value) => AuthInputValidators.email(value ?? ''),
          ),
          const SizedBox(height: IntelliaSpacing.md),
          IntelliaPasswordField(
            controller: _passwordController,
            label: context.l10n.passwordLabel,
            hint: context.l10n.passwordMinEight,
            validator: (value) => AuthInputValidators.password(value ?? ''),
          ),
          const SizedBox(height: IntelliaSpacing.md),
          IntelliaPasswordField(
            controller: _confirmPasswordController,
            label: context.l10n.confirmPasswordLabel,
            hint: context.l10n.confirmPasswordHint,
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
        _IntelliaCheckboxTile(
          value: state.acceptedTerms,
          onChanged: (value) => controller.setAcceptedTerms(value ?? false),
          label: context.l10n.acceptTerms,
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        _IntelliaCheckboxTile(
          value: state.acceptedPrivacy,
          onChanged: (value) => controller.setAcceptedPrivacy(value ?? false),
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
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    context.l10n.previousLabel,
                    maxLines: 1,
                    softWrap: false,
                  ),
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
                state.isLastStep
                    ? context.l10n.createTeacherAccount
                    : context.l10n.nextLabel,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: IntelliaMotion.medium);
  }

  Future<void> _onPrimaryAction(TeacherRegistrationState state) async {
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
