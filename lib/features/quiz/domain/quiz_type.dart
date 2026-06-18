enum QuizQuestionType { qcm, trueFalse, shortAnswer }

extension QuizQuestionTypeX on QuizQuestionType {
  String get label {
    return switch (this) {
      QuizQuestionType.qcm => 'QCM',
      QuizQuestionType.trueFalse => 'Vrai/Faux',
      QuizQuestionType.shortAnswer => 'Reponse courte',
    };
  }
}
