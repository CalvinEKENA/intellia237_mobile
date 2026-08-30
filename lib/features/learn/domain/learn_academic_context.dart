class LearnAcademicContext {
  const LearnAcademicContext({
    required this.classLevel,
    this.series,
    this.catalogClassLevel,
    this.academicLevelId,
    this.displayClassLevel,
    this.educationalSubsystem,
    this.educationType,
    this.tutorId,
  });

  /// Raw authoritative value stored on the profile. It is sent back to
  /// authorization-sensitive callables so legacy profiles remain compatible.
  final String classLevel;
  final String? series;
  final String? catalogClassLevel;
  final String? academicLevelId;
  final String? displayClassLevel;
  final String? educationalSubsystem;
  final String? educationType;
  final String? tutorId;

  /// Historical Firestore catalog key, normalized independently from UI copy.
  String get quizAndCatalogClassLevel => catalogClassLevel ?? classLevel;

  LearnAcademicContext copyWith({
    String? classLevel,
    String? series,
    String? catalogClassLevel,
    String? academicLevelId,
    String? displayClassLevel,
    String? educationalSubsystem,
    String? educationType,
    String? tutorId,
  }) {
    return LearnAcademicContext(
      classLevel: classLevel ?? this.classLevel,
      series: series ?? this.series,
      catalogClassLevel: catalogClassLevel ?? this.catalogClassLevel,
      academicLevelId: academicLevelId ?? this.academicLevelId,
      displayClassLevel: displayClassLevel ?? this.displayClassLevel,
      educationalSubsystem: educationalSubsystem ?? this.educationalSubsystem,
      educationType: educationType ?? this.educationType,
      tutorId: tutorId ?? this.tutorId,
    );
  }

  String get label {
    final levelLabel = displayClassLevel ?? classLevel;
    if (series == null || series!.isEmpty) {
      return levelLabel;
    }
    return '$levelLabel - Série $series';
  }
}
