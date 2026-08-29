import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/flow/data/flow_demo_content.dart';
import 'package:intellia237/features/flow/domain/flow_card.dart';

void main() {
  final cards = FlowDemoContent.build();

  test('le catalogue Flow contient un volume significatif d’exercices', () {
    expect(
      cards.whereType<FlowExerciseCard>().length,
      greaterThanOrEqualTo(30),
    );
  });

  test('les exercices proposent quatre formats actifs', () {
    final exercises = cards.whereType<FlowExerciseCard>();
    expect(exercises.whereType<FlowMiniQuizCard>(), isNotEmpty);
    expect(exercises.whereType<FlowTrueFalseCard>(), isNotEmpty);
    expect(exercises.whereType<FlowFillBlankCard>(), isNotEmpty);
    expect(exercises.whereType<FlowOrderingCard>(), isNotEmpty);
  });

  test('tous les identifiants du catalogue sont uniques', () {
    final ids = cards.map((card) => card.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('les exercices couvrent au moins sept matières', () {
    final subjects = cards
        .whereType<FlowExerciseCard>()
        .map((card) => card.subject.id)
        .toSet();
    expect(subjects.length, greaterThanOrEqualTo(7));
  });

  test('chaque mini-quiz possède une correction exploitable', () {
    for (final quiz in cards.whereType<FlowMiniQuizCard>()) {
      expect(quiz.options.length, greaterThanOrEqualTo(2));
      expect(quiz.correctIndex, inInclusiveRange(0, quiz.options.length - 1));
      expect(quiz.explanation.trim(), isNotEmpty);
    }
  });

  test('chaque exercice alternatif possède une correction exploitable', () {
    for (final exercise in cards.whereType<FlowExerciseCard>()) {
      expect(exercise.explanation.trim(), isNotEmpty);
      switch (exercise) {
        case FlowMiniQuizCard():
        case FlowTrueFalseCard():
          break;
        case FlowFillBlankCard card:
          expect(card.acceptedAnswers, isNotEmpty);
          expect(card.accepts(card.acceptedAnswers.first), isTrue);
        case FlowOrderingCard card:
          expect(card.items.length, greaterThanOrEqualTo(2));
          expect(card.accepts(card.items), isTrue);
      }
    }
  });
}
