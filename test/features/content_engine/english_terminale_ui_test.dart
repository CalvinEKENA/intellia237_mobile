import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/core/academics/class_key.dart';
import 'package:intellia237/features/content_engine/application/content_providers.dart';
import 'package:intellia237/features/content_engine/data/content_delivery.dart';
import 'package:intellia237/features/content_engine/data/content_pack_repository.dart';
import 'package:intellia237/features/content_engine/data/learner_content_store.dart';
import 'package:intellia237/features/content_engine/presentation/content_lesson_screen.dart';
import 'package:intellia237/features/content_engine/presentation/local_chapters_section.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

import 'pack_fixture.dart';

/// Anglais de Terminale à l'écran : Matière → Module → Unit dans Apprendre,
/// leçons à plusieurs notions, libellés dans la langue du contenu.
const _u1 = 'english_terminale_m1_u1_applying_for_passport';
const _u2 = 'english_terminale_m1_u2_discussing_recreational_activities';

Future<ProviderContainer> _pump(
  WidgetTester tester,
  Widget screen, {
  String? contentId,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      contentPackRepositoryProvider.overrideWithValue(
        ContentPackRepository(source: DiskContentPackSource()),
      ),
      learnerContentStoreProvider.overrideWithValue(
        InMemoryLearnerContentStore(),
      ),
      // Une série sans mathématiques embarquées : seul l'anglais apparaît.
      contentClassKeyProvider.overrideWith(
        (ref) async => const ClassKey('terminale', series: 'a'),
      ),
      contentPackCacheProvider.overrideWithValue(InMemoryContentPackCache()),
      remoteContentGatewayProvider.overrideWithValue(const OfflineGateway()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            disableAnimations: true,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(body: screen),
        ),
      ),
    ),
  );
  if (contentId != null) {
    await tester.runAsync(
      () => container.read(contentChapterProvider(contentId).future),
    );
  }
  await tester.runAsync(
    () => container.read(learnerContentControllerProvider.future),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return container;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('Apprendre : Anglais · Module 1, puis Unit 1 et Unit 2', (
    tester,
  ) async {
    final container = await _pump(tester, const LocalChaptersSection());
    await tester.runAsync(
      () => container.read(localContentSubjectsProvider.future),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(
      find.byKey(const ValueKey('local-module-anglais-1')),
      findsOneWidget,
    );
    expect(
      find.text('Anglais · Module 1 — Family and social life'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('local-chapter-$_u1')), findsOneWidget);
    expect(find.byKey(const ValueKey('local-chapter-$_u2')), findsOneWidget);
    expect(find.text('Applying for a passport'), findsOneWidget);
    expect(find.text('Discussing recreational activities'), findsOneWidget);
    expect(find.textContaining('Unit 2'), findsOneWidget);
  });

  testWidgets('leçon à trois notions, niveaux et Compagnon en anglais', (
    tester,
  ) async {
    await _pump(
      tester,
      const ContentLessonScreen(contentId: _u2, lessonNumber: 4),
      contentId: _u2,
    );
    for (final id in [
      'recreation_vocabulary',
      'phrasal_verbs',
      'prepositional_phrases',
    ]) {
      expect(find.byKey(ValueKey('lesson-concept-$id')), findsOneWidget);
    }
    expect(find.text('Simple English'), findsWidgets);
    expect(find.text('Very simple'), findsWidgets);
    await _tap(
      tester,
      find.byKey(const ValueKey('lesson-concept-phrasal_verbs')),
    );
    await _tap(tester, find.byKey(const ValueKey('open-companion')));
    expect(find.text('Explain this'), findsOneWidget);
    expect(find.text('Why is my answer wrong?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('320 px, texte ×1,3 : chaque étape de chaque leçon tient', (
    tester,
  ) async {
    for (final contentId in [_u1, _u2]) {
      for (var lesson = 1; lesson <= 5; lesson++) {
        await _pump(
          tester,
          ContentLessonScreen(contentId: contentId, lessonNumber: lesson),
          contentId: contentId,
          size: const Size(320, 640),
          textScale: 1.3,
        );
        for (var step = 0; step < 5; step++) {
          await _tap(tester, find.byKey(ValueKey('lesson-step-$step')));
          expect(
            tester.takeException(),
            isNull,
            reason: '$contentId leçon $lesson étape $step',
          );
        }
      }
    }
  });
}
