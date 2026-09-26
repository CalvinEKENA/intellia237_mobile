import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/core/academics/choice_order.dart';
import 'package:intellia237/core/academics/class_key.dart';
import 'package:intellia237/features/content_engine/data/content_delivery.dart';
import 'package:intellia237/features/content_engine/data/content_pack_parser.dart';
import 'package:intellia237/features/content_engine/data/content_pack_repository.dart';
import 'package:intellia237/features/content_engine/domain/chapter.dart';
import 'package:intellia237/features/content_engine/domain/companion_action.dart';
import 'package:intellia237/features/content_engine/domain/game_blueprint.dart';
import 'package:intellia237/features/content_engine/domain/pack_catalog.dart';
import 'package:intellia237/features/content_engine/domain/pedagogy.dart';
import 'package:intellia237/features/content_engine/domain/question.dart';
import 'package:intellia237/features/content_engine/domain/validation.dart';
import 'package:intellia237/features/content_engine/engine/answer_checker.dart';
import 'package:intellia237/features/content_engine/engine/companion_engine.dart';
import 'package:intellia237/features/content_engine/feed/learning_card.dart';
import 'package:intellia237/features/content_engine/feed/learning_card_factory.dart';

import '../../../tool/content/pack_bundle_builder.dart';
import 'pack_fixture.dart';

/// Physique Terminales C-D, module 1, séquence 1 « Erreurs et
/// incertitudes » : un programme en modules et séquences, visé par deux
/// séries précises, dans la même Content Engine.
const _id = 'physique_terminale_cd_m1_s1_erreurs_et_incertitudes';
const _dir =
    'assets/content/terminale_cd/physique/m1_s1_erreurs_et_incertitudes';
const _open = ['l1_q08', 'l2_q08', 'l3_q08', 'l4_q08', 'l5_q08'];

Map<String, Object?> _json(String name) =>
    jsonDecode(File('$_dir/$name').readAsStringSync()) as Map<String, Object?>;

void main() {
  late ContentPackRepository repository;
  setUp(
    () => repository = ContentPackRepository(source: DiskContentPackSource()),
  );
  Future<Chapter> pack() => repository.chapter(_id);
  bool grade(Question q, String text) =>
      const AnswerChecker().grade(q, TextResponse(text)).correct;

  group('Public : Terminales C et D seulement', () {
    test('« terminale-c-d » désigne exactement C et D', () {
      expect(ClassKey.parseTargets('terminale-c-d'), const [
        ClassKey('terminale', series: 'c'),
        ClassKey('terminale', series: 'd'),
      ]);
    });

    for (final series in ['c', 'd']) {
      test('Terminale ${series.toUpperCase()} voit la séquence, une seule '
          'fois', () async {
        final classKey = ClassKey('terminale', series: series);
        final physics = (await repository.subjectsFor(
          classKey,
        )).singleWhere((s) => s.key == 'physique');
        expect(physics.chapters.map((c) => c.contentId), [_id]);
        final all = await repository.chaptersFor(classKey);
        expect(all.where((c) => c.contentId == _id), hasLength(1));
      });
    }

    for (final classKey in const [
      ClassKey('terminale', series: 'a'),
      ClassKey('terminale'),
      ClassKey('premiere', series: 'c'),
      ClassKey('sixieme'),
    ]) {
      test('$classKey ne la voit pas', () async {
        final subjects = await repository.subjectsFor(classKey);
        expect(subjects.where((s) => s.key == 'physique'), isEmpty);
        final chapters = await repository.chaptersFor(classKey);
        expect(chapters.map((c) => c.contentId), isNot(contains(_id)));
      });
    }
  });

  test('Physique → Module 1 → Séquence 1 (jamais un chapitre)', () async {
    final entry = (await repository.chaptersFor(
      const ClassKey('terminale', series: 'c'),
    )).singleWhere((c) => c.contentId == _id);
    final curriculum = entry.curriculum;
    expect(curriculum.subjectKey, 'physique');
    expect(curriculum.moduleNumber, 1);
    expect(curriculum.moduleTitle, 'Mesures et incertitudes');
    expect(curriculum.sequenceNumber, 1);
    expect(curriculum.isSequence, isTrue);
    expect(curriculum.isUnit, isFalse);
    expect(curriculum.chapterNumber, 1);
    expect(curriculum.chapterTitle, 'Erreurs et incertitudes');
  });

  test('contenu annoncé : 5 leçons, 10 notions, 40 questions, 3 niveaux '
      'de difficulté et d’explication, 14 cartes prévues, 5 jeux', () async {
    final chapter = await pack();
    expect(chapter.isPlayable, isTrue);
    expect(chapter.llmRequired, isFalse);
    expect(chapter.lessons, hasLength(5));
    expect(chapter.concepts, hasLength(10));
    expect(chapter.questions, hasLength(40));
    expect(chapter.questions.where((q) => q.autoScorable), hasLength(35));
    expect(chapter.difficulties.map((d) => d.value), [1, 2, 3]);
    expect(chapter.difficulty(3).label, 'Défi Bac');
    expect(chapter.explanationModes, ExplanationMode.values);
    expect(chapter.games, hasLength(5));
    expect(_json('runtime.json')['learning_card_seeds'], hasLength(14));
    final stats = _json('manifest.json')['stats']! as Map;
    expect(stats['questions'], 40);
    expect(stats['auto_scored_questions'], 35);
    expect(chapter.lesson(1)!.conceptIds, [
      'measurement_range',
      'accuracy_precision',
      'random_systematic_errors',
    ]);
  });

  group('Questions', () {
    test('5 réponses rédigées : jamais notées, jamais une erreur, jamais un '
        'blocage', () async {
      final chapter = await pack();
      final open = chapter.questions.where((q) => !q.autoScorable);
      expect(open.map((q) => q.id), _open);
      for (final question in open) {
        expect(question.type, QuestionType.reasoning);
        expect(question.disabledReason, isNull);
        expect(question.requiresSelfEvaluation, isTrue);
        expect(
          () => const AnswerChecker().grade(
            question,
            const TextResponse('Il peut être fidèle mais peu juste.'),
          ),
          throwsArgumentError,
        );
      }
      // Chaque leçon garde des questions notées à toutes ses difficultés
      // proposées : la progression ne dépend jamais d'une réponse rédigée.
      for (final lesson in chapter.lessons) {
        expect(
          chapter.questions.where(
            (q) => q.lessonNumber == lesson.number && q.autoScorable,
          ),
          hasLength(7),
        );
      }
    });

    test('virgule décimale française acceptée, valeur exacte exigée', () async {
      final chapter = await pack();
      for (final (id, right, wrong) in [
        ('l2_q02', ['10,2', '10.2', ' 10,20 '], ['10,3', '102']),
        ('l2_q03', ['5', '5,0', '5.0'], ['5,2']),
        ('l3_q04', ['0,05', '0.05', '0,050'], ['0,07']),
        ('l3_q05', ['0,1', '0,10'], ['0,14']),
        ('l4_q02', ['0,1'], ['0,05']),
        ('l4_q03', ['0,24'], ['0,12']),
        ('l4_q07', ['0,05'], ['0,025']),
        ('l5_q03', ['0,183702'], ['0,18', '0,2']),
      ]) {
        final question = chapter.question(id)!;
        for (final text in right) {
          expect(grade(question, text), isTrue, reason: '$id « $text »');
        }
        for (final text in wrong) {
          expect(grade(question, text), isFalse, reason: '$id « $text »');
        }
      }
    });

    test('QCM : identifiants stables, retour par option, bonne réponse à '
        'toutes les places selon la tentative', () async {
      final chapter = await pack();
      final mcqs = chapter.questions.where((q) => q.type == QuestionType.mcq);
      expect(mcqs, hasLength(17));
      for (final question in mcqs) {
        final answer = (question.answer as ChoiceAnswer).choice;
        expect(question.choiceFeedback, hasLength(question.choices.length));
        expect(
          const AnswerChecker().grade(question, ChoiceResponse(answer)).correct,
          isTrue,
          reason: question.id,
        );
        final correct = question.choices.indexOf(answer);
        final positions = {
          for (var seed = 0; seed < 24; seed++)
            choiceOrder(
              question.choices.length,
              questionId: question.id,
              attemptKey: 'tentative-$seed',
            ).indexOf(correct),
        };
        expect(positions, {0, 1, 2, 3}, reason: question.id);
        // Même tentative : même ordre.
        expect(
          choiceOrder(4, questionId: question.id, attemptKey: 'x'),
          choiceOrder(4, questionId: question.id, attemptKey: 'x'),
        );
      }
      // Vrai / faux : jamais mélangé, corrigé par valeur.
      final trueFalse = chapter.question('l1_q05')!;
      expect(trueFalse.type, QuestionType.trueFalse);
      expect(
        const AnswerChecker()
            .grade(trueFalse, const BooleanResponse(false))
            .correct,
        isTrue,
      );
    });
  });

  test(
    'anomalies de la source conservées, aucune formule reconstruite',
    () async {
      final chapter = await pack();
      final flags = chapter.validation.flags;
      expect(flags, hasLength(2));
      expect(flags.first.severity, ValidationSeverity.important);
      expect(flags.first.source, contains('page_006.jpg'));
      expect(flags.last.source, contains('page_009.jpg'));
      // Aucune question visée : rien n'est affiché à tort à l'élève.
      expect(flags.every((f) => !f.concernsRuntime), isTrue);
      final report = _json('validation_report.json');
      expect(report['source_quality_flags'], hasLength(2));
      expect(report['non_auto_scored_question_ids'], _open);
      // Les seules relations de type B notées sont celles clairement lues.
      expect(chapter.question('l3_q03')!.answer, isA<ChoiceAnswer>());
    },
  );

  group('Mon Parcours, jeux et Compagnon', () {
    test(
      'cartes : chaque cible et réponse rédigée a sa carte, aucun jeu',
      () async {
        final chapter = await pack();
        final cards = const LearningCardFactory().build(
          chapter,
          classKeys: const [ClassKey('terminale', series: 'c')],
        );
        expect(cards.map((c) => c.id).toSet(), hasLength(cards.length));
        final questionIds = cards.map((c) => c.question?.id).toSet();
        final conceptIds = cards.map((c) => c.conceptId).toSet();
        for (final seed
            in (_json('runtime.json')['learning_card_seeds']! as List)
                .cast<Map<String, Object?>>()) {
          if (seed['question_id'] case final String id) {
            expect(questionIds, contains(id), reason: seed['id'] as String);
          }
          if (seed['concept_id'] case final String id) {
            expect(conceptIds, contains(id), reason: seed['id'] as String);
          }
        }
        expect(questionIds, containsAll(_open));
        expect(
          cards
              .where((c) => _open.contains(c.question?.id))
              .every((c) => c.type == LearningCardType.selfEvaluation),
          isTrue,
        );
        expect(
          cards.map((c) => c.type),
          isNot(contains(LearningCardType.game)),
        );
      },
    );

    test('5 jeux en préparation, jamais jouables', () async {
      final chapter = await pack();
      expect(chapter.games.map((g) => g.id), [
        'precision_lab',
        'error_detective',
        'uncertainty_mixer',
        'confidence_gauge',
        'measurement_report',
      ]);
      for (final game in chapter.games) {
        expect(game.status, GameStatus.draft, reason: game.id);
        expect(game.engine, isNull, reason: game.id);
        expect(game.playable, isFalse, reason: game.id);
      }
    });

    test(
      'Compagnon hors ligne : réponses du pack, honnête hors pack',
      () async {
        final chapter = await pack();
        expect(chapter.companion.unrecognizedLabels, isEmpty);
        expect(chapter.companion.actions, contains(CompanionAction.whyWrong));
        final engine = CompanionEngine(chapter);
        final reply = engine.ask('incertitude de type B');
        expect(reply.concept?.id, 'type_b_uncertainty');
        expect(
          reply.parts.single.text,
          chapter.concepts['type_b_uncertainty']!.explanation(
            ExplanationMode.standard,
          ),
        );
        // « type A » et « type B » ne se confondent pas.
        for (final (question, concept) in [
          ('c’est quoi le type A ?', 'type_a_uncertainty'),
          ('explique le type B', 'type_b_uncertainty'),
          ('somme quadratique', 'combined_uncertainty'),
          ('justesse et fidélité', 'accuracy_precision'),
        ]) {
          expect(engine.ask(question).concept?.id, concept, reason: question);
        }
        final unknown = engine.ask('photosynthèse des plantes vertes');
        expect(unknown.gap, CompanionGap.unknownTopic);
        expect(unknown.parts, isEmpty);
      },
    );
  });

  test('bundle draft : relu comme le pack embarqué, moteur v2', () async {
    final documents = readPackDocuments(Directory(_dir));
    final encoded = encodeBundle(
      buildPackBundle(
        id: _id,
        version: 1,
        classKeys: const ['terminale-c-d'],
        documents: documents,
      ),
    );
    final bundle = PackBundle.tryParse(utf8.decode(encoded.bytes))!;
    final remote = const ContentPackParser().parse(rawFromBundle(bundle));
    expect(remote.isPlayable, isTrue);
    expect(remote.questions.where((q) => q.autoScorable), hasLength(35));
    expect(remote.curriculum.sequenceNumber, 1);
    expect(documents['manifest']!['minimum_engine_version'], 2);
    expect(documents['manifest']!['publication_status'], 'draft');
    expect(2, lessThanOrEqualTo(kContentEngineVersion));
  });
}
