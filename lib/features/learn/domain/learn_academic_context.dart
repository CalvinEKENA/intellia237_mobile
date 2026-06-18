class LearnAcademicContext {
  const LearnAcademicContext({required this.classLevel, this.series});

  final String classLevel;
  final String? series;

  LearnAcademicContext copyWith({String? classLevel, String? series}) {
    return LearnAcademicContext(
      classLevel: classLevel ?? this.classLevel,
      series: series ?? this.series,
    );
  }

  String get label {
    if (series == null || series!.isEmpty) {
      return classLevel;
    }
    return '$classLevel - Serie $series';
  }
}
