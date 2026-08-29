import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/admin/domain/admin_content_models.dart';
import 'package:intellia237/features/quiz/domain/quiz_mode.dart';
import 'package:intellia237/features/quiz/domain/quiz_question.dart';
import 'package:intellia237/features/quiz/domain/quiz_type.dart';

void main() {
  test('le document public et le corrigé privé sont séparés', () {
    const quiz = AdminQuizModel(
      id: 'quiz-a',
      title: 'Équations',
      subjectId: 'math',
      subjectLabel: 'Mathématiques',
      description: 'Entraînement',
      difficultyLabel: 'Intermédiaire',
      classLevels: <String>['3eme'],
      status: 'published',
      mode: QuizMode.training,
      questions: <QuizQuestion>[
        QuizQuestion(
          id: 'q1',
          type: QuizQuestionType.qcm,
          prompt: '2 + 2',
          options: <String>['4', '5'],
          correctOptionIndex: 0,
          explanation: 'Deux et deux font quatre.',
          pointsReward: 10,
        ),
      ],
    );

    final publicJson = jsonEncode(quiz.toPublicFirestore());
    final privateJson = jsonEncode(quiz.toAnswerKeyFirestore());

    expect(publicJson, isNot(contains('correctOptionIndex')));
    expect(publicJson, isNot(contains('correctBooleanValue')));
    expect(publicJson, isNot(contains('acceptedAnswers')));
    expect(publicJson, isNot(contains('explanation')));
    expect(privateJson, contains('correctOptionIndex'));
    expect(privateJson, contains('explanation'));
  });

  test('l’éditeur réassemble le corrigé privé pour le personnel autorisé', () {
    final quiz = AdminQuizModel.fromFirestore(
      'quiz-a',
      <String, dynamic>{
        'title': 'Équations',
        'status': 'draft',
        'mode': 'exam',
        'questions': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'q1',
            'type': 'shortAnswer',
            'prompt': 'Capitale du Cameroun ?',
            'options': <String>[],
            'pointsReward': 10,
          },
        ],
      },
      answerKeyData: <String, dynamic>{
        'answers': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'q1',
            'acceptedAnswers': <String>['Yaoundé', 'Yaounde'],
            'explanation': 'Yaoundé est la capitale politique.',
            'pointsReward': 10,
          },
        ],
      },
    );

    expect(quiz.questions.single.acceptedAnswers, contains('Yaoundé'));
    expect(quiz.questions.single.explanation, contains('capitale politique'));
  });
}
