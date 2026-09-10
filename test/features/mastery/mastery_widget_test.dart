import 'dart:io';
import 'dart:ui' as ui;

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/mastery/application/mastery_providers.dart';
import 'package:intellia237/features/mastery/domain/learning_summary.dart';
import 'package:intellia237/features/mastery/domain/mastery_estimate.dart';
import 'package:intellia237/features/mastery/presentation/mastery_copy.dart';
import 'package:intellia237/features/mastery/presentation/mastery_scale.dart';
import 'package:intellia237/features/mastery/presentation/mastery_subject_card.dart';
import 'package:intellia237/features/mastery/presentation/mastery_subject_detail.dart';
import 'package:intellia237/features/mastery/presentation/student_mastery_profile.dart';
import 'package:intellia237/features/parent/presentation/child_overview_screen.dart';
import 'package:intellia237/features/parent/presentation/child_progress_screen.dart';
import 'package:intellia237/features/parent/presentation/parent_home_screen.dart';
import 'package:intellia237/features/student_home/presentation/student_home_screen.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

import 'mastery_test_harness.dart';

void main() {
  for (final language in ['fr', 'en']) {
    final copy = lookupAppLocalizations(Locale(language));
    for (final width in [320.0, 360.0, 390.0, 412.0, 480.0, 768.0]) {
      for (final scale in [1.0, 1.3, 1.5, 2.0]) {
        testWidgets(
          'student $language width=$width text=$scale stays readable',
          (tester) async {
            await pumpMasteryHarness(
              tester,
              language: language,
              width: width,
              textScale: scale,
            );
            expect(find.text('Amina'), findsOneWidget);
            expect(find.text('Léo'), findsOneWidget);
            expect(
              find.text(
                copy.studentSummary(LearningSummaryKind.firstEstimates),
              ),
              findsOneWidget,
            );
            await inspectWholeScroll(tester);
            expect(find.textContaining('%'), findsNothing);
            await tester.pumpWidget(const SizedBox.shrink());
          },
        );
        testWidgets(
          'parent $language width=$width text=$scale has no surveillance metrics',
          (tester) async {
            await pumpMasteryHarness(
              tester,
              language: language,
              width: width,
              textScale: scale,
              parent: true,
              content: const ChildProgressScreen(childId: 'learner'),
            );
            expect(
              find.text(copy.parentSummary(LearningSummaryKind.firstEstimates)),
              findsOneWidget,
            );
            await inspectWholeScroll(tester);
            expect(find.textContaining('9876'), findsNothing);
            expect(find.textContaining('9999'), findsNothing);
            expect(find.textContaining('FAKE_'), findsNothing);
            expect(find.textContaining('%'), findsNothing);
            await tester.pumpWidget(const SizedBox.shrink());
          },
        );
      }
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'detail $language width=$width text=$scale has no chapter mastery',
          (tester) async {
            await pumpMasteryHarness(
              tester,
              language: language,
              width: width,
              textScale: scale,
              content: MasterySubjectDetail(
                subject: subjectFixture(language: language),
              ),
            );
            expect(find.text(copy.masteryBuilding), findsOneWidget);
            await inspectWholeScroll(tester);
            expect(find.textContaining('%'), findsNothing);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
          },
        );
      }
    }
    test('student and parent narratives have distinct wording ($language)', () {
      for (final kind in LearningSummaryKind.values) {
        expect(copy.studentSummary(kind), isNot(copy.parentSummary(kind)));
      }
    });
  }

  testWidgets('complete coverage alone leaves mastery neutral', (tester) async {
    await pumpMasteryHarness(
      tester,
      repository: FixtureMasteryRepository(records: []),
    );
    await tester.scrollUntilVisible(find.byType(MasterySubjectCard).first, 200);
    expect(find.text('Pas encore assez d’éléments'), findsWidgets);
    expect(find.text('7 chapitres explorés'), findsOneWidget);
    expect(find.text('Solide'), findsNothing);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('profile survives mastery errors and retries the actual source', (
    tester,
  ) async {
    final repository = FixtureMasteryRepository(failure: true);
    final container = await pumpMasteryHarness(tester, repository: repository);
    expect(find.text('Amina'), findsOneWidget);
    expect(find.byType(MasteryUnavailable), findsOneWidget);
    expect(container.read(studentMasteryProvider).hasError, isTrue);
    repository.failure = false;
    await tester.tap(find.text('Réessayer').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(repository.calls, 2);
    expect(container.read(studentMasteryProvider).hasValue, isTrue);
    expect(find.byType(MasteryUnavailable), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'academic, coverage, school and companion errors remain isolated',
    (tester) async {
      await pumpMasteryHarness(
        tester,
        academicFailure: true,
        coverageFailure: true,
        schoolFailure: true,
        companionFailure: true,
      );
      expect(find.text('Amina'), findsOneWidget);
      expect(find.text('Erreur de chargement'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('mastery-student-summary')),
        findsOneWidget,
      );
      await inspectWholeScroll(tester);
    },
  );

  testWidgets('canonical Kira identity and portrait remain synchronized', (
    tester,
  ) async {
    await pumpMasteryHarness(tester, companion: 'grace');
    expect(find.text('Kira'), findsOneWidget);
    final image = tester.widget<Image>(
      find.byKey(const ValueKey('student-profile-tutor-image-kira')),
    );
    expect((image.image as AssetImage).assetName, 'assets/companions/kira.png');
    expect(find.text('Léo'), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  for (final reduced in [false, true]) {
    testWidgets('subject transform and back navigation; reduced=$reduced', (
      tester,
    ) async {
      await pumpMasteryHarness(
        tester,
        reduced: reduced,
        content: ListView(
          children: [
            MasterySubjectCard(
              subject: subjectFixture(),
              estimate: profileFixture().forSubject('math'),
            ),
          ],
        ),
      );
      if (!reduced) {
        final transform = tester.widget<OpenContainer<void>>(
          find.byType(OpenContainer<void>),
        );
        expect(transform.transitionDuration, const Duration(milliseconds: 280));
      } else {
        expect(find.byType(OpenContainer<void>), findsNothing);
        expect(tester.hasRunningAnimations, isFalse);
      }
      await tester.tap(find.text('Mathématiques').first);
      await tester.pumpAndSettle();
      expect(find.byType(MasterySubjectDetail), findsOneWidget);
      expect(find.text('En construction'), findsOneWidget);
      await tester.tap(find.byType(BackButton).last);
      await tester.pumpAndSettle();
      expect(find.byType(MasterySubjectDetail), findsNothing);
      expect(find.byType(MasterySubjectCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'ink semantics describe states, confidence and real trace, never scores',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final estimate = MasteryEstimate(
        entityId: 'math',
        state: MasteryState.understood,
        confidence: MasteryConfidence.supported,
        trend: MasteryTrend.progressing,
        masteryScore: 0.72,
        lastEvidenceAt: masteryNow,
        previousSnapshot: MasterySnapshot(
          entityId: 'math',
          entityType: MasteryEntityType.subject,
          state: MasteryState.building,
          confidence: MasteryConfidence.limited,
          lastEvidenceAt: masteryNow.subtract(const Duration(days: 1)),
        ),
      );
      await pumpMasteryHarness(
        tester,
        content: ListView(
          children: [
            MasteryScale(subjectLabel: 'Mathématiques', estimate: estimate),
          ],
        ),
      );
      expect(
        find.bySemanticsLabel(
          RegExp(
            'Mathématiques, Bien compris, Confiance étayée, Estimation en progression',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('percent|pour ?cent|%')),
        findsNothing,
      );
      expect(find.textContaining('72'), findsNothing);
      expect(find.text('Tracé précédent : En construction'), findsOneWidget);
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.byKey(const ValueKey('mastery-ink')),
                  )
                  .painter!
              as MasteryInkPainter;
      expect(painter.previousExtent, masteryInkExtent(MasteryState.building));
      expect(painter.traceOpacity, 1);
      semantics.dispose();
    },
  );

  testWidgets(
    'absent or foreign snapshot produces neither visible nor painted trace',
    (tester) async {
      final estimate = profileFixture().forSubject('math');
      await pumpMasteryHarness(
        tester,
        content: ListView(
          children: [
            MasteryScale(subjectLabel: 'Mathématiques', estimate: estimate),
          ],
        ),
      );
      expect(find.textContaining('Tracé précédent'), findsNothing);
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.byKey(const ValueKey('mastery-ink')),
                  )
                  .painter!
              as MasteryInkPainter;
      expect(painter.previousExtent, isNull);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    },
  );

  testWidgets('no-evidence semantics do not announce a zero percent value', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpMasteryHarness(
      tester,
      content: ListView(
        children: const [
          MasteryScale(
            subjectLabel: 'Mathématiques',
            estimate: MasteryEstimate(entityId: 'math'),
          ),
        ],
      ),
    );
    expect(
      find.bySemanticsLabel('Mathématiques, Pas encore assez d’éléments'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp('percent|pour ?cent|%')), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
    semantics.dispose();
  });

  testWidgets('child overview also uses the parent narrative and safe fields', (
    tester,
  ) async {
    await pumpMasteryHarness(
      tester,
      parent: true,
      content: const ChildOverviewScreen(childId: 'learner'),
    );
    expect(
      find.byKey(const ValueKey('mastery-parent-summary')),
      findsOneWidget,
    );
    await inspectWholeScroll(tester);
    expect(find.textContaining('9876'), findsNothing);
    expect(find.textContaining('FAKE_'), findsNothing);
  });

  testWidgets('parent home removes daily surveillance and coverage rankings', (
    tester,
  ) async {
    await pumpMasteryHarness(
      tester,
      parent: true,
      content: const ParentHomeScreen(),
    );
    expect(
      find.byKey(const ValueKey('mastery-parent-summary')),
      findsOneWidget,
    );
    await inspectWholeScroll(tester);
    expect(find.textContaining('9876'), findsNothing);
    expect(find.textContaining('FAKE_'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets(
    'iOS Reduce Motion bypasses transforms and all profile entrances',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(reduceMotion: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpMasteryHarness(tester, reduced: false);
      expect(find.byType(OpenContainer<void>), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
      await inspectWholeScroll(tester);
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    },
  );

  testWidgets(
    'new evidence settles the ink before revealing the previous trace',
    (tester) async {
      final previous = MasterySnapshot(
        entityId: 'math',
        entityType: MasteryEntityType.subject,
        state: MasteryState.exploring,
        confidence: MasteryConfidence.limited,
        lastEvidenceAt: masteryNow.subtract(const Duration(days: 1)),
      );
      final current = MasteryEstimate(
        entityId: 'math',
        state: MasteryState.building,
        confidence: MasteryConfidence.limited,
        lastEvidenceAt: masteryNow,
        previousSnapshot: previous,
        trend: MasteryTrend.progressing,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MasteryScale(
              subjectLabel: 'Mathématiques',
              estimate: current,
            ),
          ),
        ),
      );
      MasteryInkPainter painter() =>
          tester
                  .widget<CustomPaint>(
                    find.byKey(const ValueKey('mastery-ink')),
                  )
                  .painter!
              as MasteryInkPainter;
      expect(painter().traceOpacity, 0);
      await tester.pump(const Duration(milliseconds: 440));
      expect(
        painter().extent,
        closeTo(masteryInkExtent(MasteryState.building), 0.001),
      );
      expect(painter().traceOpacity, 0);
      await tester.pump(const Duration(milliseconds: 80));
      expect(painter().traceOpacity, 1);
      // Complete the next frame at the exact controller-duration boundary.
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.hasRunningAnimations, isFalse);
    },
  );

  testWidgets('capture reproducible review fixtures (not production data)', (
    tester,
  ) async {
    final captures = [
      ('student-fr-390', 390.0, 1.0, 'fr', false),
      ('student-en-412', 412.0, 1.0, 'en', false),
      ('student-fr-320-text2', 320.0, 2.0, 'fr', false),
      ('parent-fr-390', 390.0, 1.0, 'fr', true),
      ('parent-fr-320-text2', 320.0, 2.0, 'fr', true),
    ];
    for (final (name, width, scale, language, parent) in captures) {
      final key = GlobalKey();
      await pumpMasteryHarness(
        tester,
        width: width,
        textScale: scale,
        language: language,
        parent: parent,
        captureKey: key,
        content: parent
            ? const ChildProgressScreen(childId: 'learner')
            : const StudentProfileTab(),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/mastery-review/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
