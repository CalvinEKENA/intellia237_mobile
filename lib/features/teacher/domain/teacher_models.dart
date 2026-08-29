class TeacherClassOverview {
  const TeacherClassOverview({
    required this.id,
    required this.name,
    required this.levelLabel,
    required this.studentCount,
    required this.averageProgress,
    required this.pendingSubmissions,
  });

  final String id;
  final String name;
  final String levelLabel;
  final int studentCount;
  final double averageProgress;
  final int pendingSubmissions;
}

class TeacherStudentProgress {
  const TeacherStudentProgress({
    required this.id,
    required this.fullName,
    required this.progress,
    required this.studyMinutesToday,
    this.subjectProgress = const {},
  });

  final String id;
  final String fullName;
  final double progress;
  final int studyMinutesToday;
  final Map<String, double> subjectProgress;
}

class TeacherClassDetail {
  const TeacherClassDetail({
    required this.classInfo,
    required this.students,
    required this.strongSubjects,
    required this.weakSubjects,
  });

  final TeacherClassOverview classInfo;
  final List<TeacherStudentProgress> students;
  final List<String> strongSubjects;
  final List<String> weakSubjects;
}

class TeacherKpi {
  const TeacherKpi({
    required this.activeClasses,
    required this.activeStudents,
    required this.averageCompletion,
    this.dailyEngagementMinutes,
  });

  final int activeClasses;
  final int activeStudents;
  final double averageCompletion;

  /// Null tant que la mesure n'existe pas cote serveur : l'UI affiche alors
  /// un tiret (registre de decisions : jamais de zero factice).
  final int? dailyEngagementMinutes;
}

class TeacherDashboard {
  const TeacherDashboard({
    required this.teacherName,
    required this.kpi,
    required this.classes,
    required this.weeklyCompletionTrend,
    required this.latestAnnouncements,
  });

  final String teacherName;
  final TeacherKpi kpi;
  final List<TeacherClassOverview> classes;
  final List<double> weeklyCompletionTrend;
  final List<String> latestAnnouncements;
}
