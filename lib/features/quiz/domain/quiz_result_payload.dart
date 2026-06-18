class QuizQuestionCorrection {
  const QuizQuestionCorrection({
    required this.questionId,
    required this.prompt,
    required this.userAnswer,
    required this.correctAnswer,
    required this.explanation,
    required this.isCorrect,
    required this.xpReward,
  });

  final String questionId;
  final String prompt;
  final String userAnswer;
  final String correctAnswer;
  final String explanation;
  final bool isCorrect;
  final int xpReward;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'questionId': questionId,
      'prompt': prompt,
      'userAnswer': userAnswer,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'isCorrect': isCorrect,
      'xpReward': xpReward,
    };
  }
}

class QuizResultPayload {
  const QuizResultPayload({
    required this.quizId,
    required this.quizTitle,
    required this.subjectLabel,
    required this.score,
    required this.maxScore,
    required this.xpAwarded,
    required this.corrections,
  });

  final String quizId;
  final String quizTitle;
  final String subjectLabel;
  final int score;
  final int maxScore;
  final int xpAwarded;
  final List<QuizQuestionCorrection> corrections;
}
