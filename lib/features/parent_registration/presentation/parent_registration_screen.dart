import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_role.dart';
import '../../auth/presentation/widgets/auth_controls.dart';
import '../../auth/presentation/widgets/auth_experience_scaffold.dart';
import '../../auth/presentation/widgets/auth_registration_frame.dart';
import '../../auth/presentation/widgets/living_pass.dart';
import '../../auth/presentation/widgets/pass_auth_progress.dart';
import '../../auth/domain/auth_input_validators.dart';
import '../application/parent_registration_controller.dart';
import '../../legal/presentation/legal_links.dart';
import '../../parent/application/pending_child_link.dart';
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
    final draft = ref.read(parentRegistrationControllerProvider);
    // Le code enfant saisi à l'entrée figure déjà parmi les enfants à relier.
    // Ajouté après la première image : un provider ne se modifie pas pendant
    // la construction de l'arbre, et la liste n'apparaît qu'à l'étape 2.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pendingCode = ref.read(pendingChildLinkProvider).code;
      if (pendingCode == null) return;
      ref
          .read(parentRegistrationControllerProvider.notifier)
          .addChildIdentifier(pendingCode);
    });
    _firstNameController.text = draft.firstName;
    _lastNameController.text = draft.lastName;
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
    final labels = [
      l10n.parentStepIdentity,
      l10n.parentStepChildren,
      l10n.parentStepFinal,
    ];

    return AuthRegistrationFrame(
      title: l10n.parentRegistrationTitle,
      pass: LivingPass(
        key: const ValueKey('parent-living-pass'),
        role: AppRole.parent,
        name: state.firstName.trim(),
        detail: state.childIdentifiers.isEmpty
            ? context.l10n.passYourFamilySpace
            : context.l10n.passChildIdentifiersAdded(
                state.childIdentifiers.length,
              ),
        phase: labels[state.currentStep],
        progress: PassAuthProgress.registrationLine(
          step: state.currentStep,
          steps: labels.length,
        ),
        // Le sceau dit la session réellement établie, pas l'étape du
        // formulaire.
        seal: PassAuthProgress.session(ref.watch(authControllerProvider)),
      ),
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
      onRetry: state.isLastStep ? () => controller.submit() : null,
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
          AuthAnimatedField(
            controller: _firstNameController,
            label: l10n.firstNameLabel,
            hint: l10n.firstNameHint,
            icon: Icons.person_outline_rounded,
            autofillHints: const [AutofillHints.givenName],
            textInputAction: TextInputAction.next,
            validator: (value) => AuthInputValidators.displayName(
              value ?? '',
              label: l10n.firstNameLabel,
            ),
          ),
          const SizedBox(height: IntelliaSpacing.md),
          AuthAnimatedField(
            controller: _lastNameController,
            label: l10n.lastNameLabel,
            hint: l10n.lastNameHint,
            icon: Icons.badge_outlined,
            autofillHints: const [AutofillHints.familyName],
            textInputAction: TextInputAction.done,
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
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: l10n.linkChildrenTitle,
          subtitle: l10n.linkChildrenSubtitle,
        ),
        const SizedBox(height: IntelliaSpacing.lg),
        AuthAnimatedField(
          key: const ValueKey('parent-child-identifier-field'),
          controller: _childCodeController,
          label: l10n.childIdentifierLabel,
          hint: l10n.childIdentifierHint,
          icon: Icons.link_rounded,
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton(
            key: const ValueKey('parent-add-child-action'),
            onPressed: () {
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
            style: const TextStyle(
              fontSize: 14,
              color: AuthExperienceColors.textSecondary,
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
                  selectedColor: AuthExperienceColors.indigo,
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
        AuthConsentTile(
          value: state.acceptedTerms,
          onChanged: controller.setAcceptedTerms,
          label: l10n.acceptTerms,
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        AuthConsentTile(
          value: state.acceptedPrivacy,
          onChanged: controller.setAcceptedPrivacy,
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
                ? context.l10n.createParentAccount
                : context.l10n.nextLabel,
          ),
        ),
      ],
    );
  }

  Future<void> _onPrimaryAction(ParentRegistrationState state) async {
    FocusManager.instance.primaryFocus?.unfocus();
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
