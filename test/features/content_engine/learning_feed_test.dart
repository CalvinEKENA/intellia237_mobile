import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/core/academics/class_key.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/content_engine/application/content_providers.dart';
import 'package:intellia237/features/content_engine/application/learning_feed_providers.dart';
import 'package:intellia237/features/content_engine/data/content_delivery.dart';
import 'package:intellia237/features/content_engine/data/content_pack_parser.dart';
import 'package:intellia237/features/content_engine/data/content_pack_repository.dart';
import 'package:intellia237/features/content_engine/data/learner_content_store.dart';
import 'package:intellia237/features/content_engine/domain/game_blueprint.dart';
import 'package:intellia237/features/content_engine/domain/mastery.dart';
import 'package:intellia237/features/content_engine/domain/pedagogy.dart';
import 'package:intellia237/features/content_engine/feed/learning_card.dart';
import 'package:intellia237/features/content_engine/feed/learning_card_factory.dart';
import 'package:intellia237/features/content_engine/feed/learning_card_history.dart';
import 'package:intellia237/features/content_engine/feed/learning_feed_ranker.dart';

import 'delivery_fixture.dart';
import 'pack_fixture.dart';

const _terminaleD = ClassKey('terminale', series: 'd');
const _terminaleC = ClassKey('terminale', series: 'c');
const _sixieme = ClassKey('sixieme');

class _Student extends AuthController {
  @override
  AuthState build() =>
      const AuthState.authenticated(role: AppRole.student, userId: 'eleve-1');
}

/// Passerelle qui compte les appels : le fil ne doit jamais en faire.
class _CountingGateway implements RemoteContentGateway {
  int calls = 0;

  @override
  Future<Never> fetchCatalog() async {
    calls++;
    throw StateError('réseau interdit');
  }

  @override
  Future<Never> fetchBundle(String path) async {
    calls++;
    throw StateError('réseau interdit');
  }
}

ProviderContainer _container({
  required ClassKey? classKey,
  ContentPackRepository? repository,
  LearningCardHistoryStore? history,
  RemoteContentGateway? gateway,
  DateTime Function()? clock,
}) {
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(_Student.new),
      contentClassKeyProvider.overrideWith((ref) async => classKey),
      contentPackRepositoryProvider.overrideWithValue(
        repository ?? ContentPackRepository(source: DiskContentPackSource()),
      ),
      learnerContentStoreProvider.overrideWithValue(
        InMemoryLearnerContentStore(),
      ),
      learningCardHistoryStoreProvider.overrideWithValue(
        history ?? InMemoryLearningCardHistoryStore(),
      ),
      contentPackCacheProvider.overrideWithValue(InMemoryContentPackCache()),
      remoteContentGatewayProvider.overrideWithValue(
        gateway ?? const OfflineGateway(),
      ),
      if (clock != null) learningFeedClockProvider.overrideWithValue(clock),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  final chapter = pilotChapter();
  const factory = LearningCardFactory();
  final cards = factory.build(chapter, classKeys: const [_terminaleD]);

  group('fabrique de cartes — déterministe, fidèle au pack', () {
    test('Terminale D · CH01 : des cartes de chaque nature utile', () {
      final types = cards.map((c) => c.type).toSet();
      expect(cards.length, greaterThan(30));
      for (final type in [
        LearningCardType.explanation,
        LearningCardType.ultraSimple,
        LearningCardType.visual,
        LearningCardType.commonMistake,
        LearningCardType.revision,
        LearningCardType.game,
        LearningCardType.companionPrompt,
        LearningCardType.flashQuestion,
      ]) {
        expect(types, contains(type), reason: type.name);
      }
      expect(
        types.intersection({
          LearningCardType.mcq,
          LearningCardType.trueFalse,
          LearningCardType.exercise,
          LearningCardType.challenge,
        }),
        isNotEmpty,
      );
    });

    test('même pack, mêmes cartes, mêmes identifiants', () {
      final again = factory.build(
        pilotChapter(),
        classKeys: const [_terminaleD],
      );
      expect(again.map((c) => c.id), cards.map((c) => c.id));
      expect(cards.map((c) => c.id).toSet(), hasLength(cards.length));
    });

    test('aucun texte inventé : chaque texte vient du pack', () {
      final packTexts = <String>{
        for (final concept in chapter.concepts.values) ...[
          concept.title,
          ...concept.explanations.values,
          ...concept.commonMistakes,
          ?concept.visualModel,
        ],
        for (final lesson in chapter.lessons) ...[
          lesson.title,
          ...lesson.verifiedCore,
        ],
        for (final question in chapter.questions) question.prompt,
        for (final game in chapter.games) ...[game.title, game.mechanic],
        chapter.curriculum.chapterTitle,
      };
      for (final card in cards) {
        expect(packTexts, contains(card.title), reason: card.id);
        if (card.body case final body?) {
          expect(packTexts, contains(body), reason: card.id);
        }
      }
    });

    test('un jeu en préparation ou désactivé n\'est jamais proposé', () {
      final runtime = deepCopy(readPackJson('runtime.json'));
      final games = runtime['games']! as List;
      final draftId = (games.first as Map)['id'] as String;
      final disabledId = (games[1] as Map)['id'] as String;
      (games.first as Map)['status'] = 'draft';
      (games[1] as Map)['status'] = 'disabled';
      final raw = pilotRaw();
      final altered = const ContentPackParser().parse(
        RawContentPack(
          directory: raw.directory,
          manifest: raw.manifest,
          source: raw.source,
          pedagogy: raw.pedagogy,
          runtime: runtime,
          validation: raw.validation,
        ),
      );
      expect(
        altered.games.firstWhere((g) => g.id == draftId).status,
        GameStatus.draft,
      );
      final gameIds = factory
          .build(altered)
          .where((c) => c.type == LearningCardType.game)
          .map((c) => c.gameId);
      expect(gameIds, isNot(contains(draftId)));
      expect(gameIds, isNot(contains(disabledId)));
      expect(gameIds, isNotEmpty);
      for (final id in gameIds) {
        expect(altered.games.firstWhere((g) => g.id == id).playable, isTrue);
      }
    });

    test('questions du fil : notées automatiquement, sans signalement', () {
      for (final card in cards.where((c) => c.type.asksAnswer)) {
        final q = card.question!;
        expect(q.autoScorable, isTrue);
        expect(q.visibleFlags, isEmpty);
        expect(q.isIntegration, isFalse);
      }
    });
  });

  group('classement personnalisé', () {
    final now = DateTime(2026, 9, 25, 10);
    const ranker = LearningFeedRanker();

    test('un débutant commence par la leçon 1, jamais par la fin', () {
      final ranked = ranker.rank(cards, LearningFeedContext(now: now));
      expect(ranked.first.lessonNumber, 1);
      expect(ranked.take(8).every((c) => c.lessonNumber <= 2), isTrue);
    });

    test(
      'jamais deux cartes du même type de suite (quand c\'est évitable)',
      () {
        final ranked = ranker.rank(cards, LearningFeedContext(now: now));
        for (var i = 1; i < 20; i++) {
          expect(ranked[i].type, isNot(ranked[i - 1].type), reason: '$i');
        }
      },
    );

    test('après des erreurs en congruence : simple → visuel → facile → '
        'intermédiaire', () {
      final missed = cards.firstWhere(
        (c) => c.conceptId == 'congruence' && c.type.asksAnswer,
      );
      final history = LearningCardHistory.empty
          .answered(missed.id, correct: false, at: now)
          .answered(missed.id, correct: false, at: now);
      final ranked = ranker.rank(
        cards,
        LearningFeedContext(now: now, history: history),
      );
      final head = ranked.take(4).toList();
      expect(head.every((c) => c.conceptId == 'congruence'), isTrue);
      expect(head[0].type, LearningCardType.ultraSimple);
      expect(head[1].type, LearningCardType.visual);
      expect(head[2].type.asksAnswer, isTrue);
      expect(head[2].difficulty, 1);
      expect(head[3].type.asksAnswer, isTrue);
      expect(head[3].difficulty, 2);
      expect(head.map((c) => c.id), isNot(contains(missed.id)));
    });

    test('une carte vue ne revient pas tout de suite', () {
      final first = ranker.rank(cards, LearningFeedContext(now: now));
      final shown = first.take(5).toList();
      var history = LearningCardHistory.empty;
      for (final card in shown) {
        history = history.shown(card.id, now);
      }
      final next = ranker.rank(
        cards,
        LearningFeedContext(
          now: now.add(const Duration(hours: 1)),
          history: history,
        ),
        limit: 1000,
      );
      final shownIds = shown.map((c) => c.id).toSet();
      final firstRepeat = next.indexWhere((c) => shownIds.contains(c.id));
      expect(firstRepeat, greaterThanOrEqualTo(next.length - shown.length));
    });

    test('révision espacée : une question réussie revient après un jour', () {
      final question = cards.firstWhere((c) => c.type.asksAnswer);
      final history = LearningCardHistory.empty.answered(
        question.id,
        correct: true,
        at: now,
      );
      bool dueAt(Duration later) {
        final ranked = ranker.rank(
          cards,
          LearningFeedContext(now: now.add(later), history: history),
          limit: 1000,
        );
        final eligibleCount = ranked.length - 1;
        return ranked.indexOf(question) < eligibleCount;
      }

      expect(dueAt(const Duration(hours: 12)), isFalse);
      expect(dueAt(const Duration(days: 1, hours: 1)), isTrue);
    });

    test(
      'préférence « 12 ans » : l\'explication la plus simple est proposée',
      () {
        final ranked = ranker.rank(
          cards,
          LearningFeedContext(
            now: now,
            preference: const ExplanationPreference(
              mode: ExplanationMode.ultraSimple,
            ),
          ),
        );
        expect(
          ranked.any((c) => c.type == LearningCardType.ultraSimple),
          isTrue,
        );
      },
    );

    test('défi et maîtrise seulement quand la notion est travaillée', () {
      final beginner = ranker.rank(cards, LearningFeedContext(now: now));
      expect(
        beginner.where(
          (c) =>
              c.type == LearningCardType.mastery ||
              c.type == LearningCardType.challenge,
        ),
        isEmpty,
      );
    });
  });

  group('Mon Parcours alimenté par les packs de la classe', () {
    test('Terminale D : des cartes, dont la leçon 1 d\'arithmétique', () async {
      final container = _container(classKey: _terminaleD);
      final feed = await container.read(learningFeedProvider.future);
      expect(feed.cards, isNotEmpty);
      expect(feed.chapters.keys, contains(chapter.contentId));
      expect(feed.cards.first.lessonNumber, 1);
    });

    test('Sixième : aucune carte de Terminale ne fuit', () async {
      final container = _container(classKey: _sixieme);
      final feed = await container.read(learningFeedProvider.future);
      expect(
        feed.cards.where((c) => c.chapterId == chapter.contentId),
        isEmpty,
      );
      for (final card in feed.cards) {
        expect(card.classKeys.any(_sixieme.admits), isTrue, reason: card.id);
      }
    });

    test('Terminale C : un pack réservé à la série D reste absent', () async {
      final container = _container(classKey: _terminaleC);
      final feed = await container.read(learningFeedProvider.future);
      expect(
        feed.cards.where((c) => c.chapterId == chapter.contentId),
        isEmpty,
      );
    });

    test('un pack publié à distance enrichit le fil, sans code ni '
        'recompilation, et s\'annonce en tête', () async {
      final gateway = FakeGateway();
      final cache = InMemoryContentPackCache();
      ContentPackRepository repository() =>
          ContentPackRepository(source: DiskContentPackSource(), cache: cache);

      final before = await _container(
        classKey: _terminaleD,
        repository: repository(),
      ).read(learningFeedProvider.future);

      gateway.put(
        publish(
          id: 'maths_td_ch02_complexes',
          chapterNumber: 2,
          chapterTitle: 'Nombres complexes',
          classKeys: const ['terminale-c-d'],
        ),
      );
      await ContentSyncService(
        gateway: gateway,
        cache: cache,
      ).sync(_terminaleD);

      final after = await _container(
        classKey: _terminaleD,
        repository: repository(),
      ).read(learningFeedProvider.future);

      expect(
        before.cards.where((c) => c.chapterId == 'maths_td_ch02_complexes'),
        isEmpty,
      );
      expect(
        after.cards.where((c) => c.chapterId == 'maths_td_ch02_complexes'),
        isNotEmpty,
      );
      expect(after.chapters.keys, contains('maths_td_ch02_complexes'));
      expect(after.cards.first.type, LearningCardType.newContent);
      expect(after.cards.first.chapterId, 'maths_td_ch02_complexes');

      // Le même pack commun C/D sert aussi la Terminale C.
      final forC = await _container(
        classKey: _terminaleC,
        repository: repository(),
      ).read(learningFeedProvider.future);
      // (Les units d'anglais, communes à toute la Terminale, s'y ajoutent.)
      expect(forC.chapters.keys.where((id) => id.startsWith('maths')), [
        'maths_td_ch02_complexes',
      ]);
    });

    test('hors ligne : le fil se compose sans aucun appel réseau', () async {
      final gateway = _CountingGateway();
      final container = _container(classKey: _terminaleD, gateway: gateway);
      final feed = await container.read(learningFeedProvider.future);
      expect(feed.cards, isNotEmpty);
      expect(gateway.calls, 0);
      // Et aucune connexion n'est ouverte pendant la composition.
      var opened = 0;
      await HttpOverrides.runZoned(
        () async {
          final other = _container(classKey: _terminaleD, gateway: gateway);
          await other.read(learningFeedProvider.future);
        },
        createHttpClient: (_) {
          opened++;
          throw StateError('réseau');
        },
      );
      expect(opened, 0);
    });

    test('une réponse du fil fait avancer la même maîtrise que '
        '« S\'entraîner »', () async {
      final container = _container(classKey: _terminaleD);
      final feed = await container.read(learningFeedProvider.future);
      await container.read(learnerContentControllerProvider.future);
      final card = feed.cards.firstWhere((c) => c.type.asksAnswer);
      final before = container
          .read(learnerContentControllerProvider)
          .requireValue
          .conceptState(card.conceptId)
          .score;

      await container
          .read(learningCardHistoryProvider.notifier)
          .recordAnswer(
            chapter: feed.chapters[card.chapterId]!,
            card: card,
            correct: true,
          );

      final snapshot = container
          .read(learnerContentControllerProvider)
          .requireValue;
      expect(snapshot.conceptState(card.conceptId).score, greaterThan(before));
      expect(
        snapshot.conceptState(card.conceptId).answeredQuestionIds,
        contains(card.question!.id),
      );
      final history = container.read(learningCardHistoryProvider).requireValue;
      expect(history.of(card.id).correct, 1);
    });

    test('changement de classe : le fil se recompose pour la nouvelle '
        'classe', () async {
      var classKey = _terminaleD;
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(_Student.new),
          contentClassKeyProvider.overrideWith((ref) async => classKey),
          contentPackRepositoryProvider.overrideWithValue(
            ContentPackRepository(source: DiskContentPackSource()),
          ),
          learnerContentStoreProvider.overrideWithValue(
            InMemoryLearnerContentStore(),
          ),
          learningCardHistoryStoreProvider.overrideWithValue(
            InMemoryLearningCardHistoryStore(),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(
        (await container.read(learningFeedProvider.future)).cards,
        isNotEmpty,
      );
      classKey = _sixieme;
      container.invalidate(contentClassKeyProvider);
      final after = await container.read(learningFeedProvider.future);
      expect(
        after.cards.where((c) => c.chapterId == chapter.contentId),
        isEmpty,
      );
    });

    test('l\'historique survit à un redémarrage (stockage local)', () async {
      final store = InMemoryLearningCardHistoryStore();
      final first = _container(classKey: _terminaleD, history: store);
      final feed = await first.read(learningFeedProvider.future);
      await first
          .read(learningCardHistoryProvider.notifier)
          .shown(feed.cards.first.id);
      final second = _container(classKey: _terminaleD, history: store);
      final history = await second.read(learningCardHistoryProvider.future);
      expect(history.of(feed.cards.first.id).seen, 1);
      final next = await second.read(learningFeedProvider.future);
      expect(next.cards.first.id, isNot(feed.cards.first.id));
    });
  });
}
