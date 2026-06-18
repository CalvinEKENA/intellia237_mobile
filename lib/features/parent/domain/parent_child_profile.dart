class ParentChildProfile {
  const ParentChildProfile({
    required this.id,
    required this.firstName,
    required this.classLevel,
    required this.series,
    required this.globalProgress,
    required this.studyMinutesToday,
    required this.studyMinutesTarget,
    required this.strongSubjects,
    required this.weakSubjects,
    required this.weeklyProgress,
  });

  final String id;
  final String firstName;
  final String classLevel;
  final String? series;
  final double globalProgress;
  final int studyMinutesToday;
  final int studyMinutesTarget;
  final List<String> strongSubjects;
  final List<String> weakSubjects;
  final List<double> weeklyProgress;

  String get classLabel {
    if (series == null || series!.isEmpty) {
      return classLevel;
    }
    return '$classLevel - Serie $series';
  }
}
