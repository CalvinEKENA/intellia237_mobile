import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/core/academics/choice_order.dart';
import 'package:intellia237/features/content_engine/domain/question.dart';
import 'package:intellia237/features/content_engine/engine/answer_checker.dart';
import 'package:intellia237/features/content_engine/presentation/widgets/answer_input.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

/// QCM de la Content Engine : ordre mélangé, stable pendant la tentative,
/// correction par valeur quelle que soit la place à l'écran.
void main() {
  const atoms = [
    AnswerAtom.integer(12),
    AnswerAtom.integer(15),
    AnswerAtom.integer(18),
    AnswerAtom.integer(21),
  ];

  // La bonne réponse est écrite en premier dans le pack, comme souvent.
  const mcq = Question(
    id: 'q-mcq',
    lessonNumber: 1,
    difficulty: 1,
    type: QuestionType.mcq,
    rawType: 'mcq',
    prompt: 'PGCD(36, 60) ?',
    answer: ChoiceAnswer(AnswerAtom.integer(12)),
    choices: atoms,
  );

  // Un ensemble de valeurs ne peut pas être constant (== redéfini).
  final multi = Question(
    id: 'q-multi',
    lessonNumber: 1,
    difficulty: 2,
    type: QuestionType.multiSelect,
    rawType: 'multi_select',
    prompt: 'Diviseurs de 36 ?',
    answer: MultiChoiceAnswer({
      const AnswerAtom.integer(12),
      const AnswerAtom.integer(18),
    }),
    choices: atoms,
  );

  StudentResponse? response;

  Future<void> pump(
    WidgetTester tester,
    Question question, {
    required String attemptKey,
    GradeResult? grade,
  }) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: Scaffold(
        body: AnswerInput(
          question: question,
          attemptKey: attemptKey,
          enabled: grade == null,
          grade: grade,
          onChanged: (value) => response = value,
        ),
      ),
    ),
  );

  List<String> shown(WidgetTester tester) => [
    for (final chip in tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)))
      (chip.key! as ValueKey<String>).value.replaceFirst('answer-choice-', ''),
  ];

  setUp(() => response = null);

  testWidgets('la bonne réponse écrite en premier n’est pas affichée en A', (
    tester,
  ) async {
    await pump(tester, mcq, attemptKey: 'essai-1');
    // choiceOrder(4, 'q-mcq', 'essai-1') == [2, 3, 0, 1]
    expect(shown(tester), ['18', '21', '12', '15']);
    expect(shown(tester).first, isNot('12'));
  });

  testWidgets('même tentative : ordre inchangé après choix, reconstruction '
      'et affichage de la correction', (tester) async {
    await pump(tester, mcq, attemptKey: 'essai-1');
    final before = shown(tester);
    await tester.tap(find.text('21'));
    await tester.pump();
    expect(shown(tester), before);
    final grade = const AnswerChecker().grade(mcq, response!);
    expect(grade.correct, isFalse);
    await pump(tester, mcq, attemptKey: 'essai-1', grade: grade);
    expect(shown(tester), before);
  });

  testWidgets('nouvelle tentative : un autre ordre', (tester) async {
    await pump(tester, mcq, attemptKey: 'essai-1');
    final first = shown(tester);
    await pump(tester, mcq, attemptKey: 'essai-2');
    expect(shown(tester), isNot(first));
    expect(shown(tester).toSet(), first.toSet());
  });

  testWidgets('correction exacte quelle que soit la position', (tester) async {
    for (final key in ['essai-1', 'essai-2', 'essai-3']) {
      await pump(tester, mcq, attemptKey: key);
      await tester.tap(find.text('12'));
      await tester.pump();
      expect(const AnswerChecker().grade(mcq, response!).correct, isTrue);
      await tester.tap(find.text('15'));
      await tester.pump();
      expect(const AnswerChecker().grade(mcq, response!).correct, isFalse);
    }
  });

  testWidgets('choix multiples : corrigés par valeurs après mélange', (
    tester,
  ) async {
    await pump(tester, multi, attemptKey: 'essai-1');
    final order = choiceOrder(4, questionId: 'q-multi', attemptKey: 'essai-1');
    expect(shown(tester), [for (final i in order) atoms[i].display]);
    expect(shown(tester), isNot(['12', '15', '18', '21']));
    await tester.tap(find.text('18'));
    await tester.tap(find.text('12'));
    await tester.pump();
    expect(const AnswerChecker().grade(multi, response!).correct, isTrue);
    await tester.tap(find.text('21'));
    await tester.pump();
    expect(const AnswerChecker().grade(multi, response!).correct, isFalse);
  });
}
