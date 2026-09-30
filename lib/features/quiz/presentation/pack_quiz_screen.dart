import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/widgets/intellia_skeleton.dart';
import '../../../core/telemetry/intellia_telemetry.dart';
import '../../content_engine/application/content_providers.dart';
import '../../content_engine/application/reward_bridge.dart';
import '../../content_engine/domain/mastery.dart';
import '../../content_engine/engine/answer_checker.dart';
import '../../content_engine/presentation/content_style.dart';
import '../../content_engine/presentation/content_subject_screen.dart';
import '../../content_engine/presentation/subject_identity.dart';
import '../../content_engine/presentation/widgets/answer_input.dart';
import '../../content_engine/presentation/widgets/answer_summary.dart';
import '../../content_engine/presentation/widgets/practice_panel.dart'
    show diagnosisText;
import '../../rewards/application/reward_providers.dart';
import '../../rewards/domain/reward_event.dart';
import '../../rewards/domain/reward_pattern.dart';
import '../../rewards/presentation/reward_milestone.dart';
import '../../rewards/presentation/reward_stage.dart';
import '../../tutor/domain/tutor_persona.dart';
import '../application/pack_quiz_providers.dart';
import '../application/pack_quiz_session.dart';
import '../domain/pack_quiz.dart';
import '../domain/quiz_companion_narrator.dart';
import 'pack_quiz_hub_section.dart' show packQuizModeLabel;
import 'widgets/quiz_companion_bubble.dart';

/// Une séance de quiz de pack, du mot d'accueil du compagnon au bilan.
///
/// Tout se passe sur l'appareil : questions du pack, correction des leçons,
/// maîtrise de l'élève, répliques écrites à l'avance. Aucun réseau.
class PackQuizScreen extends ConsumerStatefulWidget {
  const PackQuizScreen({required this.setId, required this.mode, super.key});

  final String setId;
  final PackQuizMode mode;

  @override
  ConsumerState<PackQuizScreen> createState() => _PackQuizScreenState();
}

class _PackQuizScreenState extends ConsumerState<PackQuizScreen> {
  PackQuizSession? _session;
  LearnerContentSnapshot _before = LearnerContentSnapshot.empty;
  StudentResponse? _draft;
  String _lastKey = '';
  PackQuizPhase _lastPhase = PackQuizPhase.intro;
  QuizNarration? _line;
  String? _lineDetail;
  RewardPattern? _reward;
  DateTime _questionStartedAt = DateTime.now();
  bool _showReview = false;

  @override
  void dispose() {
    _session?.removeListener(_changed);
    _session?.dispose();
    super.dispose();
  }

  TutorPersona get _companion => ref.read(quizCompanionProvider);

  QuizNarration _narrate(
    QuizNarrationEvent event, {
    String questionId = '',
    Map<String, Object> values = const {},
  }) => QuizCompanionNarrator.narrate(
    event,
    companionId: _companion.id,
    questionId: questionId,
    attempt: _session?.plan.attempt ?? 0,
    values: values,
  );

  PackQuizSession _create(PackQuizSet set, int attempt) {
    _before =
        ref.read(learnerContentControllerProvider).valueOrNull ??
        LearnerContentSnapshot.empty;
    final plan = DeterministicQuizBuilder.build(
      set: set,
      mode: widget.mode,
      attempt: attempt,
      snapshot: _before,
    );
    final session = PackQuizSession(plan: plan, recorder: packQuizRecorder(ref))
      ..addListener(_changed);
    _lastKey = session.attemptKey;
    _lastPhase = session.phase;
    _line = QuizCompanionNarrator.narrate(
      QuizNarrationEvent.sessionStarted,
      companionId: _companion.id,
      attempt: attempt,
      values: {
        'subject': subjectDisplayName(
          context,
          set.subjectKey,
          set.subjectTitle,
        ),
        'count': plan.length,
        'title': set.isMixed ? context.l10n.quizPackMixed : set.title,
      },
    );
    return session;
  }

  void _restart(PackQuizSet set) {
    final previous = _session;
    previous?.removeListener(_changed);
    setState(() {
      _session = _create(set, (previous?.plan.attempt ?? 0) + 1);
      _draft = null;
      _reward = null;
      _lineDetail = null;
      _showReview = false;
    });
    previous?.dispose();
  }

  void _changed() {
    final session = _session;
    if (!mounted || session == null) return;
    setState(() {
      if (session.phase == PackQuizPhase.finished &&
          _lastPhase != PackQuizPhase.finished) {
        _lastPhase = session.phase;
        _finish(session);
        return;
      }
      _lastPhase = session.phase;
      if (session.attemptKey != _lastKey ||
          (session.phase == PackQuizPhase.question && _line == null)) {
        _lastKey = session.attemptKey;
        _draft = null;
        _reward = null;
        _lineDetail = null;
        _questionStartedAt = DateTime.now();
        final item = session.item;
        if (item != null) {
          _line = _narrate(
            QuizCompanionNarrator.presentationFor(
              index: session.index,
              length: session.length,
            ),
            questionId: item.id,
            values: {'current': session.index + 1, 'total': session.length},
          );
        }
      }
    });
  }

  void _begin() {
    final session = _session;
    if (session == null) return;
    _line = null;
    unawaited(
      IntelliaTelemetry.quizOpened(
        mode: widget.mode == PackQuizMode.training ? 'training' : 'exam',
        questionCount: session.length,
      ),
    );
    session.start();
    _changed();
  }

  void _hint() {
    final session = _session;
    final item = session?.item;
    if (session == null || item == null || !session.canHint) return;
    session.showHint();
    setState(() {
      _line = _narrate(QuizNarrationEvent.hintRequested, questionId: item.id);
      _lineDetail = item.question.hints[session.hintsShown - 1];
    });
  }

  Future<void> _submit() async {
    final session = _session;
    final draft = _draft;
    final item = session?.item;
    if (session == null || draft == null || item == null) return;
    FocusScope.of(context).unfocus();
    final before =
        ref.read(learnerContentControllerProvider).valueOrNull ??
        LearnerContentSnapshot.empty;
    final answer = await session.submit(draft);
    if (!mounted || answer == null) return;
    if (widget.mode == PackQuizMode.evaluation) return;
    final rewards = ref.read(rewardDispatcherProvider);
    RewardPattern? pattern;
    if (answer.correct) {
      final after =
          ref.read(learnerContentControllerProvider).valueOrNull ?? before;
      pattern = rewards.correct(
        contentRewardEvent(
          source: RewardSource.quiz,
          chapter: item.chapter,
          question: item.question,
          before: before,
          after: after,
          responseTime: DateTime.now().difference(_questionStartedAt),
        ),
      );
    } else {
      rewards.incorrect();
    }
    setState(() {
      _reward = pattern;
      _lineDetail = null;
      _line = _narrate(
        QuizCompanionNarrator.afterAnswer(
          correct: answer.correct,
          streak: session.streak,
        ),
        questionId: item.id,
        values: {'count': session.streak},
      );
    });
  }

  /// Fin de séance : bilan du compagnon, historique, et une célébration
  /// plus marquée pour un sans-faute.
  void _finish(PackQuizSession session) {
    final result = session.result;
    _line = _narrate(
      QuizNarrationEvent.sessionCompleted,
      values: {'score': result.score, 'total': result.total},
    );
    _lineDetail = null;
    unawaited(
      IntelliaTelemetry.quizSubmitted(
        answeredCount: result.answers.length,
        questionCount: result.total,
        scorePercent: result.percent,
      ),
    );
    unawaited(
      ref
          .read(packQuizHistoryProvider.notifier)
          .record(
            PackQuizHistoryEntry(
              setId: session.plan.set.id,
              subjectKey: session.plan.set.subjectKey,
              title: session.plan.set.isMixed
                  ? context.l10n.quizPackMixed
                  : session.plan.set.title,
              mode: session.mode,
              score: result.score,
              total: result.total,
              completedAt: DateTime.now(),
            ),
          ),
    );
    if (result.perfect && result.answers.isNotEmpty) {
      final last = result.answers.last;
      final after =
          ref.read(learnerContentControllerProvider).valueOrNull ?? _before;
      final pattern = ref
          .read(rewardDispatcherProvider)
          .correct(
            contentRewardEvent(
              source: RewardSource.quiz,
              chapter: last.item.chapter,
              question: last.item.question,
              before: _before,
              after: after,
            ),
          );
      if (!(MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) showRewardMilestone(context, pattern);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(packQuizCatalogProvider);
    final history = ref.watch(packQuizHistoryProvider);
    final brightness = learningBrightness(context);
    final background = learningBackground(brightness);
    final set = catalog.valueOrNull?.setById(widget.setId);
    final palette = SubjectVisualIdentity.of(
      set?.subjectKey ?? '',
    ).palette(brightness);
    final title = set == null
        ? context.l10n.quizTitle
        : subjectDisplayName(context, set.subjectKey, set.subjectTitle);

    Widget body;
    if (!catalog.hasValue || !history.hasValue) {
      body = const _QuizSkeleton();
    } else if (set == null || set.questionCount == 0) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(IntelliaSpacing.lg),
          child: Text(
            context.l10n.quizPackNoLesson,
            key: const ValueKey('pack-quiz-missing'),
            textAlign: TextAlign.center,
            style: ContentText.body(color: palette.textPrimary),
          ),
        ),
      );
    } else {
      final session = _session ??= _create(
        set,
        nextPackQuizAttempt(history.requireValue, set.id, widget.mode),
      );
      body = switch (session.phase) {
        PackQuizPhase.intro => _Intro(
          session: session,
          palette: palette,
          companion: _companion,
          line: _line!,
          onBegin: _begin,
        ),
        PackQuizPhase.question => _QuestionView(
          session: session,
          palette: palette,
          companion: _companion,
          line: _line,
          lineDetail: _lineDetail,
          reward: _reward,
          canValidate: _draft != null && !session.busy,
          onDraft: (draft) => setState(() => _draft = draft),
          onValidate: _submit,
          onHint: _hint,
        ),
        PackQuizPhase.finished => _ResultView(
          session: session,
          before: _before,
          after:
              ref.watch(learnerContentControllerProvider).valueOrNull ??
              _before,
          palette: palette,
          companion: _companion,
          line: _line!,
          showReview: _showReview,
          onToggleReview: () => setState(() => _showReview = !_showReview),
          onRetry: () => _restart(set),
          onContinue: () =>
              context.pushReplacement(AppRoutes.contentSubject(set.subjectKey)),
          narrate: _narrate,
        ),
      };
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        title: Text(
          title,
          style: ContentText.title(color: palette.textPrimary, size: 20),
        ),
      ),
      body: SafeArea(top: false, child: body),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Accueil de la séance
// ─────────────────────────────────────────────────────────────

class _Intro extends StatelessWidget {
  const _Intro({
    required this.session,
    required this.palette,
    required this.companion,
    required this.line,
    required this.onBegin,
  });

  final PackQuizSession session;
  final SubjectPalette palette;
  final TutorPersona companion;
  final QuizNarration line;
  final VoidCallback onBegin;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final plan = session.plan;
    final set = plan.set;
    final distribution = plan.distribution;
    // Réponses rédigées des séquences du quiz : hors du score objectif.
    final chapters = {
      for (final item in set.pool) item.chapter.contentId: item.chapter,
    }.values;
    final excluded = chapters
        .expand((chapter) => chapter.questions)
        .where((question) => question.requiresSelfEvaluation)
        .length;
    return ListView(
      key: const ValueKey('pack-quiz-intro'),
      padding: const EdgeInsets.fromLTRB(
        IntelliaSpacing.lg,
        IntelliaSpacing.sm,
        IntelliaSpacing.lg,
        IntelliaSpacing.xxl,
      ),
      children: [
        Text(
          (set.isMixed ? l10n.quizPackMixed : set.title),
          style: ContentText.title(color: palette.textPrimary, size: 26),
        ),
        const SizedBox(height: IntelliaSpacing.xs),
        Text(
          [
            packQuizModeLabel(context, plan.mode),
            l10n.quizPackSessionLength(plan.length),
          ].join(' · '),
          style: ContentText.label(color: palette.accent, size: 14),
        ),
        const SizedBox(height: IntelliaSpacing.md),
        QuizCompanionBubble(persona: companion, narration: line),
        const SizedBox(height: IntelliaSpacing.md),
        Text(
          plan.mode == PackQuizMode.training
              ? l10n.quizPackModeTrainingBody
              : l10n.quizPackModeEvaluationBody,
          style: ContentText.body(color: palette.textPrimary, size: 15),
        ),
        if (plan.mode == PackQuizMode.evaluation) ...[
          const SizedBox(height: IntelliaSpacing.xs),
          Text(
            l10n.quizPackDistribution(
              distribution[1] ?? 0,
              distribution[2] ?? 0,
              distribution[3] ?? 0,
            ),
            key: const ValueKey('pack-quiz-distribution'),
            style: ContentText.body(color: palette.textSecondary, size: 13.5),
          ),
        ],
        if (excluded > 0) ...[
          const SizedBox(height: IntelliaSpacing.sm),
          Text(
            l10n.quizPackUnscoredNote,
            style: ContentText.body(color: palette.textSecondary, size: 13),
          ),
        ],
        const SizedBox(height: IntelliaSpacing.lg),
        FilledButton(
          key: const ValueKey('pack-quiz-begin'),
          onPressed: onBegin,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: palette.accent,
            foregroundColor: palette.isDark
                ? const Color(0xFF111827)
                : Colors.white,
          ),
          child: Text(l10n.quizPackStart),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Question
// ─────────────────────────────────────────────────────────────

class _QuestionView extends StatelessWidget {
  const _QuestionView({
    required this.session,
    required this.palette,
    required this.companion,
    required this.line,
    required this.lineDetail,
    required this.reward,
    required this.canValidate,
    required this.onDraft,
    required this.onValidate,
    required this.onHint,
  });

  final PackQuizSession session;
  final SubjectPalette palette;
  final TutorPersona companion;
  final QuizNarration? line;
  final String? lineDetail;
  final RewardPattern? reward;
  final bool canValidate;
  final ValueChanged<StudentResponse?> onDraft;
  final VoidCallback onValidate;
  final VoidCallback onHint;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final item = session.item!;
    final question = item.question;
    final answer = session.answer;
    final training = session.mode == PackQuizMode.training;
    final card = Container(
      padding: const EdgeInsets.all(IntelliaSpacing.lg),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            question.prompt,
            key: const ValueKey('pack-quiz-prompt'),
            style: ContentText.body(
              color: palette.textPrimary,
              size: 18,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: IntelliaSpacing.md),
          AnswerInput(
            key: ValueKey('pack-quiz-answer-${session.attemptKey}'),
            question: question,
            onChanged: onDraft,
            enabled: answer == null && !session.busy,
            grade: training ? answer?.grade : null,
            attemptKey: session.attemptKey,
          ),
          for (var index = 0; index < session.hintsShown; index++) ...[
            const SizedBox(height: IntelliaSpacing.xs),
            Text(
              '${l10n.quizPackHintLabel(index + 1)} — ${question.hints[index]}',
              key: ValueKey('pack-quiz-hint-$index'),
              style: ContentText.body(color: palette.textSecondary, size: 14),
            ),
          ],
          const SizedBox(height: IntelliaSpacing.md),
          if (answer == null) ...[
            FilledButton(
              key: const ValueKey('pack-quiz-validate'),
              onPressed: canValidate ? onValidate : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: palette.accent,
                foregroundColor: palette.isDark
                    ? const Color(0xFF111827)
                    : Colors.white,
              ),
              child: Text(l10n.quizPackValidate),
            ),
            if (session.canHint)
              TextButton.icon(
                key: const ValueKey('pack-quiz-hint'),
                onPressed: onHint,
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: palette.accent,
                ),
                icon: const Icon(Icons.lightbulb_outline_rounded),
                label: Text(l10n.quizPackHint),
              ),
          ] else
            _Feedback(
              answer: answer,
              palette: palette,
              reward: reward,
              isLast: session.isLast,
              onNext: session.next,
            ),
        ],
      ),
    );
    return ListView(
      key: const ValueKey('pack-quiz-question'),
      padding: const EdgeInsets.fromLTRB(
        IntelliaSpacing.lg,
        IntelliaSpacing.xs,
        IntelliaSpacing.lg,
        IntelliaSpacing.xxl,
      ),
      children: [
        Semantics(
          label: l10n.quizPackQuestionProgress(
            session.index + 1,
            session.length,
          ),
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.quizPackQuestionProgress(
                    session.index + 1,
                    session.length,
                  ),
                  key: const ValueKey('pack-quiz-progress'),
                  style: ContentText.eyebrow(color: palette.accent),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value:
                        (session.index + (answer == null ? 0 : 1)) /
                        session.length,
                    minHeight: 5,
                    backgroundColor: palette.track,
                    color: palette.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (line case final narration?) ...[
          const SizedBox(height: IntelliaSpacing.md),
          QuizCompanionBubble(
            persona: companion,
            narration: narration,
            detail: lineDetail,
          ),
        ],
        const SizedBox(height: IntelliaSpacing.md),
        RewardStage(
          pattern: answer?.correct == true ? reward : null,
          accent: palette.accent,
          child: card,
        ),
      ],
    );
  }
}

/// Correction immédiate (entraînement) : le verdict, le diagnostic du
/// correcteur, puis le retour du pack — celui de la proposition choisie
/// s'il existe (affiché sous les choix), sinon l'explication.
class _Feedback extends StatelessWidget {
  const _Feedback({
    required this.answer,
    required this.palette,
    required this.reward,
    required this.isLast,
    required this.onNext,
  });

  final PackQuizAnswer answer;
  final SubjectPalette palette;
  final RewardPattern? reward;
  final bool isLast;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final question = answer.item.question;
    final color = answer.correct
        ? (palette.isDark ? const Color(0xFF7FD6A4) : ContentPalette.success)
        : (palette.isDark ? const Color(0xFFF2A99E) : ContentPalette.error);
    final explanation = question.explanation;
    return Column(
      key: const ValueKey('pack-quiz-feedback'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(IntelliaSpacing.md),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(IntelliaRadii.medium),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    answer.correct
                        ? Icons.check_circle_rounded
                        : Icons.highlight_off_rounded,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      answer.correct
                          ? l10n.quizPackCorrect
                          : l10n.quizPackIncorrect,
                      style: ContentText.label(color: color, size: 16),
                    ),
                  ),
                ],
              ),
              if (answer.correct && reward != null) ...[
                const SizedBox(height: 4),
                RewardMessageLine(pattern: reward),
              ],
              if (!answer.correct &&
                  answer.grade.diagnosis != null &&
                  answer.grade.diagnosis != GradeDiagnosis.different) ...[
                const SizedBox(height: 6),
                Text(
                  diagnosisText(context, answer.grade),
                  style: ContentText.body(
                    color: palette.textPrimary,
                    size: 14.5,
                  ),
                ),
              ],
              if (!answer.correct) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.expectedAnswer(answerSummary(context, question.answer)),
                  key: const ValueKey('pack-quiz-expected-answer'),
                  style: ContentText.body(
                    color: palette.textPrimary,
                    size: 14.5,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
              if (explanation != null) ...[
                const SizedBox(height: 6),
                Text(
                  explanation,
                  key: const ValueKey('pack-quiz-explanation'),
                  style: ContentText.body(
                    color: palette.textPrimary,
                    size: 14.5,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        FilledButton.icon(
          key: const ValueKey('pack-quiz-next'),
          onPressed: onNext,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: palette.accent,
            foregroundColor: palette.isDark
                ? const Color(0xFF111827)
                : Colors.white,
          ),
          icon: Icon(isLast ? Icons.flag_rounded : Icons.arrow_forward_rounded),
          label: Text(isLast ? l10n.quizPackSeeResult : l10n.quizPackNext),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bilan
// ─────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.session,
    required this.before,
    required this.after,
    required this.palette,
    required this.companion,
    required this.line,
    required this.showReview,
    required this.onToggleReview,
    required this.onRetry,
    required this.onContinue,
    required this.narrate,
  });

  final PackQuizSession session;
  final LearnerContentSnapshot before;
  final LearnerContentSnapshot after;
  final SubjectPalette palette;
  final TutorPersona companion;
  final QuizNarration line;
  final bool showReview;
  final VoidCallback onToggleReview;
  final VoidCallback onRetry;
  final VoidCallback onContinue;
  final QuizNarration Function(
    QuizNarrationEvent event, {
    String questionId,
    Map<String, Object> values,
  })
  narrate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = session.result;
    final concepts = result.concepts;
    final mastered = [
      for (final concept in concepts)
        if (concept.mastered) concept,
    ];
    final toReview = [
      for (final concept in concepts)
        if (!concept.mastered) concept,
    ];
    // Progrès mesuré dans la maîtrise elle-même (avant / après la séance).
    PackQuizConceptOutcome? improved;
    var bestGain = 0;
    for (final concept in concepts) {
      final gain =
          after.conceptState(concept.conceptId).score -
          before.conceptState(concept.conceptId).score;
      if (gain > bestGain) {
        bestGain = gain;
        improved = concept;
      }
    }
    final followUp = toReview.isNotEmpty
        ? narrate(
            QuizNarrationEvent.needsReview,
            questionId: toReview.first.conceptId,
            values: {'concept': toReview.first.title},
          )
        : improved != null
        ? narrate(
            QuizNarrationEvent.masteryImproved,
            questionId: improved.conceptId,
            values: {'concept': improved.title},
          )
        : null;

    return ListView(
      key: const ValueKey('pack-quiz-result'),
      padding: const EdgeInsets.fromLTRB(
        IntelliaSpacing.lg,
        IntelliaSpacing.sm,
        IntelliaSpacing.lg,
        IntelliaSpacing.xxl,
      ),
      children: [
        Text(
          l10n.quizPackResultTitle,
          style: ContentText.title(color: palette.textPrimary, size: 26),
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        Semantics(
          container: true,
          label:
              '${l10n.quizPackScore(result.score, result.total)}, '
              '${l10n.ljProgressPercent(result.percent)}',
          child: ExcludeSemantics(
            child: Container(
              key: const ValueKey('pack-quiz-score'),
              padding: const EdgeInsets.all(IntelliaSpacing.lg),
              decoration: BoxDecoration(
                color: palette.accent.withValues(
                  alpha: palette.isDark ? 0.18 : 0.08,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Wrap(
                spacing: IntelliaSpacing.md,
                runSpacing: IntelliaSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  Text(
                    l10n.quizPackScore(result.score, result.total),
                    style: ContentText.math(color: palette.accent, size: 34),
                  ),
                  Text(
                    l10n.ljProgressPercent(result.percent),
                    style: ContentText.math(
                      color: palette.textPrimary,
                      size: 22,
                    ),
                  ),
                  Text(
                    packQuizModeLabel(context, session.mode),
                    style: ContentText.label(
                      color: palette.textSecondary,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: IntelliaSpacing.md),
        QuizCompanionBubble(persona: companion, narration: line),
        if (followUp != null) ...[
          const SizedBox(height: IntelliaSpacing.xs),
          QuizCompanionBubble(persona: companion, narration: followUp),
        ],
        if (mastered.isNotEmpty) ...[
          const SizedBox(height: IntelliaSpacing.lg),
          _ConceptList(
            title: l10n.quizPackMastered,
            concepts: mastered,
            palette: palette,
            icon: Icons.check_circle_rounded,
            keyName: 'pack-quiz-mastered',
          ),
        ],
        if (toReview.isNotEmpty) ...[
          const SizedBox(height: IntelliaSpacing.md),
          _ConceptList(
            title: l10n.quizPackToReview,
            concepts: toReview,
            palette: palette,
            icon: Icons.replay_rounded,
            keyName: 'pack-quiz-to-review',
          ),
        ],
        const SizedBox(height: IntelliaSpacing.lg),
        OutlinedButton.icon(
          key: const ValueKey('pack-quiz-review'),
          onPressed: onToggleReview,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: palette.accent,
            side: BorderSide(color: palette.accent),
          ),
          icon: Icon(
            showReview ? Icons.expand_less_rounded : Icons.expand_more_rounded,
          ),
          label: Text(l10n.quizPackReview),
        ),
        if (showReview) ...[
          const SizedBox(height: IntelliaSpacing.sm),
          for (final (index, answer) in result.answers.indexed)
            _AnswerReview(
              index: index,
              total: result.total,
              answer: answer,
              palette: palette,
            ),
        ],
        const SizedBox(height: IntelliaSpacing.sm),
        FilledButton.icon(
          key: const ValueKey('pack-quiz-retry'),
          onPressed: onRetry,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: palette.accent,
            foregroundColor: palette.isDark
                ? const Color(0xFF111827)
                : Colors.white,
          ),
          icon: const Icon(Icons.refresh_rounded),
          label: Text(l10n.quizPackRetry),
        ),
        const SizedBox(height: IntelliaSpacing.xs),
        TextButton(
          key: const ValueKey('pack-quiz-continue'),
          onPressed: onContinue,
          style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: palette.accent,
          ),
          child: Text(l10n.quizPackContinue),
        ),
      ],
    );
  }
}

class _ConceptList extends StatelessWidget {
  const _ConceptList({
    required this.title,
    required this.concepts,
    required this.palette,
    required this.icon,
    required this.keyName,
  });

  final String title;
  final List<PackQuizConceptOutcome> concepts;
  final SubjectPalette palette;
  final IconData icon;
  final String keyName;

  @override
  Widget build(BuildContext context) => Column(
    key: ValueKey(keyName),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title.toUpperCase(),
        style: ContentText.eyebrow(color: palette.accent),
      ),
      for (final concept in concepts)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: palette.accent),
              const SizedBox(width: IntelliaSpacing.xs),
              Expanded(
                child: Text(
                  context.l10n.quizPackConceptScore(
                    concept.title,
                    concept.correct,
                    concept.total,
                  ),
                  style: ContentText.body(
                    color: palette.textPrimary,
                    size: 14.5,
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

/// Une réponse de la séance, avec la correction du pack.
class _AnswerReview extends StatelessWidget {
  const _AnswerReview({
    required this.index,
    required this.total,
    required this.answer,
    required this.palette,
  });

  final int index;
  final int total;
  final PackQuizAnswer answer;
  final SubjectPalette palette;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final question = answer.item.question;
    final color = answer.correct
        ? (palette.isDark ? const Color(0xFF7FD6A4) : ContentPalette.success)
        : (palette.isDark ? const Color(0xFFF2A99E) : ContentPalette.error);
    return Container(
      key: ValueKey('pack-quiz-review-$index'),
      margin: const EdgeInsets.only(bottom: IntelliaSpacing.sm),
      padding: const EdgeInsets.all(IntelliaSpacing.md),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                answer.correct
                    ? Icons.check_circle_rounded
                    : Icons.highlight_off_rounded,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${l10n.quizPackQuestionProgress(index + 1, total)} · '
                  '${answer.correct ? l10n.quizPackCorrect : l10n.quizPackIncorrect}',
                  style: ContentText.label(color: color, size: 13.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            question.prompt,
            style: ContentText.body(
              color: palette.textPrimary,
              size: 14.5,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.expectedAnswer(answerSummary(context, question.answer)),
            key: ValueKey('pack-quiz-review-answer-$index'),
            style: ContentText.body(color: palette.textPrimary, size: 14),
          ),
          if (question.explanation case final explanation?) ...[
            const SizedBox(height: 4),
            Text(
              explanation,
              style: ContentText.body(color: palette.textSecondary, size: 14),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuizSkeleton extends StatelessWidget {
  const _QuizSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    key: const ValueKey('pack-quiz-loading'),
    padding: const EdgeInsets.all(IntelliaSpacing.lg),
    children: const [
      IntelliaSkeletonBlock(height: 34, width: 220, radius: 10),
      SizedBox(height: IntelliaSpacing.md),
      IntelliaSkeletonBlock(height: 64, radius: 18),
      SizedBox(height: IntelliaSpacing.md),
      IntelliaSkeletonBlock(height: 260, radius: 24),
    ],
  );
}
