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

  factory QuizQuestionCorrection.fromMap(Map<String, dynamic> map) {
    return QuizQuestionCorrection(
      questionId: map['questionId'] as String? ?? '',
      prompt: map['prompt'] as String? ?? '',
      userAnswer: map['userAnswer'] as String? ?? '',
      correctAnswer: map['correctAnswer'] as String? ?? '',
      explanation: map['explanation'] as String? ?? '',
      isCorrect: map['isCorrect'] as bool? ?? false,
      xpReward: (map['xpReward'] as num?)?.toInt() ?? 0,
    );
  }

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

  factory QuizResultPayload.fromMap(Map<String, dynamic> map) {
    final rawCorrections = map['corrections'] as List<dynamic>? ?? const [];
    return QuizResultPayload(
      quizId: map['quizId'] as String? ?? '',
      quizTitle: map['quizTitle'] as String? ?? '',
      subjectLabel: map['subjectLabel'] as String? ?? '',
      score: (map['score'] as num?)?.toInt() ?? 0,
      maxScore: (map['maxScore'] as num?)?.toInt() ?? 0,
      xpAwarded: (map['xpAwarded'] as num?)?.toInt() ?? 0,
      corrections: rawCorrections
          .whereType<Map>()
          .map(
            (item) =>
                QuizQuestionCorrection.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
    );
  }
}
