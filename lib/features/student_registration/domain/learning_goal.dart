enum LearningGoal {
  examMastery,
  catchUp,
  consistency,
  improveAverage,
  conceptDepth,
}

extension LearningGoalX on LearningGoal {
  String get label {
    return switch (this) {
      LearningGoal.examMastery => 'Maitriser les examens',
      LearningGoal.catchUp => 'Combler mes lacunes',
      LearningGoal.consistency => 'Etudier avec regularite',
      LearningGoal.improveAverage => 'Augmenter ma moyenne',
      LearningGoal.conceptDepth => 'Comprendre en profondeur',
    };
  }
}
