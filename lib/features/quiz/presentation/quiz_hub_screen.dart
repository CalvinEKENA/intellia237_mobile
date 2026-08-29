import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/network/network_status.dart';
import '../../../core/widgets/tab_section_header.dart';
import '../application/quiz_providers.dart';
import '../domain/quiz_attempt_summary.dart';
import '../domain/quiz_mode.dart';
import '../domain/quiz_model.dart';
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
          : IntelliaStateView(
              kind: stateKindForError(error),
              title: 'Impossible de charger les quiz',
              message: stateMessageForKind(stateKindForError(error)),
              primaryLabel: 'Réessayer',
              onPrimary: () => ref.invalidate(quizHubProvider),
            ),
      data: (quizzes) => _QuizHubBody(quizzes: quizzes, offline: offline),
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

class _OfflineQuizHubState extends StatelessWidget {
  const _OfflineQuizHubState();

  @override
  Widget build(BuildContext context) {
    return IntelliaStateView(
      kind: IntelliaStateKind.offline,
      title: 'Les quiz attendent le réseau',
      message:
          'Aucun quiz n’est lancé sans connexion : le serveur protège la '
          'correction et valide l’envoi, sans conserver tes réponses hors '
          'ligne. Tu peux continuer avec le Flow ou une leçon téléchargée.',
      primaryLabel: 'Ouvrir le Flow hors ligne',
      onPrimary: () => context.push(AppRoutes.flow),
      secondaryLabel: 'Voir mes leçons téléchargées',
      onSecondary: () => context.push(AppRoutes.learnHub),
    );
  }
}

enum _QuizHubFilter { all, training, exam }

extension on _QuizHubFilter {
  String get label => switch (this) {
    _QuizHubFilter.all => 'Tous',
    _QuizHubFilter.training => 'Entraînement',
    _QuizHubFilter.exam => 'Évaluation / examen blanc',
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        IntelliaSpacing.lg,
        IntelliaSpacing.lg,
        IntelliaSpacing.lg,
        132,
      ),
      children: [
        const TabSectionHeader(
          eyebrow: 'Espace élève',
          title: 'Quiz',
          subtitle:
              'Entraîne-toi avec des corrections guidées ou évalue-toi '
              'dans les conditions d’un examen blanc.',
        ),
        const SizedBox(height: IntelliaSpacing.md),
        _QuizResultsPanel(quizzes: widget.quizzes),
        const SizedBox(height: IntelliaSpacing.md),
        // Focal : carte d'appel (fond sombre → texte blanc à contraste garanti).
        Container(
          padding: const EdgeInsets.all(IntelliaSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(IntelliaRadii.large),
            // Assombri (#0369A1) pour garantir un contraste ≥ 4.5:1 du texte
            // blanc sur toute la surface du banner.
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
              const Expanded(
                child: Text(
                  'Choisis ton mode de révision',
                  style: TextStyle(
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
            title: 'Quiz en pause hors connexion',
            message:
                'Les corrections et l’envoi sont vérifiés par le serveur. '
                'Pour protéger l’évaluation, aucune réponse ni aucun corrigé '
                'n’est conservé hors ligne.',
            primaryLabel: 'Ouvrir le Flow hors ligne',
            onPrimary: () => context.push(AppRoutes.flow),
            secondaryLabel: 'Voir mes leçons téléchargées',
            onSecondary: () => context.push(AppRoutes.learnHub),
          ),
          const SizedBox(height: IntelliaSpacing.md),
        ],
        const _QuizModeGuide(),
        const SizedBox(height: IntelliaSpacing.md),
        if (widget.quizzes.isNotEmpty) ...[
          Text(
            'Afficher',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: IntelliaSpacing.xs),
          Semantics(
            container: true,
            label: 'Filtrer les quiz par mode',
            child: Wrap(
              spacing: IntelliaSpacing.xs,
              runSpacing: IntelliaSpacing.xs,
              children: [
                for (final filter in _QuizHubFilter.values)
                  FilterChip(
                    label: Text(filter.label),
                    selected: _filter == filter,
                    onSelected: (_) => setState(() => _filter = filter),
                  ),
              ],
            ),
          ),
          const SizedBox(height: IntelliaSpacing.lg),
        ],
        if (widget.quizzes.isEmpty)
          const IntelliaStateView(
            kind: IntelliaStateKind.comingSoon,
            compact: true,
            title: 'Les quiz de ta classe arrivent',
            message:
                'De nouveaux quiz sont en préparation pour ton niveau. '
                'En attendant, révise une leçon ou lance le Flow depuis '
                'l\'accueil.',
          ),
        if (_filter != _QuizHubFilter.exam && training.isNotEmpty)
          _QuizModeSection(
            title: 'S’entraîner',
            subtitle:
                'Une correction guidée t’aide à comprendre avant de continuer.',
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
            title: 'S’évaluer',
            subtitle:
                'Les réponses sont corrigées à la fin. Ces quiz préparent aux '
                'épreuves, sans remplacer un examen officiel.',
            icon: Icons.assignment_turned_in_rounded,
            quizzes: exams,
            startingIndex: training.length,
            offline: widget.offline,
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
      loading: () => 'Chargement des tentatives validées…',
      error: (error, stackTrace) => 'Historique indisponible pour le moment.',
      data: (attempts) => attempts.isEmpty
          ? 'Aucune tentative validée pour le moment.'
          : 'Dernier score : ${_scoreLabel(attempts.first)}',
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Icon(
          Icons.insights_rounded,
          color: IntelliaColors.brandIndigo,
        ),
        title: const Text(
          'Mes résultats',
          style: TextStyle(fontWeight: FontWeight.w900),
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
                const Text(
                  'Impossible de récupérer les résultats validés. Tes quiz '
                  'restent accessibles.',
                  textAlign: TextAlign.center,
                ),
                TextButton.icon(
                  onPressed: () => ref.invalidate(quizAttemptHistoryProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
            data: (attempts) => attempts.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: IntelliaSpacing.md),
                    child: Text(
                      'Aucun résultat inventé ici : ta première tentative '
                      'apparaîtra après sa validation par le serveur.',
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
                      const Text(
                        'La maîtrise par thème n’est pas affichée : les '
                        'tentatives actuelles n’enregistrent pas encore de '
                        'compétences pédagogiques validées.',
                        style: TextStyle(fontSize: 12),
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
        ? 'Date non disponible'
        : MaterialLocalizations.of(
            context,
          ).formatShortDate(attempt.submittedAt!.toLocal());
    final modeLabel = switch (mode) {
      QuizMode.training => 'Entraînement',
      QuizMode.exam => 'Évaluation / examen blanc',
      null => 'Mode non précisé',
    };
    final score = _scoreLabel(attempt);

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
                    Text('+${attempt.pointsAwarded} points'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _scoreLabel(QuizAttemptSummary attempt) {
  if (attempt.maxScore <= 0) return 'Score non disponible';
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
      child: const Padding(
        padding: EdgeInsets.all(IntelliaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ModeExplanation(
              icon: Icons.lightbulb_rounded,
              title: 'Entraînement',
              description: 'Correction guidée pendant le quiz.',
            ),
            SizedBox(height: IntelliaSpacing.sm),
            _ModeExplanation(
              icon: Icons.timer_rounded,
              title: 'Évaluation / examen blanc',
              description: 'Correction complète après l’envoi.',
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
        ? 'Entraînement'
        : 'Évaluation / examen blanc';
    return Semantics(
      button: true,
      label:
          '$modeLabel. ${quiz.title}. ${quiz.subjectLabel}. '
          '${quiz.questionCount} questions.'
          '${offline ? ' Indisponible hors connexion.' : ''}',
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
              'Ce quiz a besoin du réseau',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: IntelliaSpacing.xs),
            const Text(
              'Le serveur protège la correction et valide l’envoi. Intellia237 '
              'ne met ni tes réponses ni les corrigés en cache. Reconnecte-toi '
              'pour commencer, ou poursuis une activité disponible hors ligne.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: IntelliaSpacing.lg),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                context.push(AppRoutes.flow);
              },
              icon: const Icon(Icons.bolt_rounded),
              label: const Text('Ouvrir le Flow hors ligne'),
            ),
            const SizedBox(height: IntelliaSpacing.xs),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                context.push(AppRoutes.learnHub);
              },
              icon: const Icon(Icons.download_done_rounded),
              label: const Text('Voir mes leçons téléchargées'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
    ),
  );
}
