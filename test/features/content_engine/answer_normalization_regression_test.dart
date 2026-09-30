import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/content_engine/domain/question.dart';
import 'package:intellia237/features/content_engine/engine/answer_checker.dart';

void main() {
  Question question(Answer answer) => Question(
    id: 'normalization',
    lessonNumber: 1,
    difficulty: 1,
    type: QuestionType.numeric,
    rawType: 'numeric',
    prompt: 'Test',
    answer: answer,
  );
  test('le signe négatif et la division ne deviennent pas des séparateurs', () {
    expect(parseIntegerList('1 -2'), [1, -2]);
    expect(parseIntegerList('-7, -3 ; -1 0 +2'), [-7, -3, -1, 0, 2]);
    expect(parseIntegerList('1-2'), isNull);
    expect(parseIntegerList('1/2'), isNull);
    expect(parseIntegerList('512+256+128'), [512, 256, 128]);
    expect(
      const AnswerChecker()
          .grade(
            question(const IntegerSetAnswer({1, 2})),
            const TextResponse('1 -2'),
          )
          .correct,
      isFalse,
    );
  });
  test(
    'un entier avec zéro décimal conserve le moins Unicode et les espaces',
    () {
      expect(
        const AnswerChecker()
            .grade(
              question(const ScalarAnswer(AnswerAtom.integer(-5))),
              const TextResponse('− 5,00'),
            )
            .correct,
        isTrue,
      );
      expect(
        const AnswerChecker()
            .grade(
              question(const ScalarAnswer(AnswerAtom.integer(1000))),
              const TextResponse('1 000.0'),
            )
            .correct,
        isTrue,
      );
    },
  );
  test('une expression conserve la casse significative des variables', () {
    expect(sameExpression('T=2t', 'T = 2 × t'), isTrue);
    expect(sameExpression('T=2t', 't=2t'), isFalse);
    expect(sameExpression('y=x+1', 'y=X+1'), isFalse);
  });
}
