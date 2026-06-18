import 'quiz_question.dart';

class QuizModel {
  const QuizModel({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.subjectLabel,
    required this.description,
    required this.difficultyLabel,
    required this.questions,
    this.timerSeconds,
  });

  final String id;
  final String title;
  final String subjectId;
  final String subjectLabel;
  final String description;
  final String difficultyLabel;
  final List<QuizQuestion> questions;
  final int? timerSeconds;
}
