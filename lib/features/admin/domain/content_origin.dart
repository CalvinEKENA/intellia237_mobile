/// Provenance type of educational content.
enum ContentSourceType {
  /// Manually created or edited in Intellia Content Studio.
  manual,

  /// Ingested from NotebookLM artifacts (Audio Overview, study guide, FAQ, briefing).
  notebooklm,

  /// Generated via Cloud Function AI pipeline.
  cloudFunctionAi,

  /// Read by Gemini from photographed or scanned course pages, then reviewed
  /// by its author in the Studio before any draft exists.
  pageImport,

  /// Pedagogical draft submitted by an authenticated teacher.
  teacherDraft;

  static ContentSourceType fromString(String? value) {
    return ContentSourceType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ContentSourceType.manual,
    );
  }
}

/// Provenance and import audit metadata.
class ContentOrigin {
  const ContentOrigin({
    required this.source,
    this.sourceDocumentName,
    this.importedAt,
    this.importedByUid,
    this.notebookId,
  });

  final ContentSourceType source;
  final String? sourceDocumentName;
  final DateTime? importedAt;
  final String? importedByUid;
  final String? notebookId;

  static const ContentOrigin manual = ContentOrigin(
    source: ContentSourceType.manual,
  );

  bool get isNotebookLm => source == ContentSourceType.notebooklm;
  bool get isAiGenerated => source == ContentSourceType.cloudFunctionAi;
  bool get isTeacherDraft => source == ContentSourceType.teacherDraft;

  Map<String, dynamic> toFirestore() => <String, dynamic>{
    'source': source.name,
    if (sourceDocumentName != null) 'sourceDocumentName': sourceDocumentName,
    if (importedAt != null) 'importedAt': importedAt!.toIso8601String(),
    if (importedByUid != null) 'importedByUid': importedByUid,
    if (notebookId != null) 'notebookId': notebookId,
  };

  factory ContentOrigin.fromFirestore(dynamic data) {
    if (data == null || data is! Map) return ContentOrigin.manual;
    final map = Map<String, dynamic>.from(data);
    final source = ContentSourceType.fromString(map['source'] as String?);
    final importedAtRaw = map['importedAt'] as String?;
    return ContentOrigin(
      source: source,
      sourceDocumentName: map['sourceDocumentName'] as String?,
      importedAt: importedAtRaw != null
          ? DateTime.tryParse(importedAtRaw)
          : null,
      importedByUid: map['importedByUid'] as String?,
      notebookId: map['notebookId'] as String?,
    );
  }

  ContentOrigin copyWith({
    ContentSourceType? source,
    String? sourceDocumentName,
    DateTime? importedAt,
    String? importedByUid,
    String? notebookId,
  }) {
    return ContentOrigin(
      source: source ?? this.source,
      sourceDocumentName: sourceDocumentName ?? this.sourceDocumentName,
      importedAt: importedAt ?? this.importedAt,
      importedByUid: importedByUid ?? this.importedByUid,
      notebookId: notebookId ?? this.notebookId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentOrigin &&
          runtimeType == other.runtimeType &&
          source == other.source &&
          sourceDocumentName == other.sourceDocumentName &&
          importedAt == other.importedAt &&
          importedByUid == other.importedByUid &&
          notebookId == other.notebookId;

  @override
  int get hashCode => Object.hash(
    source,
    sourceDocumentName,
    importedAt,
    importedByUid,
    notebookId,
  );

  @override
  String toString() =>
      'ContentOrigin(source: ${source.name}, doc: $sourceDocumentName, importedBy: $importedByUid)';
}
