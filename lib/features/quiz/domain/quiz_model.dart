import 'quiz_question.dart';
import 'quiz_mode.dart';

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
    this.mode = QuizMode.exam,
    int? questionCount,
  }) : questionCount = questionCount ?? questions.length;

  final String id;
  final String title;
  final String subjectId;
  final String subjectLabel;
  final String description;
  final String difficultyLabel;
  final List<QuizQuestion> questions;
  final int? timerSeconds;
  final QuizMode mode;
  final int questionCount;
}
