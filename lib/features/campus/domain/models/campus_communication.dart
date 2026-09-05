/// Institutional announcement and communication domain models.
library;

enum AnnouncementAudience {
  allEstablishment,
  singleClass,
  teachersOnly,
  parentsOnly,
  studentsOnly,
}

class CampusAnnouncement {
  final String id;
  final String establishmentId;
  final String title;
  final String message;
  final AnnouncementAudience audience;
  final String? targetClassId;
  final String? targetClassName;
  final String authorName;
  final DateTime publishedAt;
  final DateTime? expiresAt;

  const CampusAnnouncement({
    required this.id,
    required this.establishmentId,
    required this.title,
    required this.message,
    required this.audience,
    this.targetClassId,
    this.targetClassName,
    required this.authorName,
    required this.publishedAt,
    this.expiresAt,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}
