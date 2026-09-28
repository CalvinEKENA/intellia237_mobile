import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/widgets/intellia_state_view.dart';
import '../application/content_providers.dart';
import '../domain/chapter.dart';
import '../domain/mastery.dart';
import '../engine/adaptive_engine.dart';
import '../application/subject_journey.dart';
import 'content_style.dart';
import 'learning_cards.dart';

/// Un chapitre local : ses leçons, dans l'ordre conseillé, avec la maîtrise
/// de chaque notion.
class ContentChapterScreen extends ConsumerWidget {
  const ContentChapterScreen({required this.contentId, super.key});

  final String contentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapterAsync = ref.watch(contentChapterProvider(contentId));
    final snapshot =
        ref.watch(learnerContentControllerProvider).valueOrNull ??
        LearnerContentSnapshot.empty;
    return Scaffold(
      backgroundColor: ContentPalette.paper,
      appBar: AppBar(
        backgroundColor: ContentPalette.paper,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ContentPalette.ink,
      ),
      body: chapterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Unavailable(message: context.l10n.ceLoadError),
        data: (chapter) => chapter.isPlayable
            ? _ChapterBody(chapter: chapter, snapshot: snapshot)
            : _Unavailable(message: context.l10n.ceUnavailableBody),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(IntelliaSpacing.lg),
    child: IntelliaStateView(
      kind: IntelliaStateKind.comingSoon,
      title: context.l10n.ceUnavailableTitle,
      message: message,
    ),
  );
}

class _ChapterBody extends StatelessWidget {
  const _ChapterBody({required this.chapter, required this.snapshot});

  final Chapter chapter;
  final LearnerContentSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final curriculum = chapter.curriculum;
    final engine = AdaptiveEngine(
      chapter.mastery,
      maxDifficulty: chapter.maxDifficulty,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        IntelliaSpacing.lg,
        0,
        IntelliaSpacing.lg,
        IntelliaSpacing.xxl,
      ),
      children: [
        Text(
          '${subjectDisplayName(context, curriculum.subjectKey, curriculum.subject)}'
                  ' · ${curriculum.level}'
              .toUpperCase(),
          style: ContentText.eyebrow(),
        ),
        const SizedBox(height: 6),
        Text(
          key: const ValueKey('chapter-position'),
          [
            if (curriculum.moduleNumber != null)
              moduleLabel(context, curriculum),
            positionLabel(context, curriculum),
          ].join(' · '),
          style: ContentText.label(color: ContentPalette.inkSoft),
        ),
        Semantics(
          header: true,
          child: Text(
            curriculum.chapterTitle,
            style: ContentText.title(size: 32),
          ),
        ),
        // INTELLIA parle à l'élève, jamais de l'élève : la note de
        // conception du pack reste une donnée interne.
        const SizedBox(height: IntelliaSpacing.xs),
        Text(
          l10n.ceChapterPromise,
          style: ContentText.body(color: ContentPalette.inkSoft, size: 14),
        ),
        const SizedBox(height: IntelliaSpacing.lg),
        JourneyRibbon(subjectKey: curriculum.subjectKey),
        const SizedBox(height: IntelliaSpacing.lg),
        for (final lesson in chapter.lessons)
          Padding(
            padding: const EdgeInsets.only(bottom: IntelliaSpacing.sm + 2),
            child: LessonCard(
              chapter: chapter,
              journey: LessonJourney(
                lesson: lesson,
                progress: ConceptsProgress.measure(
                  lesson.conceptIds,
                  snapshot,
                  masteredAt: chapter.mastery.unlockNextLessonAt,
                ),
              ),
              unlocked: engine.isLessonUnlocked(
                chapter,
                lesson.number,
                snapshot.concepts,
              ),
              // Conseillée, jamais interdite : l'élève garde la main.
              onTap: () => context.push(
                AppRoutes.contentLesson(chapter.contentId, lesson.number),
              ),
            ),
          ),
        if (chapter.integrationConcepts.isNotEmpty ||
            chapter.integrationPracticeQuestions.isNotEmpty) ...[
          const SizedBox(height: IntelliaSpacing.md),
          SynthesisCard(
            chapter: chapter,
            title: chapter.integrationConcepts.isNotEmpty
                ? l10n.ceSynthesis
                : l10n.ceIntegrationTitle,
            onTap: () =>
                context.push(AppRoutes.contentIntegration(chapter.contentId)),
          ),
        ],
      ],
    );
  }
}

/// Je comprends → Je vois → J'essaie → Je réussis → Je passe au formalisme.
class JourneyRibbon extends StatelessWidget {
  const JourneyRibbon({this.current, this.subjectKey = '', super.key});

  /// Étape en cours (0–4), ou `null` pour la présentation du chapitre.
  final int? current;

  /// Matière du chapitre : choisit l'icône de l'étape « formalisme ».
  final String subjectKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = [
      (Icons.lightbulb_outline_rounded, l10n.ceJourneyUnderstand),
      (Icons.visibility_outlined, l10n.ceJourneySee),
      (Icons.edit_outlined, l10n.ceJourneyTry),
      (Icons.emoji_events_outlined, l10n.ceJourneySucceed),
      (formalStepIcon(subjectKey), l10n.ceJourneyFormal),
    ];
    return ContentCard(
      padding: const EdgeInsets.symmetric(
        horizontal: IntelliaSpacing.sm,
        vertical: IntelliaSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (current == null) ...[
            Text(l10n.ceJourneyTitle, style: ContentText.label()),
            const SizedBox(height: IntelliaSpacing.sm),
          ],
          AdaptiveChoiceRow(
            labels: [for (final step in steps) step.$2],
            labelStyle: ContentText.label(size: 10.5),
            reservedWidth: 2,
            spacing: 2,
            itemBuilder: (context, i, stacked) => _JourneyStep(
              icon: steps[i].$1,
              label: steps[i].$2,
              active: current == null || i <= current!,
              current: i == current,
              stacked: stacked,
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyStep extends StatelessWidget {
  const _JourneyStep({
    required this.icon,
    required this.label,
    required this.active,
    required this.current,
    this.stacked = false,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool current;

  /// Disposition en liste (icône à gauche) quand les colonnes sont trop
  /// étroites pour les libellés.
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final color = active ? ContentPalette.accent : ContentPalette.inkSoft;
    return Flex(
      direction: stacked ? Axis.horizontal : Axis.vertical,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: current ? 38 : 32,
          height: current ? 38 : 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: current
                ? ContentPalette.accent
                : color.withValues(alpha: 0.1),
          ),
          child: Icon(icon, size: 18, color: current ? Colors.white : color),
        ),
        const SizedBox(height: 6, width: 10),
        Flexible(
          fit: stacked ? FlexFit.tight : FlexFit.loose,
          child: Text(
            label,
            textAlign: stacked ? TextAlign.start : TextAlign.center,
            style: ContentText.label(color: color, size: 10.5),
          ),
        ),
      ],
    );
  }
}
