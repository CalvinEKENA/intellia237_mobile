import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/quiz/application/quiz_providers.dart';
import 'package:intellia237/features/quiz/domain/quiz_attempt_summary.dart';
import 'package:intellia237/features/quiz/domain/quiz_result_payload.dart';
import 'package:intellia237/features/quiz/presentation/quiz_result_screen.dart';

QuizResultPayload _result({int score = 3}) => QuizResultPayload(
  quizId: 'q1',
  quizTitle: 'Équations',
  subjectLabel: 'Maths',
  score: score,
  maxScore: 5,
  pointsAwarded: 12,
  corrections: const [],
);

QuizAttemptSummary _attempt({required int score, String quizId = 'q1'}) =>
    QuizAttemptSummary(
      quizId: quizId,
      quizTitle: 'Équations',
      subjectLabel: 'Maths',
      score: score,
      maxScore: 5,
      pointsAwarded: 10,
      submittedAt: DateTime(2026, 7, 10),
    );

Future<void> _pump(
  WidgetTester tester, {
  required QuizResultPayload result,
  required List<QuizAttemptSummary> history,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        quizAttemptHistoryProvider.overrideWith((ref) async => history),
      ],
      child: MaterialApp(home: QuizResultScreen(result: result)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'score en hausse vs la tentative précédente : badge « +20 % » sobre',
    (tester) async {
      await _pump(
        tester,
        result: _result(score: 3),
        // Historique frais : la tentative courante (3/5) en tête,
        // la précédente (2/5) ensuite.
        history: [_attempt(score: 3), _attempt(score: 2)],
      );

      expect(
        find.textContaining('+20 % par rapport à ta dernière tentative'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('score en baisse : aucun badge (jamais de fausse fierté)', (
    tester,
  ) async {
    await _pump(
      tester,
      result: _result(score: 2),
      history: [_attempt(score: 2), _attempt(score: 4)],
    );

    expect(find.textContaining('par rapport à ta dernière'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('première tentative du quiz : aucun badge', (tester) async {
    await _pump(
      tester,
      result: _result(score: 3),
      history: [_attempt(score: 3)],
    );

    expect(find.textContaining('par rapport à ta dernière'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'écriture serveur en retard : la tête de l\'historique sert de référence',
    (tester) async {
      await _pump(
        tester,
        // 3/5 (60 %) : sous le seuil des confettis, le badge reste testable.
        result: _result(score: 3),
        // La tentative courante (3/5) n'est pas encore dans l'historique :
        // la tête (1/5) est bien la précédente → +40 %.
        history: [_attempt(score: 1)],
      );

      expect(
        find.textContaining('+40 % par rapport à ta dernière tentative'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('autre quiz dans l\'historique : ignoré', (tester) async {
    await _pump(
      tester,
      result: _result(score: 3),
      history: [
        _attempt(score: 3),
        _attempt(score: 1, quizId: 'autre'),
      ],
    );

    expect(find.textContaining('par rapport à ta dernière'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
