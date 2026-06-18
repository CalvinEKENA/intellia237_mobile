class SubjectOverview {
  const SubjectOverview({
    required this.id,
    required this.title,
    required this.progress,
    required this.colorHex,
  });

  final String id;
  final String title;
  final double progress;
  final int colorHex;
}

class RecommendationItem {
  const RecommendationItem({
    required this.title,
    required this.subtitle,
    required this.estimatedMinutes,
  });

  final String title;
  final String subtitle;
  final int estimatedMinutes;
}

class DailyChallengeItem {
  const DailyChallengeItem({
    required this.title,
    required this.rewardXp,
    required this.completed,
  });

  final String title;
  final int rewardXp;
  final bool completed;
}

class StudentHomeSnapshot {
  const StudentHomeSnapshot({
    required this.firstName,
    required this.streakDays,
    required this.motivationText,
    required this.lastCourseTitle,
    required this.lastCourseChapter,
    required this.lastCourseProgress,
    required this.subjects,
    required this.recommendations,
    required this.challenges,
    required this.globalProgress,
    required this.level,
    required this.currentXp,
  });

  final String firstName;
  final int streakDays;
  final String motivationText;
  final String lastCourseTitle;
  final String lastCourseChapter;
  final double lastCourseProgress;
  final List<SubjectOverview> subjects;
  final List<RecommendationItem> recommendations;
  final List<DailyChallengeItem> challenges;
  final double globalProgress;
  final int level;
  final int currentXp;
}
