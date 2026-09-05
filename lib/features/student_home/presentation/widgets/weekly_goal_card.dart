import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/widgets/intellia_pressable.dart';
import '../../../../core/widgets/tab_presentation.dart';
import '../../application/personal_goal_providers.dart';
import '../../domain/personal_goal.dart';
import '../../domain/student_home_snapshot.dart';

/// Carte « Mon objectif de la semaine » de l'accueil.
///
/// Décision produit (registre) : rétention responsable — l'objectif est
/// choisi par l'élève, le compteur repart chaque lundi sans pénalité, et
/// aucun libellé ne culpabilise (« en retard », « raté »… sont bannis).
class WeeklyGoalCard extends ConsumerWidget {
  const WeeklyGoalCard({required this.subjects, this.onOpenSubject, super.key});

  /// Matières réelles de l'élève (pour le choix de matière prioritaire).
  final List<SubjectOverview> subjects;

  /// Ouvre le détail d'une matière (raccourci de la matière prioritaire).
  final ValueChanged<SubjectOverview>? onOpenSubject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(personalGoalControllerProvider);
    final progress = progressAsync.valueOrNull;

    // Pas encore chargé : rien plutôt qu'un squelette pour une carte légère.
    if (progress == null) return const SizedBox.shrink();

    if (!progress.hasGoal) {
      return _GoalInvitation(
        onTap: () => showPersonalGoalSheet(context, ref, subjects: subjects),
      );
    }

    final goal = progress.goal!;
    final done = progress.activeDays.clamp(0, goal.sessionsPerWeek);
    final s = TabSurface.of(context);
    final prioritySubject = _prioritySubject(goal);

    return Semantics(
      container: true,
      label: context.l10n.weeklyGoalProgressA11y(
        done,
        goal.sessionsPerWeek,
        progress.achieved ? context.l10n.goalAchievedA11y : '',
      ),
      child: Container(
        padding: const EdgeInsets.all(IntelliaSpacing.md),
        decoration: BoxDecoration(
          color: s.surface,
          borderRadius: BorderRadius.circular(IntelliaRadii.large),
          border: Border.all(
            color: progress.achieved
                ? s.success.withValues(alpha: 0.40)
                : s.border,
          ),
          boxShadow: IntelliaShadows.card(Colors.black),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.myWeeklyGoal,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: s.textPrimary,
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: context.l10n.editMyGoal,
                  child: IntelliaPressable(
                    onTap: () =>
                        showPersonalGoalSheet(context, ref, subjects: subjects),
                    child: Padding(
                      padding: const EdgeInsets.all(IntelliaSpacing.xs),
                      child: Icon(
                        Icons.tune_rounded,
                        size: 18,
                        color: s.iconSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: IntelliaSpacing.sm),

            // Segments de la semaine : simples, lisibles, sans chrono.
            ExcludeSemantics(
              child: Row(
                children: [
                  for (var i = 0; i < goal.sessionsPerWeek; i++) ...[
                    Expanded(
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: i < done ? s.success : s.surfaceMuted,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    if (i < goal.sessionsPerWeek - 1)
                      const SizedBox(width: IntelliaSpacing.xs),
                  ],
                ],
              ),
            ),
            const SizedBox(height: IntelliaSpacing.xs),

            Row(
              children: [
                Expanded(
                  child: Text(
                    progress.achieved
                        ? context.l10n.goalAchievedMessage
                        : context.l10n.weeklyGoalProgressSummary(
                            done,
                            goal.sessionsPerWeek,
                            goal.minutesPerSession,
                          ),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: progress.achieved ? s.success : s.textSecondary,
                    ),
                  ),
                ),
                if (progress.achieved)
                  Icon(Icons.emoji_events_rounded, size: 18, color: s.success),
              ],
            ),

            if (prioritySubject != null && onOpenSubject != null) ...[
              const SizedBox(height: IntelliaSpacing.sm),
              Semantics(
                button: true,
                label: context.l10n.openPrioritySubjectA11y(
                  prioritySubject.title,
                ),
                child: IntelliaPressable(
                  onTap: () => onOpenSubject!(prioritySubject),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: IntelliaSpacing.sm,
                      vertical: IntelliaSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: s.accentSoft,
                      borderRadius: BorderRadius.circular(IntelliaRadii.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag_rounded, size: 14, color: s.accent),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            context.l10n.prioritySubject(prioritySubject.title),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: s.accent,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: s.accent,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  SubjectOverview? _prioritySubject(PersonalGoal goal) {
    final id = goal.prioritySubjectId;
    if (id == null) return null;
    for (final subject in subjects) {
      if (subject.id == id) return subject;
    }
    // Matière plus disponible (changement de classe…) : pas de raccourci mort.
    return null;
  }
}

/// Invitation discrète quand aucun objectif n'est défini.
class _GoalInvitation extends StatelessWidget {
  const _GoalInvitation({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);
    return Semantics(
      button: true,
      label: context.l10n.setWeeklyPace,
      child: IntelliaPressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(IntelliaSpacing.md),
          decoration: BoxDecoration(
            color: s.surface,
            borderRadius: BorderRadius.circular(IntelliaRadii.large),
            border: Border.all(color: s.accent.withValues(alpha: 0.30)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: s.accentSoft,
                  borderRadius: BorderRadius.circular(IntelliaRadii.small),
                ),
                child: Icon(Icons.flag_rounded, color: s.accent, size: 22),
              ),
              const SizedBox(width: IntelliaSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.setYourWeeklyPace,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: s.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.weeklyPaceChoices,
                      style: TextStyle(fontSize: 12, color: s.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: s.iconSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ouvre la sheet de configuration de l'objectif (accueil et Paramètres).
Future<void> showPersonalGoalSheet(
  BuildContext context,
  WidgetRef ref, {
  List<SubjectOverview> subjects = const [],
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => _GoalSheet(subjects: subjects),
  );
}

class _GoalSheet extends ConsumerStatefulWidget {
  const _GoalSheet({required this.subjects});

  final List<SubjectOverview> subjects;

  @override
  ConsumerState<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends ConsumerState<_GoalSheet> {
  late int _sessions;
  late int _minutes;
  String? _prioritySubjectId;
  bool _hadGoal = false;

  @override
  void initState() {
    super.initState();
    final current = ref.read(personalGoalControllerProvider).valueOrNull?.goal;
    _hadGoal = current != null;
    _sessions = current?.sessionsPerWeek ?? 3;
    _minutes = current?.minutesPerSession ?? 20;
    _prioritySubjectId = current?.prioritySubjectId;
  }

  Future<void> _save() async {
    final subject = _prioritySubjectId == null
        ? null
        : widget.subjects.where((s) => s.id == _prioritySubjectId).firstOrNull;
    await ref
        .read(personalGoalControllerProvider.notifier)
        .saveGoal(
          PersonalGoal(
            sessionsPerWeek: _sessions,
            minutesPerSession: _minutes,
            prioritySubjectId: _prioritySubjectId,
            prioritySubjectTitle: subject?.title,
          ),
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _remove() async {
    await ref.read(personalGoalControllerProvider.notifier).clearGoal();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = TabPalette.forBrightness(Theme.of(context).brightness);

    return TabSurface(
      palette: s,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: IntelliaSpacing.lg,
            right: IntelliaSpacing.lg,
            bottom:
                MediaQuery.viewInsetsOf(context).bottom + IntelliaSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.myWeeklyGoal,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: s.textPrimary,
                ),
              ),
              const SizedBox(height: IntelliaSpacing.xxs),
              Text(
                context.l10n.weeklyGoalExplanation,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: s.textSecondary,
                ),
              ),
              const SizedBox(height: IntelliaSpacing.lg),

              _ChoiceRow<int>(
                label: context.l10n.sessionsPerWeek,
                values: PersonalGoal.allowedSessions,
                selected: _sessions,
                display: (v) => '$v',
                onSelected: (v) => setState(() => _sessions = v),
              ),
              const SizedBox(height: IntelliaSpacing.md),
              _ChoiceRow<int>(
                label: context.l10n.sessionDuration,
                values: PersonalGoal.allowedMinutes,
                selected: _minutes,
                display: (v) => '$v min',
                onSelected: (v) => setState(() => _minutes = v),
              ),

              if (widget.subjects.isNotEmpty) ...[
                const SizedBox(height: IntelliaSpacing.md),
                Text(
                  context.l10n.prioritySubjectOptional,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: s.textPrimary,
                  ),
                ),
                const SizedBox(height: IntelliaSpacing.xs),
                Wrap(
                  spacing: IntelliaSpacing.xs,
                  runSpacing: IntelliaSpacing.xs,
                  children: [
                    _ChoicePill(
                      label: context.l10n.noneLabel,
                      selected: _prioritySubjectId == null,
                      onTap: () => setState(() => _prioritySubjectId = null),
                    ),
                    for (final subject in widget.subjects)
                      _ChoicePill(
                        label: subject.title,
                        selected: _prioritySubjectId == subject.id,
                        onTap: () =>
                            setState(() => _prioritySubjectId = subject.id),
                      ),
                  ],
                ),
              ],

              const SizedBox(height: IntelliaSpacing.lg),
              Semantics(
                button: true,
                label: context.l10n.saveMyGoal,
                child: IntelliaPressable(
                  onTap: _save,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: IntelliaGradients.brand,
                      borderRadius: BorderRadius.circular(IntelliaRadii.full),
                    ),
                    child: Center(
                      child: Text(
                        context.l10n.saveMyGoal,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_hadGoal)
                TextButton(
                  onPressed: _remove,
                  child: Text(context.l10n.removeGoal),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.values,
    required this.selected,
    required this.display,
    required this.onSelected,
  });

  final String label;
  final List<T> values;
  final T selected;
  final String Function(T) display;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: s.textPrimary,
          ),
        ),
        const SizedBox(height: IntelliaSpacing.xs),
        Row(
          children: [
            for (final value in values) ...[
              Expanded(
                child: _ChoicePill(
                  label: display(value),
                  selected: value == selected,
                  onTap: () => onSelected(value),
                ),
              ),
              if (value != values.last)
                const SizedBox(width: IntelliaSpacing.xs),
            ],
          ],
        ),
      ],
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: IntelliaPressable(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            horizontal: IntelliaSpacing.sm,
            vertical: IntelliaSpacing.xs,
          ),
          decoration: BoxDecoration(
            gradient: selected ? IntelliaGradients.brand : null,
            color: selected ? null : s.surfaceMuted,
            borderRadius: BorderRadius.circular(IntelliaRadii.full),
            border: Border.all(color: selected ? Colors.transparent : s.border),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : s.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
