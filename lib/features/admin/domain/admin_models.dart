enum AdminRoleType { student, parent, teacher, admin }

/// Valeurs historiques attendues par le fan-out backend.
const adminAudienceWholeSchool = "Tout l'établissement";
const adminAudienceStudents = 'Élèves';
const adminAudienceParents = 'Parents';
const adminAudienceTeachers = 'Enseignants';
const adminAudienceAdministration = 'Administration';
const adminAudienceOptions = <String>[
  adminAudienceWholeSchool,
  adminAudienceStudents,
  adminAudienceParents,
  adminAudienceTeachers,
  adminAudienceAdministration,
];

enum ModerationStatus { pending, approved, rejected }

/// School directory projections deliberately exclude private learning data.
/// There is no student creation, deletion or reassignment contract here.
class SchoolDirectoryMember {
  const SchoolDirectoryMember({
    required this.id,
    required this.fullName,
    required this.role,
    required this.email,
    required this.phone,
    required this.classLevel,
    required this.accountStatus,
  });

  final String id;
  final String fullName;
  final AdminRoleType role;
  final String email;
  final String phone;
  final String classLevel;
  final String accountStatus;
}

class SchoolDirectoryPage {
  const SchoolDirectoryPage({required this.members, this.nextCursor});

  final List<SchoolDirectoryMember> members;
  final String? nextCursor;
}

class SchoolClassSummary {
  const SchoolClassSummary({
    required this.id,
    required this.name,
    required this.levelLabel,
    required this.studentCount,
    required this.teacherCount,
  });

  final String id;
  final String name;
  final String levelLabel;
  final int studentCount;
  final int teacherCount;
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
    this.establishmentId,
  });

  final String id;
  final String fullName;
  final String email;
  final AdminRoleType role;
  final String establishmentName;
  final DateTime submittedAt;

  /// Absent tant que l'administration générale n'a rattaché aucune école.
  final String? establishmentId;
}

/// Une école telle que l'administration générale la choisit à l'approbation.
class EstablishmentOption {
  const EstablishmentOption({
    required this.id,
    required this.name,
    required this.city,
  });

  final String id;
  final String name;
  final String city;
}

/// Un membre du personnel approuvé avant que son école existe dans INTELLIA.
///
/// Tant qu'aucune école ne le porte, il ne compose ni ne gère rien pour elle.
class UnattachedStaffMember {
  const UnattachedStaffMember({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
  });

  final String id;
  final String fullName;
  final String email;
  final AdminRoleType role;
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
    this.allSchools = false,
    required this.adminName,
    required this.establishmentName,
    required this.kpi,
    required this.pendingReviews,
    required this.openModerationTickets,
    required this.analytics,
    required this.recentAnnouncements,
  });

  /// Vue de l'administration générale : toutes les écoles confondues.
  final bool allSchools;
  final String adminName;
  final String establishmentName;
  final AdminKpi kpi;
  final int pendingReviews;
  final int openModerationTickets;
  final SchoolAnalyticsSnapshot analytics;
  final List<AdminAnnouncement> recentAnnouncements;
}
