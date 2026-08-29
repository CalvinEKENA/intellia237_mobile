import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/quiz/domain/quiz_result_payload.dart';

void main() {
  test('lit les anciennes clés xp et expose le modèle canonique points', () {
    final payload = QuizResultPayload.fromMap({
      'quizId': 'quiz-legacy',
      'xpAwarded': 25,
      'corrections': [
        {'questionId': 'q1', 'isCorrect': true, 'xpReward': 25},
      ],
    });

    expect(payload.pointsAwarded, 25);
    expect(payload.corrections.single.pointsReward, 25);
    expect(
      payload.corrections.single.toMap(),
      containsPair('pointsReward', 25),
    );
    expect(payload.corrections.single.toMap(), isNot(contains('xpReward')));
  });

  test('préfère les nouvelles clés points quand les deux formats existent', () {
    final payload = QuizResultPayload.fromMap({
      'pointsAwarded': 40,
      'xpAwarded': 10,
      'corrections': [
        {'pointsReward': 20, 'xpReward': 5},
      ],
    });

    expect(payload.pointsAwarded, 40);
    expect(payload.corrections.single.pointsReward, 20);
  });
}
