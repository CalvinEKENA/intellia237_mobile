import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../rewards/application/reward_providers.dart';
import '../../../rewards/domain/reward_event.dart';
import '../../../rewards/domain/reward_pattern.dart';
import '../../../rewards/presentation/reward_stage.dart';
import '../../application/content_providers.dart';
import '../../application/practice_session.dart';
import '../../application/reward_bridge.dart';
import '../../domain/chapter.dart';
import '../../domain/companion_action.dart';
import '../../domain/mastery.dart';
import '../../domain/pedagogy.dart';
import '../../domain/question.dart';
import '../../engine/answer_checker.dart';
import '../../engine/companion_engine.dart';
import '../content_style.dart';
import 'answer_input.dart';

/// Texte humain d'un diagnostic de correction.
String diagnosisText(BuildContext context, GradeResult grade) {
  final l10n = context.l10n;
  return switch (grade.diagnosis) {
    GradeDiagnosis.unreadable => l10n.ceDiagnosisUnreadable,
    GradeDiagnosis.someFieldsWrong => l10n.ceDiagnosisSomeFields,
    GradeDiagnosis.missingSolutions => l10n.ceDiagnosisMissing(
      grade.missingCount,
    ),
    GradeDiagnosis.extraSolutions => l10n.ceDiagnosisExtra(grade.extraCount),
    GradeDiagnosis.factorNotPrime => l10n.ceDiagnosisNotPrime,
    GradeDiagnosis.wrongExponents => l10n.ceDiagnosisExponents,
    GradeDiagnosis.wrongProduct => l10n.ceDiagnosisProduct,
    GradeDiagnosis.different || null => l10n.ceDiagnosisDifferent,
  };
}

/// « S'entraîner » : difficulté choisie par l'élève, correction immédiate.
class PracticePanel extends ConsumerStatefulWidget {
  const PracticePanel({
    required this.session,
    required this.preference,
    required this.onAcceptExplanation,
    this.showDifficulty = true,
    super.key,
  });

  final PracticeSession session;
  final ExplanationPreference preference;

  /// L'élève accepte une explication plus simple (jamais imposée).
  final ValueChanged<ExplanationMode> onAcceptExplanation;
  final bool showDifficulty;

  @override
  ConsumerState<PracticePanel> createState() => _PracticePanelState();
}

class _PracticePanelState extends ConsumerState<PracticePanel> {
  StudentResponse? _draft;
  CompanionReply? _help;

  /// Récompense de la dernière réussite (effacée à la question suivante).
  RewardPattern? _reward;

  /// Début de la question en cours : une réponse rapide reçoit un retour
  /// minimal, pour ne jamais ralentir l'élève.
  DateTime _startedAt = DateTime.now();

  PracticeSession get _session => widget.session;
  Chapter get _chapter => _session.chapter;

  @override
  void initState() {
    super.initState();
    _lastKey = _session.attemptKey;
    _session.addListener(_changed);
  }

  @override
  void didUpdateWidget(PracticePanel old) {
    super.didUpdateWidget(old);
    if (old.session != widget.session) {
      old.session.removeListener(_changed);
      widget.session.addListener(_changed);
    }
  }

  @override
  void dispose() {
    _session.removeListener(_changed);
    super.dispose();
  }

  int _lastKey = -1;

  void _changed() {
    if (!mounted) return;
    setState(() {
      if (_session.attemptKey != _lastKey) {
        _lastKey = _session.attemptKey;
        _draft = null;
        _help = null;
        _reward = null;
        _startedAt = DateTime.now();
      }
    });
  }

  CompanionContext get _context => CompanionContext(
    conceptId: _session.current == null
        ? null
        : _chapter.conceptForQuestion(_session.current!)?.id,
    lessonNumber: _session.lessonNumber,
    question: _session.current,
    lastGrade: _session.lastGrade,
    hintsShown: _session.hintsShown,
    difficulty: _session.difficulty,
    answered: _session.answeredIds,
  );

  void _ask(CompanionAction action) {
    final reply = CompanionEngine(_chapter).respond(action, _context);
    if (action == CompanionAction.hint && reply.answered) _session.hintShown();
    setState(() => _help = reply);
  }

  void _simpler() {
    final next = widget.preference.mode.simpler ?? ExplanationMode.ultraSimple;
    _ask(switch (next) {
      ExplanationMode.standard => CompanionAction.explainStandard,
      ExplanationMode.simple => CompanionAction.explainSimple,
      ExplanationMode.ultraSimple => CompanionAction.explainUltraSimple,
    });
  }

  Future<void> _check() async {
    final draft = _draft;
    if (draft == null) return;
    FocusScope.of(context).unfocus();
    final question = _session.current;
    final before =
        ref.read(learnerContentControllerProvider).valueOrNull ??
        LearnerContentSnapshot.empty;
    final grade = await _session.submit(draft);
    if (grade == null || !mounted) return;
    final rewards = ref.read(rewardDispatcherProvider);
    if (!grade.correct || question == null) {
      rewards.incorrect();
      return;
    }
    final after =
        ref.read(learnerContentControllerProvider).valueOrNull ?? before;
    setState(
      () => _reward = rewards.correct(
        contentRewardEvent(
          source: question.isIntegration
              ? RewardSource.integration
              : RewardSource.practice,
          chapter: _chapter,
          question: question,
          before: before,
          after: after,
          suggestions: _session.suggestions,
          responseTime: DateTime.now().difference(_startedAt),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final question = _session.current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showDifficulty) ...[
          _DifficultyPicker(session: _session),
          const SizedBox(height: IntelliaSpacing.md),
        ],
        for (final suggestion in _session.suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: IntelliaSpacing.sm),
            child: _SuggestionBanner(
              suggestion: suggestion,
              chapter: _chapter,
              onAccept: () {
                _session.dismissSuggestion(suggestion);
                switch (suggestion) {
                  case SuggestExplanation(:final mode):
                    widget.onAcceptExplanation(mode);
                  case SuggestHarder(:final difficulty):
                    _session.chooseDifficulty(difficulty);
                }
              },
              onDismiss: () => _session.dismissSuggestion(suggestion),
            ),
          ),
        if (question == null)
          ContentCard(
            padding: const EdgeInsets.all(IntelliaSpacing.lg),
            child: Text(
              _session.questions.isEmpty
                  ? l10n.ceNoQuestions
                  : l10n.ceLessonDone,
              style: ContentText.body(),
            ),
          )
        else
          _QuestionCard(
            key: ValueKey('practice-${question.id}-${_session.attemptKey}'),
            session: _session,
            question: question,
            onDraft: (draft) => setState(() => _draft = draft),
            canCheck: _draft != null && !_session.busy,
            onCheck: _check,
            onHint: () => _ask(CompanionAction.hint),
            onSimpler: _simpler,
            onWhyWrong: () => _ask(CompanionAction.whyWrong),
            reward: _reward,
          ),
        if (_help != null) ...[
          const SizedBox(height: IntelliaSpacing.md),
          CompanionReplyCard(reply: _help!),
        ],
      ],
    );
  }
}

class _DifficultyPicker extends StatelessWidget {
  const _DifficultyPicker({required this.session});
  final PracticeSession session;

  @override
  Widget build(BuildContext context) {
    final chapter = session.chapter;
    final available = session.selector.availableDifficulties(
      chapter,
      session.lessonNumber,
    );
    final levels = chapter.difficulties;
    return AdaptiveChoiceRow(
      labels: [
        for (final level in levels)
          difficultyLabel(context, chapter, level.value),
      ],
      labelStyle: ContentText.label(size: 11.5),
      reservedWidth: 16,
      itemBuilder: (context, i, _) {
        final level = levels[i];
        return _DifficultyChip(
          key: ValueKey('difficulty-${level.value}'),
          label: difficultyLabel(context, chapter, level.value),
          color: ContentPalette.difficulty(level.value),
          selected: session.difficulty == level.value,
          enabled: available.contains(level.value),
          onTap: () => session.chooseDifficulty(level.value),
        );
      },
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  const _DifficultyChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final String label;
  final Color color;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: enabled ? 1 : 0.4,
    child: Material(
      color: selected ? color : Colors.white,
      borderRadius: BorderRadius.circular(IntelliaRadii.medium),
      child: InkWell(
        borderRadius: BorderRadius.circular(IntelliaRadii.medium),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(IntelliaRadii.medium),
            border: Border.all(color: color, width: selected ? 2 : 1.2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: ContentText.label(
                  size: 11.5,
                  color: selected ? Colors.white : ContentPalette.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.session,
    required this.question,
    required this.onDraft,
    required this.canCheck,
    required this.onCheck,
    required this.onHint,
    required this.onSimpler,
    required this.onWhyWrong,
    this.reward,
    super.key,
  });

  final RewardPattern? reward;
  final PracticeSession session;
  final Question question;
  final ValueChanged<StudentResponse?> onDraft;
  final bool canCheck;
  final VoidCallback onCheck;
  final VoidCallback onHint;
  final VoidCallback onSimpler;
  final VoidCallback onWhyWrong;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final grade = session.lastGrade;
    final color = ContentPalette.difficulty(question.difficulty);
    final reward = grade?.correct == true ? this.reward : null;
    return RewardStage(
      pattern: reward,
      child: ContentCard(
        borderColor: color.withValues(alpha: 0.4),
        padding: const EdgeInsets.all(IntelliaSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l10n.ceQuestionProgress(
                    session.index + 1,
                    session.questions.length,
                  ),
                  style: ContentText.eyebrow(color: color),
                ),
                if (question.tags.contains('situation_probleme'))
                  _Tag(
                    label: l10n.ceSituationTag,
                    color: ContentPalette.accent,
                  ),
                if (question.isIntegration)
                  _Tag(
                    label: l10n.ceIntegrationTag,
                    color: ContentPalette.warm,
                  ),
              ],
            ),
            const SizedBox(height: IntelliaSpacing.sm),
            Text(
              question.prompt,
              style: ContentText.body(size: 18, weight: FontWeight.w700),
            ),
            if (question.visibleFlags.isNotEmpty) ...[
              const SizedBox(height: IntelliaSpacing.sm),
              _SourceCaution(question: question),
            ],
            const SizedBox(height: IntelliaSpacing.md),
            AnswerInput(
              question: question,
              onChanged: onDraft,
              enabled: grade == null,
              grade: grade,
            ),
            const SizedBox(height: IntelliaSpacing.md),
            if (grade == null) ...[
              FilledButton(
                key: const ValueKey('practice-check'),
                onPressed: canCheck ? onCheck : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: ContentPalette.ink,
                ),
                child: Text(l10n.ceCheck),
              ),
              const SizedBox(height: IntelliaSpacing.xs),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: IntelliaSpacing.xs,
                children: [
                  TextButton.icon(
                    key: const ValueKey('practice-hint'),
                    onPressed: onHint,
                    icon: const Icon(Icons.lightbulb_outline_rounded),
                    label: Text(l10n.ceHint),
                  ),
                  TextButton.icon(
                    key: const ValueKey('practice-simpler'),
                    onPressed: onSimpler,
                    icon: const Icon(Icons.child_care_rounded),
                    label: Text(l10n.ceSimpler),
                  ),
                ],
              ),
            ] else ...[
              if (reward != null) ...[
                RewardMessageLine(pattern: reward),
                const SizedBox(height: IntelliaSpacing.xs),
              ],
              _Feedback(
                question: question,
                grade: grade,
                onNext: session.next,
                onRetry: session.retry,
                onWhyWrong: onWhyWrong,
                onSimpler: onSimpler,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({
    required this.question,
    required this.grade,
    required this.onNext,
    required this.onRetry,
    required this.onWhyWrong,
    required this.onSimpler,
  });

  final Question question;
  final GradeResult grade;
  final VoidCallback onNext;
  final VoidCallback onRetry;
  final VoidCallback onWhyWrong;
  final VoidCallback onSimpler;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = grade.correct ? ContentPalette.success : ContentPalette.error;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Column(
        key: const ValueKey('practice-feedback'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(IntelliaSpacing.md),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(IntelliaRadii.medium),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      grade.correct
                          ? Icons.check_circle_rounded
                          : Icons.highlight_off_rounded,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      grade.correct ? l10n.ceCorrect : l10n.ceIncorrect,
                      style: ContentText.label(color: color, size: 16),
                    ),
                  ],
                ),
                if (!grade.correct) ...[
                  const SizedBox(height: 6),
                  Text(
                    diagnosisText(context, grade),
                    style: ContentText.body(size: 14.5),
                  ),
                ],
                if (grade.correct && question.explanation != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    question.explanation!,
                    style: ContentText.body(size: 14.5),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          if (grade.correct)
            FilledButton.icon(
              key: const ValueKey('practice-next'),
              onPressed: onNext,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: ContentPalette.success,
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(l10n.ceNextQuestion),
            )
          else ...[
            FilledButton(
              key: const ValueKey('practice-retry'),
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: ContentPalette.ink,
              ),
              child: Text(l10n.ceTryAgain),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: IntelliaSpacing.xs,
              children: [
                TextButton.icon(
                  key: const ValueKey('practice-why-wrong'),
                  onPressed: onWhyWrong,
                  icon: const Icon(Icons.help_outline_rounded),
                  label: Text(l10n.ceWhyWrong),
                ),
                TextButton.icon(
                  onPressed: onSimpler,
                  icon: const Icon(Icons.child_care_rounded),
                  label: Text(l10n.ceSimpler),
                ),
                TextButton(
                  key: const ValueKey('practice-skip'),
                  onPressed: onNext,
                  child: Text(l10n.ceNextQuestion),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SuggestionBanner extends StatelessWidget {
  const _SuggestionBanner({
    required this.suggestion,
    required this.chapter,
    required this.onAccept,
    required this.onDismiss,
  });

  final AdaptiveSuggestion suggestion;
  final Chapter chapter;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (text, color, icon) = switch (suggestion) {
      SuggestExplanation(:final mode) => (
        l10n.ceSuggestSimpler(explanationModeLabel(context, mode)),
        ContentPalette.mode(mode),
        Icons.child_care_rounded,
      ),
      SuggestHarder(:final difficulty) => (
        l10n.ceSuggestHarder(difficultyLabel(context, chapter, difficulty)),
        ContentPalette.difficulty(difficulty),
        Icons.trending_up_rounded,
      ),
    };
    return ContentCard(
      key: ValueKey('suggestion-${suggestion.runtimeType}'),
      color: color.withValues(alpha: 0.08),
      borderColor: color.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(text, style: ContentText.body(size: 14.5))),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onDismiss, child: Text(l10n.ceDismiss)),
              FilledButton(
                key: const ValueKey('suggestion-accept'),
                style: FilledButton.styleFrom(backgroundColor: color),
                onPressed: onAccept,
                child: Text(l10n.ceAccept),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceCaution extends StatelessWidget {
  const _SourceCaution({required this.question});
  final Question question;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(IntelliaSpacing.sm),
    decoration: BoxDecoration(
      color: ContentPalette.warm.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(IntelliaRadii.small),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.fact_check_outlined,
              size: 16,
              color: ContentPalette.warm,
            ),
            const SizedBox(width: 6),
            Text(
              context.l10n.ceSourceCaution,
              style: ContentText.label(color: ContentPalette.warm, size: 12),
            ),
          ],
        ),
        for (final flag in question.visibleFlags)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(flag.issue, style: ContentText.body(size: 13)),
          ),
      ],
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(IntelliaRadii.full),
    ),
    child: Text(label, style: ContentText.label(color: color, size: 11)),
  );
}

/// Réponse du Compagnon, affichée telle que le pack la fournit.
class CompanionReplyCard extends StatelessWidget {
  const CompanionReplyCard({
    required this.reply,
    this.onTryQuestion,
    super.key,
  });

  final CompanionReply reply;
  final ValueChanged<Question>? onTryQuestion;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gapText = switch (reply.gap) {
      CompanionGap.unknownTopic => l10n.ceCompanionUnknown,
      CompanionGap.explanationMissing => l10n.ceExplanationUnavailable,
      CompanionGap.noMoreHints => l10n.ceCompanionNoMoreHints,
      CompanionGap.nothingToExplain => l10n.ceCompanionNothingWrong,
      CompanionGap.noQuestionLeft => l10n.ceCompanionNoQuestion,
      CompanionGap.noConcept => l10n.ceCompanionNoConcept,
      CompanionGap.noExample => l10n.ceCompanionNoExample,
      null => null,
    };
    final color = reply.mode == null
        ? ContentPalette.accent
        : ContentPalette.mode(reply.mode!);
    return ContentCard(
      key: const ValueKey('companion-reply'),
      color: color.withValues(alpha: 0.05),
      borderColor: color.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (reply.mode != null)
            Text(
              explanationModeLabel(context, reply.mode!).toUpperCase(),
              style: ContentText.eyebrow(color: color),
            ),
          if (gapText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                gapText,
                style: ContentText.body(
                  color: ContentPalette.inkSoft,
                  size: 14,
                ),
              ),
            ),
          if (reply.fallbackMode != null)
            Text(
              l10n.ceShownInsteadMode(
                explanationModeLabel(context, reply.fallbackMode!),
              ),
              style: ContentText.label(color: ContentPalette.inkSoft, size: 12),
            ),
          if (reply.diagnosis != null && reply.gap == null) ...[
            Text(
              diagnosisText(
                context,
                GradeResult(
                  correct: false,
                  diagnosis: reply.diagnosis,
                  missingCount: reply.missingCount,
                  extraCount: reply.extraCount,
                ),
              ),
              style: ContentText.body(size: 14.5, weight: FontWeight.w700),
            ),
            for (final entry in reply.fieldResults.entries)
              Text(
                '${fieldLabel(context, entry.key)} : ${entry.value ? '✓' : '✗'}',
                style: ContentText.body(
                  size: 14,
                  color: entry.value
                      ? ContentPalette.success
                      : ContentPalette.error,
                ),
              ),
            const SizedBox(height: 6),
          ],
          for (final part in reply.parts)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _PartText(part: part),
            ),
          if (reply.suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(l10n.ceCompanionClosest, style: ContentText.label(size: 12)),
            for (final concept in reply.suggestions)
              Text('• ${concept.title}', style: ContentText.body(size: 14)),
          ],
          if (reply.question != null && onTryQuestion != null) ...[
            const SizedBox(height: 8),
            Text(
              reply.question!.prompt,
              style: ContentText.body(weight: FontWeight.w700),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                key: const ValueKey('companion-try-question'),
                onPressed: () => onTryQuestion!(reply.question!),
                child: Text(l10n.ceCompanionTryIt),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PartText extends StatelessWidget {
  const _PartText({required this.part});
  final CompanionPart part;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = switch (part.role) {
      CompanionPartRole.mistake => l10n.ceCompanionTrap,
      CompanionPartRole.correction => l10n.ceCompanionCorrection,
      CompanionPartRole.hint => l10n.ceHint,
      CompanionPartRole.example => l10n.ceCompanionExample,
      CompanionPartRole.explanation || CompanionPartRole.visual => null,
    };
    final color = part.role == CompanionPartRole.mistake
        ? ContentPalette.error
        : ContentPalette.ink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Text(label.toUpperCase(), style: ContentText.eyebrow(color: color)),
        Text(part.text, style: ContentText.body(size: 15.5)),
      ],
    );
  }
}
