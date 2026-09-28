import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/widgets/intellia_pressable.dart';
import '../../../core/widgets/intellia_state_view.dart';
import '../application/subject_journey.dart';
import 'content_style.dart';
import 'learning_cards.dart';
import 'subject_identity.dart';

/// Fond des écrans d'apprentissage : un gris très clair qui fait ressortir
/// les cartes, un noir profond en sombre.
Color learningBackground(Brightness brightness) => brightness == Brightness.dark
    ? const Color(0xFF0B0B0D)
    : const Color(0xFFF4F4F6);

/// Une matière : ses modules, puis ses séquences (ou units, ou chapitres)
/// en accordéons repliés, chacun avec son état, sa progression et, déplié,
/// les titres de ses leçons.
class ContentSubjectScreen extends ConsumerWidget {
  const ContentSubjectScreen({required this.subjectKey, super.key});

  final String subjectKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journey = ref.watch(subjectJourneyProvider(subjectKey));
    final brightness = learningBrightness(context);
    final palette = SubjectVisualIdentity.of(subjectKey).palette(brightness);
    final background = learningBackground(brightness);
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: palette.textPrimary,
        elevation: 0,
      ),
      // Rouvrir une leçon met à jour la « dernière visite » : la page garde
      // alors son contenu (accordéons ouverts, défilement) pendant le calcul.
      body: journey.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Unavailable(message: context.l10n.ceLoadError),
        data: (journey) => journey == null
            ? _Unavailable(message: context.l10n.ceUnavailableBody)
            : _SubjectBody(journey: journey, palette: palette),
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

class _SubjectBody extends ConsumerWidget {
  const _SubjectBody({required this.journey, required this.palette});

  final SubjectJourney journey;
  final SubjectPalette palette;

  /// Toute ouverture (séquence, leçon, synthèse) retient la séquence comme
  /// dernière visitée.
  void _visit(WidgetRef ref, ChapterJourney chapter) => ref
      .read(learningRecentsProvider.notifier)
      .visited(journey.key, chapter.contentId);

  void _open(BuildContext context, WidgetRef ref, ChapterJourney chapter) {
    _visit(ref, chapter);
    context.push(AppRoutes.contentChapter(chapter.contentId));
  }

  void _openLesson(
    BuildContext context,
    WidgetRef ref,
    ChapterJourney chapter,
    int lesson,
  ) {
    _visit(ref, chapter);
    context.push(AppRoutes.contentLesson(chapter.contentId, lesson));
  }

  void _openSynthesis(
    BuildContext context,
    WidgetRef ref,
    ChapterJourney chapter,
  ) {
    _visit(ref, chapter);
    context.push(AppRoutes.contentIntegration(chapter.contentId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapters = journey.chapters;
    return ListView(
      key: const ValueKey('subject-journey-list'),
      padding: const EdgeInsets.fromLTRB(
        IntelliaSpacing.lg,
        0,
        IntelliaSpacing.lg,
        IntelliaSpacing.xxl,
      ),
      children: [
        _SubjectHero(
          journey: journey,
          onResume: journey.lastVisited == null
              ? null
              : () => _open(context, ref, journey.lastVisited!),
        ),
        const SizedBox(height: IntelliaSpacing.xl),
        for (final (index, chapter) in chapters.indexed) ...[
          // Matière → Module → Séquence : le titre du module avant sa
          // première séquence.
          if (chapter.entry.curriculum.moduleNumber != null &&
              (index == 0 ||
                  chapters[index - 1].entry.curriculum.moduleNumber !=
                      chapter.entry.curriculum.moduleNumber))
            Padding(
              padding: EdgeInsets.only(
                top: index == 0 ? 0 : IntelliaSpacing.lg,
                bottom: IntelliaSpacing.sm,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  moduleLabel(context, chapter.entry.curriculum),
                  key: ValueKey(
                    'local-module-${journey.key}-'
                    '${chapter.entry.curriculum.moduleNumber}',
                  ),
                  style: ContentText.title(
                    color: palette.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: IntelliaSpacing.md),
            child: SequenceCard(
              journey: chapter,
              lastVisited: journey.lastVisited?.contentId == chapter.contentId,
              onOpenLesson: (lesson) =>
                  _openLesson(context, ref, chapter, lesson),
              onOpenOverview: () => _open(context, ref, chapter),
              onOpenSynthesis:
                  chapter.chapter.integrationConcepts.isNotEmpty ||
                      chapter.chapter.integrationPracticeQuestions.isNotEmpty
                  ? () => _openSynthesis(context, ref, chapter)
                  : null,
            ),
          ),
        ],
      ],
    );
  }
}

/// En-tête de la matière : son identité, sa progression, ses notions.
class _SubjectHero extends StatelessWidget {
  const _SubjectHero({required this.journey, this.onResume});

  final SubjectJourney journey;

  /// Rouvre la dernière séquence visitée, s'il y en a une.
  final VoidCallback? onResume;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final identity = SubjectVisualIdentity.of(journey.key);
    final palette = identity.palette(learningBrightness(context));
    final subject = journey.subject;
    final progress = journey.progress;
    return LearningSurface(
      key: const ValueKey('subject-hero'),
      palette: palette,
      identity: identity,
      showMotif: true,
      padding: const EdgeInsets.all(IntelliaSpacing.lg + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SubjectBadge(identity: identity, palette: palette, size: 56),
          const SizedBox(height: IntelliaSpacing.md),
          Semantics(
            header: true,
            child: Text(
              subjectDisplayName(context, subject.key, subject.title),
              style: ContentText.title(color: palette.textPrimary, size: 34),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            [
              subject.levelLabel,
              subjectPartsLabel(context, subject),
              l10n.ceLessonCount(journey.lessonCount),
            ].where((part) => part.isNotEmpty).join(' · '),
            style: ContentText.body(color: palette.textSecondary, size: 14),
          ),
          const SizedBox(height: IntelliaSpacing.lg),
          Row(
            children: [
              Expanded(
                child: JourneyProgressBar(
                  value: progress.progress,
                  palette: palette,
                  height: 8,
                ),
              ),
              const SizedBox(width: IntelliaSpacing.sm),
              Text(
                l10n.ljProgressPercent(progress.percent),
                style: ContentText.math(color: palette.accent, size: 18),
              ),
            ],
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          Text(
            l10n.ljConceptsMastered(progress.mastered, progress.total),
            style: ContentText.body(
              color: palette.textSecondary,
              size: 13.5,
              weight: FontWeight.w600,
            ),
          ),
          if (journey.lastVisited case final last? when onResume != null) ...[
            const SizedBox(height: IntelliaSpacing.md),
            Divider(height: 1, color: palette.border),
            const SizedBox(height: IntelliaSpacing.xs),
            Semantics(
              button: true,
              child: IntelliaPressable(
                key: ValueKey('subject-resume-${journey.key}'),
                onTap: onResume,
                scaleFactor: 0.98,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(
                    children: [
                      Icon(
                        Icons.play_circle_fill_rounded,
                        color: palette.accent,
                        size: 22,
                      ),
                      const SizedBox(width: IntelliaSpacing.xs),
                      Expanded(
                        child: Text(
                          l10n.ljResume(last.entry.curriculum.chapterTitle),
                          style: ContentText.label(
                            color: palette.accent,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
