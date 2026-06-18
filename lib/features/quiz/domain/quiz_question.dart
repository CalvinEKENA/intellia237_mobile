import 'quiz_type.dart';

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.type,
    required this.prompt,
    required this.explanation,
    required this.xpReward,
    this.options = const [],
    this.correctOptionIndex,
    this.correctBooleanValue,
    this.acceptedAnswers = const [],
  });

  final String id;
  final QuizQuestionType type;
  final String prompt;
  final List<String> options;
  final int? correctOptionIndex;
  final bool? correctBooleanValue;
  final List<String> acceptedAnswers;
  final String explanation;
  final int xpReward;
}
