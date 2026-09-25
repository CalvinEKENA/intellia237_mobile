import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/widgets/intellia_state_view.dart';
import '../application/content_providers.dart';
import '../application/practice_session.dart';
import '../domain/chapter.dart';
import '../domain/game_blueprint.dart';
import '../domain/mastery.dart';
import '../domain/pedagogy.dart';
import '../domain/visual_kind.dart';
import '../engine/companion_engine.dart';
import 'content_style.dart';
import 'visuals/concept_visuals.dart';
import 'widgets/companion_sheet.dart';
import 'widgets/explanation_panel.dart';
import 'widgets/practice_panel.dart';

/// Une leçon : Je comprends → Je vois → J'essaie → Je réussis → Je passe au
/// formalisme. Tout est déjà sur l'appareil : aucun changement ne recharge.
class ContentLessonScreen extends ConsumerWidget {
  const ContentLessonScreen({
    required this.contentId,
    required this.lessonNumber,
    super.key,
  });

  final String contentId;
  final int lessonNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapterAsync = ref.watch(contentChapterProvider(contentId));
    return chapterAsync.when(
      loading: () => const Scaffold(
        backgroundColor: ContentPalette.paper,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => _Missing(message: context.l10n.ceLoadError),
      data: (chapter) {
        final lesson = chapter.lesson(lessonNumber);
        final concept = chapter.conceptForLesson(lessonNumber);
        if (!chapter.isPlayable || lesson == null || concept == null) {
          return _Missing(message: context.l10n.ceUnavailableBody);
        }
        return _LessonView(chapter: chapter, lesson: lesson, concept: concept);
      },
    );
  }
}

class _Missing extends StatelessWidget {
  const _Missing({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: ContentPalette.paper,
    appBar: AppBar(backgroundColor: ContentPalette.paper),
    body: Padding(
      padding: const EdgeInsets.all(IntelliaSpacing.lg),
      child: IntelliaStateView(
        kind: IntelliaStateKind.comingSoon,
        title: context.l10n.ceUnavailableTitle,
        message: message,
      ),
    ),
  );
}

class _LessonView extends ConsumerStatefulWidget {
  const _LessonView({
    required this.chapter,
    required this.lesson,
    required this.concept,
  });

  final Chapter chapter;
  final Lesson lesson;
  final Concept concept;

  @override
  ConsumerState<_LessonView> createState() => _LessonViewState();
}

class _LessonViewState extends ConsumerState<_LessonView> {
  static const _steps = 5;
  int _step = 0;
  late final PracticeSession _session;

  @override
  void initState() {
    super.initState();
    final snapshot =
        ref.read(learnerContentControllerProvider).valueOrNull ??
        LearnerContentSnapshot.empty;
    _session = PracticeSession(
      chapter: widget.chapter,
      lessonNumber: widget.lesson.number,
      answered: snapshot.conceptState(widget.concept.id).answeredQuestionIds,
      recorder: (question, correct) => ref
          .read(learnerContentControllerProvider.notifier)
          .recordAnswer(
            chapter: widget.chapter,
            question: question,
            correct: correct,
          ),
    );
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  void _chooseMode(ExplanationMode mode) => ref
      .read(learnerContentControllerProvider.notifier)
      .chooseExplanation(
        mode,
        chapter: widget.chapter,
        conceptId: widget.concept.id,
      );

  CompanionContext _companionContext() => CompanionContext(
    conceptId: widget.concept.id,
    lessonNumber: widget.lesson.number,
    question: _step == 2 ? _session.current : null,
    lastGrade: _step == 2 ? _session.lastGrade : null,
    hintsShown: _session.hintsShown,
    difficulty: _session.difficulty,
    answered: _session.answeredIds,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final snapshot =
        ref.watch(learnerContentControllerProvider).valueOrNull ??
        LearnerContentSnapshot.empty;
    final state = snapshot.conceptState(widget.concept.id);
    final journey = [
      l10n.ceJourneyUnderstand,
      l10n.ceJourneySee,
      l10n.ceJourneyTry,
      l10n.ceJourneySucceed,
      l10n.ceJourneyFormal,
    ];
    return Scaffold(
      backgroundColor: ContentPalette.paper,
      appBar: AppBar(
        backgroundColor: ContentPalette.paper,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ContentPalette.ink,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.ceLessonLabel(widget.lesson.number).toUpperCase(),
              style: ContentText.eyebrow(),
            ),
            Text(
              widget.lesson.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ContentText.label(size: 16),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: IntelliaSpacing.md),
            child: MasteryRing(
              score: state.score,
              size: 36,
              child: Text('${state.score}', style: ContentText.label(size: 11)),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: _StepBar(
            current: _step,
            onSelected: (step) => setState(() => _step = step),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('open-companion'),
        backgroundColor: ContentPalette.ink,
        foregroundColor: Colors.white,
        onPressed: () => CompanionSheet.show(
          context,
          chapter: widget.chapter,
          companionContext: _companionContext,
          onHintShown: _session.hintShown,
          onTryQuestion: (question) {
            setState(() => _step = 2);
            _session.focus(question);
          },
        ),
        icon: const Icon(Icons.auto_awesome_rounded),
        label: Text(l10n.ceCompanionButton),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          IntelliaSpacing.lg,
          IntelliaSpacing.md,
          IntelliaSpacing.lg,
          120,
        ),
        children: [
          Text(journey[_step].toUpperCase(), style: ContentText.eyebrow()),
          const SizedBox(height: 4),
          Text(widget.concept.title, style: ContentText.title(size: 26)),
          const SizedBox(height: IntelliaSpacing.md),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            child: KeyedSubtree(
              key: ValueKey(_step),
              child: switch (_step) {
                0 => ExplanationPanel(
                  concept: widget.concept,
                  modes: widget.chapter.explanationModes,
                  preference: snapshot.preference,
                  onModeSelected: _chooseMode,
                  onToggleLock: ref
                      .read(learnerContentControllerProvider.notifier)
                      .toggleExplanationLock,
                ),
                1 => _SeeStep(concept: widget.concept),
                2 => PracticePanel(
                  session: _session,
                  preference: snapshot.preference,
                  onAcceptExplanation: (mode) {
                    _chooseMode(mode);
                    setState(() => _step = 0);
                  },
                ),
                3 => _PlayStep(
                  chapter: widget.chapter,
                  concept: widget.concept,
                ),
                _ => _FormalStep(
                  lesson: widget.lesson,
                  concept: widget.concept,
                  state: state,
                ),
              },
            ),
          ),
          if (_step < _steps - 1) ...[
            const SizedBox(height: IntelliaSpacing.lg),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                key: const ValueKey('lesson-next-step'),
                onPressed: () => setState(() => _step++),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(l10n.ceNextStep(journey[_step + 1])),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.current, required this.onSelected});

  final int current;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = [
      (Icons.lightbulb_outline_rounded, l10n.ceStepUnderstand),
      (Icons.visibility_outlined, l10n.ceStepSee),
      (Icons.edit_outlined, l10n.ceStepPractice),
      (Icons.sports_esports_outlined, l10n.ceStepPlay),
      (Icons.functions_rounded, l10n.ceStepFormal),
    ];
    return SizedBox(
      height: 70,
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++)
            Expanded(
              child: InkWell(
                key: ValueKey('lesson-step-$i'),
                onTap: () => onSelected(i),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == current
                            ? ContentPalette.accent
                            : i < current
                            ? ContentPalette.accent.withValues(alpha: 0.15)
                            : ContentPalette.ink.withValues(alpha: 0.05),
                      ),
                      child: Icon(
                        steps[i].$1,
                        size: 18,
                        color: i == current
                            ? Colors.white
                            : i < current
                            ? ContentPalette.accent
                            : ContentPalette.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[i].$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ContentText.label(
                        size: 10.5,
                        color: i == current
                            ? ContentPalette.accent
                            : ContentPalette.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SeeStep extends StatelessWidget {
  const _SeeStep({required this.concept});
  final Concept concept;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (concept.visualModel case final model?)
        Text(model, style: ContentText.body(color: ContentPalette.inkSoft)),
      const SizedBox(height: IntelliaSpacing.sm),
      if (concept.visualKind != VisualKind.none)
        Text(
          context.l10n.ceSeeCaption,
          style: ContentText.label(color: ContentPalette.accent, size: 12),
        ),
      const SizedBox(height: IntelliaSpacing.sm),
      ContentCard(
        padding: const EdgeInsets.all(IntelliaSpacing.lg),
        child: ConceptVisual(kind: concept.visualKind),
      ),
    ],
  );
}

class _PlayStep extends StatelessWidget {
  const _PlayStep({required this.chapter, required this.concept});

  final Chapter chapter;
  final Concept concept;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final games = chapter.gamesForConcept(concept.id);
    if (games.isEmpty) {
      return ContentCard(
        child: Text(
          l10n.ceNoGame,
          style: ContentText.body(color: ContentPalette.inkSoft),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final game in games)
          Padding(
            padding: const EdgeInsets.only(bottom: IntelliaSpacing.sm),
            child: GameCard(chapter: chapter, game: game),
          ),
      ],
    );
  }
}

/// Carte d'un jeu : jouable, ou honnêtement « en préparation ».
class GameCard extends StatelessWidget {
  const GameCard({required this.chapter, required this.game, super.key});

  final Chapter chapter;
  final GameBlueprint game;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ContentCard(
      key: ValueKey('game-card-${game.id}'),
      color: game.playable ? ContentPalette.ink : ContentPalette.card,
      borderColor: game.playable ? ContentPalette.ink : ContentPalette.line,
      padding: const EdgeInsets.all(IntelliaSpacing.lg),
      onTap: game.playable
          ? () =>
                context.push(AppRoutes.contentGame(chapter.contentId, game.id))
          : null,
      child: Row(
        children: [
          Icon(
            game.playable
                ? Icons.sports_esports_rounded
                : Icons.construction_rounded,
            color: game.playable
                ? IntelliaFlag.yellowOnInk
                : ContentPalette.inkSoft,
            size: 32,
          ),
          const SizedBox(width: IntelliaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.title,
                  style: ContentText.title(
                    size: 19,
                    color: game.playable ? Colors.white : ContentPalette.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  game.mechanic,
                  style: ContentText.body(
                    size: 13,
                    color: game.playable
                        ? Colors.white.withValues(alpha: 0.8)
                        : ContentPalette.inkSoft,
                  ),
                ),
                if (!game.playable) ...[
                  const SizedBox(height: 6),
                  Text(
                    l10n.ceGameComingSoon,
                    style: ContentText.label(
                      color: ContentPalette.warm,
                      size: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (game.playable)
            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
        ],
      ),
    );
  }
}

class _FormalStep extends StatelessWidget {
  const _FormalStep({
    required this.lesson,
    required this.concept,
    required this.state,
  });

  final Lesson lesson;
  final Concept concept;
  final MasteryState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (concept.explanation(ExplanationMode.standard) case final text?)
          ContentCard(
            borderColor: ContentPalette.accent.withValues(alpha: 0.4),
            padding: const EdgeInsets.all(IntelliaSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.ceFormalTitle.toUpperCase(),
                  style: ContentText.eyebrow(),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: ContentText.body(size: 17, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
        if (lesson.verifiedCore.isNotEmpty) ...[
          const SizedBox(height: IntelliaSpacing.md),
          Text(l10n.ceCourseSays, style: ContentText.label()),
          const SizedBox(height: 6),
          for (final statement in lesson.verifiedCore)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: ContentPalette.success,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(statement, style: ContentText.body(size: 14.5)),
                  ),
                ],
              ),
            ),
        ],
        if (lesson.sourceSituation case final situation?) ...[
          const SizedBox(height: IntelliaSpacing.md),
          ContentCard(
            color: ContentPalette.warm.withValues(alpha: 0.07),
            borderColor: ContentPalette.warm.withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.ceSituationTitle.toUpperCase(),
                  style: ContentText.eyebrow(color: ContentPalette.warm),
                ),
                const SizedBox(height: 4),
                Text(situation, style: ContentText.body(size: 14.5)),
              ],
            ),
          ),
        ],
        const SizedBox(height: IntelliaSpacing.md),
        Text(
          l10n.ceFormalProgress(state.score, state.correct, state.attempts),
          style: ContentText.body(color: ContentPalette.inkSoft, size: 13),
        ),
      ],
    );
  }
}
