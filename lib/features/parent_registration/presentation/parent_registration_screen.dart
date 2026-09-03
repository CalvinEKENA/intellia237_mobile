import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/widgets/intellia_buttons.dart';
import '../../../core/widgets/intellia_text_field.dart';
import '../../auth/presentation/widgets/auth_registration_frame.dart';
import '../../auth/domain/auth_input_validators.dart';
import '../application/parent_registration_controller.dart';
import '../../legal/presentation/legal_links.dart';
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
  final _childCodeController = TextEditingController();

  int _previousStep = 0;

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
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _childCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(parentRegistrationControllerProvider);
    final controller = ref.read(parentRegistrationControllerProvider.notifier);
    final l10n = context.l10n;

    return AuthRegistrationFrame(
      title: l10n.parentRegistrationTitle,
      currentStep: state.currentStep,
      labels: [
        l10n.parentStepIdentity,
        l10n.parentStepChildren,
        l10n.parentStepFinal,
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

  Widget _buildStepContent(ParentRegistrationState state) {
    return switch (state.currentStep) {
      0 => _buildIdentityStep(),
      1 => _buildChildrenLinkStep(state),
      2 => _buildFinalStep(state),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildIdentityStep() {
    final l10n = context.l10n;
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: l10n.parentDetailsTitle,
            subtitle: l10n.parentDetailsSubtitle,
          ),
          const SizedBox(height: IntelliaSpacing.lg),
          IntelliaTextField(
            controller: _firstNameController,
            label: l10n.firstNameLabel,
            hint: l10n.firstNameHint,
            prefixIcon: Icons.person_rounded,
            validator: (value) => AuthInputValidators.displayName(
              value ?? '',
              label: l10n.firstNameLabel,
            ),
          ),
          const SizedBox(height: IntelliaSpacing.md),
          IntelliaTextField(
            controller: _lastNameController,
            label: l10n.lastNameLabel,
            hint: l10n.lastNameHint,
            prefixIcon: Icons.badge_rounded,
            validator: (value) => AuthInputValidators.displayName(
              value ?? '',
              label: l10n.lastNameLabel,
            ),
          ),
          const SizedBox(height: IntelliaSpacing.md),
          _InfoBanner(message: l10n.phoneVerifiedNoExtraCredential),
        ],
      ),
    );
  }

  Widget _buildChildrenLinkStep(ParentRegistrationState state) {
    final controller = ref.read(parentRegistrationControllerProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: l10n.linkChildrenTitle,
          subtitle: l10n.linkChildrenSubtitle,
        ),
        const SizedBox(height: IntelliaSpacing.lg),
        IntelliaTextField(
          key: const ValueKey('parent-child-identifier-field'),
          controller: _childCodeController,
          label: l10n.childIdentifierLabel,
          hint: l10n.childIdentifierHint,
          prefixIcon: Icons.link_rounded,
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: IntelliaOutlineButton(
            key: const ValueKey('parent-add-child-action'),
            expand: false,
            onTap: () {
              if (_childCodeController.text.trim().isNotEmpty) {
                controller.addChildIdentifier(_childCodeController.text.trim());
                _childCodeController.clear();
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(l10n.addLabel),
            ),
          ),
        ),
        const SizedBox(height: IntelliaSpacing.md),
        if (state.childIdentifiers.isEmpty)
          Text(
            l10n.noLinkedChild,
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
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: l10n.finalReviewTitle,
          subtitle: l10n.finalReviewSubtitle,
        ),
        const SizedBox(height: IntelliaSpacing.lg),
        _IntelliaCheckboxTile(
          value: state.acceptedTerms,
          onChanged: (value) => controller.setAcceptedTerms(value ?? false),
          label: l10n.acceptTerms,
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        _IntelliaCheckboxTile(
          value: state.acceptedPrivacy,
          onChanged: (value) => controller.setAcceptedPrivacy(value ?? false),
          label: l10n.acceptPrivacy,
        ),
        const LegalLinks(),
        const SizedBox(height: IntelliaSpacing.lg),
        _InfoBanner(message: l10n.parentChildrenLater),
      ],
    );
  }

  Widget _buildBottomActions(ParentRegistrationState state) {
    final controller = ref.read(parentRegistrationControllerProvider.notifier);
    final l10n = context.l10n;

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
                  child: Text(l10n.previousLabel, maxLines: 1, softWrap: false),
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
                state.isLastStep ? l10n.createParentAccount : l10n.nextLabel,
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
