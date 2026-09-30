import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/content_engine/application/content_providers.dart';
import 'package:intellia237/features/content_engine/application/subject_journey.dart';
import 'package:intellia237/features/content_engine/data/content_pack_parser.dart';
import 'package:intellia237/features/content_engine/data/learner_content_store.dart';
import 'package:intellia237/features/content_engine/domain/chapter.dart';
import 'package:intellia237/features/content_engine/domain/game_blueprint.dart';
import 'package:intellia237/features/content_engine/domain/mastery.dart';
import 'package:intellia237/features/content_engine/engine/matching_game_engine.dart';
import 'package:intellia237/features/content_engine/presentation/games/game_screen.dart';
import 'package:intellia237/features/profile/application/user_preferences_controller.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mastery/mastery_test_harness.dart' show loadMasteryReviewFonts;
import 'pack_fixture.dart';

const directories = [
  'assets/content/terminale/anglais/m1_u1_applying_for_a_passport',
  'assets/content/terminale_cd/physique/m1_s2_dimension_d_une_grandeur_physique',
  'assets/content/terminale_d/svt/m1_s1_les_echanges_cellulaires',
];

RawContentPack rawPack(String dir, {Map<String, Object?>? runtime}) =>
    RawContentPack(
      directory: dir,
      manifest: readPackJson('manifest.json', directory: dir),
      source: readPackJson('source.json', directory: dir),
      pedagogy: readPackJson('pedagogy.json', directory: dir),
      runtime: runtime ?? readPackJson('runtime.json', directory: dir),
      validation: readPackJson('validation_report.json', directory: dir),
    );

Chapter chapterAt(String dir) => const ContentPackParser().parse(rawPack(dir));
GameBlueprint gameOf(Chapter chapter) =>
    chapter.games.singleWhere((g) => g.engine == GameEngineKind.matching);
MatchingGameEngine completed(GameBlueprint game, {bool wrong = false}) {
  final board = MatchingGameEngine(game.matchingRounds.first);
  if (wrong) {
    board.select(board.left.first.id);
    board.link(board.right.firstWhere((p) => p.id != board.selected).id);
  }
  for (final p in board.round.pairs) {
    board.select(p.id);
    board.link(p.id);
  }
  return board;
}

class _FailingStore extends InMemoryLearnerContentStore {
  bool failing = true;
  @override
  Future<void> save(String learnerId, LearnerContentSnapshot snapshot) async {
    if (failing) throw StateError('offline-storage');
    await super.save(learnerId, snapshot);
  }
}

Future<ProviderContainer> pumpGame(
  WidgetTester tester,
  Chapter chapter, {
  double width = 412,
  LearnerContentStore? store,
}) async {
  await tester.runAsync(loadMasteryReviewFonts);
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = Size(width, 860);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      contentChapterProvider(
        chapter.contentId,
      ).overrideWith((ref) async => chapter),
      learnerContentStoreProvider.overrideWithValue(
        store ?? InMemoryLearnerContentStore(),
      ),
    ],
  );
  addTearDown(container.dispose);
  await container.read(userPreferencesProvider.notifier).setReduceMotion(true);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(fontFamily: 'Manrope'),
        locale: Locale(chapter.curriculum.subject == 'anglais' ? 'en' : 'fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.5)),
          child: child!,
        ),
        home: ContentGameScreen(
          contentId: chapter.contentId,
          gameId: gameOf(chapter).id,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> tapVisible(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void readable(WidgetTester tester) {
  expect(tester.takeException(), isNull);
  for (final p in tester.allRenderObjects.whereType<RenderParagraph>()) {
    expect(p.didExceedMaxLines, isFalse, reason: p.text.toPlainText());
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final dir in directories) {
    final chapter = chapterAt(dir);
    final game = gameOf(chapter);
    test(
      '${game.id}: three validated boards, source-backed stable relations',
      () {
        expect(game.playable, isTrue);
        expect(game.matchingRounds.map((r) => r.difficulty), [1, 2, 3]);
        expect(
          chapter.issues.where((i) => i.code == 'matching_game_invalid'),
          isEmpty,
        );
        for (final round in game.matchingRounds) {
          expect(chapter.concepts.containsKey(round.conceptId), isTrue);
          expect(
            round.pairs.map((p) => p.id).toSet(),
            hasLength(round.pairs.length),
          );
          for (final pair in round.pairs) {
            expect(pair.explanation, isNotEmpty);
            expect(pair.sourceAnchor, isNotEmpty);
          }
          final board = MatchingGameEngine(round, seed: 123);
          final duplicate = MatchingGameEngine(round, seed: 123);
          expect(board.left.map((p) => p.id), duplicate.left.map((p) => p.id));
          expect(
            board.right.map((p) => p.id),
            duplicate.right.map((p) => p.id),
          );
          expect(board.link(board.right.first.id), isNull);
          for (final pair in round.pairs) {
            board.select(pair.id);
            expect(board.link(pair.id), isTrue);
            expect(board.link(pair.id), isNull);
          }
          expect(board.attempts, round.pairs.length);
          expect(board.firstPass, round.pairs.length);
          expect(board.independentSuccess, isTrue);
        }
      },
    );
    for (final width in [320.0, 360.0, 412.0, 480.0]) {
      testWidgets(
        '${game.id}: tap board at $width, text x1.5, reduced/offline',
        (tester) async {
          final container = await pumpGame(tester, chapter, width: width);
          for (final round in game.matchingRounds) {
            for (final pair in round.pairs) {
              await tapVisible(
                tester,
                find.byKey(ValueKey('matching-left-${pair.id}')),
              );
              await tapVisible(
                tester,
                find.byKey(ValueKey('matching-right-${pair.id}')),
              );
              readable(tester);
            }
            final status = find.byKey(
              const ValueKey('matching-evidence-status'),
            );
            await tester.ensureVisible(status);
            await tester.pumpAndSettle();
            final state = container
                .read(learnerContentControllerProvider)
                .requireValue;
            expect(
              state.conceptState(round.conceptId).answeredQuestionIds,
              contains('game:${chapter.contentId}:${game.id}:${round.id}'),
            );
            expect(tester.hasRunningAnimations, isFalse);
            readable(tester);
            await tapVisible(
              tester,
              find.byKey(const ValueKey('matching-next')),
            );
          }
        },
      );
    }
  }

  for (final fault in [
    'duplicate-label',
    'duplicate-id',
    'missing-source',
    'unknown-concept',
    'missing-level',
  ]) {
    test('invalid board $fault is withheld completely', () {
      final runtime = deepCopy(
        readPackJson('runtime.json', directory: directories.first),
      );
      final game = (runtime['games'] as List).last as Map;
      final rounds = game['rounds'] as List;
      final first = rounds.first as Map;
      final pairs = first['pairs'] as List;
      switch (fault) {
        case 'duplicate-label':
          (pairs[1] as Map)['right'] = (pairs[0] as Map)['right'];
        case 'duplicate-id':
          (pairs[1] as Map)['id'] = (pairs[0] as Map)['id'];
        case 'missing-source':
          (pairs[0] as Map).remove('source_anchor');
        case 'unknown-concept':
          first['concept_id'] = 'missing';
        case 'missing-level':
          rounds.removeLast();
      }
      final chapter = const ContentPackParser().parse(
        rawPack(directories.first, runtime: runtime),
      );
      final parsed = gameOf(chapter);
      expect(parsed.playable, isFalse);
      expect(parsed.matchingRounds, isEmpty);
      expect(parsed.status, GameStatus.draft);
    });
  }

  test(
    'error locks neither answer nor full mastery; hint remains practice',
    () {
      final game = gameOf(chapterAt(directories.first));
      final wrong = completed(game, wrong: true);
      expect(wrong.errors, 1);
      expect(wrong.firstPass, game.matchingRounds.first.pairs.length - 1);
      expect(wrong.independentSuccess, isFalse);
      final helped = MatchingGameEngine(game.matchingRounds.first)
        ..revealHint();
      for (final p in helped.round.pairs) {
        helped.select(p.id);
        helped.link(p.id);
      }
      expect(helped.complete, isTrue);
      expect(helped.independentSuccess, isFalse);
    },
  );

  test(
    'concurrent replay earns one persisted evidence, same Parcours concept',
    () async {
      final chapter = chapterAt(directories.first),
          game = gameOf(chapterAt(directories.first));
      // Use the exact blueprint owned by the chapter, not a separately parsed object.
      final owned = chapter.games.singleWhere((g) => g.id == game.id);
      final store = InMemoryLearnerContentStore();
      final container = ProviderContainer(
        overrides: [learnerContentStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      await container.read(learnerContentControllerProvider.future);
      final controller = container.read(
        learnerContentControllerProvider.notifier,
      );
      final results = await Future.wait([
        for (var i = 0; i < 2; i++)
          controller.recordMatchingBoard(
            chapter: chapter,
            game: owned,
            board: completed(owned),
          ),
      ]);
      expect(results, [true, false]);
      final state = container
          .read(learnerContentControllerProvider)
          .requireValue;
      final concept = state.conceptState(owned.matchingRounds.first.conceptId);
      expect(concept.correct, 1);
      expect(concept.score, greaterThan(0));
      expect((await store.load('guest')).toJson(), state.toJson());
      expect((await store.load('other-learner')).concepts, isEmpty);
      expect(
        ConceptsProgress.measure(
              chapter.concepts.keys,
              state,
              masteredAt: chapter.mastery.unlockNextLessonAt,
            ).started >
            0,
        isTrue,
      );
    },
  );

  test(
    'assisted board does not change mastery; wrong board adds one failed attempt',
    () async {
      final chapter = chapterAt(directories.first),
          game = gameOf(chapterAt(directories.first));
      final owned = chapter.games.singleWhere((g) => g.id == game.id);
      final container = ProviderContainer(
        overrides: [
          learnerContentStoreProvider.overrideWithValue(
            InMemoryLearnerContentStore(),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(learnerContentControllerProvider.future);
      final controller = container.read(
        learnerContentControllerProvider.notifier,
      );
      final helped = completed(owned)..helped = true;
      expect(
        await controller.recordMatchingBoard(
          chapter: chapter,
          game: owned,
          board: helped,
        ),
        isFalse,
      );
      expect(
        container.read(learnerContentControllerProvider).requireValue.concepts,
        isEmpty,
      );
      expect(
        await controller.recordMatchingBoard(
          chapter: chapter,
          game: owned,
          board: completed(owned, wrong: true),
        ),
        isTrue,
      );
      final state = container
          .read(learnerContentControllerProvider)
          .requireValue
          .conceptState(owned.matchingRounds.first.conceptId);
      expect(state.attempts, 1);
      expect(state.correct, 0);
      expect(state.answeredQuestionIds, isEmpty);
    },
  );

  testWidgets(
    'storage failure offers retry and does not claim saved evidence',
    (tester) async {
      final chapter = chapterAt(directories.first), store = _FailingStore();
      final container = await pumpGame(tester, chapter, store: store);
      for (final pair in gameOf(chapter).matchingRounds.first.pairs) {
        await tapVisible(
          tester,
          find.byKey(ValueKey('matching-left-${pair.id}')),
        );
        await tapVisible(
          tester,
          find.byKey(ValueKey('matching-right-${pair.id}')),
        );
      }
      final status = find.byKey(const ValueKey('matching-evidence-status'));
      await tester.ensureVisible(status);
      await tester.pumpAndSettle();
      expect(
        container.read(learnerContentControllerProvider).requireValue.concepts,
        isEmpty,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('matching-next')))
            .onPressed,
        isNull,
      );
      store.failing = false;
      await tapVisible(tester, find.text('Réessayer'));
      expect(
        container.read(learnerContentControllerProvider).requireValue.concepts,
        isNotEmpty,
      );
      readable(tester);
    },
  );

  test('verified local evidence survives store restart', () async {
    const store = LocalLearnerContentStore();
    final snapshot = LearnerContentSnapshot(
      concepts: {
        'c': const MasteryState(
          conceptId: 'c',
          score: 20,
          attempts: 1,
          correct: 1,
        ),
      },
    );
    await store.saveVerified('learner', snapshot);
    expect(
      (await const LocalLearnerContentStore().load('learner')).toJson(),
      snapshot.toJson(),
    );
    expect((await store.load('other')).concepts, isEmpty);
    expect(File('${directories.last}/runtime.json').existsSync(), isTrue);
  });
}
