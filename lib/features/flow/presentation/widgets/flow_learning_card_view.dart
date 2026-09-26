import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../content_engine/application/content_providers.dart';
import '../../../content_engine/application/learning_feed_providers.dart';
import '../../../content_engine/application/reward_bridge.dart';
import '../../../rewards/application/reward_providers.dart';
import '../../../rewards/domain/reward_event.dart';
import '../../../rewards/domain/reward_pattern.dart';
import '../../../rewards/presentation/reward_stage.dart';
import '../../../content_engine/domain/mastery.dart';
import '../../../content_engine/domain/pedagogy.dart';
import '../../../content_engine/engine/answer_checker.dart';
import '../../../content_engine/engine/companion_engine.dart';
import '../../../content_engine/feed/learning_card.dart';
import '../../../content_engine/presentation/content_style.dart';
import '../../../content_engine/presentation/visuals/concept_visuals.dart';
import '../../../content_engine/presentation/widgets/answer_input.dart';
import '../../../content_engine/presentation/widgets/open_response_panel.dart';
import '../../../content_engine/presentation/widgets/companion_sheet.dart';
import '../../application/flow_controller.dart';
import '../../domain/flow_card.dart';
import 'flow_card_scaffold.dart';
import 'flow_motion.dart';
import 'flow_typography.dart';

/// Libellé de tête d'une carte de pack.
String learningCardKicker(BuildContext context, LearningCardType type) {
  final l10n = context.l10n;
  return switch (type) {
    LearningCardType.explanation => l10n.ceFeedKickerExplanation,
    LearningCardType.ultraSimple => l10n.ceFeedKickerUltraSimple,
    LearningCardType.flashQuestion => l10n.ceFeedKickerFlash,
    LearningCardType.mcq => l10n.ceFeedKickerMcq,
    LearningCardType.trueFalse => l10n.ceFeedKickerTrueFalse,
    LearningCardType.exercise => l10n.ceFeedKickerExercise,
    LearningCardType.selfEvaluation => l10n.ceSelfEvaluation,
    LearningCardType.visual => l10n.ceFeedKickerVisual,
    LearningCardType.game => l10n.ceFeedKickerGame,
    LearningCardType.commonMistake => l10n.ceFeedKickerMistake,
    LearningCardType.revision => l10n.ceFeedKickerRevision,
    LearningCardType.challenge => l10n.ceFeedKickerChallenge,
    LearningCardType.mastery => l10n.ceFeedKickerMastery,
    LearningCardType.newContent => l10n.ceFeedKickerNew,
    LearningCardType.companionPrompt => l10n.ceFeedKickerCompanion,
  };
}

/// Carte « Mon Parcours » tirée d'un pack : lire, répondre, jouer, puis
/// « Approfondir » (la leçon, à la bonne étape) ou demander au Compagnon.
class FlowLearningCardView extends ConsumerStatefulWidget {
  const FlowLearningCardView({
    required this.card,
    required this.onAward,
    super.key,
  });

  final FlowLearningCard card;
  final ValueChanged<FlowAward> onAward;

  @override
  ConsumerState<FlowLearningCardView> createState() =>
      _FlowLearningCardViewState();
}

class _FlowLearningCardViewState extends ConsumerState<FlowLearningCardView> {
  StudentResponse? _response;
  GradeResult? _grade;
  String? _nameLine;
  RewardPattern? _reward;
  final DateTime _shownAt = DateTime.now();

  LearningCard get _learning => widget.card.learning;

  LearnerContentSnapshot get _snapshot =>
      ref.read(learnerContentControllerProvider).valueOrNull ??
      LearnerContentSnapshot.empty;

  Future<void> _check() async {
    final question = _learning.question;
    final response = _response;
    if (question == null ||
        !question.autoScorable ||
        response == null ||
        _grade != null) {
      return;
    }
    final grade = const AnswerChecker().grade(question, response);
    setState(() => _grade = grade);
    final before = await ref.read(learnerContentControllerProvider.future);
    await ref
        .read(learningCardHistoryProvider.notifier)
        .recordAnswer(
          chapter: widget.card.chapter,
          card: _learning,
          correct: grade.correct,
        );
    if (!mounted) return;
    final rewards = ref.read(rewardDispatcherProvider);
    if (grade.correct) {
      // Même moteur de récompense que « S'entraîner », lu sur le même état
      // de maîtrise. Le geste reste libre : rien ne retient la carte.
      setState(
        () => _reward = rewards.correct(
          contentRewardEvent(
            source: RewardSource.feed,
            chapter: widget.card.chapter,
            question: question,
            before: before,
            after: _snapshot,
            responseTime: DateTime.now().difference(_shownAt),
          ),
        ),
      );
    } else {
      rewards.incorrect();
      // Après plusieurs erreurs, un mot d'encouragement (prénom rare, même
      // règle que le Compagnon).
      final state = _snapshot.conceptState(_learning.conceptId);
      if (state.errorsSinceExplanationChange >= 2) {
        final name = ref
            .read(companionNamePolicyProvider)
            .nameFor(
              CompanionMoment.afterErrors,
              ref.read(authControllerProvider).firstName,
            );
        if (name != null) {
          setState(() => _nameLine = context.l10n.ceFeedNameAfterErrors(name));
        }
      }
    }
    widget.onAward(FlowAward(correct: grade.correct));
  }

  void _deepen() => context.push(
    _learning.lessonNumber == 0
        ? AppRoutes.contentIntegration(_learning.contentId)
        : AppRoutes.contentLesson(
            _learning.contentId,
            _learning.lessonNumber,
            step: _learning.lessonStep,
          ),
  );

  void _askCompanion() => CompanionSheet.show(
    context,
    chapter: widget.card.chapter,
    companionContext: () => CompanionContext(
      conceptId: _learning.conceptId,
      lessonNumber: _learning.lessonNumber,
      question: _learning.question,
      lastGrade: _grade,
      difficulty: _learning.difficulty,
      mastery: _snapshot.conceptState(_learning.conceptId).score,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final card = widget.card;
    final accent = card.subject.accent;
    final concept = card.chapter.concepts[_learning.conceptId];
    return FlowCardScaffold(
      subject: card.subject,
      kicker: _learning.lessonNumber == 0
          ? l10n.ceSynthesis
          : learningCardKicker(context, _learning.type),
      footer: Wrap(
        spacing: IntelliaSpacing.sm,
        runSpacing: IntelliaSpacing.sm,
        children: [
          if (_learning.type != LearningCardType.newContent)
            OutlinedButton.icon(
              key: const ValueKey('flow-pack-deepen'),
              onPressed: _deepen,
              icon: const Icon(Icons.menu_book_rounded),
              label: Text(l10n.ceFeedDeepen),
            ),
          if (_learning.type != LearningCardType.game)
            TextButton.icon(
              key: const ValueKey('flow-pack-companion'),
              onPressed: _askCompanion,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: Text(l10n.ceFeedAskCompanion),
            ),
        ],
      ),
      // La réussite se voit sur toute la carte ; le swipe reste libre.
      child: RewardStage(
        pattern: _reward,
        accent: accent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                _learning.title,
                style: FlowTypography.title(context),
              ),
            ),
            const SizedBox(height: IntelliaSpacing.sm),
            FlowInkUnderline(accent: accent),
            const SizedBox(height: IntelliaSpacing.md),
            ..._content(context, concept, accent),
            if (_nameLine case final line?) ...[
              const SizedBox(height: IntelliaSpacing.md),
              Text(
                line,
                key: const ValueKey('flow-pack-name-line'),
                style: FlowTypography.body(
                  context,
                ).copyWith(fontWeight: FontWeight.w700, color: accent),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, Concept? concept, Color accent) {
    final l10n = context.l10n;
    final body = _learning.body;
    Widget text(String value) =>
        Text(value, style: FlowTypography.body(context));

    switch (_learning.type) {
      case LearningCardType.selfEvaluation:
        return [
          OpenResponsePanel(
            key: ValueKey('flow-open-${_learning.question!.id}'),
            question: _learning.question!,
            onEvaluate: (evaluation) => ref
                .read(learningCardHistoryProvider.notifier)
                .recordSelfEvaluation(
                  chapter: widget.card.chapter,
                  card: _learning,
                  evaluation: evaluation,
                ),
          ),
        ];
      case LearningCardType.explanation:
        // Le niveau d'explication préféré de l'élève, s'il existe dans le pack.
        final preferred = _snapshot.preference.mode;
        final value = concept?.explanation(preferred) ?? body ?? '';
        final beats = flowIdeaBeats(value);
        return beats == null
            ? [text(value)]
            : [
                FlowKeyIdea(text: beats.first, accent: accent),
                const SizedBox(height: IntelliaSpacing.lg),
                FlowIdeaTrail(ideas: beats.sublist(1), accent: accent),
              ];
      case LearningCardType.ultraSimple || LearningCardType.revision:
        return [if (body != null) text(body)];
      case LearningCardType.commonMistake:
        return [
          Text(l10n.ceFeedMistakeLead, style: FlowTypography.caption(context)),
          const SizedBox(height: IntelliaSpacing.xs),
          if (body != null) text(body),
        ];
      case LearningCardType.visual:
        return [
          ConceptVisual(kind: _learning.visual),
          if (body != null) ...[
            const SizedBox(height: IntelliaSpacing.md),
            text(body),
          ],
        ];
      case LearningCardType.game:
        return [
          if (body != null) text(body),
          const SizedBox(height: IntelliaSpacing.md),
          FilledButton.icon(
            key: const ValueKey('flow-pack-play'),
            onPressed: () => context.push(
              AppRoutes.contentGame(_learning.contentId, _learning.gameId!),
            ),
            icon: const Icon(Icons.sports_esports_rounded),
            label: Text(l10n.ceFeedPlay),
          ),
        ];
      case LearningCardType.newContent:
        return [
          text(l10n.ceFeedNewBody),
          if (body != null) ...[
            const SizedBox(height: IntelliaSpacing.xs),
            Text(body, style: FlowTypography.question(context)),
          ],
          const SizedBox(height: IntelliaSpacing.md),
          FilledButton.icon(
            key: const ValueKey('flow-pack-open-chapter'),
            onPressed: () =>
                context.push(AppRoutes.contentChapter(_learning.contentId)),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(l10n.ceFeedOpenChapter),
          ),
        ];
      case LearningCardType.companionPrompt:
        return [text(l10n.ceFeedCompanionBody(_learning.title))];
      case LearningCardType.flashQuestion ||
          LearningCardType.mcq ||
          LearningCardType.trueFalse ||
          LearningCardType.exercise ||
          LearningCardType.challenge ||
          LearningCardType.mastery:
        return _questionContent(context, accent);
    }
  }

  List<Widget> _questionContent(BuildContext context, Color accent) {
    final l10n = context.l10n;
    final question = _learning.question!;
    final grade = _grade;
    return [
      Text(question.prompt, style: FlowTypography.question(context)),
      const SizedBox(height: IntelliaSpacing.md),
      AnswerInput(
        key: ValueKey('flow-pack-answer-${question.id}'),
        question: question,
        enabled: grade == null,
        grade: grade,
        onChanged: (response) => setState(() => _response = response),
      ),
      const SizedBox(height: IntelliaSpacing.md),
      if (grade == null)
        FilledButton(
          key: const ValueKey('flow-pack-check'),
          onPressed: _response == null ? null : _check,
          child: Text(l10n.ceFeedCheck),
        )
      else ...[
        Semantics(
          liveRegion: true,
          child: Text(
            grade.correct ? l10n.ceFeedCorrect : l10n.ceFeedWrong,
            key: const ValueKey('flow-pack-verdict'),
            style: FlowTypography.body(context).copyWith(
              fontWeight: FontWeight.w700,
              color: grade.correct
                  ? ContentPalette.success
                  : ContentPalette.error,
            ),
          ),
        ),
        if (_reward != null) ...[
          const SizedBox(height: IntelliaSpacing.xs),
          RewardMessageLine(pattern: _reward),
        ],
        if (question.explanation case final explanation?) ...[
          const SizedBox(height: IntelliaSpacing.xs),
          Text(explanation, style: FlowTypography.explanation(context)),
        ],
      ],
    ];
  }
}
