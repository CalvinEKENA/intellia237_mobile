/// Editorial publishing status in Intellia Content Studio V2.
enum EditorialStatus {
  /// Initial pedagogical drafting state. Editable by author.
  draft,

  /// Submitted by author/teacher for peer or pedagogical inspection.
  inReview,

  /// Reviewed and validated by pedagogical inspector / admin.
  approved,

  /// Returned to author with correction requirements and rejection reason.
  rejected,

  /// Approved and waiting for a scheduled release timestamp.
  scheduled,

  /// Live and visible to secondary students in Intellia237.
  published,

  /// Superseded, deprecated, or removed from live curriculum view.
  archived;

  static EditorialStatus fromString(String? value) {
    return EditorialStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EditorialStatus.draft,
    );
  }
}

/// Metadata and audit trail for editorial publication workflows.
class EditorialWorkflowMetadata {
  const EditorialWorkflowMetadata({
    this.status = EditorialStatus.draft,
    this.submittedByUid,
    this.submittedAt,
    this.reviewedByUid,
    this.reviewedAt,
    this.rejectionReason,
    this.scheduledPublishAt,
    this.publishedAt,
    this.publishedByUid,
    this.archivedAt,
    this.previousVersionId,
    this.version = 1,
  });

  final EditorialStatus status;
  final String? submittedByUid;
  final DateTime? submittedAt;
  final String? reviewedByUid;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final DateTime? scheduledPublishAt;
  final DateTime? publishedAt;

  /// Qui a rendu ce contenu visible aux élèves. Distinct du relecteur : un
  /// contenu peut être approuvé par l'un et publié par l'autre.
  final String? publishedByUid;

  final DateTime? archivedAt;

  /// Crucial for versioning: when updating an already published lesson,
  /// a new revision draft is created with [previousVersionId] pointing to
  /// the existing published lesson ID. A published lesson is never wiped
  /// in-place back to draft.
  final String? previousVersionId;

  /// Numéro de révision, incrémenté à chaque nouvelle révision d'un contenu
  /// déjà publié. La version 1 est la première rédaction.
  final int version;

  bool get isDraft => status == EditorialStatus.draft;
  bool get isInReview => status == EditorialStatus.inReview;
  bool get isApproved => status == EditorialStatus.approved;
  bool get isRejected => status == EditorialStatus.rejected;
  bool get isScheduled => status == EditorialStatus.scheduled;
  bool get isPublished => status == EditorialStatus.published;
  bool get isArchived => status == EditorialStatus.archived;

  /// Default draft metadata.
  static const EditorialWorkflowMetadata draft = EditorialWorkflowMetadata(
    status: EditorialStatus.draft,
  );

  /// Validates whether a transition from [status] to [next] is permitted.
  bool canTransitionTo(
    EditorialStatus next, {
    required bool isReviewerOrAdmin,
    required bool isAuthor,
  }) {
    if (status == next) return true;

    switch (status) {
      case EditorialStatus.draft:
        if (next == EditorialStatus.inReview) {
          return isAuthor || isReviewerOrAdmin;
        }
        if (next == EditorialStatus.published && isReviewerOrAdmin) return true;
        return false;

      case EditorialStatus.inReview:
        if (!isReviewerOrAdmin) return false;
        return next == EditorialStatus.approved ||
            next == EditorialStatus.rejected ||
            next == EditorialStatus.published;

      case EditorialStatus.approved:
        if (!isReviewerOrAdmin) return false;
        return next == EditorialStatus.scheduled ||
            next == EditorialStatus.published ||
            next == EditorialStatus.draft;

      case EditorialStatus.rejected:
        return next == EditorialStatus.draft && (isAuthor || isReviewerOrAdmin);

      case EditorialStatus.scheduled:
        if (!isReviewerOrAdmin) return false;
        return next == EditorialStatus.published ||
            next == EditorialStatus.approved ||
            next == EditorialStatus.draft;

      case EditorialStatus.published:
        // A published lesson cannot be wiped directly to draft in-place.
        // It must either be archived or a new revision created via previousVersionId.
        if (next == EditorialStatus.archived && isReviewerOrAdmin) return true;
        return false;

      case EditorialStatus.archived:
        return next == EditorialStatus.draft && isReviewerOrAdmin;
    }
  }

  /// Transitions to [EditorialStatus.inReview].
  EditorialWorkflowMetadata submitForReview({
    required String uid,
    DateTime? at,
  }) {
    return copyWith(
      status: EditorialStatus.inReview,
      submittedByUid: uid,
      submittedAt: at ?? DateTime.now(),
      rejectionReason: null,
    );
  }

  /// Transitions to [EditorialStatus.approved].
  EditorialWorkflowMetadata approve({
    required String reviewerUid,
    DateTime? at,
  }) {
    return copyWith(
      status: EditorialStatus.approved,
      reviewedByUid: reviewerUid,
      reviewedAt: at ?? DateTime.now(),
      rejectionReason: null,
    );
  }

  /// Transitions to [EditorialStatus.rejected].
  EditorialWorkflowMetadata reject({
    required String reviewerUid,
    required String reason,
    DateTime? at,
  }) {
    return copyWith(
      status: EditorialStatus.rejected,
      reviewedByUid: reviewerUid,
      reviewedAt: at ?? DateTime.now(),
      rejectionReason: reason,
    );
  }

  /// Transitions to [EditorialStatus.scheduled].
  EditorialWorkflowMetadata schedule({
    required String reviewerUid,
    required DateTime publishAt,
    DateTime? at,
  }) {
    return copyWith(
      status: EditorialStatus.scheduled,
      reviewedByUid: reviewerUid,
      reviewedAt: at ?? DateTime.now(),
      scheduledPublishAt: publishAt,
      rejectionReason: null,
    );
  }

  /// Transitions to [EditorialStatus.published].
  EditorialWorkflowMetadata publish({
    required String reviewerUid,
    DateTime? at,
  }) {
    final now = at ?? DateTime.now();
    return copyWith(
      status: EditorialStatus.published,
      reviewedByUid: reviewerUid,
      reviewedAt: reviewedAt ?? now,
      publishedAt: now,
      publishedByUid: reviewerUid,
      rejectionReason: null,
    );
  }

  /// Transitions to [EditorialStatus.archived].
  EditorialWorkflowMetadata archive({DateTime? at}) {
    return copyWith(
      status: EditorialStatus.archived,
      archivedAt: at ?? DateTime.now(),
    );
  }

  /// Spawns a revision draft linked to this published item.
  ///
  /// La version publiée n'est pas touchée : elle reste en ligne pour les
  /// élèves tant que la révision n'a pas été approuvée puis publiée à son
  /// tour. Les horodatages de l'ancienne version ne sont pas recopiés — cette
  /// révision n'a été ni relue ni publiée.
  EditorialWorkflowMetadata spawnRevisionDraft({
    required String currentPublishedLessonId,
    required String authorUid,
  }) {
    return EditorialWorkflowMetadata(
      status: EditorialStatus.draft,
      submittedByUid: authorUid,
      previousVersionId: currentPublishedLessonId,
      version: version + 1,
    );
  }

  Map<String, dynamic> toFirestore() => <String, dynamic>{
    'status': status.name,
    if (submittedByUid != null) 'submittedByUid': submittedByUid,
    if (submittedAt != null) 'submittedAt': submittedAt!.toIso8601String(),
    if (reviewedByUid != null) 'reviewedByUid': reviewedByUid,
    if (reviewedAt != null) 'reviewedAt': reviewedAt!.toIso8601String(),
    if (rejectionReason != null) 'rejectionReason': rejectionReason,
    if (scheduledPublishAt != null)
      'scheduledPublishAt': scheduledPublishAt!.toIso8601String(),
    if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
    if (publishedByUid != null) 'publishedByUid': publishedByUid,
    if (archivedAt != null) 'archivedAt': archivedAt!.toIso8601String(),
    if (previousVersionId != null) 'previousVersionId': previousVersionId,
    'version': version,
  };

  factory EditorialWorkflowMetadata.fromFirestore(
    dynamic data, {
    String? legacyStatus,
  }) {
    if (data != null && data is Map && data.containsKey('status')) {
      final map = Map<String, dynamic>.from(data);
      final status = EditorialStatus.fromString(map['status'] as String?);
      return EditorialWorkflowMetadata(
        status: status,
        submittedByUid: map['submittedByUid'] as String?,
        submittedAt: _parseDateTime(map['submittedAt']),
        reviewedByUid: map['reviewedByUid'] as String?,
        reviewedAt: _parseDateTime(map['reviewedAt']),
        rejectionReason: map['rejectionReason'] as String?,
        scheduledPublishAt: _parseDateTime(map['scheduledPublishAt']),
        publishedAt: _parseDateTime(map['publishedAt']),
        publishedByUid: map['publishedByUid'] as String?,
        archivedAt: _parseDateTime(map['archivedAt']),
        previousVersionId: map['previousVersionId'] as String?,
        // Les documents antérieurs au Studio V2 n'ont pas de numéro de
        // révision : ils sont la première version par définition.
        version: (map['version'] as num?)?.toInt() ?? 1,
      );
    }

    // Fallback based on legacy status string ('published' | 'draft' | 'ai_generated')
    EditorialStatus fallbackStatus = EditorialStatus.draft;
    if (legacyStatus == 'published') {
      fallbackStatus = EditorialStatus.published;
    }

    return EditorialWorkflowMetadata(status: fallbackStatus);
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  EditorialWorkflowMetadata copyWith({
    EditorialStatus? status,
    String? submittedByUid,
    DateTime? submittedAt,
    String? reviewedByUid,
    DateTime? reviewedAt,
    String? rejectionReason,
    DateTime? scheduledPublishAt,
    DateTime? publishedAt,
    String? publishedByUid,
    DateTime? archivedAt,
    String? previousVersionId,
    int? version,
  }) {
    return EditorialWorkflowMetadata(
      status: status ?? this.status,
      submittedByUid: submittedByUid ?? this.submittedByUid,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedByUid: reviewedByUid ?? this.reviewedByUid,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      scheduledPublishAt: scheduledPublishAt ?? this.scheduledPublishAt,
      publishedAt: publishedAt ?? this.publishedAt,
      publishedByUid: publishedByUid ?? this.publishedByUid,
      archivedAt: archivedAt ?? this.archivedAt,
      previousVersionId: previousVersionId ?? this.previousVersionId,
      version: version ?? this.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorialWorkflowMetadata &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          submittedByUid == other.submittedByUid &&
          submittedAt == other.submittedAt &&
          reviewedByUid == other.reviewedByUid &&
          reviewedAt == other.reviewedAt &&
          rejectionReason == other.rejectionReason &&
          scheduledPublishAt == other.scheduledPublishAt &&
          publishedAt == other.publishedAt &&
          publishedByUid == other.publishedByUid &&
          archivedAt == other.archivedAt &&
          previousVersionId == other.previousVersionId &&
          version == other.version;

  @override
  int get hashCode => Object.hash(
    status,
    submittedByUid,
    submittedAt,
    reviewedByUid,
    reviewedAt,
    rejectionReason,
    scheduledPublishAt,
    publishedAt,
    publishedByUid,
    archivedAt,
    previousVersionId,
    version,
  );

  @override
  String toString() =>
      'EditorialWorkflowMetadata(status: ${status.name}, v$version, '
      'prevVersion: $previousVersionId)';
}
