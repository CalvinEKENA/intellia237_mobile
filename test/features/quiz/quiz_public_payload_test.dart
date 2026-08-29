import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/quiz/data/firestore_quiz_repository.dart';
import 'package:intellia237/features/quiz/domain/quiz_attempt.dart';
import 'package:intellia237/features/quiz/domain/quiz_mode.dart';

void main() {
  test('le payload public ne peuple jamais un corrigé côté élève', () {
    final quiz = parsePublicQuizPayload(<String, dynamic>{
      'id': 'quiz-a',
      'title': 'Équations',
      'subjectId': 'math',
      'subjectLabel': 'Mathématiques',
      'description': 'Entraînement',
      'difficultyLabel': 'Intermédiaire',
      'mode': 'training',
      'questionCount': 1,
      'questions': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'q1',
          'type': 'qcm',
          'prompt': '2 + 2',
          'options': <String>['4', '5'],
          'pointsReward': 10,
          // Même si un backend défectueux ajoutait ces champs, le parseur
          // étudiant les ignore explicitement.
          'correctOptionIndex': 0,
          'acceptedAnswers': <String>['4'],
          'explanation': 'La réponse est 4.',
        },
      ],
    });

    expect(quiz.mode, QuizMode.training);
    expect(quiz.questionCount, 1);
    expect(quiz.questions.single.correctOptionIndex, isNull);
    expect(quiz.questions.single.correctBooleanValue, isNull);
    expect(quiz.questions.single.acceptedAnswers, isEmpty);
    expect(quiz.questions.single.explanation, isEmpty);
  });

  test(
    'un résumé de hub conserve le nombre sans télécharger les questions',
    () {
      final quiz = parsePublicQuizPayload(<String, dynamic>{
        'id': 'quiz-a',
        'title': 'Équations',
        'questionCount': 12,
        'mode': 'exam',
      });

      expect(quiz.mode, QuizMode.exam);
      expect(quiz.questions, isEmpty);
      expect(quiz.questionCount, 12);
    },
  );

  test('le mode examen ne vérifie jamais question par question', () {
    expect(
      shouldCheckQuizAnswerImmediately(
        mode: QuizMode.exam,
        answer: '0',
        checkedAnswer: null,
      ),
      isFalse,
    );
    expect(
      shouldCheckQuizAnswerImmediately(
        mode: QuizMode.training,
        answer: '0',
        checkedAnswer: null,
      ),
      isTrue,
    );
    expect(
      shouldCheckQuizAnswerImmediately(
        mode: QuizMode.training,
        answer: '0',
        checkedAnswer: '0',
      ),
      isFalse,
    );
  });

  test('une nouvelle tentative réutilise son identifiant lors des retries', () {
    final attempt = QuizAttempt(
      quizId: 'quiz-a',
      clientAttemptId: 'attempt_12345678',
      answersByQuestion: const <String, String>{'q1': '0'},
      startedAt: DateTime.utc(2026, 7, 16),
    );

    expect(attempt.toCallablePayload()['clientAttemptId'], 'attempt_12345678');
    expect(attempt.toCallablePayload()['clientAttemptId'], 'attempt_12345678');
  });
}
