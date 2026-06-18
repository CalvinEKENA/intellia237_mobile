class QuizAttempt {
  const QuizAttempt({
    required this.userId,
    required this.quizId,
    required this.quizTitle,
    required this.subjectId,
    required this.score,
    required this.maxScore,
    required this.xpAwarded,
    required this.answersByQuestion,
    required this.createdAt,
    required this.details,
  });

  final String userId;
  final String quizId;
  final String quizTitle;
  final String subjectId;
  final int score;
  final int maxScore;
  final int xpAwarded;
  final Map<String, String> answersByQuestion;
  final DateTime createdAt;
  final List<Map<String, dynamic>> details;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userId': userId,
      'quizId': quizId,
      'quizTitle': quizTitle,
      'subjectId': subjectId,
      'score': score,
      'maxScore': maxScore,
      'xpAwarded': xpAwarded,
      'answersByQuestion': answersByQuestion,
      'details': details,
      'createdAt': createdAt.toUtc(),
    };
  }
}
