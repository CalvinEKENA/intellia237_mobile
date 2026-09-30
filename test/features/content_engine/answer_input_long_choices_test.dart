import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/content_engine/domain/question.dart';
import 'package:intellia237/features/content_engine/engine/answer_checker.dart';
import 'package:intellia237/features/content_engine/presentation/widgets/answer_input.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

import '../../support/intellia_fonts.dart';

/// Propositions longues d'un QCM : jamais coupées. Cas réel, anglais
/// Terminale, unité 1 : « The person who solemnises the marriage » était
/// tronquée dans sa pastille sur un téléphone.
void main() {
  setUpAll(loadIntelliaFonts);

  const long = 'The person who solemnises the marriage';
  const celebrant = Question(
    id: 'q-celebrant',
    lessonNumber: 1,
    difficulty: 1,
    type: QuestionType.mcq,
    rawType: 'mcq',
    prompt: "In the unit's formal-notice vocabulary, who is the 'celebrant'?",
    answer: ChoiceAnswer(AnswerAtom.text(long)),
    choices: [
      AnswerAtom.text(long),
      AnswerAtom.text('The bridegroom'),
      AnswerAtom.text('The bride'),
      AnswerAtom.text('The document itself'),
    ],
  );

  const short = Question(
    id: 'q-short',
    lessonNumber: 1,
    difficulty: 1,
    type: QuestionType.mcq,
    rawType: 'mcq',
    prompt: 'PGCD(36, 60) ?',
    answer: ChoiceAnswer(AnswerAtom.integer(12)),
    choices: [
      AnswerAtom.integer(12),
      AnswerAtom.integer(15),
      AnswerAtom.integer(18),
    ],
  );

  StudentResponse? response;
  setUp(() => response = null);

  Future<void> pump(
    WidgetTester tester,
    Question question, {
    double width = 360,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 800),
            textScaler: TextScaler.linear(scale),
          ),
          child: Scaffold(
            body: Padding(
              // Marges de la carte de question du quiz.
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: AnswerInput(
                question: question,
                attemptKey: 'essai-1',
                onChanged: (value) => response = value,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Chaque libellé est affiché en entier : aucune ligne perdue, aucun
  /// débordement hors de son option.
  void expectWhole(WidgetTester tester, String label) {
    final text = find.text(label);
    expect(text, findsOneWidget, reason: label);
    final paragraph = tester.renderObject<RenderParagraph>(text);
    expect(paragraph.didExceedMaxLines, isFalse, reason: label);
    final option = find.ancestor(
      of: text,
      matching: find.byKey(ValueKey('answer-choice-$label')),
    );
    final bounds = tester.getRect(option);
    final rect = tester.getRect(text);
    expect(
      bounds.left <= rect.left && rect.right <= bounds.right,
      isTrue,
      reason: '$label : $rect hors de $bounds',
    );
  }

  for (final (width, scale) in [(320.0, 1.0), (360.0, 1.0), (412.0, 1.3)]) {
    testWidgets('proposition longue à ${width.toInt()} px, texte '
        '×$scale : entière, sur plusieurs lignes', (tester) async {
      await pump(tester, celebrant, width: width, scale: scale);
      expect(find.byType(ChoiceChip), findsNothing);
      for (final choice in celebrant.choices) {
        expectWhole(tester, choice.display);
      }
      // Plusieurs lignes plutôt qu'une coupure.
      expect(
        tester.getSize(find.text(long)).height,
        greaterThan(tester.getSize(find.text('The bride')).height),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('une option longue se choisit comme une pastille', (
    tester,
  ) async {
    await pump(tester, celebrant);
    await tester.tap(find.byKey(const ValueKey('answer-choice-$long')));
    await tester.pump();
    expect(response, isA<ChoiceResponse>());
    expect((response! as ChoiceResponse).choice, const AnswerAtom.text(long));
    expect(
      tester.getSemantics(find.byKey(const ValueKey('answer-choice-$long'))),
      isSemantics(isSelected: true, isButton: true),
    );
  });

  testWidgets('propositions courtes : les pastilles restent', (tester) async {
    await pump(tester, short);
    expect(find.byType(ChoiceChip), findsNWidgets(3));
  });
}
