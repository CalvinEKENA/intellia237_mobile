/// Teaching Studio institutional resource model.
library;

enum ResourceStatus { draft, pendingReview, published, archived }

enum ResourceType {
  courseSummary,
  exerciseSheet,
  methodologyGuide,
  diagnosticSheet,
}

class CampusResource {
  final String id;
  final String establishmentId;
  final String title;
  final ResourceType type;
  final String subjectName;
  final String? curriculumUnitTitle;
  final String targetClassName;
  final String authorName;
  final ResourceStatus status;
  final DateTime createdAt;
  final DateTime? publishedAt;

  const CampusResource({
    required this.id,
    required this.establishmentId,
    required this.title,
    required this.type,
    required this.subjectName,
    this.curriculumUnitTitle,
    required this.targetClassName,
    required this.authorName,
    required this.status,
    required this.createdAt,
    this.publishedAt,
  });

  bool get isPublished => status == ResourceStatus.published;
  bool get isPendingReview => status == ResourceStatus.pendingReview;
  bool get isDraft => status == ResourceStatus.draft;

  CampusResource copyWith({
    String? id,
    String? establishmentId,
    String? title,
    ResourceType? type,
    String? subjectName,
    String? curriculumUnitTitle,
    String? targetClassName,
    String? authorName,
    ResourceStatus? status,
    DateTime? createdAt,
    DateTime? publishedAt,
  }) {
    return CampusResource(
      id: id ?? this.id,
      establishmentId: establishmentId ?? this.establishmentId,
      title: title ?? this.title,
      type: type ?? this.type,
      subjectName: subjectName ?? this.subjectName,
      curriculumUnitTitle: curriculumUnitTitle ?? this.curriculumUnitTitle,
      targetClassName: targetClassName ?? this.targetClassName,
      authorName: authorName ?? this.authorName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }
}
