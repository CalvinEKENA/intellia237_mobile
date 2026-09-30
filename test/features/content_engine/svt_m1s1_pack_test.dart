import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/core/academics/choice_order.dart';
import 'package:intellia237/core/academics/class_key.dart';
import 'package:intellia237/features/content_engine/application/subject_journey.dart';
import 'package:intellia237/features/content_engine/data/content_pack_repository.dart';
import 'package:intellia237/features/content_engine/domain/chapter.dart';
import 'package:intellia237/features/content_engine/domain/content_issue.dart';
import 'package:intellia237/features/content_engine/domain/mastery.dart';
import 'package:intellia237/features/content_engine/domain/question.dart';
import 'package:intellia237/features/content_engine/engine/answer_checker.dart';
import 'package:intellia237/features/quiz/domain/pack_quiz.dart';

import 'pack_fixture.dart';

const _directory =
    'assets/content/terminale_d/svt/m1_s1_les_echanges_cellulaires';
const _id = 'svt_terminale_d_m1_s1_les_echanges_cellulaires';

Map<String, Object?> _json(String name) =>
    readPackJson(name, directory: _directory);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentPackRepository repository;
  setUp(() {
    repository = ContentPackRepository(source: DiskContentPackSource());
  });
  Future<Chapter> chapter() => repository.chapter(_id);

  test('S1 est embarquée hors ligne et réservée à Terminale D', () async {
    final embedded = ContentPackRepository(source: AssetContentPackSource());
    final svt = (await embedded.subjectsFor(
      const ClassKey('terminale', series: 'd'),
    )).singleWhere((s) => s.key == 'svt');
    expect(svt.chapters.map((c) => c.contentId), [_id]);
    final pack = await embedded.chapter(_id);
    expect(pack.isPlayable, isTrue);
    expect(pack.llmRequired, isFalse);
    expect(pack.curriculum.chapterTitle, 'Les échanges cellulaires');
    expect(pack.curriculum.sequenceNumber, 1);
    for (final audience in const [
      ClassKey('terminale', series: 'c'),
      ClassKey('terminale', series: 'a'),
      ClassKey('premiere', series: 'd'),
    ]) {
      expect(
        (await embedded.subjectsFor(audience)).map((s) => s.key),
        isNot(contains('svt')),
      );
    }
  });

  test('le parseur conserve les 46 activités sans warning ni erreur', () async {
    final pack = await chapter();
    expect(pack.lessons, hasLength(5));
    expect(pack.concepts, hasLength(14));
    expect(pack.questions, hasLength(46));
    expect(pack.questions.where((q) => q.autoScorable), hasLength(38));
    expect(
      pack.issues.where((i) => i.severity != ContentIssueSeverity.info),
      isEmpty,
      reason: pack.issues.join('\n'),
    );
    expect(pack.integrationConcepts.single.id, 'sequence_integration');
    for (final question in pack.questions) {
      expect(question.explanation, isNotEmpty, reason: question.id);
      expect(question.sourceAnchor, matches(r'^page_\d{3}\.jpg$'));
      expect(question.isPracticeReady, isTrue, reason: question.id);
    }
  });

  test('les réponses rédigées restent hors des quiz notés', () async {
    final pack = await chapter();
    final subjects = await repository.subjectsFor(
      const ClassKey('terminale', series: 'd'),
    );
    final subject = subjects.singleWhere((s) => s.key == 'svt');
    final journey = SubjectJourney.build(subject, {
      _id: pack,
    }, LearnerContentSnapshot.empty);
    final catalog = PackQuizCatalog.fromJourneys([journey]);
    final quiz = catalog.setById('seq:$_id')!;
    expect(quiz.pool, hasLength(38));
    expect(quiz.pool.every((item) => item.question.autoScorable), isTrue);
    final plan = DeterministicQuizBuilder.build(
      set: quiz,
      mode: PackQuizMode.evaluation,
    );
    expect(plan.items, hasLength(10));
    expect(plan.distribution, {1: 3, 2: 4, 3: 3});
    for (final question in pack.questions.where((q) => !q.autoScore)) {
      expect(question.requiresSelfEvaluation, isTrue);
      expect(question.expectedPoints, isNotEmpty);
      expect(
        () => const AnswerChecker().grade(
          question,
          TextResponse(question.modelAnswer!),
        ),
        throwsArgumentError,
      );
      expect(quiz.pool.map((item) => item.id), isNot(contains(question.id)));
    }
  });

  test(
    'les nombres sources acceptent la virgule et refusent unité/signe faux',
    () async {
      final pack = await chapter();
      const checker = AnswerChecker();
      for (final (number, accepted, wrong) in [
        (14, ['300', '300,0'], ['27', '-300']),
        (15, ['9,84', '9.840'], ['984', '0,984']),
        (16, ['75', '75,0'], ['0,75', '0,4']),
        (18, ['1,6', '1.60'], ['-1,6', '31,6']),
      ]) {
        final q = pack.question('svt_s1_q$number')!;
        for (final value in accepted) {
          expect(checker.grade(q, TextResponse(value)).correct, isTrue);
        }
        for (final value in wrong) {
          expect(checker.grade(q, TextResponse(value)).correct, isFalse);
        }
      }
    },
  );

  test(
    'les mots SVT normalisent accents, casse et apostrophes sans synonymes faux',
    () async {
      final pack = await chapter();
      const checker = AnswerChecker();
      for (final (id, answer, wrong) in [
        ('svt_s1_q03', '  PLASMOLYSÉE  ', 'turgescence'),
        ('svt_s1_q04', 'deplasmolyse', 'plasmolyse'),
        ('svt_s1_q06', 'HEMOLYSE', 'osmose'),
        ('svt_s1_q30', "l'exocytose", 'endocytose'),
      ]) {
        final q = pack.question(id)!;
        expect(q.answer, isA<ShortTextAnswer>());
        expect(checker.grade(q, TextResponse(answer)).correct, isTrue);
        expect(checker.grade(q, TextResponse(wrong)).correct, isFalse);
      }
    },
  );

  test(
    'les QCM restent justes après mélange et expliquent chaque distracteur',
    () async {
      final pack = await chapter();
      for (final q in pack.questions.where((q) => q.type == QuestionType.mcq)) {
        final answer = (q.answer as ChoiceAnswer).choice;
        final feedbacks = <String>{};
        for (final index in choiceOrder(
          q.choices.length,
          questionId: q.id,
          attemptKey: 'svt-source-review',
        )) {
          final choice = q.choices[index];
          expect(
            const AnswerChecker().grade(q, ChoiceResponse(choice)).correct,
            choice == answer,
            reason: '${q.id}: $choice',
          );
          expect(q.choiceFeedback[choice], isNotEmpty);
          feedbacks.add(q.choiceFeedback[choice]!);
        }
        expect(feedbacks.length, q.choices.length, reason: q.id);
      }
    },
  );

  test(
    'les 79 consignes sourcées distinguent inconnues et réponses corrigées',
    () {
      final source = _json('source.json');
      final groups = (source['exercise_inventory']! as List).cast<Map>();
      final tasks = (source['source_tasks']! as List).cast<Map>();
      expect(groups, hasLength(29));
      expect(tasks, hasLength(79));
      expect(tasks.map((t) => t['id']).toSet().length, tasks.length);
      expect(
        tasks.expand((t) => (t['printed_pages'] as List).cast<int>()).toSet(),
        containsAll([15, 16, 17, 18, 19, 20, 21]),
      );
      for (final item in tasks) {
        expect(item['images'], isNotEmpty, reason: item['id'].toString());
        expect(item['justification'], isNotEmpty);
        if (item['correct_answer_or_model'] == null) {
          expect(item['classification'], 'NEEDS_SOURCE_REVIEW');
          expect(item['runtime_action'], isNotEmpty);
        }
      }
      for (final id in ['QRO6.c', 'B1.4a', 'B1.3a', 'C1.4', 'A6']) {
        final item = tasks.singleWhere((t) => t['id'] == id);
        expect(item['correct_answer_or_model'], isNull, reason: id);
      }
      final table =
          (source['verified_experimental_data'] as Map)['chou_rouge'] as Map;
      expect(table['plasmolysed_per_100'], [8, 75, 95, 100, 100]);
      expect(table['plasmolysed_per_100'], isNot(contains(50)));
    },
  );

  test('les empreintes du manifeste correspondent aux fichiers canoniques', () {
    final hashes = _json('manifest.json')['sha256']! as Map;
    expect(hashes, hasLength(4));
    for (final entry in hashes.entries) {
      final file = File('$_directory/${entry.key}');
      expect(sha256.convert(file.readAsBytesSync()).toString(), entry.value);
    }
  });
}
