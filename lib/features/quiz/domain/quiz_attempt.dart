class QuizAttempt {
  const QuizAttempt({
    required this.quizId,
    required this.answersByQuestion,
    required this.startedAt,
    this.durationSeconds,
  });

  final String quizId;
  final Map<String, String> answersByQuestion;
  final DateTime startedAt;
  final int? durationSeconds;

  Map<String, dynamic> toCallablePayload({required String clientAttemptId}) {
    return <String, dynamic>{
      'quizId': quizId,
      'clientAttemptId': clientAttemptId,
      'answersByQuestion': answersByQuestion,
      'startedAt': startedAt.toUtc().toIso8601String(),
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
    };
  }
}
