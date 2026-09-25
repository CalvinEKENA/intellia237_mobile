import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intellia237/core/academics/choice_order.dart';
import 'package:intellia237/features/quiz/domain/quiz_question.dart';
import 'package:intellia237/features/quiz/domain/quiz_type.dart';
import 'package:intellia237/features/quiz/presentation/widgets/qcm_question_card.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

/// Quiz de 6e : la lettre suit la place à l'écran, la réponse transmise
/// reste l'index d'origine, et l'ordre ne bouge pas pendant la tentative.
void main() {
  const question = QuizQuestion(
    id: 'qcm-capitale',
    type: QuizQuestionType.qcm,
    prompt: 'Capitale du Cameroun ?',
    options: ['Yaoundé', 'Douala', 'Garoua', 'Bafoussam'],
    correctOptionIndex: 0,
    explanation: '',
    pointsReward: 5,
  );

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pump(
    WidgetTester tester, {
    required String attemptKey,
    int? selected,
    ValueChanged<int>? onSelected,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: QcmQuestionCard(
              question: question,
              selectedIndex: selected,
              onSelected: onSelected ?? (_) {},
              attemptKey: attemptKey,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  List<String> shown(WidgetTester tester) => [...question.options]
    ..sort(
      (a, b) => tester
          .getTopLeft(find.text(a))
          .dy
          .compareTo(tester.getTopLeft(find.text(b)).dy),
    );

  testWidgets('ordre de la tentative, stable après sélection ; index '
      'd’origine transmis', (tester) async {
    int? chosen;
    await pump(tester, attemptKey: 'essai-1', onSelected: (i) => chosen = i);
    final order = choiceOrder(
      4,
      questionId: question.id,
      attemptKey: 'essai-1',
    );
    final expected = [for (final i in order) question.options[i]];
    expect(shown(tester), expected);
    expect(shown(tester).first, isNot('Yaoundé'));

    await tester.tap(find.text('Yaoundé'));
    expect(chosen, 0);
    await pump(tester, attemptKey: 'essai-1', selected: chosen);
    expect(shown(tester), expected);
  });

  testWidgets('la lettre A désigne la première proposition affichée', (
    tester,
  ) async {
    await pump(tester, attemptKey: 'essai-1');
    final first = shown(tester).first;
    final letterA = tester.getCenter(find.text('A')).dy;
    expect(
      tester.getCenter(find.text(first)).dy,
      moreOrLessEquals(letterA, epsilon: 24),
    );
  });
}
