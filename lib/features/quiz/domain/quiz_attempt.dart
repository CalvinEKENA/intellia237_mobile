class QuizAttempt {
  const QuizAttempt({
    required this.quizId,
    required this.clientAttemptId,
    required this.answersByQuestion,
    required this.startedAt,
    this.durationSeconds,
  });

  final String quizId;
  final String clientAttemptId;
  final Map<String, String> answersByQuestion;
  final DateTime startedAt;
  final int? durationSeconds;

  Map<String, dynamic> toCallablePayload() {
    return <String, dynamic>{
      'quizId': quizId,
      'clientAttemptId': clientAttemptId,
      'answersByQuestion': answersByQuestion,
      'startedAt': startedAt.toUtc().toIso8601String(),
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
    };
  }
}
