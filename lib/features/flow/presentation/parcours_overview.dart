import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../auth/application/auth_controller.dart';
import '../../content_engine/application/content_providers.dart';
import '../../content_engine/application/subject_journey.dart';
import '../../content_engine/presentation/learning_cards.dart';
import '../../content_engine/presentation/subject_identity.dart';
import '../../learn/application/learn_providers.dart';
import '../../profile/application/user_preferences_controller.dart';
import '../../quiz/application/pack_quiz_providers.dart';
import '../../student_home/application/personal_goal_providers.dart';
import '../domain/parcours_metrics.dart';
import 'widgets/parcours_charts.dart';

/// The learning pager remains mounted below this sheet. Closing the overview
/// does not change the current card, view mode, answer or scroll position.
Future<void> showParcoursOverview(BuildContext context) {
  final reduced =
      MediaQuery.disableAnimationsOf(context) ||
      ProviderScope.containerOf(
        context,
        listen: false,
      ).read(userPreferencesProvider).reduceMotion;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    sheetAnimationStyle: reduced
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: Duration(milliseconds: 250),
            reverseDuration: Duration(milliseconds: 180),
          ),
    useSafeArea: true,
    backgroundColor: IntelliaColors.backgroundPrimary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => FractionallySizedBox(
      heightFactor: 0.94,
      child: ParcoursOverview(
        onOpen: (chapter, lesson) {
          Navigator.of(sheetContext).pop();
          if (context.mounted) {
            context.push(AppRoutes.contentLesson(chapter.contentId, lesson));
          }
        },
      ),
    ),
  );
}

final parcoursClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

class ParcoursOverview extends ConsumerWidget {
  const ParcoursOverview({required this.onOpen, super.key});
  final void Function(ChapterJourney chapter, int lesson) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(userPreferencesProvider);
    final reduced =
        preferences.reduceMotion || MediaQuery.disableAnimationsOf(context);
    final media = MediaQuery.of(context).copyWith(disableAnimations: reduced);
    return MediaQuery(
      data: media,
      child: _OverviewBody(onOpen: onOpen),
    );
  }
}

class _OverviewBody extends ConsumerWidget {
  const _OverviewBody({required this.onOpen});
  final void Function(ChapterJourney chapter, int lesson) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeys = ref.watch(subjectJourneysProvider);
    final snapshot = ref.watch(learnerContentControllerProvider);
    final history = ref.watch(packQuizHistoryProvider);
    final entries = history.valueOrNull;
    final now = ref.watch(parcoursClockProvider)();
    final l10n = context.l10n;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
            child: Row(
              children: [
                Expanded(child: Text(l10n.pvTitle, style: _title)),
                IconButton(
                  key: const ValueKey('parcours-overview-close'),
                  tooltip: l10n.closeLabel,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              key: const ValueKey('parcours-overview-scroll'),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                const _LearningHero(),
                const SizedBox(height: 20),
                if (!snapshot.hasValue || !journeys.hasValue)
                  _Paper(
                    child: Text(
                      snapshot.hasError || journeys.hasError
                          ? l10n.loadErrorLabel
                          : l10n.stateLoadingTitle,
                    ),
                  )
                else if (journeys.requireValue.isEmpty)
                  _Paper(child: Text(l10n.pvNoAvailablePack))
                else ...[
                  Text(l10n.pvChapterMap, style: _title),
                  const SizedBox(height: 8),
                  Text(l10n.pvChapterScope, style: _caption),
                  const SizedBox(height: 14),
                  for (final journey in journeys.requireValue) ...[
                    _SubjectMap(journey: journey, onOpen: onOpen),
                    const SizedBox(height: 14),
                  ],
                  _FocusNext(journeys: journeys.requireValue, onOpen: onOpen),
                  const SizedBox(height: 20),
                ],
                if (entries == null)
                  _Paper(
                    child: Text(
                      history.hasError
                          ? l10n.loadErrorLabel
                          : l10n.stateLoadingTitle,
                    ),
                  )
                else ...[
                  _Paper(
                    child: ParcoursQuizHeatmap(
                      days: quizActivityDays(entries, now: now),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Paper(
                    child: ParcoursQuizCurve(
                      series: QuizSeries.from(entries, now: now),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningHero extends ConsumerWidget {
  const _LearningHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final academic = ref.watch(studentAcademicContextProvider).valueOrNull;
    final weekly = ref.watch(personalGoalControllerProvider);
    final goal = weekly.valueOrNull?.goal;
    return _Paper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            auth.firstName?.trim().isNotEmpty == true
                ? auth.firstName!
                : context.l10n.intelliaUser,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 28,
              color: IntelliaColors.textPrimary,
            ),
          ),
          if (academic != null) ...[
            const SizedBox(height: 4),
            Text(academic.label, style: _caption),
          ],
          const SizedBox(height: 16),
          Text(context.l10n.myWeeklyGoal, style: _title.copyWith(fontSize: 16)),
          const SizedBox(height: 6),
          if (goal == null)
            Text(
              weekly.hasValue
                  ? context.l10n.weeklyGoalUnset
                  : weekly.hasError
                  ? context.l10n.loadErrorLabel
                  : context.l10n.stateLoadingTitle,
              style: _caption,
            )
          else ...[
            Text(
              context.l10n.weeklyGoalSummary(
                goal.sessionsPerWeek,
                goal.minutesPerSession,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.pvGoalActiveDays(
                weekly.requireValue.activeDays,
                goal.sessionsPerWeek,
              ),
              style: _caption,
            ),
          ],
        ],
      ),
    );
  }
}

class _SubjectMap extends StatelessWidget {
  const _SubjectMap({required this.journey, required this.onOpen});
  final SubjectJourney journey;
  final void Function(ChapterJourney chapter, int lesson) onOpen;

  @override
  Widget build(BuildContext context) {
    final identity = SubjectVisualIdentity.of(journey.key);
    final palette = identity.palette(Brightness.light);
    return _Paper(
      key: ValueKey('parcours-map-${journey.key}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(identity.icon, color: palette.accent),
              const SizedBox(width: 10),
              Expanded(child: Text(journey.subject.title, style: _title)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.ljConceptsMastered(
              journey.progress.mastered,
              journey.progress.total,
            ),
            style: _caption,
          ),
          const SizedBox(height: 14),
          for (final (index, chapter) in journey.chapters.indexed)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      ParcoursMasteryArc(
                        mastered: chapter.progress.mastered,
                        total: chapter.progress.total,
                        color: palette.accent,
                      ),
                      if (index + 1 < journey.chapters.length)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            color: palette.accent.withValues(alpha: 0.15),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chapter.chapter.curriculum.chapterTitle,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            journeyStatusLabel(
                              context,
                              chapter.progress.status,
                            ),
                            style: _caption.copyWith(color: palette.accent),
                          ),
                          Text(
                            context.l10n.ljConceptsMastered(
                              chapter.progress.mastered,
                              chapter.progress.total,
                            ),
                            style: _caption,
                          ),
                          if (chapter.lessons.isNotEmpty)
                            TextButton.icon(
                              key: ValueKey(
                                'parcours-open-${chapter.contentId}',
                              ),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(48, 48),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                foregroundColor: palette.accent,
                                alignment: Alignment.centerLeft,
                              ),
                              onPressed: () => onOpen(
                                chapter,
                                chapter.focusLesson ??
                                    chapter.lessons.first.lesson.number,
                              ),
                              icon: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                              ),
                              label: Text(
                                chapter.focusStarted
                                    ? context.l10n.companionActionResumeLesson
                                    : context.l10n.companionActionOpenCourse,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FocusNext extends StatelessWidget {
  const _FocusNext({required this.journeys, required this.onOpen});
  final List<SubjectJourney> journeys;
  final void Function(ChapterJourney chapter, int lesson) onOpen;

  @override
  Widget build(BuildContext context) {
    final chapters = journeys.expand((j) => j.chapters).toList();
    final review = chapters
        .where(
          (c) => c.focusStarted && c.focusLesson != null && c.focus != null,
        )
        .take(3)
        .toList();
    final candidates = review.isNotEmpty
        ? review
        : chapters
              .where((c) => c.focusLesson != null && c.focus != null)
              .take(1)
              .toList();
    if (candidates.isEmpty) return const SizedBox.shrink();
    return _Paper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            review.isNotEmpty
                ? context.l10n.pvStrengthen
                : context.l10n.pvNextStep,
            style: _title,
          ),
          const SizedBox(height: 8),
          for (final chapter in candidates)
            TextButton.icon(
              key: ValueKey('parcours-focus-${chapter.contentId}'),
              onPressed: () => onOpen(chapter, chapter.focusLesson!),
              icon: const Icon(Icons.school_outlined),
              label: Text(chapter.focus!.title),
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                minimumSize: const Size(48, 48),
                foregroundColor: IntelliaColors.brandIndigo,
              ),
            ),
        ],
      ),
    );
  }
}

class _Paper extends StatelessWidget {
  const _Paper({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0x165856D6)),
    ),
    child: child,
  );
}

const _title = TextStyle(
  color: IntelliaColors.textPrimary,
  fontWeight: FontWeight.w800,
  fontSize: 19,
);
const _caption = TextStyle(
  color: IntelliaColors.textSecondary,
  height: 1.45,
  fontSize: 13,
);
