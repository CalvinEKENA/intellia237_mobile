enum QuizMode { training, exam }

extension QuizModeX on QuizMode {
  String get wireValue => switch (this) {
    QuizMode.training => 'training',
    QuizMode.exam => 'exam',
  };

  String get label => switch (this) {
    QuizMode.training => 'Entraînement',
    QuizMode.exam => 'Examen',
  };

  static QuizMode fromWireValue(Object? value) => switch (value) {
    'training' => QuizMode.training,
    _ => QuizMode.exam,
  };
}

/// Only training sessions may reveal a correction before final submission.
/// Exam sessions therefore always use the single grouped submission call.
bool shouldCheckQuizAnswerImmediately({
  required QuizMode mode,
  required String answer,
  required String? checkedAnswer,
}) {
  final normalizedAnswer = answer.trim();
  return mode == QuizMode.training &&
      normalizedAnswer.isNotEmpty &&
      checkedAnswer != normalizedAnswer;
}
