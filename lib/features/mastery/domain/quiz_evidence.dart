/// Latest server-scored result for one quiz from `progress/{student}_{quiz}`.
/// No answers, corrections, chats, marks, time counters or coverage enter
/// this contract. The current source does not establish unaided performance.
class QuizEvidence {
  const QuizEvidence({
    required this.quizId,
    required this.subjectId,
    required this.correctAnswers,
    required this.questionCount,
    required this.recordedAt,
  });

  final String quizId;
  final String subjectId;
  final int correctAnswers;
  final int questionCount;
  final DateTime recordedAt;

  bool get isValid =>
      quizId.trim().isNotEmpty &&
      subjectId.trim().isNotEmpty &&
      questionCount > 0 &&
      correctAnswers >= 0 &&
      correctAnswers <= questionCount;

  String get fingerprint =>
      '$quizId|$subjectId|$correctAnswers|$questionCount|'
      '${recordedAt.toUtc().microsecondsSinceEpoch}';
}
