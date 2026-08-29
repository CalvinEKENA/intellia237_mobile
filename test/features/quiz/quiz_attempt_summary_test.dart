import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/quiz/domain/quiz_attempt_summary.dart';

void main() {
  test('projette uniquement le résumé validé d’une tentative', () {
    final submittedAt = DateTime.utc(2026, 7, 16, 8, 30);
    final summary = QuizAttemptSummary.fromFirestore({
      'quizId': 'quiz-1',
      'quizTitle': 'Fonctions numériques',
      'subjectLabel': 'Mathématiques',
      'score': 7,
      'maxScore': 10,
      'pointsAwarded': 35,
      'createdAt': Timestamp.fromDate(submittedAt),
      // Ces champs existent sur le document serveur, mais la projection UI
      // ne les expose volontairement pas.
      'answersByQuestion': {'question-1': 'réponse privée'},
      'corrections': [
        {'correctAnswer': 'corrigé privé'},
      ],
    });

    expect(summary.quizId, 'quiz-1');
    expect(summary.score, 7);
    expect(summary.maxScore, 10);
    expect(summary.pointsAwarded, 35);
    expect(summary.submittedAt?.toUtc(), submittedAt);
  });

  test('garde une date inconnue honnête sur un ancien document incomplet', () {
    final summary = QuizAttemptSummary.fromFirestore(const {
      'quizTitle': 'Ancien quiz',
    });

    expect(summary.submittedAt, isNull);
    expect(summary.maxScore, 0);
  });
}
