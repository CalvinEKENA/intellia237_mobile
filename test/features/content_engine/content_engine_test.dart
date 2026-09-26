import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/core/academics/class_key.dart';
import 'package:intellia237/features/content_engine/data/content_pack_parser.dart';
import 'package:intellia237/features/content_engine/data/content_pack_repository.dart';
import 'package:intellia237/features/content_engine/data/learner_content_store.dart';
import 'package:intellia237/features/content_engine/domain/companion_action.dart';
import 'package:intellia237/features/content_engine/domain/content_issue.dart';
import 'package:intellia237/features/content_engine/domain/mastery.dart';
import 'package:intellia237/features/content_engine/domain/pedagogy.dart';
import 'package:intellia237/features/content_engine/domain/question.dart';
import 'package:intellia237/features/content_engine/domain/visual_kind.dart';
import 'package:intellia237/features/content_engine/engine/adaptive_engine.dart';
import 'package:intellia237/features/content_engine/engine/answer_checker.dart';
import 'package:intellia237/features/content_engine/engine/companion_engine.dart';

import 'pack_fixture.dart';

void main() {
  final chapter = pilotChapter();
  const checker = AnswerChecker();
  Question q(String id) => chapter.question(id)!;
  bool ok(String id, StudentResponse response) =>
      checker.grade(q(id), response).correct;

  group('correction déterministe — chaque type du pack', () {
    test('numeric : entier, texte binaire, champs nommés', () {
      expect(ok('l2_e1', const TextResponse('45')), isTrue);
      expect(ok('l2_e1', const TextResponse(' 45 ')), isTrue);
      expect(ok('l2_e1', const TextResponse('46')), isFalse);
      expect(ok('l2_e2', const TextResponse('1101')), isTrue);
      expect(ok('l2_e2', const TextResponse('1 101₂')), isTrue);
      expect(ok('l2_e2', const TextResponse('1011')), isFalse);
      expect(ok('l1_e1', const FieldsResponse({'q': '7', 'r': '5'})), isTrue);
      final partial = checker.grade(
        q('l1_e1'),
        const FieldsResponse({'q': '7', 'r': '6'}),
      );
      expect(partial.correct, isFalse);
      expect(partial.diagnosis, GradeDiagnosis.someFieldsWrong);
      expect(partial.fieldResults, {'q': true, 'r': false});
      // Signe moins typographique accepté.
      expect(ok('l3_e1', const FieldsResponse({'q': '−11', 'r': '1'})), isTrue);
    });

    test('mcq : entier et texte', () {
      expect(ok('l1_e2', const ChoiceResponse(AnswerAtom.integer(9))), isTrue);
      expect(
        ok('l1_e2', const ChoiceResponse(AnswerAtom.integer(17))),
        isFalse,
      );
      expect(
        ok('l3_m1', const ChoiceResponse(AnswerAtom.text('3a-5c'))),
        isTrue,
      );
    });

    test('true_false, reasoning et procedure', () {
      expect(ok('l1_e3', const BooleanResponse(false)), isTrue);
      expect(ok('l3_e2', const BooleanResponse(false)), isFalse);
      expect(ok('l1_h1', const BooleanResponse(false)), isTrue); // « non »
      expect(ok('int_water1', const BooleanResponse(true)), isTrue); // « oui »
    });

    test('solution_set : ensemble d\'entiers, sans ordre ni doublon', () {
      expect(
        ok('l3_m2', const IntegerSetResponse({9, 5, 3, 2, 0, -1, -3, -7})),
        isTrue,
      );
      expect(
        ok('l3_m2', const TextResponse('-7, -3, -1, 0, 2, 3, 5, 9')),
        isTrue,
      );
      final missing = checker.grade(
        q('l3_m2'),
        const IntegerSetResponse({2, 3, 5, 9}),
      );
      expect(missing.diagnosis, GradeDiagnosis.missingSolutions);
      expect(missing.missingCount, 4);
      // Défi Awa : une seule valeur n'est jamais un corrigé.
      expect(ok('int_awa2', const IntegerSetResponse({23})), isFalse);
      expect(ok('int_awa2', const IntegerSetResponse({23, 58, 93})), isTrue);
    });

    test('solution_set de congruences : restes modulo n', () {
      expect(ok('l4_h1', const IntegerSetResponse({2, 3})), isTrue);
      expect(ok('l4_h1', const IntegerSetResponse({7, 8})), isTrue); // 7≡2, 8≡3
      expect(ok('l4_h1', const IntegerSetResponse({2})), isFalse);
    });

    test('multi_select', () {
      const seven = AnswerAtom.integer(7);
      const twelve = AnswerAtom.integer(12);
      const minusThree = AnswerAtom.integer(-3);
      expect(
        ok('l4_m2', MultiChoiceResponse({seven, twelve, minusThree})),
        isTrue,
      );
      final extra = checker.grade(
        q('l4_m2'),
        MultiChoiceResponse({
          seven,
          twelve,
          minusThree,
          const AnswerAtom.integer(8),
        }),
      );
      expect(extra.diagnosis, GradeDiagnosis.extraSolutions);
    });

    test('factorization : écritures variées et diagnostic', () {
      for (final text in ['2²×3×5', '2^2*3*5', '2x2x3x5', '5 × 3 × 2²']) {
        expect(ok('l5_e3', TextResponse(text)), isTrue, reason: text);
      }
      expect(
        checker.grade(q('l5_e3'), const TextResponse('4×3×5')).diagnosis,
        GradeDiagnosis.factorNotPrime,
      );
      expect(
        checker.grade(q('l5_e3'), const TextResponse('2×3×5')).diagnosis,
        GradeDiagnosis.wrongProduct,
      );
      expect(
        checker.grade(q('l5_m1'), const TextResponse('17²×23')).correct,
        isTrue,
      );
      expect(
        checker.grade(q('l5_e3'), const TextResponse('deux')).diagnosis,
        GradeDiagnosis.unreadable,
      );
    });

    test('multi_step : multiensemble et champs composés', () {
      expect(ok('l5_h1', const TextResponse('23, 17, 17')), isTrue);
      expect(ok('l5_h1', const TextResponse('17, 23')), isFalse);
      expect(
        ok(
          'l2_h1',
          const FieldsResponse({
            'binary': '1111101000',
            'decomposition': '512+256+128+64+32+8',
          }),
        ),
        isTrue,
      );
      expect(
        ok('l6_h1', const FieldsResponse({'gcd': '159', 'lcm': '4904514'})),
        isTrue,
      );
    });

    test('même réponse, même verdict (100 fois)', () {
      final verdicts = {
        for (var i = 0; i < 100; i++)
          checker
              .grade(q('l3_m2'), const TextResponse('9,5,3,2,0,-1,-3,-7'))
              .correct,
      };
      expect(verdicts, {true});
    });

    test('entier attendu : « 5,0 » et « 5.00 » acceptés, jamais un '
        'arrondi ni une fraction', () {
      const mean = Question(
        id: 'moyenne',
        lessonNumber: 1,
        difficulty: 1,
        type: QuestionType.numeric,
        rawType: 'numeric',
        prompt: 'Moyenne de 5,0 ; 5,2 ; 4,8 ; 5,0 ?',
        answer: ScalarAnswer(AnswerAtom.integer(5)),
      );
      bool grade(String text) =>
          checker.grade(mean, TextResponse(text)).correct;
      for (final text in ['5', '5,0', '5.00', ' 5,0 ']) {
        expect(grade(text), isTrue, reason: text);
      }
      for (final text in ['5,1', '4,99', '10/2', '5,']) {
        expect(grade(text), isFalse, reason: text);
      }
    });

    test('une question non notable est refusée, jamais devinée', () {
      const unscorable = Question(
        id: 'x',
        lessonNumber: 1,
        difficulty: 1,
        type: QuestionType.reasoning,
        rawType: 'reasoning',
        prompt: 'Justifie.',
        answer: UnscorableAnswer('rédaction libre'),
      );
      expect(
        () => checker.grade(unscorable, const TextResponse('…')),
        throwsArgumentError,
      );
    });
  });

  group('sélection des questions', () {
    const selector = QuestionSelector();

    test('3 difficultés disponibles pour chaque leçon', () {
      for (final lesson in chapter.lessons) {
        expect(selector.availableDifficulties(chapter, lesson.number), [
          1,
          2,
          3,
        ]);
      }
    });

    test('ordre du pack, questions réussies en dernier', () {
      final first = selector.forLesson(chapter, lessonNumber: 1, difficulty: 1);
      expect(first.map((q) => q.id), ['l1_e1', 'l1_e2', 'l1_e3']);
      final after = selector.forLesson(
        chapter,
        lessonNumber: 1,
        difficulty: 1,
        answered: {'l1_e1'},
      );
      expect(after.map((q) => q.id), ['l1_e2', 'l1_e3', 'l1_e1']);
    });

    test(
      '« Teste-moi » passe à la difficulté suivante quand tout est réussi',
      () {
        final next = selector.next(
          chapter,
          lessonNumber: 1,
          difficulty: 1,
          answered: {'l1_e1', 'l1_e2', 'l1_e3'},
        );
        expect(next?.difficulty, 2);
      },
    );
  });

  group('adaptation — les deux axes restent indépendants', () {
    final engine = AdaptiveEngine(chapter.mastery, maxDifficulty: 3);
    final hard = q('l1_h1');
    final easy = q('l1_e1');

    test('2 erreurs → « simple » ; une de plus → « 12 ans »', () {
      var state = const MasteryState(conceptId: 'euclidean_division_N');
      const standard = ExplanationPreference();
      var outcome = engine.record(
        state: state,
        question: hard,
        correct: false,
        preference: standard,
      );
      expect(outcome.suggestions, isEmpty);
      outcome = engine.record(
        state: outcome.state,
        question: hard,
        correct: false,
        preference: standard,
      );
      expect(outcome.suggestions.single, isA<SuggestExplanation>());
      expect(
        (outcome.suggestions.single as SuggestExplanation).mode,
        ExplanationMode.simple,
      );
      // L'élève accepte : le compteur repart, la difficulté ne bouge pas.
      state = engine.explanationChanged(outcome.state);
      const simple = ExplanationPreference(mode: ExplanationMode.simple);
      outcome = engine.record(
        state: state,
        question: hard,
        correct: false,
        preference: simple,
      );
      expect(
        (outcome.suggestions.single as SuggestExplanation).mode,
        ExplanationMode.ultraSimple,
      );
      expect(outcome.suggestions.whereType<SuggestHarder>(), isEmpty);
    });

    test('préférence verrouillée : aucune proposition d\'explication', () {
      var state = const MasteryState(conceptId: 'c');
      const locked = ExplanationPreference(locked: true);
      for (var i = 0; i < 4; i++) {
        final outcome = engine.record(
          state: state,
          question: hard,
          correct: false,
          preference: locked,
        );
        expect(outcome.suggestions, isEmpty);
        state = outcome.state;
      }
    });

    test('3 réussites consécutives → proposer la difficulté supérieure', () {
      var state = const MasteryState(conceptId: 'c');
      const ultra = ExplanationPreference(mode: ExplanationMode.ultraSimple);
      AdaptiveOutcome? outcome;
      for (var i = 0; i < 3; i++) {
        outcome = engine.record(
          state: state,
          question: easy,
          correct: true,
          preference: ultra,
        );
        state = outcome.state;
      }
      // Explication « 12 ans » et pourtant une difficulté plus haute proposée.
      expect((outcome!.suggestions.single as SuggestHarder).difficulty, 2);
    });

    test('jamais au-delà de la difficulté maximale', () {
      var state = const MasteryState(conceptId: 'c');
      for (var i = 0; i < 5; i++) {
        final outcome = engine.record(
          state: state,
          question: hard,
          correct: true,
          preference: const ExplanationPreference(),
        );
        expect(outcome.suggestions.whereType<SuggestHarder>(), isEmpty);
        state = outcome.state;
      }
    });

    test('maîtrise par notion, bornée, et déblocage à 70', () {
      var state = const MasteryState(conceptId: 'euclidean_division_N');
      for (var i = 0; i < 20; i++) {
        state = engine
            .record(
              state: state,
              question: hard,
              correct: true,
              preference: const ExplanationPreference(),
            )
            .state;
      }
      expect(state.score, 100);
      expect(state.bestDifficulty, 3);
      expect(engine.isLessonUnlocked(chapter, 1, const {}), isTrue);
      expect(engine.isLessonUnlocked(chapter, 2, const {}), isFalse);
      expect(
        engine.isLessonUnlocked(chapter, 2, {state.conceptId: state}),
        isTrue,
      );
    });

    test('le suivi reste distinct d\'une notion à l\'autre', () {
      var snapshot = LearnerContentSnapshot.empty;
      final outcome = engine.record(
        state: snapshot.conceptState('congruence'),
        question: q('l4_e1'),
        correct: true,
        preference: snapshot.preference,
      );
      snapshot = snapshot.withConcept(outcome.state);
      expect(snapshot.conceptState('congruence').correct, 1);
      expect(snapshot.conceptState('prime_numbers').attempts, 0);
    });
  });

  group('Compagnon sans modèle de langage', () {
    final companion = CompanionEngine(chapter);
    const context = CompanionContext(conceptId: 'congruence', lessonNumber: 4);

    test('les trois explications viennent mot pour mot du pack', () {
      final concept = chapter.concepts['congruence']!;
      for (final (action, mode) in [
        (CompanionAction.explainStandard, ExplanationMode.standard),
        (CompanionAction.explainSimple, ExplanationMode.simple),
        (CompanionAction.explainUltraSimple, ExplanationMode.ultraSimple),
      ]) {
        final reply = companion.respond(action, context);
        expect(reply.answered, isTrue);
        expect(reply.parts.single.text, concept.explanation(mode));
      }
      expect(
        companion.respond(CompanionAction.explainUltraSimple, context).visual,
        VisualKind.modularClock,
      );
    });

    test('« Montre-moi » renvoie la primitive visuelle et sa description', () {
      final reply = companion.respond(CompanionAction.showMe, context);
      expect(reply.visual, VisualKind.modularClock);
      expect(reply.parts.single.text, 'Horloge circulaire modulo n.');
    });

    test('indices : échelle issue du pack, puis « plus d\'indice »', () {
      final concept = chapter.concepts['congruence']!;
      // Les indices propres à la question d'abord, puis les pièges de la
      // notion, puis l'explication simple.
      final ladder = [
        ...q('l4_e1').hints,
        ...concept.commonMistakes,
        concept.explanation(ExplanationMode.simple),
      ];
      expect(q('l4_e1').hints, isNotEmpty);
      for (var i = 0; i < ladder.length; i++) {
        final reply = companion.respond(
          CompanionAction.hint,
          CompanionContext(
            conceptId: 'congruence',
            lessonNumber: 4,
            question: q('l4_e1'),
            hintsShown: i,
          ),
        );
        expect(reply.parts.single.text, ladder[i]);
        // Un indice ne donne jamais la réponse.
        expect(reply.parts.single.text, isNot(contains('9')));
      }
      final done = companion.respond(
        CompanionAction.hint,
        CompanionContext(
          conceptId: 'congruence',
          lessonNumber: 4,
          hintsShown: ladder.length,
        ),
      );
      expect(done.gap, CompanionGap.noMoreHints);
    });

    test('« Pourquoi c\'est faux ? » utilise la réponse de l\'élève', () {
      final question = q('l1_e1');
      final grade = checker.grade(
        question,
        const FieldsResponse({'q': '7', 'r': '6'}),
      );
      final reply = companion.respond(
        CompanionAction.whyWrong,
        CompanionContext(
          conceptId: 'euclidean_division_N',
          lessonNumber: 1,
          question: question,
          lastGrade: grade,
        ),
      );
      expect(reply.diagnosis, GradeDiagnosis.someFieldsWrong);
      expect(reply.fieldResults, {'q': true, 'r': false});
      expect(reply.parts.first.text, question.explanation);
      expect(reply.parts.skip(1).map((p) => p.text), contains('accepter r≥b'));
      final nothing = companion.respond(CompanionAction.whyWrong, context);
      expect(nothing.gap, CompanionGap.nothingToExplain);
    });

    test('« Teste-moi » propose une vraie question du pack', () {
      final reply = companion.respond(CompanionAction.testMe, context);
      expect(reply.question?.lessonNumber, 4);
      expect(chapter.question(reply.question!.id), isNotNull);
    });

    test(
      'demande hors pack : notions proches, ou « pas encore disponible »',
      () {
        final prime = companion.ask('c\'est quoi un nombre premier ?');
        expect(prime.concept?.id, 'prime_numbers');
        final gcd = companion.ask('comment calculer le PGCD');
        expect(gcd.concept?.id, 'gcd_lcm');
        final binary = companion.ask('écriture binaire');
        expect(binary.concept?.id, 'binary_decimal');
        final unknown = companion.ask('photosynthèse des plantes');
        expect(unknown.gap, CompanionGap.unknownTopic);
        expect(unknown.parts, isEmpty);
      },
    );

    test(
      'explication manquante : signalée, plus proche montrée, rien d\'inventé',
      () {
        final raw = pilotRaw();
        final pedagogy = deepCopy(raw.pedagogy!);
        final concepts = pedagogy['concepts']! as List;
        ((concepts[3] as Map)['explanations'] as Map).remove('ultra_simple');
        final altered = const ContentPackParser().parse(
          RawContentPack(
            directory: raw.directory,
            manifest: raw.manifest,
            source: raw.source,
            pedagogy: pedagogy,
            runtime: raw.runtime,
            validation: raw.validation,
          ),
        );
        final reply = CompanionEngine(
          altered,
        ).respond(CompanionAction.explainUltraSimple, context);
        expect(reply.gap, CompanionGap.explanationMissing);
        expect(reply.fallbackMode, ExplanationMode.simple);
        expect(
          reply.parts.single.text,
          altered.concepts['congruence']!.explanation(ExplanationMode.simple),
        );
        expect(
          altered.issues.map((i) => i.code),
          contains('explanation_missing'),
        );
      },
    );
  });

  group('données invalides et champs facultatifs', () {
    RawContentPack withRuntime(Map<String, Object?> runtime) {
      final raw = pilotRaw();
      return RawContentPack(
        directory: raw.directory,
        manifest: raw.manifest,
        source: raw.source,
        pedagogy: raw.pedagogy,
        runtime: runtime,
        validation: raw.validation,
      );
    }

    test(
      'réponse de QCM absente des propositions : question retirée, signalée',
      () {
        final runtime = deepCopy(pilotRaw().runtime!);
        final bank = runtime['question_bank']! as List;
        (bank[1] as Map)['answer'] = 42;
        final altered = const ContentPackParser().parse(withRuntime(runtime));
        expect(altered.question('l1_e2')!.autoScorable, isFalse);
        expect(
          altered.issues.map((i) => i.code),
          contains('question_answer_unscorable'),
        );
        expect(
          const QuestionSelector()
              .forLesson(altered, lessonNumber: 1, difficulty: 1)
              .map((q) => q.id),
          isNot(contains('l1_e2')),
        );
      },
    );

    test('type inconnu, identifiant en double, difficulté non déclarée', () {
      final runtime = deepCopy(pilotRaw().runtime!);
      final bank = runtime['question_bank']! as List;
      (bank[0] as Map)['type'] = 'drag_and_drop_v9';
      bank.add(Map.of(bank[2] as Map));
      (bank[3] as Map)['difficulty'] = 7;
      final altered = const ContentPackParser().parse(withRuntime(runtime));
      final codes = altered.issues.map((i) => i.code);
      expect(
        codes,
        containsAll([
          'question_type_unknown',
          'question_duplicate_id',
          'question_difficulty_unknown',
        ]),
      );
      expect(altered.question('l1_e1')!.autoScorable, isFalse);
      expect(altered.questions, hasLength(41));
    });

    test('champs facultatifs absents : aucun plantage', () {
      final runtime = deepCopy(pilotRaw().runtime!)
        ..remove('games')
        ..remove('companion')
        ..remove('mastery')
        ..remove('explanation_modes')
        ..remove('difficulty_levels');
      for (final item in runtime['question_bank']! as List) {
        (item as Map)
          ..remove('explanation')
          ..remove('source_anchor')
          ..remove('tags');
      }
      final pedagogy = deepCopy(pilotRaw().pedagogy!);
      for (final concept in pedagogy['concepts']! as List) {
        (concept as Map)
          ..remove('visual_model')
          ..remove('common_mistakes')
          ..remove('prerequisites');
      }
      final raw = pilotRaw();
      final altered = const ContentPackParser().parse(
        RawContentPack(
          directory: raw.directory,
          manifest: const {},
          pedagogy: pedagogy,
          runtime: runtime,
          validation: raw.validation,
        ),
      );
      expect(altered.questions, hasLength(41));
      expect(altered.games, isEmpty);
      expect(altered.companion.actions, CompanionAction.values);
      expect(altered.mastery.unlockNextLessonAt, 70);
      expect(altered.difficulties.map((d) => d.value), [1, 2, 3]);
      expect(
        altered.concepts.values.every((c) => c.visualKind == VisualKind.none),
        isTrue,
      );
      final hint = CompanionEngine(altered).respond(
        CompanionAction.hint,
        const CompanionContext(conceptId: 'congruence', lessonNumber: 4),
      );
      expect(hint.parts.single.role, CompanionPartRole.explanation);
    });

    test('schéma majeur trop récent : refusé, jamais deviné', () {
      final runtime = deepCopy(pilotRaw().runtime!)
        ..['schema_version'] = 'intellia.runtime-learning-pack.v3';
      final altered = const ContentPackParser().parse(withRuntime(runtime));
      expect(altered.isPlayable, isFalse);
      expect(
        altered.issues
            .where((i) => i.severity == ContentIssueSeverity.error)
            .map((i) => i.code),
        contains('pack_schema_too_recent'),
      );
    });

    test('un pack qui exige un modèle de langage n\'est pas proposé', () {
      final runtime = deepCopy(pilotRaw().runtime!)..['llm_required'] = true;
      expect(
        const ContentPackParser().parse(withRuntime(runtime)).isPlayable,
        isFalse,
      );
    });
  });

  group('hors ligne : aucun réseau nécessaire', () {
    test(
      'catalogue, chapitre, correction, Compagnon et progression sans réseau',
      () async {
        await HttpOverrides.runZoned(
          () async {
            final source = DiskContentPackSource();
            final repository = ContentPackRepository(source: source);
            final subjects = await repository.subjectsFor(
              const ClassKey('terminale', series: 'd'),
            );
            final maths = subjects.singleWhere((s) => s.key == 'mathematiques');
            expect(maths.title, 'Mathématiques');
            expect(maths.chapters.map((c) => c.contentId), [
              'maths_td_ch01_arithmetique',
              'maths_td_ch02_nombres_complexes_algebrique',
              'maths_td_ch03_fonctions_numeriques',
            ]);
            final loaded = await repository.chapter(
              'maths_td_ch01_arithmetique',
            );
            expect(loaded.lessons, hasLength(6));
            expect(
              checker
                  .grade(loaded.question('l2_m1')!, const TextResponse('125'))
                  .correct,
              isTrue,
            );
            expect(
              CompanionEngine(loaded)
                  .respond(
                    CompanionAction.showMe,
                    const CompanionContext(
                      conceptId: 'binary_decimal',
                      lessonNumber: 2,
                    ),
                  )
                  .visual,
              VisualKind.placeValue,
            );
            final store = InMemoryLearnerContentStore();
            await store.save(
              'learner',
              LearnerContentSnapshot.empty.withPreference(
                const ExplanationPreference(
                  mode: ExplanationMode.ultraSimple,
                  locked: true,
                ),
              ),
            );
            expect((await store.load('learner')).preference.locked, isTrue);
            // Seuls des fichiers locaux ont été lus.
            expect(
              source.reads.every((path) => path.startsWith('assets/content/')),
              isTrue,
            );
          },
          createHttpClient: (_) =>
              throw StateError('Aucun appel réseau autorisé.'),
        );
      },
    );

    test('une autre classe ne voit pas ce chapitre', () async {
      final repository = ContentPackRepository(source: DiskContentPackSource());
      // Les mathématiques de Terminale D ne sont pas servies en Terminale C
      // (l'anglais, commun à toute la Terminale, l'est).
      final subjects = await repository.subjectsFor(
        const ClassKey('terminale', series: 'c'),
      );
      expect(subjects.where((s) => s.key == 'mathematiques'), isEmpty);
      await expectLater(
        repository.chapter('inconnu'),
        throwsA(isA<ContentPackNotFound>()),
      );
    });

    test('la progression sérialisée se relit à l\'identique', () {
      final snapshot = LearnerContentSnapshot.empty
          .withPreference(
            const ExplanationPreference(mode: ExplanationMode.simple),
          )
          .withConcept(
            const MasteryState(
              conceptId: 'gcd_lcm',
              score: 42,
              attempts: 3,
              correct: 2,
              answeredQuestionIds: {'l6_e1'},
            ),
          );
      final copy = LearnerContentSnapshot.fromJson(snapshot.toJson());
      expect(copy.preference.mode, ExplanationMode.simple);
      expect(copy.conceptState('gcd_lcm').score, 42);
      expect(copy.conceptState('gcd_lcm').answeredQuestionIds, {'l6_e1'});
      expect(LearnerContentSnapshot.fromJson('illisible').concepts, isEmpty);
    });
  });

  group('chaque pack présent est déclaré dans pubspec.yaml', () {
    test('aucun pack oublié', () async {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final directory in await DiskContentPackSource().packDirectories()) {
        expect(pubspec, contains('- $directory/'), reason: directory);
      }
    });
  });
}
