import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/content_engine/data/content_pack_parser.dart';
import 'package:intellia237/features/content_engine/data/content_pack_repository.dart';
import 'package:intellia237/features/content_engine/domain/chapter.dart';
import 'package:intellia237/features/content_engine/domain/question.dart';
import 'package:intellia237/features/content_engine/domain/short_text.dart';
import 'package:intellia237/features/content_engine/engine/answer_checker.dart';
import 'package:intellia237/features/content_engine/presentation/widgets/answer_input.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

import 'pack_fixture.dart';

/// Réponses de langue et expressions mathématiques : deux saisies, deux
/// corrections, jamais confondues. Cas réel observé sur Android : « calm ___ »
/// (anglais, M1U2) s'affichait avec « Par exemple y=x+1 » et les touches
/// = √ ² −.
const _u1Dir = 'assets/content/terminale/anglais/m1_u1_applying_for_a_passport';
const _u2Dir =
    'assets/content/terminale/anglais/m1_u2_discussing_recreational_activities';
const _ch03Dir =
    'assets/content/terminale_d/mathematiques/ch03_fonctions_numeriques';

RawContentPack _raw(String directory, {Map<String, Object?>? runtime}) =>
    RawContentPack(
      directory: directory,
      manifest: readPackJson('manifest.json', directory: directory),
      source: readPackJson('source.json', directory: directory),
      pedagogy: readPackJson('pedagogy.json', directory: directory),
      runtime: runtime ?? readPackJson('runtime.json', directory: directory),
      validation: readPackJson('validation_report.json', directory: directory),
    );

Chapter _chapter(String directory, {Map<String, Object?>? runtime}) =>
    const ContentPackParser().parse(_raw(directory, runtime: runtime));

bool _grade(Question question, String text) =>
    const AnswerChecker().grade(question, TextResponse(text)).correct;

/// Question [id] du runtime de [directory], modifiable.
Map<String, Object?> _runtimeWith(
  String directory,
  String id,
  void Function(Map<String, Object?> question) change,
) {
  final runtime = deepCopy(readPackJson('runtime.json', directory: directory));
  final question =
      ((runtime['question_bank'] ?? runtime['questions'])! as List).firstWhere(
            (q) => (q as Map)['id'] == id,
          )
          as Map<String, Object?>;
  change(question);
  return runtime;
}

void main() {
  final u1 = _chapter(_u1Dir);
  final u2 = _chapter(_u2Dir);
  final ch03 = _chapter(_ch03Dir);

  group('anglais : des réponses de texte', () {
    for (final (id, prompt, answer, wrong) in [
      (
        'l4_q04',
        "Complete: 'You really need to learn to calm ___.'",
        'down',
        'out',
      ),
      (
        'l4_q05',
        "Complete: 'I came ___ this wonderful app.'",
        'across',
        'through',
      ),
      (
        'l4_q06',
        "Complete: 'I need to figure ___ how to complete my work.'",
        'out',
        'down',
      ),
    ]) {
      test('$id « $answer » : short_text, noté, corrigé exactement', () {
        final question = u2.question(id)!;
        expect(question.prompt, prompt);
        expect(question.type, QuestionType.shortText);
        expect(question.answer, isA<ShortTextAnswer>());
        expect(question.autoScorable, isTrue);
        expect(_grade(question, answer), isTrue);
        expect(_grade(question, answer.toUpperCase()), isTrue);
        expect(
          _grade(
            question,
            ' ${answer[0].toUpperCase()}'
            '${answer.substring(1)} ',
          ),
          isTrue,
        );
        expect(_grade(question, '$answer.'), isTrue);
        expect(_grade(question, wrong), isFalse);
        expect(_grade(question, 'calm $answer'), isFalse);
      });
    }

    test('M1U1, groupes verbaux au passif : short_text', () {
      for (final (id, answer) in [
        ('l5_q02', 'were completed'),
        ('l5_q03', 'be signed'),
        ('l5_q04', 'be made'),
        ('l5_q05', 'was opposed'),
      ]) {
        final question = u1.question(id)!;
        expect(question.type, QuestionType.shortText, reason: id);
        expect(_grade(question, answer), isTrue, reason: id);
        expect(_grade(question, '  ${answer.toUpperCase()}  '), isTrue);
        expect(_grade(question, answer.split(' ').last), isFalse, reason: id);
      }
    });
  });

  group('normalisation prudente, jamais floue', () {
    test('espaces, casse, apostrophes et ponctuation autour', () {
      expect(normalizeShortText('  Calm   Down. '), 'calm down');
      expect(normalizeShortText('don’t'), "don't");
      expect(normalizeShortText('« down »'), 'down');
      expect(matchesShortText(['down'], 'Down'), isTrue);
      expect(matchesShortText(['down'], 'dow'), isFalse);
      expect(matchesShortText(['down'], 'downn'), isFalse);
      expect(matchesShortText(['down'], ''), isFalse);
      expect(matchesShortText(['café'], 'cafe'), isFalse);
    });

    test('les variantes valides viennent du pack (accepted_answers)', () {
      final chapter = _chapter(
        _u2Dir,
        runtime: _runtimeWith(_u2Dir, 'l4_q04', (q) {
          q['answer'] = 'colour';
          q['accepted_answers'] = ['color'];
        }),
      );
      final question = chapter.question('l4_q04')!;
      expect((question.answer as ShortTextAnswer).accepted, [
        'colour',
        'color',
      ]);
      expect(_grade(question, 'colour'), isTrue);
      expect(_grade(question, 'Color'), isTrue);
      expect(_grade(question, 'colr'), isFalse);
    });

    test('sans réponse, la question n’est pas notée', () {
      final chapter = _chapter(
        _u2Dir,
        runtime: _runtimeWith(_u2Dir, 'l4_q04', (q) => q.remove('answer')),
      );
      expect(chapter.question('l4_q04')!.autoScorable, isFalse);
    });
  });

  group('validation des packs', () {
    test('un mot déclaré « expression » : lu comme du texte, et signalé', () {
      final chapter = _chapter(
        _u2Dir,
        runtime: _runtimeWith(
          _u2Dir,
          'l4_q04',
          (q) => q['type'] = 'expression',
        ),
      );
      final question = chapter.question('l4_q04')!;
      expect(question.answer, isA<ShortTextAnswer>());
      expect(_grade(question, 'down'), isTrue);
      expect(
        chapter.issues.where((i) => i.code == 'question_expression_is_text'),
        hasLength(1),
      );
    });

    test('une vraie expression reste mathématique, sans signalement', () {
      expect(
        ch03.issues.map((i) => i.code),
        isNot(contains('question_expression_is_text')),
      );
      final question = ch03.question('l3_m1')!;
      expect(question.answer, isA<ExpressionAnswer>());
      expect(_grade(question, 'y = x + 1'), isTrue);
      expect(_grade(question, 'y=x−1'), isFalse);
    });

    test('tous les packs : aucune réponse de langue sous expression', () async {
      final repository = ContentPackRepository(source: DiskContentPackSource());
      var expressions = 0;
      for (final entry in await repository.catalog()) {
        final chapter = await repository.chapter(entry.contentId);
        expect(
          chapter.issues.map((i) => i.code),
          isNot(contains('question_expression_is_text')),
          reason: entry.contentId,
        );
        for (final question in chapter.questions) {
          if (question.answer case ExpressionAnswer(:final text)) {
            expressions++;
            expect(looksLikeWords(text), isFalse, reason: question.id);
          }
        }
      }
      // ch03 : 5 expressions déclarées + 1 formule de raisonnement.
      expect(expressions, 6);
    });
  });

  group('saisie', () {
    Future<StudentResponse? Function()> pump(
      WidgetTester tester,
      Question question,
    ) async {
      StudentResponse? response;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Scaffold(
            body: AnswerInput(
              question: question,
              onChanged: (value) => response = value,
            ),
          ),
        ),
      );
      return () => response;
    }

    for (final id in ['l4_q04', 'l4_q05', 'l4_q06']) {
      testWidgets('$id : champ texte normal, aucun symbole mathématique', (
        tester,
      ) async {
        final question = u2.question(id)!;
        final response = await pump(tester, question);
        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.keyboardType, TextInputType.text);
        expect(field.textCapitalization, TextCapitalization.none);
        expect(field.autocorrect, isFalse);
        expect(field.style?.fontFamily, isNot(contains('Math')));
        expect(field.decoration?.hintText, 'Écris ta réponse');
        expect(find.textContaining('y=x+1'), findsNothing);
        expect(find.byType(ActionChip), findsNothing);
        for (final symbol in ['=', '√', '²', '−']) {
          expect(find.text(symbol), findsNothing, reason: symbol);
        }
        final expected = (question.answer as ShortTextAnswer).display;
        await tester.enterText(find.byType(TextField), expected);
        expect(
          const AnswerChecker().grade(question, response()!).correct,
          isTrue,
        );
      });
    }

    testWidgets('maths : l’expression garde ses touches et son exemple', (
      tester,
    ) async {
      final question = ch03.question('l3_m1')!;
      final response = await pump(tester, question);
      expect(
        tester.widget<TextField>(find.byType(TextField)).decoration?.hintText,
        'Par exemple y=x+1',
      );
      for (final symbol in ['=', '√', '²', '−']) {
        expect(find.widgetWithText(ActionChip, symbol), findsOneWidget);
      }
      await tester.enterText(find.byType(TextField), 'y=x');
      await tester.tap(find.widgetWithText(ActionChip, '−'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'y=x+1');
      expect(
        const AnswerChecker().grade(question, response()!).correct,
        isTrue,
      );
    });
  });
}
