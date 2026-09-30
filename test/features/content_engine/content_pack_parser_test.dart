import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/content_engine/data/content_pack_parser.dart';
import 'package:intellia237/features/content_engine/domain/content_issue.dart';
import 'package:intellia237/features/content_engine/domain/game_blueprint.dart';
import 'package:intellia237/features/content_engine/domain/pedagogy.dart';
import 'package:intellia237/features/content_engine/domain/question.dart';
import 'package:intellia237/features/content_engine/domain/validation.dart';
import 'package:intellia237/features/content_engine/domain/visual_kind.dart';

import 'pack_fixture.dart';

void main() {
  group('pack pilote — lecture des 5 fichiers', () {
    final chapter = pilotChapter();

    test('curriculum, identifiants et règles', () {
      expect(chapter.contentId, 'maths_td_ch01_arithmetique');
      expect(chapter.packId, 'maths_td_ch01_arithmetique_runtime_v1');
      expect(chapter.curriculum.level, 'Terminale D');
      expect(chapter.curriculum.levelKey, 'terminale-d');
      expect(chapter.curriculum.subjectKey, 'mathematiques');
      expect(chapter.curriculum.chapterNumber, 1);
      expect(chapter.llmRequired, isFalse);
      expect(chapter.isPlayable, isTrue);
      expect(chapter.designPrinciple, isNotNull);
      expect(chapter.adaptiveRuleTexts, hasLength(5));
    });

    test('six leçons, chacune reliée à sa notion et à sa provenance', () {
      expect(chapter.lessons.map((l) => l.number), [1, 2, 3, 4, 5, 6]);
      for (final lesson in chapter.lessons) {
        expect(chapter.concepts[lesson.conceptId], isNotNull);
        expect(lesson.verifiedCore, isNotEmpty, reason: '${lesson.number}');
        expect(lesson.sourcePages, isNotEmpty);
      }
      // Six notions de leçon, puis la notion d'intégration du chapitre.
      expect(chapter.learningPath, hasLength(7));
      expect(chapter.learningPath.last, 'chapter_integration');
      expect(chapter.concepts['chapter_integration']!.lessonNumber, 0);
    });

    test('trois niveaux d\'explication pour chaque notion', () {
      expect(chapter.explanationModes, ExplanationMode.values);
      for (final concept in chapter.concepts.values) {
        expect(
          concept.availableModes,
          ExplanationMode.values,
          reason: concept.id,
        );
        expect(concept.commonMistakes, isNotEmpty);
      }
    });

    test('trois difficultés, libellées par la pédagogie', () {
      expect(chapter.difficulties.map((d) => d.value), [1, 2, 3]);
      expect(chapter.difficulty(3).label, 'Difficile / Défi Bac');
      expect(chapter.maxDifficulty, 3);
    });

    test('les primitives visuelles sont reconnues depuis visual_model', () {
      final kinds = {
        for (final concept in chapter.concepts.values)
          concept.id: concept.visualKind,
      };
      expect(kinds['euclidean_division_N'], VisualKind.grouping);
      expect(kinds['binary_decimal'], VisualKind.placeValue);
      expect(kinds['euclidean_division_Z'], VisualKind.remainderBand);
      expect(kinds['congruence'], VisualKind.modularClock);
      expect(kinds['prime_numbers'], VisualKind.factorBricks);
      expect(kinds['gcd_lcm'], VisualKind.tiling);
    });

    test('41 questions, toutes notables, chaque type présent reconnu', () {
      expect(chapter.questions, hasLength(41));
      expect(
        chapter.questions.where((q) => !q.autoScorable).map((q) => q.id),
        isEmpty,
      );
      final types = {for (final q in chapter.questions) q.type};
      expect(types, {
        QuestionType.numeric,
        QuestionType.mcq,
        QuestionType.trueFalse,
        QuestionType.reasoning,
        QuestionType.multiStep,
        QuestionType.solutionSet,
        QuestionType.multiSelect,
        QuestionType.factorization,
        QuestionType.procedure,
      });
      expect(chapter.integrationQuestions.map((q) => q.id), [
        'int_awa1',
        'int_awa2',
        'int_awa3',
        'int_water1',
        'int_water2',
      ]);
    });

    test('chaque forme de réponse est typée sans perte', () {
      Answer answer(String id) => chapter.question(id)!.answer;
      expect(answer('l1_e1'), isA<FieldsAnswer>());
      expect((answer('l1_e1') as FieldsAnswer).fields.keys, ['q', 'r']);
      expect(
        (answer('l2_e2') as ScalarAnswer).value,
        const AnswerAtom.text('1101'),
      );
      expect(
        (answer('l2_e1') as ScalarAnswer).value,
        const AnswerAtom.integer(45),
      );
      expect(
        (answer('l1_e2') as ChoiceAnswer).choice,
        const AnswerAtom.integer(9),
      );
      expect(
        (answer('l3_m1') as ChoiceAnswer).choice,
        const AnswerAtom.text('3a-5c'),
      );
      expect((answer('l1_e3') as BooleanAnswer).value, isFalse);
      expect((answer('l1_h1') as VerdictAnswer).yes, isFalse);
      expect((answer('int_water1') as VerdictAnswer).yes, isTrue);
      expect((answer('l3_m2') as IntegerSetAnswer).values, {
        -7,
        -3,
        -1,
        0,
        2,
        3,
        5,
        9,
      });
      final congruences = answer('l4_h1') as CongruenceSetAnswer;
      expect(congruences.modulus, 5);
      expect(congruences.residues, {2, 3});
      expect((answer('l4_m2') as MultiChoiceAnswer).choices, {
        const AnswerAtom.integer(7),
        const AnswerAtom.integer(12),
        const AnswerAtom.integer(-3),
      });
      expect((answer('l5_e3') as FactorizationAnswer).exponents, {
        2: 2,
        3: 1,
        5: 1,
      });
      expect((answer('l5_m1') as FactorizationAnswer).product, 6647);
      expect((answer('l5_h1') as MultisetAnswer).values, [17, 17, 23]);
      final steps = answer('l2_h1') as FieldsAnswer;
      expect(steps.fields['decomposition'], isA<MultisetAnswer>());
      expect(steps.fields['binary'], isA<ScalarAnswer>());
    });

    test('sept blueprints, tous jouables', () {
      expect(chapter.games, hasLength(7));
      final engines = {for (final g in chapter.games) g.id: g.engine};
      expect(engines['soap_factory'], GameEngineKind.grouping);
      expect(engines['binary_suitcase'], GameEngineKind.placeValue);
      expect(engines['modulo_clock'], GameEngineKind.modularClock);
      expect(engines['prime_forge'], GameEngineKind.factorForge);
      expect(engines['tile_master'], GameEngineKind.tiling);
      expect(engines['remainder_zone'], GameEngineKind.remainderZone);
      expect(engines['mission_awa'], GameEngineKind.integrationMission);
      expect(chapter.games.every((g) => g.playable), isTrue);
      expect(chapter.games.every((g) => g.status == GameStatus.ready), isTrue);
      final soap = chapter.games.firstWhere((g) => g.id == 'soap_factory');
      expect(soap.levels.keys, [1, 2, 3]);
      expect(soap.scoring.correct, 100);
      expect(soap.scoring.streakBonus, 25);
      expect(soap.scoring.penalty, 20);
      expect(soap.scoring.penaltyFromLevel, 3);
      expect(soap.scoring.pointsFor(correct: false, streak: 0, level: 2), 0);
      expect(soap.scoring.pointsFor(correct: false, streak: 0, level: 3), -20);
      expect(soap.scoring.pointsFor(correct: true, streak: 3, level: 1), 150);
    });

    test('Compagnon : les 7 actions du pack sont reconnues', () {
      expect(chapter.companion.actions, hasLength(7));
      expect(chapter.companion.unrecognizedLabels, isEmpty);
      expect(chapter.companion.fallbackSuggestions, 3);
    });

    test('règles de maîtrise lues depuis le pack', () {
      expect(chapter.mastery.unlockNextLessonAt, 70);
      expect(chapter.mastery.suggestHarderAfterConsecutiveCorrect, 3);
      expect(chapter.mastery.showSimpleAfterErrors, 2);
      expect(chapter.mastery.showUltraSimpleAfterAdditionalErrors, 1);
    });
  });

  group('rapport de validation respecté', () {
    final chapter = pilotChapter();

    test('statut, contrôles et anomalies lus', () {
      expect(chapter.validation.status, 'PASS_WITH_SOURCE_QUALITY_FLAGS');
      expect(chapter.validation.blocksRuntime, isFalse);
      expect(chapter.validation.checks, hasLength(25));
      expect(chapter.validation.failedChecks, isEmpty);
      expect(chapter.validation.flags, hasLength(2));
      expect(chapter.validation.flags.first.sourcePage, 'page_025.jpg');
      expect(
        chapter.validation.flags.first.severity,
        ValidationSeverity.important,
      );
    });

    test('chaque anomalie accompagne exactement la question qu\'elle vise', () {
      final awa2 = chapter.question('int_awa2')!;
      expect(awa2.flags, hasLength(1));
      // « Ne jamais afficher une valeur unique comme corrigé » : la réponse
      // attendue est l'ensemble complet des trois possibilités.
      expect((awa2.answer as IntegerSetAnswer).values, {23, 58, 93});
      expect(awa2.visibleFlags.single.issue, contains('23, 58 et 93'));
      expect(chapter.question('int_awa3')!.visibleFlags, hasLength(1));
      expect(chapter.question('int_water1')!.flags, isEmpty);
      expect(chapter.question('int_awa1')!.flags, isEmpty);
      expect(
        chapter.issues.map((i) => i.code),
        isNot(contains('validation_flag_page_level')),
      );
    });

    test(
      'une anomalie qui ne nomme qu\'une page suit toutes ses questions',
      () {
        final raw = pilotRaw();
        final validation = deepCopy(raw.validation!);
        for (final flag in validation['source_quality_flags']! as List) {
          (flag as Map).remove('question_ids');
        }
        final chapter = const ContentPackParser().parse(
          RawContentPackCopy.withValidation(raw, validation),
        );
        final flagged = chapter.questions.where((q) => q.flags.isNotEmpty);
        expect(flagged.map((q) => q.sourceAnchor).toSet(), {'page_025.jpg'});
        expect(chapter.question('int_awa2')!.flags, hasLength(2));
        // Visibles seulement là où le pack marque la question comme fragile.
        expect(chapter.question('int_awa2')!.visibleFlags, hasLength(2));
        expect(chapter.question('int_water1')!.visibleFlags, isEmpty);
        // L'imprécision du rapport (page, pas question) est signalée.
        expect(
          chapter.issues.map((i) => i.code),
          contains('validation_flag_page_level'),
        );
      },
    );

    test('un rapport en échec bloque le pack', () {
      final raw = pilotRaw();
      final validation = deepCopy(raw.validation!)..['status'] = 'FAIL';
      final chapter = const ContentPackParser().parse(
        RawContentPackCopy.withValidation(raw, validation),
      );
      expect(chapter.isPlayable, isFalse);
    });

    test('un rapport absent bloque le pack', () {
      final raw = pilotRaw();
      final chapter = const ContentPackParser().parse(
        RawContentPackCopy.withValidation(raw, null),
      );
      expect(chapter.isPlayable, isFalse);
      expect(
        chapter.issues.map((i) => i.code),
        contains('pack_validation_missing'),
      );
    });

    test('question_ids explicites (schéma futur) ciblent précisément', () {
      final raw = pilotRaw();
      final validation = deepCopy(raw.validation!);
      final flags = validation['source_quality_flags']! as List;
      (flags.first as Map)['question_ids'] = ['int_awa2'];
      // La seconde ne nomme que sa page.
      (flags.last as Map).remove('question_ids');
      final chapter = const ContentPackParser().parse(
        RawContentPackCopy.withValidation(raw, validation),
      );
      expect(chapter.question('int_awa2')!.flags, hasLength(2));
      expect(chapter.question('int_awa1')!.flags, hasLength(1));
    });
  });

  group('anomalies du pilote signalées, jamais corrigées', () {
    final chapter = pilotChapter();

    test('mission_awa : notion d\'intégration et moteur explicites', () {
      expect(
        chapter.issues.map((i) => i.code),
        isNot(contains('game_concept_unknown')),
      );
      final mission = chapter.games.firstWhere((g) => g.id == 'mission_awa');
      expect(mission.conceptId, 'chapter_integration');
      expect(mission.engine, GameEngineKind.integrationMission);
      expect(mission.levels.keys, [3]);
    });

    test('jeu visant une notion absente, sans moteur : signalé, mission par '
        'convention', () {
      final raw = pilotRaw();
      final pedagogy = deepCopy(raw.pedagogy!);
      (pedagogy['concepts']! as List).removeWhere(
        (c) => (c as Map)['id'] == 'chapter_integration',
      );
      (pedagogy['learning_path']! as List).remove('chapter_integration');
      final runtime = deepCopy(raw.runtime!);
      final mission =
          (runtime['games']! as List).firstWhere(
                (g) => (g as Map)['id'] == 'mission_awa',
              )
              as Map;
      mission.remove('engine');
      mission.remove('status');
      final altered = const ContentPackParser().parse(
        RawContentPack(
          directory: raw.directory,
          manifest: raw.manifest,
          source: raw.source,
          pedagogy: pedagogy,
          runtime: runtime,
          validation: raw.validation,
        ),
      );
      final issue = altered.issues.firstWhere(
        (i) => i.code == 'game_concept_unknown',
      );
      expect(issue.path, contains('mission_awa'));
      expect(
        altered.games.firstWhere((g) => g.id == 'mission_awa').engine,
        GameEngineKind.integrationMission,
      );
    });

    test("un jeu `draft` ou `disabled` du pack n'est jamais jouable", () {
      final raw = pilotRaw();
      final runtime = deepCopy(raw.runtime!);
      final games = runtime['games']! as List;
      (games[0] as Map)['status'] = 'draft';
      (games[1] as Map)['status'] = 'disabled';
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
      expect(altered.games[0].playable, isFalse);
      expect(altered.games[1].playable, isFalse);
      expect(altered.games[2].playable, isTrue);
    });

    test('aucune erreur bloquante sur le pilote', () {
      expect(
        chapter.issues.where((i) => i.severity == ContentIssueSeverity.error),
        isEmpty,
        reason: chapter.issues.join('\n'),
      );
    });
  });
}

/// Aide de test : un pack pilote dont seul un document change.
extension RawContentPackCopy on RawContentPack {
  static RawContentPack withValidation(
    RawContentPack raw,
    Map<String, Object?>? validation,
  ) => RawContentPack(
    directory: raw.directory,
    manifest: raw.manifest,
    source: raw.source,
    pedagogy: raw.pedagogy,
    runtime: raw.runtime,
    validation: validation,
  );
}
