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
    this.hasProgressData = false,
    this.hasStudyTimeData = false,
    this.exploredLessonCount,
    this.coverageIsPartial = false,
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
  final bool hasProgressData;
  final bool hasStudyTimeData;

  /// Coverage only. Null means that this optional source is unavailable.
  final int? exploredLessonCount;
  final bool coverageIsPartial;

  String get classLabel {
    if (series == null || series!.isEmpty) {
      return classLevel;
    }
    return '$classLevel - Série $series';
  }
}
