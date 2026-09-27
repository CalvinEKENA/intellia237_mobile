import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/core/academics/choice_order.dart';
import 'package:intellia237/core/academics/class_key.dart';
import 'package:intellia237/features/content_engine/application/content_providers.dart';
import 'package:intellia237/features/content_engine/application/learning_feed_providers.dart';
import 'package:intellia237/features/content_engine/data/content_delivery.dart';
import 'package:intellia237/features/content_engine/data/content_pack_parser.dart';
import 'package:intellia237/features/content_engine/data/content_pack_repository.dart';
import 'package:intellia237/features/content_engine/data/learner_content_store.dart';
import 'package:intellia237/features/content_engine/domain/chapter.dart';
import 'package:intellia237/features/content_engine/domain/game_blueprint.dart';
import 'package:intellia237/features/content_engine/domain/pack_catalog.dart';
import 'package:intellia237/features/content_engine/domain/pedagogy.dart';
import 'package:intellia237/features/content_engine/domain/question.dart';
import 'package:intellia237/features/content_engine/engine/answer_checker.dart';
import 'package:intellia237/features/content_engine/feed/learning_card.dart';
import 'package:intellia237/features/content_engine/feed/learning_card_factory.dart';
import 'package:intellia237/features/content_engine/feed/learning_card_history.dart';
import 'package:intellia237/features/content_engine/feed/learning_feed_ranker.dart';

import '../../../tool/content/pack_bundle_builder.dart';
import 'pack_fixture.dart';

const _s1 = 'physique_terminale_cd_m1_s1_erreurs_et_incertitudes';
const _s2 = 'physique_terminale_cd_m1_s2_dimension_grandeur_physique';
const _dir =
    'assets/content/terminale_cd/physique/m1_s2_dimension_d_une_grandeur_physique';
const _open = ['l1_q08', 'l2_q08', 'l3_q08', 'l4_q08', 'l5_q08'];

Map<String, Object?> _json(String file) => readPackJson(file, directory: _dir);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentPackRepository repository;
  setUp(
    () => repository = ContentPackRepository(source: DiskContentPackSource()),
  );
  Future<Chapter> pack() => repository.chapter(_s2);

  for (final series in ['c', 'd']) {
    test(
      'Terminale $series : M1S1 puis M1S2, chacune une seule fois',
      () async {
        final classKey = ClassKey('terminale', series: series);
        final physics = (await repository.subjectsFor(
          classKey,
        )).singleWhere((subject) => subject.key == 'physique');
        expect(physics.chapters.map((entry) => entry.contentId), [_s1, _s2]);
        expect(physics.chapters.map((entry) => entry.curriculum.moduleNumber), [
          1,
          1,
        ]);
        expect(
          physics.chapters.map((entry) => entry.curriculum.sequenceNumber),
          [1, 2],
        );
        final chapters = await repository.chaptersFor(classKey);
        for (final id in [_s1, _s2]) {
          expect(
            chapters.where((chapter) => chapter.contentId == id),
            hasLength(1),
          );
        }
      },
    );
  }
  for (final classKey in const [
    ClassKey('terminale', series: 'a'),
    ClassKey('premiere', series: 'c'),
    ClassKey('sixieme'),
  ]) {
    test('$classKey : les deux séquences C-D restent absentes', () async {
      final chapters = await repository.chaptersFor(classKey);
      expect(chapters.map((c) => c.contentId), isNot(contains(_s1)));
      expect(chapters.map((c) => c.contentId), isNot(contains(_s2)));
    });
  }

  test('fallback embarqué : deux séquences disponibles sans cache', () async {
    final embedded = ContentPackRepository(
      source: AssetContentPackSource(),
      cache: InMemoryContentPackCache(),
    );
    final physics = (await embedded.subjectsFor(
      const ClassKey('terminale', series: 'c'),
    )).singleWhere((s) => s.key == 'physique');
    expect(physics.chapters.map((e) => e.contentId), [_s1, _s2]);
    for (final id in [_s1, _s2]) {
      final chapter = await embedded.chapter(id);
      expect(chapter.isPlayable, isTrue);
      expect(chapter.questions, hasLength(40));
    }
  });

  test(
    'identité et comptes réels : 5 leçons, 10 concepts, 40 questions',
    () async {
      final chapter = await pack();
      final curriculum = chapter.curriculum;
      expect(curriculum.subjectKey, 'physique');
      expect(curriculum.moduleNumber, 1);
      expect(curriculum.moduleTitle, 'Mesures et incertitudes');
      expect(curriculum.sequenceNumber, 2);
      expect(curriculum.chapterTitle, "Dimension d'une grandeur physique");
      expect(curriculum.isSequence, isTrue);
      expect(chapter.isPlayable, isTrue);
      expect(chapter.llmRequired, isFalse);
      expect(chapter.lessons.map((lesson) => lesson.number), [1, 2, 3, 4, 5]);
      expect(
        chapter.concepts.keys,
        unorderedEquals([
          'dimension_vs_unit',
          'base_dimensions',
          'derived_quantities',
          'dimensional_equation',
          'derived_units',
          'dimensionless_quantities',
          'dimensional_analysis',
          'dimensional_homogeneity',
          'dimensional_problem_solving',
          'sequence_integration',
        ]),
      );
      expect(chapter.questions, hasLength(40));
      expect(chapter.questions.map((q) => q.id).toSet(), hasLength(40));
      expect(chapter.questions.where((q) => q.autoScorable), hasLength(35));
      expect(
        chapter.questions
            .where((q) => q.requiresSelfEvaluation)
            .map((q) => q.id),
        _open,
      );
      expect(chapter.difficulties.map((d) => d.value), [1, 2, 3]);
      expect(chapter.explanationModes, ExplanationMode.values);
      for (final concept in chapter.concepts.values) {
        for (final mode in ExplanationMode.values) {
          expect(
            concept.explanation(mode),
            isNotEmpty,
            reason: '${concept.id}: $mode',
          );
        }
      }
      final rawQuestions = (_json('runtime.json')['question_bank']! as List)
          .cast<Map>();
      expect(rawQuestions.where((q) => q['auto_score'] == true), hasLength(35));
      expect(rawQuestions.where((q) => q['auto_score'] == false), hasLength(5));
      for (final lesson in chapter.lessons) {
        final questions = chapter.questions.where(
          (q) => q.lessonNumber == lesson.number,
        );
        expect(questions, hasLength(8));
        expect(questions.where((q) => q.autoScorable), hasLength(7));
      }
      final seeds = (_json('runtime.json')['learning_card_seeds']! as List)
          .cast<Map>();
      expect(seeds, hasLength(14));
      expect(seeds.map((s) => s['id']).toSet(), hasLength(14));
    },
  );

  test(
    'source canonique : empreintes, pages 010–013 et réserves préservées',
    () async {
      final hashes = _json('manifest.json')['sha256']! as Map;
      for (final entry in hashes.entries) {
        expect(
          sha256Hex(File('$_dir/${entry.key}').readAsBytesSync()),
          entry.value,
        );
      }
      final source = _json('source.json');
      final location = source['source_location']! as Map;
      expect(location['image_range'], 'page_010.jpg → page_013.jpg');
      expect(location['next_module_starts_at'], 'page_014.jpg');
      final pages = (source['source_sections']! as List)
          .cast<Map>()
          .expand((section) => section['images']! as List)
          .toSet();
      expect(pages, {
        'page_010.jpg',
        'page_011.jpg',
        'page_012.jpg',
        'page_013.jpg',
      });
      final flags = (await pack()).validation.flags;
      expect(flags, hasLength(2));
      expect(flags.first.source, contains('page_013.jpg'));
      expect(flags.last.source, contains('page_011.jpg'));
      expect(flags.every((flag) => !flag.concernsRuntime), isTrue);
      final rawFlags =
          (_json('validation_report.json')['source_quality_flags']! as List)
              .cast<Map>();
      expect(rawFlags.map((flag) => flag['id']), [
        'advanced_exercises_page_013_partially_legible',
        'electrical_resistance_symbol_source_ambiguous',
      ]);
    },
  );

  test(
    'QCM : IDs stables, correction et feedback indépendants de la position',
    () async {
      final chapter = await pack();
      final raws = (_json('runtime.json')['question_bank']! as List)
          .cast<Map>();
      for (final raw in raws.where((q) => q['type'] == 'mcq')) {
        final question = chapter.question(raw['id'] as String)!;
        final metadata = (raw['option_metadata']! as List).cast<Map>();
        expect(
          metadata.map((o) => o['id']).toSet(),
          hasLength(question.choices.length),
        );
        final correctIds = raw['correct_option_ids']! as List;
        expect(correctIds, hasLength(1));
        expect(
          metadata.singleWhere((o) => o['id'] == correctIds.single)['label'],
          raw['answer'],
        );
        final policy = raw['option_order_policy']! as Map;
        expect(policy['correctness_binding'], 'option_id');
        expect(policy['stable_within_attempt'], isTrue);
        expect(policy['shuffle_between_attempts'], isTrue);
        final correct = (question.answer as ChoiceAnswer).choice;
        final positions = <int>{};
        for (var attempt = 0; attempt < 24; attempt++) {
          final order = choiceOrder(
            question.choices.length,
            questionId: question.id,
            attemptKey: 'm1s2-$attempt',
          );
          expect(
            order,
            choiceOrder(
              question.choices.length,
              questionId: question.id,
              attemptKey: 'm1s2-$attempt',
            ),
          );
          positions.add(order.indexOf(question.choices.indexOf(correct)));
          for (final index in order) {
            final value = question.choices[index];
            expect(
              const AnswerChecker()
                  .grade(question, ChoiceResponse(value))
                  .correct,
              value == correct,
              reason: '${question.id}, tentative $attempt',
            );
            expect(question.choiceFeedback[value], isNotNull);
          }
        }
        expect(positions, {0, 1, 2, 3}, reason: question.id);
      }
      for (final q in chapter.questions.where(
        (q) => q.type == QuestionType.trueFalse,
      )) {
        final answer = (q.answer as BooleanAnswer).value;
        expect(
          const AnswerChecker().grade(q, BooleanResponse(answer)).correct,
          isTrue,
        );
        expect(
          const AnswerChecker().grade(q, BooleanResponse(!answer)).correct,
          isFalse,
        );
      }
    },
  );

  for (final (id, answer) in [
    ('l2_q04', 'L T^-2'),
    ('l3_q02', 'T^-1'),
    ('l5_q01', 'kg·m·s^-2'),
    ('l5_q02', 'N·m²·kg^-2'),
  ]) {
    test('relation canonique $id : $answer', () async {
      final q = (await pack()).question(id)!;
      expect((q.answer as ChoiceAnswer).choice.display, answer);
      expect(
        const AnswerChecker()
            .grade(q, ChoiceResponse(AnswerAtom.text(answer)))
            .correct,
        isTrue,
      );
    });
  }
  test('homogénéité de x = 1/2·g·t² et exposant négatif du temps', () async {
    final chapter = await pack();
    expect(chapter.question('l4_q05')!.prompt, contains('1/2·g·t²'));
    expect(
      const AnswerChecker()
          .grade(chapter.question('l4_q05')!, const BooleanResponse(true))
          .correct,
      isTrue,
    );
    final numeric = chapter.question('l2_q07')!;
    for (final answer in ['-3', '-3,0', '-3.00']) {
      expect(
        const AnswerChecker().grade(numeric, TextResponse(answer)).correct,
        isTrue,
      );
    }
    expect(
      const AnswerChecker().grade(numeric, const TextResponse('3')).correct,
      isFalse,
    );
  });

  test(
    'les cinq réponses rédigées restent praticables et jamais notées',
    () async {
      final chapter = await pack();
      for (final id in _open) {
        final q = chapter.question(id)!;
        expect(q.type, QuestionType.reasoning);
        expect(q.autoScore, isFalse);
        expect(q.requiresSelfEvaluation, isTrue);
        expect(q.modelAnswer, isNotEmpty);
        expect(q.hints, isNotEmpty);
        expect(q.explanation, isNotEmpty);
        expect(
          () => const AnswerChecker().grade(q, TextResponse(q.modelAnswer!)),
          throwsArgumentError,
        );
      }
    },
  );

  test('cinq jeux draft sans moteur restent non jouables', () async {
    final chapter = await pack();
    expect(chapter.games, hasLength(5));
    expect(chapter.games.map((game) => game.id).toSet(), hasLength(5));
    for (final game in chapter.games) {
      expect(game.status, GameStatus.draft);
      expect(game.engine, isNull);
      expect(game.playable, isFalse);
    }
    expect(
      const LearningCardFactory()
          .build(chapter)
          .where((c) => c.type == LearningCardType.game),
      isEmpty,
    );
  });

  test(
    'fabrique : graines couvertes et synthèse unique après les cinq leçons',
    () async {
      final chapter = await pack();
      final cards = const LearningCardFactory().build(chapter);
      expect(cards.map((card) => card.id).toSet(), hasLength(cards.length));
      final questionIds = cards.map((card) => card.question?.id).toSet();
      final conceptIds = cards.map((card) => card.conceptId).toSet();
      for (final seed
          in (_json('runtime.json')['learning_card_seeds']! as List)
              .cast<Map>()) {
        if (seed['question_id'] case final String id) {
          expect(questionIds, contains(id));
        }
        if (seed['concept_id'] case final String id) {
          expect(conceptIds, contains(id));
        }
      }
      expect(
        cards
            .where((c) => c.type == LearningCardType.selfEvaluation)
            .map((c) => c.question!.id),
        _open,
      );
      final synthesis = cards.where((card) => card.lessonNumber == 0).single;
      expect(synthesis.type, LearningCardType.revision);
      expect(synthesis.conceptId, 'sequence_integration');
      expect(cards.last, synthesis);
      expect(chapter.lesson(0), isNull);
      for (final id in ['l5_q07', 'l5_q08']) {
        expect(
          cards.singleWhere((card) => card.question?.id == id).lessonNumber,
          5,
        );
        expect(
          chapter.integrationPracticeQuestions.map((q) => q.id),
          isNot(contains(id)),
        );
      }
      var history = LearningCardHistory.empty;
      final now = DateTime(2026, 9, 26);
      for (var lesson = 0; lesson <= 5; lesson++) {
        if (lesson > 0) {
          history = history.shown(
            cards.firstWhere((c) => c.lessonNumber == lesson).id,
            now,
          );
        }
        final ranked = const LearningFeedRanker().rank(
          cards,
          LearningFeedContext(now: now, history: history),
          limit: 500,
        );
        expect(ranked.contains(synthesis), lesson == 5);
        expect(ranked.first.lessonNumber, isNot(0));
      }
    },
  );

  for (final series in ['c', 'd']) {
    test(
      'fil réel Terminale $series : M1S1 et M1S2 automatiquement composées',
      () async {
        final container = ProviderContainer(
          overrides: [
            contentPackRepositoryProvider.overrideWithValue(repository),
            contentClassKeyProvider.overrideWith(
              (ref) async => ClassKey('terminale', series: series),
            ),
            learnerContentStoreProvider.overrideWithValue(
              InMemoryLearnerContentStore(),
            ),
            learningCardHistoryStoreProvider.overrideWithValue(
              InMemoryLearningCardHistoryStore(),
            ),
            contentPackCacheProvider.overrideWithValue(
              InMemoryContentPackCache(),
            ),
            remoteContentGatewayProvider.overrideWithValue(
              const OfflineGateway(),
            ),
          ],
        );
        addTearDown(container.dispose);
        final feed = await container.read(learningFeedProvider.future);
        expect(feed.chapters.keys, containsAll([_s1, _s2]));
        expect(
          feed.cards.map((card) => card.contentId),
          containsAll([_s1, _s2]),
        );
        expect(
          feed.cards.map((card) => card.id).toSet(),
          hasLength(feed.cards.length),
        );
      },
    );
  }

  test(
    'bundle local draft relu fidèlement, audience C-D et moteur v2',
    () async {
      final documents = readPackDocuments(Directory(_dir));
      final encoded = encodeBundle(
        buildPackBundle(
          id: _s2,
          version: 1,
          classKeys: const ['terminale-c-d'],
          documents: documents,
        ),
      );
      final bundle = PackBundle.tryParse(utf8.decode(encoded.bytes))!;
      final remote = const ContentPackParser().parse(rawFromBundle(bundle));
      final embedded = await pack();
      expect(remote.isPlayable, isTrue);
      expect(remote.curriculum.sequenceNumber, 2);
      expect(
        remote.questions.map((q) => q.id),
        embedded.questions.map((q) => q.id),
      );
      expect(remote.questions.where((q) => q.autoScorable), hasLength(35));
      expect(
        remote.questions.where((q) => q.requiresSelfEvaluation),
        hasLength(5),
      );
      expect(documents['manifest']!['publication_status'], 'draft');
      expect(documents['manifest']!['minimum_engine_version'], 2);
      final entry = catalogEntry(
        id: _s2,
        version: 1,
        classKeys: const ['terminale-c-d'],
        sha256: encoded.sha256,
        sizeBytes: encoded.bytes.length,
        status: 'draft',
        minimumEngineVersion: 2,
      );
      expect(entry['status'], 'draft');
      expect(entry['minimum_engine_version'], 2);
    },
  );
}
