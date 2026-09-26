import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intellia237/features/content_engine/application/content_providers.dart';
import 'package:intellia237/features/content_engine/application/learning_feed_providers.dart';
import 'package:intellia237/features/content_engine/application/practice_session.dart';
import 'package:intellia237/features/content_engine/data/content_pack_parser.dart';
import 'package:intellia237/features/content_engine/data/learner_content_store.dart';
import 'package:intellia237/features/content_engine/domain/chapter.dart';
import 'package:intellia237/features/content_engine/domain/mastery.dart';
import 'package:intellia237/features/content_engine/engine/adaptive_engine.dart';
import 'package:intellia237/features/content_engine/engine/answer_checker.dart';
import 'package:intellia237/features/content_engine/feed/learning_card.dart';
import 'package:intellia237/features/content_engine/feed/learning_card_factory.dart';
import 'package:intellia237/features/content_engine/feed/learning_card_history.dart';
import 'package:intellia237/features/content_engine/feed/learning_feed_ranker.dart';

import 'pack_fixture.dart';

const physicsDirectory =
    'assets/content/terminale_cd/physique/m1_s1_erreurs_et_incertitudes';

RawContentPack physicsRaw({void Function(Map question)? alter}) {
  final runtime = readPackJson('runtime.json', directory: physicsDirectory);
  if (alter != null) {
    alter(
      (runtime['question_bank']! as List).cast<Map>().firstWhere(
        (q) => q['id'] == 'l1_q08',
      ),
    );
  }
  return RawContentPack(
    directory: physicsDirectory,
    manifest: readPackJson('manifest.json', directory: physicsDirectory),
    source: readPackJson('source.json', directory: physicsDirectory),
    pedagogy: readPackJson('pedagogy.json', directory: physicsDirectory),
    runtime: runtime,
    validation: readPackJson(
      'validation_report.json',
      directory: physicsDirectory,
    ),
  );
}

Chapter physicsChapter() => const ContentPackParser().parse(physicsRaw());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final chapter = physicsChapter();
  final question = chapter.question('l1_q08')!;
  final conceptId = question.conceptId!;

  test('vraie réponse ouverte : modèle, explication et indices conservés', () {
    expect(question.requiresSelfEvaluation, isTrue);
    expect(question.autoScorable, isFalse);
    expect(question.modelAnswer, 'Il peut être fidèle mais peu juste.');
    expect(question.explanation, contains('proximité entre répétitions'));
    expect(question.hints, hasLength(2));
    expect(chapter.llmRequired, isFalse);
    final selected = const QuestionSelector().forLesson(
      chapter,
      lessonNumber: 1,
      difficulty: 3,
    );
    expect(selected.map((q) => q.id), contains('l1_q08'));
  });

  test(
    'auto_score:false interdit même une correction techniquement possible',
    () {
      final pack = const ContentPackParser().parse(
        physicsRaw(
          alter: (q) {
            q['type'] = 'numeric';
            q['answer'] = 5;
          },
        ),
      );
      final manual = pack.question('l1_q08')!;
      expect(manual.requiresSelfEvaluation, isTrue);
      expect(manual.modelAnswer, '5');
      expect(
        () => const AnswerChecker().grade(manual, const TextResponse('5')),
        throwsArgumentError,
      );
      expect(manual.withFlags([]).autoScorable, isFalse);
    },
  );

  test('prose reconnue sans auto_score, points clés facultatifs', () {
    final pack = const ContentPackParser().parse(
      physicsRaw(
        alter: (q) {
          q.remove('auto_score');
          q['expected_points'] = ['Fidélité', 'Justesse'];
        },
      ),
    );
    final open = pack.question('l1_q08')!;
    expect(open.requiresSelfEvaluation, isTrue);
    expect(open.expectedPoints, ['Fidélité', 'Justesse']);
  });

  test('question invalide ou sans modèle : jamais proposée', () {
    for (final change in <void Function(Map)>[
      (q) => q.remove('answer'),
      (q) => q.remove('prompt'),
      (q) => q['difficulty'] = 99,
      (q) => q['lesson'] = 99,
      (q) => q['type'] = 'future_unknown',
    ]) {
      final invalid = const ContentPackParser()
          .parse(physicsRaw(alter: change))
          .question('l1_q08')!;
      expect(invalid.isPracticeReady, isFalse);
    }
  });

  test(
    'réponse courte non corrigeable ou modèle explicite : auto-évaluation',
    () {
      for (final modelOnly in [false, true]) {
        final pack = const ContentPackParser().parse(
          physicsRaw(
            alter: (q) {
              q.remove('auto_score');
              q['answer'] = modelOnly ? null : 'Bonne fidélité';
              if (modelOnly) q['model_answer'] = 'Des mesures rapprochées.';
            },
          ),
        );
        final open = pack.question('l1_q08')!;
        expect(open.requiresSelfEvaluation, isTrue);
        expect(
          open.modelAnswer,
          modelOnly ? 'Des mesures rapprochées.' : 'Bonne fidélité',
        );
        expect(
          () => const AnswerChecker().grade(open, const TextResponse('texte')),
          throwsArgumentError,
        );
      }
    },
  );

  test(
    'session : jamais de note, erreur, récompense ni appel au correcteur',
    () async {
      var corrections = 0;
      var evaluations = 0;
      final session = PracticeSession(
        chapter: chapter,
        lessonNumber: 1,
        questionsOverride: [question],
        recorder: (_, _) async {
          corrections++;
          return [];
        },
        selfEvaluationRecorder: (_, _) async {
          evaluations++;
        },
      );
      addTearDown(session.dispose);
      expect(await session.submit(const TextResponse('Texte libre')), isNull);
      expect(session.busy, isFalse);
      expect(session.lastGrade, isNull);
      await session.selfEvaluate(SelfEvaluation.needsReview);
      await session.selfEvaluate(SelfEvaluation.selfMastered);
      expect(corrections, 0);
      expect(evaluations, 1);
      expect(session.answered, isTrue);
      expect(session.answeredIds, isEmpty);
      expect(session.suggestions, isEmpty);
      session.next();
      expect(session.answered, isFalse);
      expect(session.current, isNull);
    },
  );

  test('MasteryState : dernier signal, compteurs objectifs inchangés', () {
    const engine = AdaptiveEngine(MasteryConfig());
    final initial = MasteryState(
      conceptId: conceptId,
      score: 42,
      attempts: 3,
      correct: 2,
      consecutiveCorrect: 1,
      bestDifficulty: 2,
      errorsSinceExplanationChange: 1,
      answeredQuestionIds: {'earlier'},
    );
    var state = initial;
    for (final value in SelfEvaluation.values) {
      state = engine.recordSelfEvaluation(
        state: state,
        question: question,
        evaluation: value,
      );
      expect(state.selfEvaluations, {question.id: value});
      expect(state.needsSelfReview, value != SelfEvaluation.selfMastered);
      final objective = state.toJson()..remove('selfEvaluations');
      expect(objective, initial.toJson()..remove('selfEvaluations'));
      expect(
        engine
            .record(
              state: state,
              question: question,
              correct: false,
              preference: const ExplanationPreference(),
            )
            .state,
        same(state),
      );
    }
    expect(
      MasteryState.fromJson(state.toJson())!.selfEvaluations,
      state.selfEvaluations,
    );
    expect(
      MasteryState.fromJson({'conceptId': conceptId})!.selfEvaluations,
      isEmpty,
    );
  });

  test(
    'maîtrise partagée, stockage local et historique sans fausse erreur',
    () async {
      const store = LocalLearnerContentStore();
      final container = ProviderContainer(
        overrides: [
          learnerContentStoreProvider.overrideWithValue(store),
          learningCardHistoryStoreProvider.overrideWithValue(
            InMemoryLearningCardHistoryStore(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        learnerContentControllerProvider.notifier,
      );
      await controller.recordSelfEvaluation(
        chapter: chapter,
        question: question,
        evaluation: SelfEvaluation.needsReview,
      );
      final card = const LearningCardFactory()
          .build(chapter)
          .singleWhere((c) => c.question?.id == question.id);
      final feed = container.read(learningCardHistoryProvider.notifier);
      await feed.recordAnswer(chapter: chapter, card: card, correct: false);
      await controller.recordAnswer(
        chapter: chapter,
        question: question,
        correct: false,
      );
      await feed.recordSelfEvaluation(
        chapter: chapter,
        card: card,
        evaluation: SelfEvaluation.partialConfidence,
      );
      final state = container
          .read(learnerContentControllerProvider)
          .requireValue
          .conceptState(conceptId);
      expect(
        state.selfEvaluations[question.id],
        SelfEvaluation.partialConfidence,
      );
      expect(state.attempts, 0);
      expect(state.correct, 0);
      expect(state.errorsSinceExplanationChange, 0);
      expect(state.score, 0);
      final history = await container.read(learningCardHistoryProvider.future);
      expect(history.of(card.id).incorrect, 0);
      expect(history.of(card.id).answered, 0);
      expect(history.of(card.id).seen, 1);
      final restored = await store.load('guest');
      expect(
        restored.conceptState(conceptId).selfEvaluations,
        state.selfEvaluations,
      );
      expect((await store.load('other-learner')).concepts, isEmpty);
    },
  );

  test('confiance partielle guide la révision dans le fil partagé', () {
    final cards = const LearningCardFactory().build(chapter);
    final ranked = const LearningFeedRanker().rank(
      cards,
      LearningFeedContext(
        now: DateTime(2026, 9, 26),
        mastery: {
          conceptId: MasteryState(
            conceptId: conceptId,
            selfEvaluations: {question.id: SelfEvaluation.partialConfidence},
          ),
        },
      ),
    );
    expect(ranked.first.conceptId, conceptId);
    expect(ranked.first.type, LearningCardType.ultraSimple);
  });

  test('lesson:0 : synthèse unique, questions rattachées à la leçon 5', () {
    final cards = const LearningCardFactory().build(chapter);
    final synthesis = cards.where((c) => c.lessonNumber == 0).single;
    expect(chapter.lessons.map((l) => l.number), [1, 2, 3, 4, 5]);
    expect(chapter.lesson(0), isNull);
    expect(chapter.integrationConcepts.single.id, 'sequence_integration');
    expect(synthesis.conceptId, 'sequence_integration');
    expect(synthesis.type, LearningCardType.revision);
    expect(synthesis.body, isNotEmpty);
    expect(cards.last, synthesis);
    for (final id in ['l5_q07', 'l5_q08']) {
      expect(chapter.question(id)!.lessonNumber, 5);
      expect(cards.singleWhere((c) => c.question?.id == id).lessonNumber, 5);
      expect(
        chapter.integrationPracticeQuestions.map((q) => q.id),
        isNot(contains(id)),
      );
    }
    expect(cards.map((c) => c.id).toSet(), hasLength(cards.length));
    expect(
      cards.where((c) => c.type == LearningCardType.selfEvaluation),
      hasLength(5),
    );
  });

  test(
    'synthèse dans Mon Parcours après les cinq leçons, jamais en premier',
    () {
      final cards = const LearningCardFactory().build(chapter);
      final now = DateTime(2026, 9, 26);
      const ranker = LearningFeedRanker();
      var history = LearningCardHistory.empty;
      expect(
        ranker
            .rank(cards, LearningFeedContext(now: now), limit: 500)
            .any((c) => c.lessonNumber == 0),
        isFalse,
      );
      for (var n = 1; n <= 5; n++) {
        final card = cards.firstWhere((c) => c.lessonNumber == n);
        history = history.shown(card.id, now);
        final ranked = ranker.rank(
          cards,
          LearningFeedContext(now: now, history: history),
          limit: 500,
        );
        expect(ranked.any((c) => c.lessonNumber == 0), n == 5);
        expect(ranked.first.lessonNumber, isNot(0));
      }
    },
  );
}
