import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/core/academics/class_key.dart';
import 'package:intellia237/features/content_engine/application/content_providers.dart';
import 'package:intellia237/features/content_engine/application/subject_journey.dart';
import 'package:intellia237/features/content_engine/data/content_delivery.dart';
import 'package:intellia237/features/content_engine/data/content_pack_repository.dart';
import 'package:intellia237/features/content_engine/data/learner_content_store.dart';
import 'package:intellia237/features/content_engine/domain/mastery.dart';
import 'package:intellia237/features/content_engine/domain/question.dart';
import 'package:intellia237/features/content_engine/engine/answer_checker.dart';
import 'package:intellia237/features/quiz/application/pack_quiz_session.dart';
import 'package:intellia237/features/quiz/domain/pack_quiz.dart';
import 'package:intellia237/features/quiz/domain/quiz_companion_narrator.dart';
import 'package:intellia237/features/quiz/presentation/quiz_narration_text.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../content_engine/pack_fixture.dart';

/// Quiz des cours : projection déterministe des questions des packs,
/// corrigées par le moteur des leçons, racontées par Kira ou Léo sans aucune
/// génération.
const _maths1 = 'maths_td_ch01_arithmetique';
const _maths2 = 'maths_td_ch02_nombres_complexes_algebrique';
const _maths3 = 'maths_td_ch03_fonctions_numeriques';
const _english1 = 'english_terminale_m1_u1_applying_for_passport';
const _english2 = 'english_terminale_m1_u2_discussing_recreational_activities';
const _physics1 = 'physique_terminale_cd_m1_s1_erreurs_et_incertitudes';
const _physics2 = 'physique_terminale_cd_m1_s2_dimension_grandeur_physique';

Future<List<SubjectJourney>> _journeys(
  WidgetTester tester, {
  String series = 'd',
}) async {
  SharedPreferences.setMockInitialValues(const {});
  final container = ProviderContainer(
    overrides: [
      contentPackRepositoryProvider.overrideWithValue(
        ContentPackRepository(source: DiskContentPackSource()),
      ),
      learnerContentStoreProvider.overrideWithValue(
        InMemoryLearnerContentStore(),
      ),
      contentClassKeyProvider.overrideWith(
        (ref) async => ClassKey('terminale', series: series),
      ),
      contentPackCacheProvider.overrideWithValue(InMemoryContentPackCache()),
      remoteContentGatewayProvider.overrideWithValue(const OfflineGateway()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const SizedBox()),
  );
  await settleSubjectJourneys(tester, container);
  return container.read(subjectJourneysProvider).requireValue;
}

/// La réponse juste, pour les types à choix (les autres : une réponse
/// quelconque, jugée par le correcteur).
StudentResponse _correct(Question question) => switch (question.answer) {
  ChoiceAnswer(:final choice) => ChoiceResponse(choice),
  MultiChoiceAnswer(:final choices) => MultiChoiceResponse(choices.toSet()),
  BooleanAnswer(:final value) => BooleanResponse(value),
  _ => const TextResponse('0'),
};

StudentResponse _wrong(Question question) => switch (question.answer) {
  ChoiceAnswer(:final choice) => ChoiceResponse(
    question.choices.firstWhere((other) => other != choice),
  ),
  BooleanAnswer(:final value) => BooleanResponse(!value),
  _ => const TextResponse('zzz'),
};

bool _isChoice(Question question) =>
    question.answer is ChoiceAnswer || question.answer is BooleanAnswer;

void main() {
  group('catalogue', () {
    testWidgets('Terminale D : Mathématiques CH01–03, Anglais U1–U2, '
        'Physique S1–S2, avec les nombres réels du pack', (tester) async {
      final journeys = await _journeys(tester);
      final catalog = PackQuizCatalog.fromJourneys(journeys);
      final bySubject = {
        for (final subject in catalog.subjects)
          subject.key: [for (final set in subject.sequences) set.contentId],
      };
      expect(bySubject, {
        'anglais': [_english1, _english2],
        'mathematiques': [_maths1, _maths2, _maths3],
        'physique': [_physics1, _physics2],
      });

      // Chaque séquence propose exactement ses questions éligibles.
      final chapters = {
        for (final journey in journeys)
          for (final chapter in journey.chapters)
            chapter.contentId: chapter.chapter,
      };
      final expected = {
        _maths1: 41,
        _maths2: 35,
        _maths3: 36,
        _english1: 34,
        _english2: 34,
        _physics1: 35,
        _physics2: 35,
      };
      for (final subject in catalog.subjects) {
        for (final set in subject.sequences) {
          final chapter = chapters[set.contentId]!;
          expect(
            set.questionCount,
            chapter.questions.where((q) => q.autoScorable).length,
          );
          expect(set.questionCount, expected[set.contentId], reason: set.id);
          for (final item in set.pool) {
            expect(item.question.autoScorable, isTrue);
            expect(item.question.disabledReason, isNull);
            expect(item.question.requiresSelfEvaluation, isFalse);
          }
        }
      }
      expect(catalog.questionCount, 250);
      // Révision mixte : plusieurs séquences, assez de questions.
      for (final subject in catalog.subjects) {
        expect(subject.mixed, isNotNull, reason: subject.key);
        expect(subject.mixed!.questionCount, subject.questionCount);
      }
    });

    testWidgets('Terminale A : seulement l\'anglais', (tester) async {
      final catalog = PackQuizCatalog.fromJourneys(
        await _journeys(tester, series: 'a'),
      );
      expect(catalog.subjects.map((s) => s.key), ['anglais']);
    });

    test('sans pack : catalogue vide', () {
      expect(PackQuizCatalog.fromJourneys(const []).isEmpty, isTrue);
    });
  });

  group('sélection déterministe', () {
    test('empreinte stable (FNV-1a 32 bits, exacte aussi sur le web)', () {
      // Référence calculée en arithmétique exacte.
      expect(stableHash('seq:abc|training|0|q1'), 2007265122);
      expect(stableHash(''), 0x811c9dc5);
    });

    testWidgets('même quiz, même tentative : même ordre ; nouvelle '
        'tentative : autre ordre, reproductible', (tester) async {
      final catalog = PackQuizCatalog.fromJourneys(await _journeys(tester));
      final set = catalog.setById(PackQuizSet.sequenceId(_physics2))!;
      List<String> ids(int attempt, PackQuizMode mode) => [
        for (final item in DeterministicQuizBuilder.build(
          set: set,
          mode: mode,
          attempt: attempt,
        ).items)
          item.id,
      ];
      for (final mode in PackQuizMode.values) {
        expect(ids(0, mode), ids(0, mode));
        expect(ids(1, mode), ids(1, mode));
        expect(ids(1, mode), isNot(ids(0, mode)));
        expect(ids(0, mode).toSet(), hasLength(ids(0, mode).length));
      }
    });

    testWidgets('évaluation : répartition stable et annoncée, niveaux '
        'manquants complétés', (tester) async {
      final catalog = PackQuizCatalog.fromJourneys(await _journeys(tester));
      final maths = DeterministicQuizBuilder.build(
        set: catalog.setById(PackQuizSet.sequenceId(_maths1))!,
        mode: PackQuizMode.evaluation,
      );
      expect(maths.length, 10);
      expect(maths.distribution, {1: 3, 2: 4, 3: 3});
      final difficulties = [for (final i in maths.items) i.question.difficulty];
      expect(difficulties, [...difficulties]..sort());

      // Unit 1 d'anglais n'a aucune question de niveau 3.
      final english = DeterministicQuizBuilder.build(
        set: catalog.setById(PackQuizSet.sequenceId(_english1))!,
        mode: PackQuizMode.evaluation,
      );
      expect(english.length, 10);
      expect(english.distribution, {1: 3, 2: 7});

      final mixed = DeterministicQuizBuilder.build(
        set: catalog.setById(PackQuizSet.mixedId('mathematiques'))!,
        mode: PackQuizMode.evaluation,
      );
      expect(mixed.length, DeterministicQuizBuilder.mixedEvaluationLength);
    });

    testWidgets('entraînement : d\'abord les questions non réussies, au '
        'niveau de la maîtrise', (tester) async {
      final catalog = PackQuizCatalog.fromJourneys(await _journeys(tester));
      final set = catalog.setById(PackQuizSet.sequenceId(_physics1))!;
      final fresh = DeterministicQuizBuilder.build(
        set: set,
        mode: PackQuizMode.training,
      );
      expect(fresh.length, DeterministicQuizBuilder.trainingLength);
      // Élève nouveau : niveau 1.
      expect(fresh.items.every((i) => i.question.difficulty == 1), isTrue);

      // Les questions déjà réussies passent après les autres.
      final first = fresh.items.first;
      final concept = first.chapter.conceptForQuestion(first.question)!;
      final snapshot = const LearnerContentSnapshot().withConcept(
        MasteryState(conceptId: concept.id, answeredQuestionIds: {first.id}),
      );
      final again = DeterministicQuizBuilder.build(
        set: set,
        mode: PackQuizMode.training,
        snapshot: snapshot,
      );
      expect(again.items.map((i) => i.id), isNot(contains(first.id)));
    });
  });

  group('séance', () {
    Future<PackQuizPlan> plan(
      WidgetTester tester,
      String contentId,
      PackQuizMode mode,
    ) async {
      final catalog = PackQuizCatalog.fromJourneys(await _journeys(tester));
      return DeterministicQuizBuilder.build(
        set: catalog.setById(PackQuizSet.sequenceId(contentId))!,
        mode: mode,
      );
    }

    testWidgets('entraînement : correction immédiate, une seule écriture de '
        'maîtrise par réponse, puis bilan', (tester) async {
      final quiz = await plan(tester, _physics2, PackQuizMode.training);
      final recorded = <(String, bool)>[];
      final session = PackQuizSession(
        plan: quiz,
        recorder: (item, correct) async {
          recorded.add((item.id, correct));
          return const [];
        },
      );
      addTearDown(session.dispose);
      expect(session.phase, PackQuizPhase.intro);
      session.start();
      var expectedScore = 0;
      for (var i = 0; i < quiz.length; i++) {
        final question = session.item!.question;
        final right = _isChoice(question) && i.isEven;
        final answer = await session.submit(
          right ? _correct(question) : _wrong(question),
        );
        expect(answer, isNotNull);
        // Entraînement : la correction reste affichée jusqu'à « suivante ».
        expect(session.answer, same(answer));
        expect(await session.submit(_correct(question)), isNull);
        if (answer!.correct) expectedScore++;
        session.next();
      }
      expect(session.phase, PackQuizPhase.finished);
      expect(recorded, hasLength(quiz.length));
      expect(session.result.score, expectedScore);
      expect(session.result.total, quiz.length);
      expect(
        session.result.concepts.fold(0, (sum, c) => sum + c.total),
        quiz.length,
      );
    });

    testWidgets('évaluation : rien n\'est révélé, la séance avance seule, '
        'aucun indice', (tester) async {
      final quiz = await plan(tester, _english2, PackQuizMode.evaluation);
      final session = PackQuizSession(
        plan: quiz,
        recorder: (_, _) async => const [],
      )..start();
      addTearDown(session.dispose);
      expect(session.canHint, isFalse);
      final first = session.item!;
      await session.submit(_correct(first.question));
      expect(session.answer, isNull);
      expect(session.index, 1);
      while (session.phase == PackQuizPhase.question) {
        await session.submit(_wrong(session.item!.question));
      }
      expect(session.result.answers, hasLength(quiz.length));
    });

    testWidgets('indices : seulement ceux du pack, et seulement en '
        'entraînement', (tester) async {
      final quiz = await plan(tester, _maths1, PackQuizMode.training);
      final session = PackQuizSession(
        plan: quiz,
        recorder: (_, _) async => const [],
      )..start();
      addTearDown(session.dispose);
      final hints = session.item!.question.hints.length;
      expect(hints, greaterThan(0));
      for (var i = 0; i < hints; i++) {
        expect(session.canHint, isTrue);
        session.showHint();
      }
      expect(session.hintsShown, hints);
      expect(session.canHint, isFalse);
    });
  });

  group('Kira et Léo, maîtres de séance', () {
    test('réplique déterministe : même situation, même réplique ; '
        'variée d\'une question à l\'autre', () {
      QuizNarration line(String id, String question, int attempt) =>
          QuizCompanionNarrator.narrate(
            QuizNarrationEvent.correct,
            companionId: id,
            questionId: question,
            attempt: attempt,
          );
      expect(line('kira', 'q1', 0).variant, line('kira', 'q1', 0).variant);
      final variants = {
        for (var i = 0; i < 30; i++) line('leo', 'q$i', 0).variant,
      };
      expect(variants, {0, 1, 2});
      expect(line('inconnu', 'q1', 0).companionId, 'kira');
    });

    test('série, mi-parcours, dernière question', () {
      expect(
        QuizCompanionNarrator.afterAnswer(correct: true, streak: 3),
        QuizNarrationEvent.streak,
      );
      expect(
        QuizCompanionNarrator.afterAnswer(correct: true, streak: 2),
        QuizNarrationEvent.correct,
      );
      expect(
        QuizCompanionNarrator.afterAnswer(correct: false, streak: 0),
        QuizNarrationEvent.incorrect,
      );
      expect(
        QuizCompanionNarrator.presentationFor(index: 4, length: 8),
        QuizNarrationEvent.halfway,
      );
      expect(
        QuizCompanionNarrator.presentationFor(index: 7, length: 8),
        QuizNarrationEvent.lastQuestion,
      );
      expect(
        QuizCompanionNarrator.presentationFor(index: 1, length: 8),
        QuizNarrationEvent.questionPresented,
      );
    });

    for (final locale in const ['fr', 'en']) {
      test('toutes les répliques existent, complètes ($locale)', () {
        final l10n = lookupAppLocalizations(Locale(locale));
        const values = {
          'subject': 'Physique',
          'count': 8,
          'title': 'Erreurs et incertitudes',
          'current': 3,
          'total': 8,
          'score': 6,
          'concept': 'Incertitude de type A',
        };
        final seen = <String>{};
        for (final companion in const ['kira', 'leo']) {
          for (final event in QuizNarrationEvent.values) {
            for (var variant = 0; variant < 3; variant++) {
              final text = quizNarrationText(
                l10n,
                QuizNarration(
                  companionId: companion,
                  event: event,
                  variant: variant,
                  values: values,
                ),
              );
              expect(text.trim(), isNotEmpty);
              expect(text, isNot(contains('{')), reason: text);
              // Jamais présenté comme une « IA » : le compagnon ne génère
              // rien ici.
              expect(
                text,
                isNot(contains(RegExp(r'(^|[\s«(])(IA|AI)([\s».,!?)]|$)'))),
              );
              expect(
                text.toLowerCase(),
                isNot(contains(RegExp('gemini|openai'))),
              );
              seen.add(text);
            }
          }
        }
        // 2 compagnons × 11 moments × 3 variantes, toutes différentes.
        expect(seen, hasLength(66));
      });
    }

    test('aucun appel de modèle de langue, aucun réseau dans les quiz des '
        'cours', () {
      final files = [
        'lib/features/quiz/domain/pack_quiz.dart',
        'lib/features/quiz/domain/quiz_companion_narrator.dart',
        'lib/features/quiz/application/pack_quiz_session.dart',
        'lib/features/quiz/application/pack_quiz_providers.dart',
        'lib/features/quiz/presentation/pack_quiz_screen.dart',
        'lib/features/quiz/presentation/pack_quiz_hub_section.dart',
        'lib/features/quiz/presentation/quiz_narration_text.dart',
        'lib/features/quiz/presentation/widgets/quiz_companion_bubble.dart',
      ];
      for (final file in files) {
        final source = File(file).readAsStringSync();
        for (final forbidden in const [
          'cloud_functions',
          'ai_companion',
          'askTutor',
          'package:http',
          'cloud_firestore',
          'gemini',
          'openai',
        ]) {
          expect(
            source.toLowerCase().contains(forbidden.toLowerCase()),
            isFalse,
            reason: '$file → $forbidden',
          );
        }
      }
    });
  });
}
