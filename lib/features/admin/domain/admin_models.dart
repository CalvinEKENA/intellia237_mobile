enum AdminRoleType { student, parent, teacher, admin }

extension AdminRoleTypeX on AdminRoleType {
  String get label {
    return switch (this) {
      AdminRoleType.student => 'Élève',
      AdminRoleType.parent => 'Parent',
      AdminRoleType.teacher => 'Enseignant',
      AdminRoleType.admin => 'Administration',
    };
  }
}

enum ModerationStatus { pending, approved, rejected }

extension ModerationStatusX on ModerationStatus {
  String get label {
    return switch (this) {
      ModerationStatus.pending => 'En attente',
      ModerationStatus.approved => 'Approuvé',
      ModerationStatus.rejected => 'Masqué',
    };
  }
}

class AdminKpi {
  const AdminKpi({
    required this.totalStudents,
    required this.totalTeachers,
    required this.totalParents,
    required this.dailyActiveUsers,
    required this.averageCompletion,
  });

  final int totalStudents;
  final int totalTeachers;
  final int totalParents;
  final int dailyActiveUsers;
  final double averageCompletion;
}

class PendingAccountReview {
  const PendingAccountReview({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.establishmentName,
    required this.submittedAt,
  });

  final String id;
  final String fullName;
  final String email;
  final AdminRoleType role;
  final String establishmentName;
  final DateTime submittedAt;
}

class ModerationEntry {
  const ModerationEntry({
    required this.id,
    required this.contentTitle,
    required this.contentType,
    required this.reportCount,
    required this.status,
  });

  final String id;
  final String contentTitle;
  final String contentType;
  final int reportCount;
  final ModerationStatus status;
}

class AdminAnnouncement {
  const AdminAnnouncement({
    required this.id,
    required this.title,
    required this.message,
    required this.audience,
    required this.publishedAt,
  });

  final String id;
  final String title;
  final String message;
  final String audience;
  final DateTime publishedAt;
}

class SchoolAnalyticsSnapshot {
  const SchoolAnalyticsSnapshot({
    required this.weeklyActiveUsers,
    required this.weeklyStudyMinutes,
  });

  final List<int> weeklyActiveUsers;
  final List<int> weeklyStudyMinutes;
}

class AdminDashboard {
  const AdminDashboard({
    required this.adminName,
    required this.establishmentName,
    required this.kpi,
    required this.pendingReviews,
    required this.openModerationTickets,
    required this.analytics,
    required this.recentAnnouncements,
  });

  final String adminName;
  final String establishmentName;
  final AdminKpi kpi;
  final int pendingReviews;
  final int openModerationTickets;
  final SchoolAnalyticsSnapshot analytics;
  final List<AdminAnnouncement> recentAnnouncements;
}
