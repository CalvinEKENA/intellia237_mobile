import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/network/network_status.dart';
import '../../../core/widgets/tab_section_header.dart';
import '../application/quiz_providers.dart';
import '../data/quiz_diagnostic.dart';
import '../domain/quiz_attempt_summary.dart';
import '../domain/quiz_mode.dart';
import '../domain/quiz_model.dart';
import 'widgets/quiz_unavailable_state.dart';
import '../../../core/widgets/intellia_async_states.dart';
import '../../../core/widgets/intellia_state_view.dart';

class QuizHubScreen extends ConsumerWidget {
  const QuizHubScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizAsync = ref.watch(quizHubProvider);
    final offline = ref.watch(isOfflineProvider);

    final content = quizAsync.when(
      loading: () => offline
          ? const _OfflineQuizHubState()
          : const IntelliaStateView(kind: IntelliaStateKind.loading),
      error: (error, stackTrace) => offline
          ? const _OfflineQuizHubState()
          : _QuizFailureState(
              error: error,
              onRetry: () => ref.invalidate(quizHubProvider),
            ),
      // Un quiz publié depuis le Studio arrive d'un simple geste, sans
      // relancer l'application.
      data: (quizzes) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(quizHubProvider);
          try {
            await ref.read(quizHubProvider.future);
          } catch (_) {
            // L'état d'erreur du hub prend le relais.
          }
        },
        child: _QuizHubBody(quizzes: quizzes, offline: offline),
      ),
    );

    if (embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: content,
    );
  }
}

class _QuizFailureState extends StatelessWidget {
  const _QuizFailureState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final failure = error is QuizContentException
        ? error as QuizContentException
        : null;
    // La cause reste dans les journaux ; l'élève voit un état humain.
    developer.log(
      'Quiz hub unavailable.',
      name: 'intellia.quiz',
      error: failure?.operation.name ?? error.runtimeType.toString(),
    );
    final operation = failure?.operation;
    final offline =
        operation == QuizOperation.network ||
        operation == QuizOperation.appCheck ||
        (operation == null &&
            stateKindForError(error) == IntelliaStateKind.offline);
    // Seul un profil à compléter mérite un message particulier : c'est une
    // action que l'élève peut faire.
    final message = switch (operation) {
      QuizOperation.profileMissing ||
      QuizOperation.classMapping => context.l10n.quizProfileIncompleteBody,
      QuizOperation.firestorePermission => context.l10n.quizCatalogDeniedBody,
      _ => null,
    };

    return QuizUnavailableState(
      message: message,
      offline: offline,
      onRetry: onRetry,
      onContinuePath: () => context.push(AppRoutes.flow),
    );
  }
}

class _OfflineQuizHubState extends StatelessWidget {
  const _OfflineQuizHubState();

  @override
  Widget build(BuildContext context) {
    return IntelliaStateView(
      kind: IntelliaStateKind.offline,
      title: context.l10n.quizOfflineTitle,
      message: context.l10n.quizOfflineBody,
      primaryLabel: context.l10n.openOfflineFlow,
      onPrimary: () => context.push(AppRoutes.flow),
      secondaryLabel: context.l10n.viewDownloadedLessons,
      onSecondary: () => context.push(AppRoutes.learnHub),
    );
  }
}

enum _QuizHubFilter { all, training, exam }

extension on _QuizHubFilter {
  String label(BuildContext context) => switch (this) {
    _QuizHubFilter.all => context.l10n.allLabel,
    _QuizHubFilter.training => context.l10n.quizModeTraining,
    _QuizHubFilter.exam => context.l10n.quizModeExam,
  };
}

class _QuizHubBody extends StatefulWidget {
  const _QuizHubBody({required this.quizzes, required this.offline});

  final List<QuizModel> quizzes;
  final bool offline;

  @override
  State<_QuizHubBody> createState() => _QuizHubBodyState();
}

class _QuizHubBodyState extends State<_QuizHubBody> {
  _QuizHubFilter _filter = _QuizHubFilter.all;

  @override
  Widget build(BuildContext context) {
    final training = widget.quizzes
        .where((quiz) => quiz.mode == QuizMode.training)
        .toList(growable: false);
    final exams = widget.quizzes
        .where((quiz) => quiz.mode == QuizMode.exam)
        .toList(growable: false);

    final sections = <Widget>[
      Text(
        context.l10n.quizHubIntro,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: IntelliaSpacing.md),
      _QuizResultsPanel(quizzes: widget.quizzes),
      const SizedBox(height: IntelliaSpacing.md),
      // Focal : carte d'appel (fond sombre → texte blanc à contraste garanti).
      Container(
        padding: const EdgeInsets.all(IntelliaSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(IntelliaRadii.large),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0369A1), Color(0xFF1D4ED8)],
          ),
          boxShadow: IntelliaShadows.glow(
            const Color(0xFF1D4ED8),
            intensity: 0.22,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.chooseRevisionMode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: IntelliaSpacing.sm),
            Icon(
              Icons.bolt_rounded,
              color: Colors.white.withValues(alpha: 0.9),
              size: 30,
            ),
          ],
        ),
      ),
      const SizedBox(height: IntelliaSpacing.md),
      if (widget.offline) ...[
        IntelliaStateView(
          kind: IntelliaStateKind.offline,
          compact: true,
          title: context.l10n.quizPausedOfflineTitle,
          message: context.l10n.quizPausedOfflineBody,
          primaryLabel: context.l10n.openOfflineFlow,
          onPrimary: () => context.push(AppRoutes.flow),
          secondaryLabel: context.l10n.viewDownloadedLessons,
          onSecondary: () => context.push(AppRoutes.learnHub),
        ),
        const SizedBox(height: IntelliaSpacing.md),
      ],
      const _QuizModeGuide(),
      const SizedBox(height: IntelliaSpacing.md),
      if (widget.quizzes.isNotEmpty) ...[
        Text(
          context.l10n.displayLabel,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: IntelliaSpacing.xs),
        Semantics(
          container: true,
          label: context.l10n.filterQuizByModeA11y,
          child: Wrap(
            spacing: IntelliaSpacing.xs,
            runSpacing: IntelliaSpacing.xs,
            children: [
              for (final filter in _QuizHubFilter.values)
                FilterChip(
                  label: Text(filter.label(context)),
                  selected: _filter == filter,
                  onSelected: (_) => setState(() => _filter = filter),
                ),
            ],
          ),
        ),
        const SizedBox(height: IntelliaSpacing.lg),
      ],
      if (widget.quizzes.isEmpty)
        IntelliaStateView(
          kind: IntelliaStateKind.comingSoon,
          compact: true,
          title: context.l10n.quizComingTitle,
          message: context.l10n.quizComingBody,
        ),
      if (_filter != _QuizHubFilter.exam && training.isNotEmpty)
        _QuizModeSection(
          title: context.l10n.quizTrainingAction,
          subtitle: context.l10n.quizTrainingDescription,
          icon: Icons.school_rounded,
          quizzes: training,
          startingIndex: 0,
          offline: widget.offline,
        ),
      if (_filter == _QuizHubFilter.all &&
          training.isNotEmpty &&
          exams.isNotEmpty)
        const SizedBox(height: IntelliaSpacing.lg),
      if (_filter != _QuizHubFilter.training && exams.isNotEmpty)
        _QuizModeSection(
          title: context.l10n.quizExamAction,
          subtitle: context.l10n.quizExamDescription,
          icon: Icons.assignment_turned_in_rounded,
          quizzes: exams,
          startingIndex: training.length,
          offline: widget.offline,
        ),
    ];

    return CustomScrollView(
      slivers: [
        StickyTabSectionHeader(
          key: ValueKey('quiz-sticky-header'),
          eyebrow: context.l10n.studentSpace,
          title: context.l10n.quizTitle,
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            IntelliaSpacing.lg,
            IntelliaSpacing.md,
            IntelliaSpacing.lg,
            132,
          ),
          sliver: SliverList.list(children: sections),
        ),
      ],
    );
  }
}

class _QuizResultsPanel extends ConsumerWidget {
  const _QuizResultsPanel({required this.quizzes});

  final List<QuizModel> quizzes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(quizAttemptHistoryProvider);
    final modeByQuizId = {for (final quiz in quizzes) quiz.id: quiz.mode};
    final subtitle = history.when(
      loading: () => context.l10n.quizHistoryLoading,
      error: (error, stackTrace) => context.l10n.quizHistoryUnavailable,
      data: (attempts) => attempts.isEmpty
          ? context.l10n.quizNoValidatedAttempt
          : context.l10n.lastScore(_scoreLabel(context, attempts.first)),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Icon(
          Icons.insights_rounded,
          color: IntelliaColors.brandIndigo,
        ),
        title: Text(
          context.l10n.myResults,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(subtitle),
        childrenPadding: const EdgeInsets.fromLTRB(
          IntelliaSpacing.md,
          0,
          IntelliaSpacing.md,
          IntelliaSpacing.md,
        ),
        children: [
          history.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(IntelliaSpacing.md),
              child: CircularProgressIndicator(),
            ),
            error: (error, stackTrace) => Column(
              children: [
                Text(
                  context.l10n.quizResultsLoadFailed,
                  textAlign: TextAlign.center,
                ),
                TextButton.icon(
                  onPressed: () => ref.invalidate(quizAttemptHistoryProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(context.l10n.retryLabel),
                ),
              ],
            ),
            data: (attempts) => attempts.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: IntelliaSpacing.md,
                    ),
                    child: Text(
                      context.l10n.quizFirstResultBody,
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < attempts.length; i++) ...[
                        _QuizAttemptRow(
                          attempt: attempts[i],
                          mode: modeByQuizId[attempts[i].quizId],
                        ),
                        if (i < attempts.length - 1) const Divider(height: 1),
                      ],
                      const SizedBox(height: IntelliaSpacing.sm),
                      Text(
                        context.l10n.quizMasteryUnavailable,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _QuizAttemptRow extends StatelessWidget {
  const _QuizAttemptRow({required this.attempt, required this.mode});

  final QuizAttemptSummary attempt;
  final QuizMode? mode;

  @override
  Widget build(BuildContext context) {
    final date = attempt.submittedAt == null
        ? context.l10n.dateUnavailable
        : MaterialLocalizations.of(
            context,
          ).formatShortDate(attempt.submittedAt!.toLocal());
    final modeLabel = switch (mode) {
      QuizMode.training => context.l10n.quizModeTraining,
      QuizMode.exam => context.l10n.quizModeExam,
      null => context.l10n.quizModeUnspecified,
    };
    final score = _scoreLabel(context, attempt);

    return Semantics(
      container: true,
      label:
          '${attempt.quizTitle}. $modeLabel. $score. $date.'
          '${attempt.pointsAwarded > 0 ? ' ${attempt.pointsAwarded} points.' : ''}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: IntelliaSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attempt.quizTitle,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text('${attempt.subjectLabel} • $modeLabel'),
                    Text(date),
                  ],
                ),
              ),
              const SizedBox(width: IntelliaSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    score,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: IntelliaColors.brandIndigo,
                    ),
                  ),
                  if (attempt.pointsAwarded > 0)
                    Text(context.l10n.pointsEarned(attempt.pointsAwarded)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _scoreLabel(BuildContext context, QuizAttemptSummary attempt) {
  if (attempt.maxScore <= 0) return context.l10n.scoreUnavailable;
  final percentage = (attempt.score / attempt.maxScore * 100).round();
  return '${attempt.score}/${attempt.maxScore} ($percentage %)';
}

class _QuizModeGuide extends StatelessWidget {
  const _QuizModeGuide();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(IntelliaRadii.medium),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(IntelliaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ModeExplanation(
              icon: Icons.lightbulb_rounded,
              title: context.l10n.quizModeTraining,
              description: context.l10n.quizTrainingGuide,
            ),
            SizedBox(height: IntelliaSpacing.sm),
            _ModeExplanation(
              icon: Icons.timer_rounded,
              title: context.l10n.quizModeExam,
              description: context.l10n.quizExamGuide,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeExplanation extends StatelessWidget {
  const _ModeExplanation({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: IntelliaColors.brandIndigo),
        const SizedBox(width: IntelliaSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(description),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuizModeSection extends StatelessWidget {
  const _QuizModeSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.quizzes,
    required this.startingIndex,
    required this.offline,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<QuizModel> quizzes;
  final int startingIndex;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: IntelliaColors.brandIndigo),
            const SizedBox(width: IntelliaSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(subtitle),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        for (var i = 0; i < quizzes.length; i++) ...[
          _QuizCard(
            quiz: quizzes[i],
            index: startingIndex + i,
            offline: offline,
          ),
          const SizedBox(height: IntelliaSpacing.sm),
        ],
      ],
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({
    required this.quiz,
    required this.index,
    required this.offline,
  });

  final QuizModel quiz;
  final int index;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modeLabel = quiz.mode == QuizMode.training
        ? context.l10n.quizModeTraining
        : context.l10n.quizModeExam;
    return Semantics(
      button: true,
      label:
          '$modeLabel. ${quiz.title}. ${quiz.subjectLabel}. '
          '${context.l10n.questionCount(quiz.questionCount)}.'
          '${offline ? context.l10n.unavailableOfflineA11y : ''}',
      child: ExcludeSemantics(
        child: Card(
          child:
              InkWell(
                    borderRadius: BorderRadius.circular(IntelliaRadii.medium),
                    onTap: offline
                        ? () => _showOfflineQuizHelp(context)
                        : () => context.push(AppRoutes.quizPlay(quiz.id)),
                    child: Padding(
                      padding: const EdgeInsets.all(IntelliaSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _QuizModeBadge(
                            icon: quiz.mode == QuizMode.training
                                ? Icons.school_rounded
                                : Icons.assignment_turned_in_rounded,
                            label: modeLabel,
                          ),
                          const SizedBox(height: IntelliaSpacing.xs),
                          Wrap(
                            spacing: IntelliaSpacing.xs,
                            runSpacing: IntelliaSpacing.xs,
                            children: [
                              Chip(label: Text(quiz.subjectLabel)),
                              Chip(label: Text(quiz.difficultyLabel)),
                              if (quiz.timerSeconds != null)
                                Chip(
                                  avatar: const Icon(
                                    Icons.timer_rounded,
                                    size: 16,
                                  ),
                                  label: Text(
                                    '${quiz.timerSeconds! ~/ 60} min',
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: IntelliaSpacing.xs),
                          Text(
                            quiz.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: IntelliaSpacing.xs),
                          Text(quiz.description),
                          const SizedBox(height: IntelliaSpacing.sm),
                          Row(
                            children: [
                              Icon(
                                Icons.help_outline_rounded,
                                size: 16,
                                color: IntelliaColors.brandIndigo,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${quiz.questionCount} questions',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate(delay: Duration(milliseconds: index * 60))
                  .fadeIn(duration: 360.ms)
                  .slideY(begin: 0.06, end: 0),
        ),
      ),
    );
  }
}

class _QuizModeBadge extends StatelessWidget {
  const _QuizModeBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(IntelliaRadii.full),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: IntelliaSpacing.sm,
          vertical: IntelliaSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colors.onPrimaryContainer),
            const SizedBox(width: IntelliaSpacing.xs),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showOfflineQuizHelp(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(IntelliaSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 40),
            const SizedBox(height: IntelliaSpacing.sm),
            Text(
              context.l10n.quizNeedsNetworkTitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: IntelliaSpacing.xs),
            Text(
              context.l10n.quizNeedsNetworkBody,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: IntelliaSpacing.lg),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                context.push(AppRoutes.flow);
              },
              icon: const Icon(Icons.bolt_rounded),
              label: Text(context.l10n.openOfflineFlow),
            ),
            const SizedBox(height: IntelliaSpacing.xs),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                context.push(AppRoutes.learnHub);
              },
              icon: const Icon(Icons.download_done_rounded),
              label: Text(context.l10n.viewDownloadedLessons),
            ),
            TextButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: Text(context.l10n.closeLabel),
            ),
          ],
        ),
      ),
    ),
  );
}
