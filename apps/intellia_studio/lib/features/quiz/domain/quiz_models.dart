enum QuizDifficulty { debutant, intermediaire, avance, expert }

enum QuizQuestionType { qcm, trueFalse, shortAnswer }

class StudioQuizQuestion {
  final String id;
  final String subjectId;
  final String classLevel;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final QuizDifficulty difficulty;
  final QuizQuestionType type;
  final int points;

  const StudioQuizQuestion({
    required this.id,
    required this.subjectId,
    required this.classLevel,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.difficulty = QuizDifficulty.intermediaire,
    this.type = QuizQuestionType.qcm,
    this.points = 10,
  });

  bool get isValid =>
      prompt.trim().isNotEmpty &&
      options.length >= 2 &&
      correctIndex >= 0 &&
      correctIndex < options.length;
}
