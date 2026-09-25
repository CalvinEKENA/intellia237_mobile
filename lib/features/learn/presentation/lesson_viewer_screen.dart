import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/academics/choice_order.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/telemetry/intellia_telemetry.dart';
import '../../../core/widgets/intellia_async_states.dart';
import '../../../core/widgets/intellia_pressable.dart';
import '../../../core/widgets/intellia_state_view.dart';
import '../../../core/widgets/tab_presentation.dart';
import '../../auth/application/auth_controller.dart';
import '../../student_home/application/personal_goal_providers.dart';
import '../../student_home/application/student_home_controller.dart';
import '../../student_home/domain/student_home_snapshot.dart';
import '../../tutor/application/tutor_preference_provider.dart';
import '../../tutor/domain/tutor_persona.dart';
import '../application/learn_providers.dart';
import '../data/lesson_resume_store.dart';
import '../domain/learn_lesson.dart';
import '../domain/learn_route_requests.dart';
import 'widgets/content_block_view.dart';

/// Lecteur de leçon — mode lecture clair, chrome minimal.
///
/// Décisions produit (registre) :
/// - Le slider manuel d'avancement est supprimé : la progression vient
///   d'interactions pédagogiquement significatives (mini-quiz réussi → 90 %
///   côté serveur, « Marquer comme terminée » → 100 %).
/// - La prochaine action est toujours identifiable : fin de leçon → sheet
///   « Leçon terminée » avec accès direct à la leçon suivante du chapitre.
/// - L'accès au compagnon transmet le sujet de la leçon (contexte).
class LessonViewerScreen extends ConsumerStatefulWidget {
  const LessonViewerScreen({
    required this.subjectId,
    required this.chapterId,
    required this.lessonId,
    super.key,
  });

  final String subjectId;
  final String chapterId;
  final String lessonId;

  @override
  ConsumerState<LessonViewerScreen> createState() => _LessonViewerScreenState();
}

class _LessonViewerScreenState extends ConsumerState<LessonViewerScreen> {
  final Map<String, int> _miniQuizAnswers = {};

  /// Une seule tentative de mini-quiz par ouverture de la leçon : l'ordre
  /// des propositions ne bouge plus jusqu'à la correction.
  final String _quizAttemptKey = newChoiceAttemptKey();
  final ScrollController _scrollCtrl = ScrollController();

  bool _quizSubmitted = false;
  int _quizScore = 0;
  double _scrollProgress = 0.0;
  bool _showFinishButton = false;
  bool _isMarkingDone = false;
  bool _resumeSaved = false;
  LearnLesson? _loadedLesson;

  LessonRequest get _request => LessonRequest(
    subjectId: widget.subjectId,
    chapterId: widget.chapterId,
    lessonId: widget.lessonId,
  );

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  /// Ne reconstruit que si la barre bouge visiblement (pas de setState par
  /// frame de scroll : budget perf des téléphones modestes).
  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final max = _scrollCtrl.position.maxScrollExtent;
    if (max <= 0) return;

    final ratio = (_scrollCtrl.offset / max).clamp(0.0, 1.0);
    final shouldShow = ratio >= 0.80;
    if ((ratio - _scrollProgress).abs() < 0.01 &&
        shouldShow == _showFinishButton) {
      return;
    }
    setState(() {
      _scrollProgress = ratio;
      _showFinishButton = shouldShow;
    });
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(lessonDetailProvider(_request));

    return TabSurface(
      palette: const TabPalette(TabPresentationMode.embeddedLight),
      child: Scaffold(
        backgroundColor: IntelliaColors.backgroundPrimary,
        body: Column(
          children: [
            _ScrollProgressBar(progress: _scrollProgress),
            Expanded(
              child: lessonAsync.when(
                loading: () =>
                    const IntelliaStateView(kind: IntelliaStateKind.loading),
                error: (error, stackTrace) => IntelliaStateView(
                  kind: stateKindForError(error),
                  title: context.l10n.lessonUnavailable,
                  message: stateMessageForKind(
                    context,
                    stateKindForError(error),
                  ),
                  primaryLabel: context.l10n.retryLabel,
                  onPrimary: () =>
                      ref.invalidate(lessonDetailProvider(_request)),
                  secondaryLabel: context.l10n.backLabel,
                  onSecondary: () => Navigator.of(context).maybePop(),
                ),
                data: (lesson) {
                  _loadedLesson = lesson;
                  _saveResumeBookmark(lesson.progress, lesson: lesson);
                  return _LessonBody(
                    lesson: lesson,
                    scrollCtrl: _scrollCtrl,
                    miniQuizAnswers: _miniQuizAnswers,
                    quizAttemptKey: _quizAttemptKey,
                    quizSubmitted: _quizSubmitted,
                    quizScore: _quizScore,
                    showFinishButton: _showFinishButton,
                    isMarkingDone: _isMarkingDone,
                    onAnswer: (questionId, index) {
                      if (_quizSubmitted) return;
                      setState(() => _miniQuizAnswers[questionId] = index);
                    },
                    onSubmitQuiz: () => _submitMiniQuiz(lesson),
                    onMarkDone: _handleMarkDone,
                    onAskAi: () => _openCompanion(lesson),
                    onToggleFavorite: () => ref
                        .read(learnActionsProvider)
                        .toggleFavorite(
                          subjectId: widget.subjectId,
                          chapterId: widget.chapterId,
                          lessonId: widget.lessonId,
                        ),
                    tutor:
                        ref.watch(selectedTutorProvider) ??
                        TutorPersona.all.first,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Compagnon avec contexte : le sujet de la leçon voyage avec la route.
  void _openCompanion(LearnLesson lesson) {
    final topic = Uri.encodeComponent(lesson.title);
    context.push('${AppRoutes.aiCompanion}?topic=$topic');
  }

  Future<void> _submitMiniQuiz(LearnLesson lesson) async {
    if (lesson.miniQuiz.isEmpty) return;

    int score = 0;
    for (final question in lesson.miniQuiz) {
      if (_miniQuizAnswers[question.id] == question.correctIndex) {
        score += 1;
      }
    }

    setState(() {
      _quizSubmitted = true;
      _quizScore = score;
    });

    final ratio = score / lesson.miniQuiz.length;
    if (ratio >= 0.7 && lesson.progress < 0.9) {
      // Progression pédagogiquement significative : mini-quiz réussi.
      try {
        await ref
            .read(learnActionsProvider)
            .saveProgress(
              subjectId: widget.subjectId,
              chapterId: widget.chapterId,
              lessonId: widget.lessonId,
              progress: 0.9,
            );
        _saveResumeBookmark(0.9);
      } catch (_) {
        // L'échec de sauvegarde ne casse pas la lecture ; l'élève pourra
        // marquer la leçon terminée (avec message d'erreur explicite).
      }
    }
  }

  /// Signet local de reprise : écrit à l'ouverture, mis à jour à la fin.
  void _saveResumeBookmark(double progress, {LearnLesson? lesson}) {
    final loaded = lesson ?? _loadedLesson;
    if (loaded == null) return;
    if (lesson != null && _resumeSaved) return;
    if (lesson != null) {
      _resumeSaved = true;
      IntelliaTelemetry.lessonOpened().ignore();
    }

    Future(() async {
      try {
        final userId = ref.read(authControllerProvider).userId;
        if (userId == null) return;
        final store = await ref.read(lessonResumeStoreProvider.future);
        await store.save(
          userId,
          ResumeTarget(
            subjectId: widget.subjectId,
            chapterId: widget.chapterId,
            lessonId: widget.lessonId,
            lessonTitle: loaded.title,
            progress: progress.clamp(0.0, 1.0),
          ),
        );
      } catch (_) {
        // Signet non critique.
      }
    });
  }

  Future<void> _handleMarkDone() async {
    if (_isMarkingDone) return;

    setState(() => _isMarkingDone = true);

    try {
      final saveStatus = await ref
          .read(learnActionsProvider)
          .saveProgress(
            subjectId: widget.subjectId,
            chapterId: widget.chapterId,
            lessonId: widget.lessonId,
            progress: 1.0,
          );

      _saveResumeBookmark(1.0);
      IntelliaTelemetry.lessonCompleted(completionPercent: 100).ignore();
      ref.invalidate(studentHomeControllerProvider);
      // Objectif hebdo : une leçon terminée compte comme séance du jour.
      ref
          .read(personalGoalControllerProvider.notifier)
          .recordActivityToday()
          .ignore();

      if (!mounted) return;
      if (saveStatus == LessonProgressSaveStatus.queued) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.localProgressSaved),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _showCompletionSheet();
    } catch (error) {
      if (!mounted) return;
      final kind = stateKindForError(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kind == IntelliaStateKind.offline
                ? context.l10n.lessonProgressQueuedOffline
                : context.l10n.lessonProgressSaveFailed,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isMarkingDone = false);
      }
    }
  }

  /// Fin de leçon : célébration sobre + prochaine action explicite.
  Future<void> _showCompletionSheet() async {
    final next = await _findNextLesson();
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isDismissible: true,
      builder: (sheetContext) => _CompletionSheet(
        nextLesson: next,
        onNext: next == null
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                context.pushReplacement(
                  AppRoutes.lessonViewer(
                    widget.subjectId,
                    widget.chapterId,
                    next.id,
                  ),
                );
              },
        onBack: () {
          Navigator.of(sheetContext).pop();
          Navigator.of(context).maybePop();
        },
      ),
    );
  }

  Future<LearnLessonPreview?> _findNextLesson() async {
    try {
      final chapter = await ref.read(
        chapterDetailProvider(
          ChapterRequest(
            subjectId: widget.subjectId,
            chapterId: widget.chapterId,
          ),
        ).future,
      );
      final index = chapter.lessons.indexWhere((l) => l.id == widget.lessonId);
      if (index == -1 || index + 1 >= chapter.lessons.length) return null;
      return chapter.lessons[index + 1];
    } catch (_) {
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Fine barre de progression de lecture
// ─────────────────────────────────────────────────────────────

class _ScrollProgressBar extends StatelessWidget {
  const _ScrollProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 3,
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Container(color: s.surfaceMuted),
              Container(
                width: constraints.maxWidth * progress,
                decoration: const BoxDecoration(
                  gradient: IntelliaGradients.brand,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Corps de la leçon
// ─────────────────────────────────────────────────────────────

class _LessonBody extends StatelessWidget {
  const _LessonBody({
    required this.lesson,
    required this.scrollCtrl,
    required this.miniQuizAnswers,
    required this.quizAttemptKey,
    required this.quizSubmitted,
    required this.quizScore,
    required this.showFinishButton,
    required this.isMarkingDone,
    required this.onAnswer,
    required this.onSubmitQuiz,
    required this.onMarkDone,
    required this.onAskAi,
    required this.onToggleFavorite,
    required this.tutor,
  });

  final LearnLesson lesson;
  final ScrollController scrollCtrl;
  final Map<String, int> miniQuizAnswers;
  final String quizAttemptKey;
  final bool quizSubmitted;
  final int quizScore;
  final bool showFinishButton;
  final bool isMarkingDone;
  final void Function(String, int) onAnswer;
  final VoidCallback onSubmitQuiz;
  final VoidCallback onMarkDone;
  final VoidCallback onAskAi;
  final VoidCallback onToggleFavorite;
  final TutorPersona tutor;

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);

    return Stack(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(
                IntelliaSpacing.lg,
                IntelliaSpacing.sm,
                IntelliaSpacing.lg,
                120,
              ),
              children: [
                // Retour + favori.
                Row(
                  children: [
                    IconButton(
                      tooltip: context.l10n.backLabel,
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: s.iconPrimary,
                      ),
                    ),
                    const Spacer(),
                    Semantics(
                      button: true,
                      label: lesson.isFavorite
                          ? context.l10n.removeFromFavorites
                          : context.l10n.addToFavorites,
                      child: IconButton(
                        onPressed: onToggleFavorite,
                        icon: Icon(
                          lesson.isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: lesson.isFavorite
                              ? const Color(0xFFE0426B)
                              : s.iconSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: IntelliaSpacing.xs),

                _LessonHeader(lesson: lesson),
                const SizedBox(height: IntelliaSpacing.md),

                _AskAiBanner(onTap: onAskAi, tutor: tutor),
                const SizedBox(height: IntelliaSpacing.lg),

                // Contenu de la leçon. `effectiveBlocks` promeut les sections
                // d'une leçon V1 en blocs de texte : le lecteur ne connaît
                // donc qu'un seul flux, et une leçon ancienne reste rendue
                // exactement comme avant.
                for (final block in lesson.effectiveBlocks) ...[
                  ContentBlockView(block: block),
                  const SizedBox(height: IntelliaSpacing.lg),
                ],

                if (lesson.miniQuiz.isNotEmpty) ...[
                  _MiniQuizSection(
                    questions: lesson.miniQuiz,
                    selectedAnswers: miniQuizAnswers,
                    attemptKey: quizAttemptKey,
                    submitted: quizSubmitted,
                    score: quizScore,
                    onAnswer: onAnswer,
                    onSubmit: onSubmitQuiz,
                  ),
                  const SizedBox(height: IntelliaSpacing.lg),
                ],
              ],
            ),
          ),
        ),

        // CTA de fin (après 80 % de lecture) — n'apparaît pas si déjà faite.
        if (showFinishButton && lesson.progress < 1.0)
          Positioned(
            bottom: IntelliaSpacing.lg,
            left: IntelliaSpacing.lg,
            right: IntelliaSpacing.lg,
            child: SafeArea(
              top: false,
              child: _FinishButton(
                isLoading: isMarkingDone,
                onPressed: onMarkDone,
              ),
            ),
          ),
      ],
    );
  }
}

class _FinishButton extends StatefulWidget {
  const _FinishButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  State<_FinishButton> createState() => _FinishButtonState();
}

class _FinishButtonState extends State<_FinishButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: IntelliaMotion.medium,
    );
    if (SchedulerBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .disableAnimations ||
        (WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .reduceMotion)) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _entrance,
              curve: IntelliaMotion.emphasizedDecelerate,
            ),
          ),
      child: Semantics(
        button: true,
        label: context.l10n.markLessonComplete,
        child: IntelliaPressable(
          onTap: widget.isLoading ? null : widget.onPressed,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: IntelliaGradients.brand,
              borderRadius: BorderRadius.circular(IntelliaRadii.full),
              boxShadow: IntelliaShadows.glow(
                IntelliaColors.brandIndigo,
                intensity: 0.30,
              ),
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      context.l10n.markComplete,
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
    );
  }
}

// ─────────────────────────────────────────────────────────────
// En-tête de la leçon
// ─────────────────────────────────────────────────────────────

class _LessonHeader extends StatelessWidget {
  const _LessonHeader({required this.lesson});

  final LearnLesson lesson;

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lesson.title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: s.textPrimary,
            height: 1.2,
          ),
        ),
        if (lesson.summary.isNotEmpty) ...[
          const SizedBox(height: IntelliaSpacing.xs),
          Text(
            lesson.summary,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: s.textSecondary,
              height: 1.55,
            ),
          ),
        ],
        const SizedBox(height: IntelliaSpacing.sm),
        Row(
          children: [
            Icon(Icons.schedule_rounded, size: 14, color: s.numberAccent),
            const SizedBox(width: 4),
            Text(
              context.l10n.lessonReadingMinutes(lesson.estimatedMinutes),
              style: TextStyle(
                fontSize: 12,
                color: s.numberAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (lesson.progress >= 1.0) ...[
              const SizedBox(width: IntelliaSpacing.sm),
              Icon(Icons.check_circle_rounded, size: 14, color: s.success),
              const SizedBox(width: 4),
              Text(
                context.l10n.completedLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: s.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bannière compagnon (avec contexte de leçon)
// ─────────────────────────────────────────────────────────────

class _AskAiBanner extends StatelessWidget {
  const _AskAiBanner({required this.onTap, required this.tutor});

  final VoidCallback onTap;
  final TutorPersona tutor;

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);
    return Semantics(
      button: true,
      label: context.l10n.askTutorAboutLesson(tutor.name),
      child: IntelliaPressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: IntelliaSpacing.md,
            vertical: IntelliaSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: s.accentSoft,
            borderRadius: BorderRadius.circular(IntelliaRadii.medium),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage(tutor.imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: IntelliaSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.askTutorPrompt(tutor.name.split(' ').first),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: s.accent,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: s.accent, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Section de contenu (lecture)
// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
// Mini quiz de fin de leçon
// ─────────────────────────────────────────────────────────────

class _MiniQuizSection extends StatelessWidget {
  const _MiniQuizSection({
    required this.questions,
    required this.selectedAnswers,
    required this.attemptKey,
    required this.submitted,
    required this.score,
    required this.onAnswer,
    required this.onSubmit,
  });

  final List<LessonMiniQuizQuestion> questions;
  final Map<String, int> selectedAnswers;
  final String attemptKey;
  final bool submitted;
  final int score;
  final void Function(String questionId, int index) onAnswer;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);
    final allAnswered = questions.every((q) => selectedAnswers[q.id] != null);

    return Container(
      padding: const EdgeInsets.all(IntelliaSpacing.lg),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.circular(IntelliaRadii.large),
        border: Border.all(color: s.border),
        boxShadow: IntelliaShadows.card(Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.checkUnderstanding,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: s.textPrimary,
            ),
          ),
          const SizedBox(height: IntelliaSpacing.md),
          for (final question in questions) ...[
            Text(
              question.prompt,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: s.textPrimary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: IntelliaSpacing.sm),
            // Ordre mélangé, index d'origine conservés pour la correction.
            for (final index in choiceOrder(
              question.options.length,
              questionId: question.id,
              attemptKey: attemptKey,
            ))
              Padding(
                padding: const EdgeInsets.only(bottom: IntelliaSpacing.xs),
                child: _QuizOptionTile(
                  label: question.options[index],
                  selected: selectedAnswers[question.id] == index,
                  enabled: !submitted,
                  // Après soumission : la bonne réponse est montrée, et
                  // l'erreur de l'élève est signalée (couleur + icône).
                  verdict: !submitted
                      ? _OptionVerdict.none
                      : index == question.correctIndex
                      ? _OptionVerdict.correct
                      : selectedAnswers[question.id] == index
                      ? _OptionVerdict.incorrect
                      : _OptionVerdict.none,
                  onTap: () => onAnswer(question.id, index),
                ),
              ),
            if (submitted) ...[
              Container(
                margin: const EdgeInsets.only(top: IntelliaSpacing.xs),
                padding: const EdgeInsets.all(IntelliaSpacing.sm),
                decoration: BoxDecoration(
                  color: s.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(IntelliaRadii.small),
                  border: Border.all(color: s.success.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 14,
                      color: s.success,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        question.explanation,
                        style: TextStyle(
                          fontSize: 12,
                          color: s.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: IntelliaSpacing.md),
            ],
          ],
          if (submitted)
            Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: IntelliaSpacing.md,
                  vertical: IntelliaSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: s.accentSoft,
                  borderRadius: BorderRadius.circular(IntelliaRadii.small),
                ),
                child: Text(
                  score / questions.length >= 0.7
                      ? context.l10n.miniQuizScoreSuccess(
                          score,
                          questions.length,
                        )
                      : context.l10n.miniQuizScoreReview(
                          score,
                          questions.length,
                        ),
                  style: TextStyle(
                    color: s.accent,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            Semantics(
              button: true,
              label: allAnswered
                  ? context.l10n.submitMiniQuiz
                  : context.l10n.answerAllBeforeSubmit,
              child: IntelliaPressable(
                onTap: allAnswered ? onSubmit : null,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: allAnswered ? IntelliaGradients.brand : null,
                    color: allAnswered ? null : s.surfaceMuted,
                    borderRadius: BorderRadius.circular(IntelliaRadii.full),
                  ),
                  child: Center(
                    child: Text(
                      allAnswered
                          ? context.l10n.submitMiniQuiz
                          : context.l10n.answerAllQuestions,
                      style: TextStyle(
                        color: allAnswered ? Colors.white : s.textDisabled,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _OptionVerdict { none, correct, incorrect }

class _QuizOptionTile extends StatelessWidget {
  const _QuizOptionTile({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.verdict,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final _OptionVerdict verdict;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);

    final Color borderColor;
    final Color? fillColor;
    final IconData? trailingIcon;
    final Color? trailingColor;
    switch (verdict) {
      case _OptionVerdict.correct:
        borderColor = s.success;
        fillColor = s.success.withValues(alpha: 0.10);
        trailingIcon = Icons.check_circle_rounded;
        trailingColor = s.success;
      case _OptionVerdict.incorrect:
        borderColor = s.error;
        fillColor = s.error.withValues(alpha: 0.08);
        trailingIcon = Icons.cancel_rounded;
        trailingColor = s.error;
      case _OptionVerdict.none:
        borderColor = selected ? s.accent : s.border;
        fillColor = selected ? s.accentSoft : null;
        trailingIcon = null;
        trailingColor = null;
    }

    return Semantics(
      button: enabled,
      selected: selected,
      label: switch (verdict) {
        _OptionVerdict.correct => context.l10n.correctAnswerA11y(label),
        _OptionVerdict.incorrect => context.l10n.incorrectAnswerA11y(label),
        _OptionVerdict.none => label,
      },
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: IntelliaMotion.fast,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(
            horizontal: IntelliaSpacing.md,
            vertical: IntelliaSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(IntelliaRadii.small),
            color: fillColor ?? s.surfaceMuted.withValues(alpha: 0.5),
            border: Border.all(
              color: borderColor,
              width: selected || verdict != _OptionVerdict.none ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: IntelliaMotion.fast,
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? s.accent : Colors.transparent,
                  border: Border.all(
                    color: selected ? s.accent : s.textTertiary,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 11,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: IntelliaSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: s.textPrimary,
                    height: 1.4,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (trailingIcon != null)
                Icon(trailingIcon, size: 18, color: trailingColor),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Sheet de fin de leçon — prochaine action explicite
// ─────────────────────────────────────────────────────────────

class _CompletionSheet extends StatelessWidget {
  const _CompletionSheet({
    required this.nextLesson,
    required this.onNext,
    required this.onBack,
  });

  final LearnLessonPreview? nextLesson;
  final VoidCallback? onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final s = TabPalette.forBrightness(Theme.of(context).brightness);
    return TabSurface(
      palette: s,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            IntelliaSpacing.lg,
            0,
            IntelliaSpacing.lg,
            IntelliaSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 64,
                height: 64,
                margin: const EdgeInsets.only(bottom: IntelliaSpacing.sm),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: s.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded, color: s.success, size: 34),
              ),
              Text(
                context.l10n.lessonCompletedCongrats,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: s.textPrimary,
                ),
              ),
              const SizedBox(height: IntelliaSpacing.xs),
              Text(
                nextLesson == null
                    ? context.l10n.lastLessonCompleted
                    : context.l10n.nextStepLesson(nextLesson!.title),
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: s.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: IntelliaSpacing.lg),
              if (onNext != null)
                Semantics(
                  button: true,
                  label: context.l10n.startNextLesson,
                  child: IntelliaPressable(
                    onTap: onNext,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: IntelliaGradients.brand,
                        borderRadius: BorderRadius.circular(IntelliaRadii.full),
                      ),
                      child: Center(
                        child: Text(
                          context.l10n.nextLesson,
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
              const SizedBox(height: IntelliaSpacing.xs),
              TextButton(
                onPressed: onBack,
                child: Text(context.l10n.backToChapter),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
