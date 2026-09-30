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
    this.initialStep = 0,
    super.key,
  });

  final String contentId;
  final int lessonNumber;

  /// Étape ouverte à l'arrivée (0 comprendre … 4 formaliser) : « Approfondir »
  /// depuis Mon Parcours mène directement à l'étape utile.
  final int initialStep;

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
        final concepts = chapter.conceptsForLesson(lessonNumber);
        if (!chapter.isPlayable || lesson == null || concepts.isEmpty) {
          return _Missing(message: context.l10n.ceUnavailableBody);
        }
        return _LessonHost(
          chapter: chapter,
          lesson: lesson,
          concepts: concepts,
          initialStep: initialStep,
        );
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

/// Une leçon peut porter plusieurs notions : l'élève passe de l'une à
/// l'autre sans quitter la leçon.
class _LessonHost extends StatefulWidget {
  const _LessonHost({
    required this.chapter,
    required this.lesson,
    required this.concepts,
    required this.initialStep,
  });

  final Chapter chapter;
  final Lesson lesson;
  final List<Concept> concepts;
  final int initialStep;

  @override
  State<_LessonHost> createState() => _LessonHostState();
}

class _LessonHostState extends State<_LessonHost> {
  late Concept _concept = widget.concepts.first;

  @override
  Widget build(BuildContext context) => _LessonView(
    key: ValueKey(_concept.id),
    chapter: widget.chapter,
    lesson: widget.lesson,
    concept: _concept,
    siblings: widget.concepts,
    onConcept: (concept) => setState(() => _concept = concept),
    initialStep: widget.initialStep,
  );
}

class _LessonView extends ConsumerStatefulWidget {
  const _LessonView({
    required this.chapter,
    required this.lesson,
    required this.concept,
    this.siblings = const [],
    this.onConcept,
    this.initialStep = 0,
    super.key,
  });

  final Chapter chapter;
  final Lesson lesson;
  final Concept concept;

  /// Toutes les notions de la leçon (au moins [concept]).
  final List<Concept> siblings;
  final ValueChanged<Concept>? onConcept;
  final int initialStep;

  @override
  ConsumerState<_LessonView> createState() => _LessonViewState();
}

class _LessonViewState extends ConsumerState<_LessonView> {
  static const _steps = 5;
  late int _step = widget.initialStep.clamp(0, _steps - 1);

  /// Chaque étape s'ouvre par son début, quel que soit l'endroit où
  /// l'élève avait défilé.
  final _scroll = ScrollController();

  void _goTo(int step) {
    setState(() => _step = step);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

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
      selfEvaluationRecorder: (question, evaluation) => ref
          .read(learnerContentControllerProvider.notifier)
          .recordSelfEvaluation(
            chapter: widget.chapter,
            question: question,
            evaluation: evaluation,
          ),
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
    _scroll.dispose();
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
    difficultyChosen: _step == 2,
    answered: _session.answeredIds,
    mastery:
        (ref.read(learnerContentControllerProvider).valueOrNull ??
                LearnerContentSnapshot.empty)
            .conceptState(widget.concept.id)
            .score,
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
        title: Text(
          l10n.ceLessonLabel(widget.lesson.number).toUpperCase(),
          style: ContentText.eyebrow(),
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
          preferredSize: Size.fromHeight(_StepBar.heightFor(context)),
          child: _StepBar(
            subjectKey: widget.chapter.curriculum.subjectKey,
            current: _step,
            onSelected: _goTo,
          ),
        ),
      ),
      // Compagnon et étape suivante dans une barre sous le contenu, jamais
      // par-dessus : aucun bouton flottant ne masque une question, une
      // réponse ou un bouton, quelle que soit la taille de l'écran.
      bottomNavigationBar: _LessonActionBar(
        onCompanion: () => CompanionSheet.show(
          context,
          chapter: widget.chapter,
          companionContext: _companionContext,
          onHintShown: _session.hintShown,
          onTryQuestion: (question) {
            _goTo(2);
            _session.focus(question);
          },
        ),
        nextLabel: _step < _steps - 1
            ? l10n.ceNextStep(journey[_step + 1])
            : null,
        onNext: () => _goTo(_step + 1),
      ),
      body: ListView(
        key: const ValueKey('lesson-scroll'),
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(
          IntelliaSpacing.lg,
          IntelliaSpacing.md,
          IntelliaSpacing.lg,
          IntelliaSpacing.xl,
        ),
        children: [
          // Titre de la leçon en entier, quelle que soit sa longueur.
          ContentHeading(
            widget.lesson.title,
            key: const ValueKey('lesson-title'),
            style: ContentText.title(size: 22),
          ),
          if (widget.siblings.length > 1) ...[
            const SizedBox(height: IntelliaSpacing.sm),
            Wrap(
              spacing: IntelliaSpacing.xs,
              runSpacing: IntelliaSpacing.xs,
              children: [
                for (final concept in widget.siblings)
                  ChoiceChip(
                    key: ValueKey('lesson-concept-${concept.id}'),
                    // Titre en entier, sur plusieurs lignes au besoin.
                    label: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width - 120,
                      ),
                      child: _WrappingLabel(concept.title),
                    ),
                    selected: concept.id == widget.concept.id,
                    onSelected: (_) => widget.onConcept?.call(concept),
                  ),
              ],
            ),
          ],
          const SizedBox(height: IntelliaSpacing.sm),
          Text(journey[_step].toUpperCase(), style: ContentText.eyebrow()),
          const SizedBox(height: 4),
          if (widget.concept.title != widget.lesson.title)
            Text(widget.concept.title, style: ContentText.title(size: 20)),
          const SizedBox(height: IntelliaSpacing.md),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            child: KeyedSubtree(
              key: ValueKey(_step),
              child: switch (_step) {
                0 => ExplanationPanel(
                  modeLabels: widget.chapter.explanationLabels,
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
                    _goTo(0);
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
        ],
      ),
    );
  }
}

/// Libellé de puce sur plusieurs lignes : une puce impose une seule ligne
/// (le titre serait coupé en fondu), on lève cette limite.
class _WrappingLabel extends StatelessWidget {
  const _WrappingLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final inherited = DefaultTextStyle.of(context);
    return DefaultTextStyle(
      style: inherited.style,
      textAlign: inherited.textAlign,
      child: Text(text),
    );
  }
}

/// Barre d'actions de la leçon : le Compagnon et l'étape suivante, côte à
/// côte quand les deux libellés tiennent en entier, l'un sous l'autre sinon
/// (petit écran, grand texte, traduction plus longue).
class _LessonActionBar extends StatelessWidget {
  const _LessonActionBar({
    required this.onCompanion,
    required this.onNext,
    this.nextLabel,
  });

  final VoidCallback onCompanion;
  final VoidCallback onNext;

  /// `null` à la dernière étape : seul le Compagnon reste.
  final String? nextLabel;

  /// Largeur d'un bouton à icône, hors libellé : marges intérieures (16 et
  /// 24), icône (18) et espace (8), plus une marge de sécurité.
  static const _buttonChrome = 16 + 24 + 18 + 8 + 8.0;
  static const _gap = IntelliaSpacing.sm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final companion = OutlinedButton.icon(
      key: const ValueKey('open-companion'),
      style: OutlinedButton.styleFrom(
        foregroundColor: ContentPalette.ink,
        side: const BorderSide(color: ContentPalette.line),
        minimumSize: const Size(0, 48),
      ),
      onPressed: onCompanion,
      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
      label: Text(l10n.ceCompanionButton, textAlign: TextAlign.center),
    );
    final label = nextLabel;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: ContentPalette.paper,
        border: Border(top: BorderSide(color: ContentPalette.line)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.symmetric(
          horizontal: IntelliaSpacing.lg,
          vertical: IntelliaSpacing.sm,
        ),
        child: label == null
            // heightFactor 1 : la barre garde la hauteur du bouton.
            ? Align(
                alignment: Alignment.centerLeft,
                heightFactor: 1,
                child: companion,
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final next = FilledButton.icon(
                    key: const ValueKey('lesson-next-step'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: onNext,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: Text(label, textAlign: TextAlign.center),
                  );
                  final style =
                      Theme.of(context).textTheme.labelLarge ??
                      const TextStyle(fontSize: 14);
                  final needed =
                      lineWidth(context, l10n.ceCompanionButton, style) +
                      lineWidth(context, label, style) +
                      2 * _buttonChrome +
                      _gap;
                  if (needed <= constraints.maxWidth) {
                    return Row(
                      children: [
                        companion,
                        const SizedBox(width: _gap),
                        Expanded(child: next),
                      ],
                    );
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      next,
                      const SizedBox(height: _gap),
                      companion,
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({
    required this.subjectKey,
    required this.current,
    required this.onSelected,
  });

  final String subjectKey;

  final int current;
  final ValueChanged<int> onSelected;

  static TextStyle _style(Color color) =>
      ContentText.label(size: 10.5, color: color);

  /// Hauteur de la barre à l'échelle de texte de l'appareil : l'étiquette
  /// n'est jamais rognée, même avec un texte agrandi.
  static double heightFor(BuildContext context) {
    final line = MediaQuery.textScalerOf(context).scale(10.5) * 1.35;
    return 34 + 4 + line + 14;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = [
      (Icons.lightbulb_outline_rounded, l10n.ceStepUnderstand),
      (Icons.visibility_outlined, l10n.ceStepSee),
      (Icons.edit_outlined, l10n.ceStepPractice),
      (Icons.sports_esports_outlined, l10n.ceStepPlay),
      (formalStepIcon(subjectKey), l10n.ceStepFormal),
    ];
    Widget step(int i) => InkWell(
      key: ValueKey('lesson-step-$i'),
      onTap: () => onSelected(i),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
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
              softWrap: false,
              style: _style(
                i == current ? ContentPalette.accent : ContentPalette.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
    return SizedBox(
      height: heightFor(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final column = constraints.maxWidth / steps.length - 12;
          final fits = steps.every(
            (s) =>
                longestWordWidth(context, s.$2, _style(ContentPalette.ink)) <=
                column,
          );
          if (fits) {
            return Row(
              children: [
                for (var i = 0; i < steps.length; i++) Expanded(child: step(i)),
              ],
            );
          }
          // Écran étroit ou grand texte : les étapes défilent de côté,
          // chacune avec son libellé complet.
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [for (var i = 0; i < steps.length; i++) step(i)],
          );
        },
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
    // Seuls les jeux prêts sont annoncés : jamais de promesse injouable.
    final games = [
      for (final game in chapter.gamesForConcept(concept.id))
        if (game.playable) game,
    ];
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
