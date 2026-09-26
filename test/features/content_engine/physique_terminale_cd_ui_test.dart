import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/core/academics/class_key.dart';
import 'package:intellia237/features/content_engine/application/content_providers.dart';
import 'package:intellia237/features/content_engine/data/content_delivery.dart';
import 'package:intellia237/features/content_engine/data/content_pack_repository.dart';
import 'package:intellia237/features/content_engine/data/learner_content_store.dart';
import 'package:intellia237/features/content_engine/presentation/content_chapter_screen.dart';
import 'package:intellia237/features/content_engine/presentation/content_lesson_screen.dart';
import 'package:intellia237/features/content_engine/presentation/local_chapters_section.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

import 'pack_fixture.dart';

/// Physique Terminales C-D à l'écran : Physique → Module 1 → Séquence 1
/// dans Apprendre, jamais présentée comme un chapitre de mathématiques.
const _id = 'physique_terminale_cd_m1_s1_erreurs_et_incertitudes';

Future<ProviderContainer> _pump(
  WidgetTester tester,
  Widget screen, {
  ClassKey classKey = const ClassKey('terminale', series: 'c'),
  bool loadChapter = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
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
      contentClassKeyProvider.overrideWith((ref) async => classKey),
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
          data: const MediaQueryData(
            size: Size(390, 844),
            disableAnimations: true,
          ),
          child: Scaffold(body: screen),
        ),
      ),
    ),
  );
  if (loadChapter) {
    await tester.runAsync(
      () => container.read(contentChapterProvider(_id).future),
    );
  }
  await tester.runAsync(
    () => container.read(learnerContentControllerProvider.future),
  );
  await tester.runAsync(
    () => container.read(localContentSubjectsProvider.future),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return container;
}

void main() {
  testWidgets('Apprendre : Physique · Module 1, puis Séquence 1', (
    tester,
  ) async {
    await _pump(
      tester,
      const SingleChildScrollView(child: LocalChaptersSection()),
    );
    expect(
      find.byKey(const ValueKey('local-module-physique-1')),
      findsOneWidget,
    );
    expect(
      find.text('Physique · Module 1 — Mesures et incertitudes'),
      findsOneWidget,
    );
    final tile = find.byKey(const ValueKey('local-chapter-$_id'));
    expect(tile, findsOneWidget);
    expect(
      find.descendant(of: tile, matching: find.text('Erreurs et incertitudes')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: tile, matching: find.textContaining('Séquence 1')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: tile, matching: find.textContaining('Chapitre')),
      findsNothing,
    );
  });

  testWidgets('Terminale A : aucune physique de C-D dans Apprendre', (
    tester,
  ) async {
    await _pump(
      tester,
      const SingleChildScrollView(child: LocalChaptersSection()),
      classKey: const ClassKey('terminale', series: 'a'),
    );
    expect(find.byKey(const ValueKey('local-chapter-$_id')), findsNothing);
    expect(find.textContaining('Physique'), findsNothing);
  });

  testWidgets('écran de la séquence : module et séquence, 5 leçons', (
    tester,
  ) async {
    await _pump(
      tester,
      const ContentChapterScreen(contentId: _id),
      loadChapter: true,
    );
    expect(
      find.text('Module 1 — Mesures et incertitudes · Séquence 1'),
      findsOneWidget,
    );
    expect(find.text('Erreurs et incertitudes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leçon 1 : trois notions, une à la fois', (tester) async {
    await _pump(
      tester,
      const ContentLessonScreen(contentId: _id, lessonNumber: 1),
      loadChapter: true,
    );
    for (final id in [
      'measurement_range',
      'accuracy_precision',
      'random_systematic_errors',
    ]) {
      expect(find.byKey(ValueKey('lesson-concept-$id')), findsOneWidget);
    }
    await tester.tap(
      find.byKey(const ValueKey('lesson-concept-accuracy_precision')),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(
      find.textContaining('La justesse concerne', skipOffstage: false),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
