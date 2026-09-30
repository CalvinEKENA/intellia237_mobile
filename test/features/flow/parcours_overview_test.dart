import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intellia237/core/academics/class_key.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/content_engine/application/content_providers.dart';
import 'package:intellia237/features/content_engine/application/subject_journey.dart';
import 'package:intellia237/features/content_engine/domain/chapter.dart';
import 'package:intellia237/features/content_engine/domain/mastery.dart';
import 'package:intellia237/features/flow/presentation/parcours_overview.dart';
import 'package:intellia237/features/flow/presentation/widgets/parcours_charts.dart';
import 'package:intellia237/features/learn/application/learn_providers.dart';
import 'package:intellia237/features/learn/domain/learn_academic_context.dart';
import 'package:intellia237/features/profile/application/user_preferences_controller.dart';
import 'package:intellia237/features/quiz/application/pack_quiz_providers.dart';
import 'package:intellia237/features/quiz/application/pack_quiz_session.dart';
import 'package:intellia237/features/quiz/domain/pack_quiz.dart';
import 'package:intellia237/features/student_home/application/personal_goal_providers.dart';
import 'package:intellia237/features/student_home/domain/personal_goal.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../content_engine/pack_fixture.dart';
import '../mastery/mastery_test_harness.dart' show loadMasteryReviewFonts;

class _Snapshot extends LearnerContentController {
  @override
  Future<LearnerContentSnapshot> build() async => LearnerContentSnapshot(
    concepts: {
      pilotChapter().concepts.keys.first: MasteryState(
        conceptId: pilotChapter().concepts.keys.first,
        attempts: 3,
        correct: 3,
        score: 75,
      ),
    },
  );
}

class _History extends PackQuizHistory {
  @override
  Future<List<PackQuizHistoryEntry>> build() async => [
    for (var day = 29; day >= 27; day--)
      PackQuizHistoryEntry(
        setId: 'arithmetique',
        subjectKey: 'mathematiques',
        title: 'Arithmétique',
        mode: PackQuizMode.training,
        score: day - 25,
        total: 5,
        completedAt: DateTime(2026, 9, day, 10),
      ),
    PackQuizHistoryEntry(
      setId: 'arithmetique',
      subjectKey: 'mathematiques',
      title: 'Arithmétique',
      mode: PackQuizMode.evaluation,
      score: 1,
      total: 5,
      completedAt: DateTime(2026, 9, 26, 10),
    ),
  ];
}

class _EmptyHistory extends PackQuizHistory {
  @override
  Future<List<PackQuizHistoryEntry>> build() async => [];
}

class _Goal extends PersonalGoalController {
  @override
  Future<WeeklyGoalProgress> build() async => const WeeklyGoalProgress(
    goal: PersonalGoal(sessionsPerWeek: 3, minutesPerSession: 20),
    activeDays: 2,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  double width = 412,
  double scale = 1,
  bool reduced = true,
  bool empty = false,
  bool failure = false,
  bool modal = false,
  Locale locale = const Locale('fr'),
  void Function(ChapterJourney, int)? onOpen,
}) async {
  await tester.runAsync(loadMasteryReviewFonts);
  SharedPreferences.setMockInitialValues(const {});
  tester.view.physicalSize = Size(width, 860);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final chapter = pilotChapter();
  final entry = ChapterEntry(
    contentId: chapter.contentId,
    directory: pilotDirectory,
    curriculum: chapter.curriculum,
    lessonCount: chapter.lessons.length,
  );
  final container = ProviderContainer(
    overrides: [
      learnerContentControllerProvider.overrideWith(_Snapshot.new),
      packQuizHistoryProvider.overrideWith(
        empty ? _EmptyHistory.new : _History.new,
      ),
      personalGoalControllerProvider.overrideWith(_Goal.new),
      parcoursClockProvider.overrideWithValue(() => DateTime(2026, 9, 30, 18)),
      studentAcademicContextProvider.overrideWith(
        (ref) async =>
            const LearnAcademicContext(classLevel: 'Terminale', series: 'D'),
      ),
      subjectJourneysProvider.overrideWith((ref) async {
        if (failure) throw StateError('unavailable');
        if (empty) return [];
        final snapshot = await ref.watch(
          learnerContentControllerProvider.future,
        );
        return [
          SubjectJourney.build(
            Subject(
              key: 'mathematiques',
              title: 'Mathématiques',
              classKey: const ClassKey('terminale', series: 'd'),
              levelLabel: 'Terminale D',
              chapters: [entry],
            ),
            {chapter.contentId: chapter},
            snapshot,
          ),
        ];
      }),
    ],
  );
  addTearDown(container.dispose);
  container
      .read(authControllerProvider.notifier)
      .setAuthenticatedUser(
        role: AppRole.student,
        userId: 'parcours-test',
        email: 'parcours@example.com',
        firstName: 'Amina',
      );
  await container
      .read(userPreferencesProvider.notifier)
      .setReduceMotion(reduced);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(fontFamily: 'Manrope'),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: false,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: modal
              ? Builder(
                  builder: (context) => Column(
                    children: [
                      const Text('Underlying card 17'),
                      TextButton(
                        key: const ValueKey('overview-open'),
                        onPressed: () => showParcoursOverview(context),
                        child: const Text('Open overview'),
                      ),
                    ],
                  ),
                )
              : RepaintBoundary(
                  key: const ValueKey('parcours-capture'),
                  child: ColoredBox(
                    color: const Color(0xFFFAF9F6),
                    child: ParcoursOverview(onOpen: onOpen ?? (_, _) {}),
                  ),
                ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _readable(WidgetTester tester) {
  expect(tester.takeException(), isNull);
  for (final paragraph
      in tester.allRenderObjects.whereType<RenderParagraph>()) {
    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason: paragraph.text.toPlainText(),
    );
  }
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final locale in const [Locale('fr'), Locale('en')]) {
    for (final width in [320.0, 360.0, 412.0, 480.0]) {
      testWidgets(
        'map + heatmap + curve ${locale.languageCode} $width text x1.5 offline',
        (tester) async {
          await _pump(tester, width: width, scale: 1.5, locale: locale);
          expect(find.text('Amina'), findsOneWidget);
          await _scrollTo(
            tester,
            find.byKey(const ValueKey('parcours-map-mathematiques')),
          );
          expect(
            find.byKey(const ValueKey('parcours-map-mathematiques')),
            findsOneWidget,
          );
          _readable(tester);
          await _scrollTo(tester, find.byType(ParcoursQuizHeatmap));
          _readable(tester);
          await _scrollTo(tester, find.byType(ParcoursQuizCurve));
          _readable(tester);
          expect(
            tester.hasRunningAnimations,
            isFalse,
            reason:
                'preference Reduce Motion is respected without a system flag',
          );
          expect(
            find.byKey(const ValueKey('parcours-quiz-datum')),
            findsNWidgets(3),
          );
        },
      );
    }
  }

  testWidgets(
    'chapter CTA opens its real lesson and mastery comes from snapshot',
    (tester) async {
      ChapterJourney? opened;
      int? lesson;
      await _pump(
        tester,
        onOpen: (c, l) {
          opened = c;
          lesson = l;
        },
      );
      final chapter = pilotChapter();
      final target = find.byKey(ValueKey('parcours-open-${chapter.contentId}'));
      await _scrollTo(tester, target);
      await tester.tap(target);
      expect(opened!.progress.mastered, 1);
      expect(lesson, isIn(chapter.lessons.map((l) => l.number)));
    },
  );

  testWidgets('chart switches training/evaluation without mixing evidence', (
    tester,
  ) async {
    await _pump(tester);
    await _scrollTo(tester, find.byType(ParcoursQuizCurve));
    final evaluation = find.byKey(
      const ValueKey('parcours-series-arithmetique-evaluation'),
    );
    await _scrollTo(tester, evaluation);
    await tester.tap(evaluation);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('parcours-quiz-datum')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('parcours-quiz-curve')),
      findsNothing,
      reason: 'one observation does not invent an evolution',
    );
  });

  testWidgets('missing packs and empty history show honest empty states', (
    tester,
  ) async {
    await _pump(tester, empty: true);
    expect(
      find.byKey(const ValueKey('parcours-map-mathematiques')),
      findsNothing,
    );
    await _scrollTo(tester, find.byType(ParcoursQuizCurve));
    expect(find.byKey(const ValueKey('parcours-quiz-datum')), findsNothing);
    expect(find.byKey(const ValueKey('parcours-quiz-curve')), findsNothing);
    _readable(tester);
  });

  testWidgets('unavailable catalogue preserves identity and explicit error', (
    tester,
  ) async {
    await _pump(tester, failure: true);
    expect(find.text('Amina'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('parcours-map-mathematiques')),
      findsNothing,
    );
    _readable(tester);
  });

  testWidgets('reduced modal closes and leaves the underlying card mounted', (
    tester,
  ) async {
    await _pump(tester, modal: true);
    await tester.tap(find.byKey(const ValueKey('overview-open')));
    await tester.pumpAndSettle();
    expect(find.byType(ParcoursOverview), findsOneWidget);
    expect(
      find.text('Underlying card 17', skipOffstage: false),
      findsOneWidget,
    );
    final route = ModalRoute.of(tester.element(find.byType(ParcoursOverview)))!;
    expect(route.transitionDuration, Duration.zero);
    await tester.tap(find.byKey(const ValueKey('parcours-overview-close')));
    await tester.pumpAndSettle();
    expect(find.byType(ParcoursOverview), findsNothing);
    expect(find.text('Underlying card 17'), findsOneWidget);
    _readable(tester);
  });

  testWidgets('all visual animations stop after the finite entrance', (
    tester,
  ) async {
    await _pump(tester, reduced: false);
    await _scrollTo(tester, find.byType(ParcoursQuizCurve));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.hasRunningAnimations, isFalse);
    _readable(tester);
  });

  testWidgets('optional 412px capture of the source-backed map', (
    tester,
  ) async {
    await _pump(tester);
    final directory = Platform.environment['PARCOURS_CAPTURE_DIR'];
    if (directory == null) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('parcours-capture')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory(directory).createSync(recursive: true);
      File(
        '$directory/parcours_412.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
