import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/widgets/intellia_scaffold.dart';
import '../../../core/widgets/intellia_buttons.dart';
import '../../../core/widgets/intellia_text_field.dart';
import '../../tutor/domain/tutor_persona.dart';
import '../application/student_registration_controller.dart';
import '../application/student_registration_state.dart';
import '../domain/academic_rules.dart';
import '../domain/learning_goal.dart';
import '../domain/subject_catalog.dart';
import 'widgets/premium_stepper.dart';
import 'widgets/searchable_establishment_field.dart';
import 'widgets/subject_multi_selector.dart';

class StudentRegistrationFlowScreen extends ConsumerStatefulWidget {
  const StudentRegistrationFlowScreen({super.key});

  @override
  ConsumerState<StudentRegistrationFlowScreen> createState() =>
      _StudentRegistrationFlowScreenState();
}

class _StudentRegistrationFlowScreenState
    extends ConsumerState<StudentRegistrationFlowScreen> {
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _step5FormKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _previousStep = 0;

  static const _stepLabels = <String>[
    'Identité',
    'Parcours scolaire',
    'Préférences d\'apprentissage',
    'Sécurité et validation',
  ];

  @override
  void initState() {
    super.initState();

    _firstNameController.addListener(() {
      ref
          .read(studentRegistrationControllerProvider.notifier)
          .setFirstName(_firstNameController.text);
    });

    _lastNameController.addListener(() {
      ref
          .read(studentRegistrationControllerProvider.notifier)
          .setLastName(_lastNameController.text);
    });

    _emailController.addListener(() {
      ref
          .read(studentRegistrationControllerProvider.notifier)
          .setEmail(_emailController.text);
    });

    _passwordController.addListener(() {
      ref
          .read(studentRegistrationControllerProvider.notifier)
          .setPassword(_passwordController.text);
    });

    _confirmPasswordController.addListener(() {
      ref
          .read(studentRegistrationControllerProvider.notifier)
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
    final state = ref.watch(studentRegistrationControllerProvider);
    final controller = ref.read(studentRegistrationControllerProvider.notifier);

    ref.listen<StudentRegistrationState>(
      studentRegistrationControllerProvider,
      (previous, next) {
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
      },
    );

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
                  controller.goToPreviousStep();
                },
        ),
        title: const Text('Inscription Élève'),
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

  Widget _buildStepContent(StudentRegistrationState state) {
    return switch (state.currentStep) {
      0 => _buildIdentityStep(),
      1 => _buildAcademicStep(state),
      2 => _buildPreferencesStep(state),
      3 => _buildSecurityStep(state),
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
            title: 'Informations personnelles',
            subtitle: 'Commencez par votre identité.',
          ),
          const SizedBox(height: IntelliaSpacing.lg),
          IntelliaTextField(
            controller: _firstNameController,
            label: 'Prénom',
            hint: 'Ex: Marie',
            prefixIcon: Icons.person_rounded,
            validator: (value) {
              if ((value ?? '').trim().length < 2) {
                return 'Minimum 2 caractères';
              }
              return null;
            },
          ),
          const SizedBox(height: IntelliaSpacing.md),
          IntelliaTextField(
            controller: _lastNameController,
            label: 'Nom',
            hint: 'Ex: Ndzi',
            prefixIcon: Icons.badge_rounded,
            validator: (value) {
              if ((value ?? '').trim().length < 2) {
                return 'Minimum 2 caractères';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicStep(StudentRegistrationState state) {
    final controller = ref.read(studentRegistrationControllerProvider.notifier);
    final selectedClass = state.schoolClass;
    final allowedSeries = selectedClass?.allowedSeries ?? <SchoolSeries>[];

    return Form(
      key: _step2FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Parcours scolaire',
            subtitle: 'Établissement, classe et série.',
          ),
          const SizedBox(height: IntelliaSpacing.lg),
          SearchableEstablishmentField(
            selected: state.establishment,
            onSelected: controller.setEstablishment,
          ),
          const SizedBox(height: IntelliaSpacing.md),
          _IntelliaDropdown<SchoolClass>(
            label: 'Classe',
            prefixIcon: Icons.menu_book_rounded,
            value: state.schoolClass,
            items: [
              for (final item in SchoolClassX.ordered)
                DropdownMenuItem(value: item, child: Text(item.label)),
            ],
            onChanged: (value) {
              if (value != null) controller.setSchoolClass(value);
            },
            validator: (value) =>
                value == null ? 'Sélectionnez une classe' : null,
          ),
          const SizedBox(height: IntelliaSpacing.md),
          _IntelliaDropdown<SchoolSeries>(
            label: state.schoolClass?.seriesFieldLabel ?? 'Série',
            prefixIcon: Icons.category_rounded,
            value: state.schoolSeries,
            items: [
              for (final item in allowedSeries)
                DropdownMenuItem(value: item, child: Text(item.label)),
            ],
            onChanged: controller.setSchoolSeries,
            validator: (value) =>
                value == null ? 'Sélectionnez une option' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesStep(StudentRegistrationState state) {
    final controller = ref.read(studentRegistrationControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Préférences d\'apprentissage',
          subtitle: 'Aidez INTELLIA237 à personnaliser votre expérience.',
        ),
        const SizedBox(height: IntelliaSpacing.lg),
        SubjectMultiSelector(
          title: 'Matières préférées',
          caption: 'Sélectionnez jusqu\'à 6 matières.',
          options: SubjectCatalog.all,
          selected: state.preferredSubjects,
          onToggle: controller.togglePreferredSubject,
        ),
        const SizedBox(height: IntelliaSpacing.lg),
        SubjectMultiSelector(
          title: 'Matières difficiles',
          caption: 'Celles qui demandent plus d\'accompagnement.',
          options: SubjectCatalog.all,
          selected: state.difficultSubjects,
          onToggle: controller.toggleDifficultSubject,
        ),
        const SizedBox(height: IntelliaSpacing.lg),
        _IntelliaDropdown<LearningGoal>(
          label: 'Objectif d\'apprentissage',
          prefixIcon: Icons.flag_rounded,
          value: state.learningGoal,
          items: [
            for (final item in LearningGoal.values)
              DropdownMenuItem(value: item, child: Text(item.label)),
          ],
          onChanged: controller.setLearningGoal,
        ),
        const SizedBox(height: IntelliaSpacing.lg),
        Text(
          'Temps d\'étude quotidien: ${state.dailyStudyMinutes} min',
          style: const TextStyle(
            color: IntelliaColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: IntelliaColors.brandIndigo,
            inactiveTrackColor: IntelliaColors.backgroundSecondary,
            thumbColor: IntelliaColors.brandIndigo,
            overlayColor: IntelliaColors.brandIndigo.withValues(alpha: 0.20),
            valueIndicatorColor: IntelliaColors.brandIndigo,
            valueIndicatorTextStyle: const TextStyle(color: Colors.white),
          ),
          child: Slider(
            value: state.dailyStudyMinutes.toDouble(),
            min: 15,
            max: 240,
            divisions: 15,
            label: '${state.dailyStudyMinutes} min',
            onChanged: (value) =>
                controller.setDailyStudyMinutes(value.round()),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityStep(StudentRegistrationState state) {
    final controller = ref.read(studentRegistrationControllerProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Form(
      key: _step5FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Sécurité et consentements',
            subtitle: 'Finalisez votre compte INTELLIA237.',
          ),
          const SizedBox(height: IntelliaSpacing.lg),
          IntelliaTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'prenom.nom@exemple.com',
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
          IntelliaPasswordField(
            controller: _passwordController,
            label: 'Mot de passe',
            hint: '8 caractères minimum',
            validator: (value) {
              final password = value ?? '';
              final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
              final hasDigit = RegExp(r'[0-9]').hasMatch(password);

              if (password.length < 8 || !hasUppercase || !hasDigit) {
                return '8 caractères, 1 majuscule, 1 chiffre minimum';
              }
              return null;
            },
          ),
          const SizedBox(height: IntelliaSpacing.md),
          IntelliaPasswordField(
            controller: _confirmPasswordController,
            label: 'Confirmer le mot de passe',
            hint: 'Retapez le mot de passe',
            validator: (value) {
              if ((value ?? '') != _passwordController.text) {
                return 'La confirmation ne correspond pas';
              }
              return null;
            },
          ),
          const SizedBox(height: IntelliaSpacing.lg),
          _DarkCheckboxTile(
            value: state.acceptedTerms,
            onChanged: (v) => controller.setAcceptedTerms(v ?? false),
            label: 'J\'accepte les conditions d\'utilisation.',
          ),
          const SizedBox(height: IntelliaSpacing.xs),
          _DarkCheckboxTile(
            value: state.acceptedPrivacy,
            onChanged: (v) => controller.setAcceptedPrivacy(v ?? false),
            label: 'J\'accepte la politique de confidentialité.',
          ),
          const SizedBox(height: IntelliaSpacing.xs),
          _DarkCheckboxTile(
            value: state.acceptedDataPolicy,
            onChanged: (v) => controller.setAcceptedDataPolicy(v ?? false),
            label: 'J\'accepte le traitement pédagogique des données.',
          ),
          const SizedBox(height: IntelliaSpacing.md),
          Container(
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
              'Vérifiez vos informations avant de créer votre compte.',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? IntelliaColors.textSecondaryDark
                    : IntelliaColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(StudentRegistrationState state) {
    final controller = ref.read(studentRegistrationControllerProvider.notifier);

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
                        setState(() => _previousStep = state.currentStep);
                        controller.goToPreviousStep();
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
              onTap: state.isSubmitting
                  ? null
                  : () => _handlePrimaryAction(state),
              isLoading: state.isSubmitting,
              child: Text(state.isLastStep ? 'Créer mon compte' : 'Suivant'),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: IntelliaMotion.medium);
  }

  Future<void> _handlePrimaryAction(StudentRegistrationState state) async {
    final controller = ref.read(studentRegistrationControllerProvider.notifier);

    final valid = switch (state.currentStep) {
      0 => _step1FormKey.currentState?.validate() ?? false,
      1 => _step2FormKey.currentState?.validate() ?? false,
      3 => _step5FormKey.currentState?.validate() ?? false,
      _ => true,
    };

    if (!valid) return;

    final error = controller.validateStep(state.currentStep);
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(error),
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
      final success = await controller.submit();
      if (success && mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: IntelliaSpacing.sm),
                  Text('Inscription complétée avec succès !'),
                ],
              ),
              backgroundColor: IntelliaColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(IntelliaRadii.small),
              ),
              margin: const EdgeInsets.all(IntelliaSpacing.md),
            ),
          );
      }
      return;
    }

    // Après l'étape Parcours scolaire, ouvrir la sélection du tuteur.
    if (state.currentStep == 1) {
      final filterLevel = state.schoolClass?.tutorLevel;
      final currentTutorId = state.selectedTutorId;
      final savedStep = state.currentStep;

      final tutorQuery = currentTutorId != null
          ? '?filterLevel=${filterLevel ?? 'bepc'}&tutorId=$currentTutorId'
          : '?filterLevel=${filterLevel ?? 'bepc'}';
      await context.push<void>(
        '${AppRoutes.tutorSelection}$tutorQuery',
        extra: (TutorPersona chosen) {
          ref
              .read(studentRegistrationControllerProvider.notifier)
              .setSelectedTutorId(chosen.id);
          context.pop();
        },
      );

      if (mounted) {
        setState(() => _previousStep = savedStep);
        controller.goToNextStep();
      }
      return;
    }

    setState(() => _previousStep = state.currentStep);
    controller.goToNextStep();
  }
}

// ─────────────────────────────────────────────────────────────
// Surface de contenu lumineuse.
// ─────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────
// Dropdown lumineux
// ─────────────────────────────────────────────────────────────

class _IntelliaDropdown<T> extends StatelessWidget {
  const _IntelliaDropdown({
    required this.label,
    required this.prefixIcon,
    required this.items,
    required this.onChanged,
    this.value,
    this.validator,
  });

  final String label;
  final IconData prefixIcon;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark
                ? IntelliaColors.textSecondaryDark
                : IntelliaColors.textSecondary,
          ),
        ),
        const SizedBox(height: IntelliaSpacing.xs),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          dropdownColor: isDark
              ? IntelliaColors.surfaceSolidDark
              : IntelliaColors.surfaceSolid,
          style: TextStyle(
            color: isDark
                ? IntelliaColors.textPrimaryDark
                : IntelliaColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          iconEnabledColor: isDark
              ? IntelliaColors.textSecondaryDark
              : IntelliaColors.textSecondary,
          decoration: InputDecoration(prefixIcon: Icon(prefixIcon, size: 20)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Checkbox tile
// ─────────────────────────────────────────────────────────────

class _DarkCheckboxTile extends StatelessWidget {
  const _DarkCheckboxTile({
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
