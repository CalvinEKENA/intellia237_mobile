enum ContentBlockType { text, callout, image, audio, video }

enum ContentOriginSource { manual, notebooklm, cloudFunctionAi, pageImport, teacherDraft }

class StudioContentOrigin {
  final ContentOriginSource source;
  final String? sourceDocumentName;
  final String? importedAt;
  final String? importedByUid;
  final String? notebookId;

  const StudioContentOrigin({
    this.source = ContentOriginSource.manual,
    this.sourceDocumentName,
    this.importedAt,
    this.importedByUid,
    this.notebookId,
  });

  Map<String, dynamic> toMap() => {
    'source': source.name,
    if (sourceDocumentName != null) 'sourceDocumentName': sourceDocumentName,
    if (importedAt != null) 'importedAt': importedAt,
    if (importedByUid != null) 'importedByUid': importedByUid,
    if (notebookId != null) 'notebookId': notebookId,
  };
}

class StudioContentBlock {
  final String id;
  final ContentBlockType type;
  final String title;
  final String body;
  final String? storagePath;
  final Map<String, dynamic> metadata;

  const StudioContentBlock({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.storagePath,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'title': title,
    'body': body,
    if (storagePath != null) 'storagePath': storagePath,
    'metadata': metadata,
  };
}

class StudioSubject {
  final String id;
  final String classLevel;
  final String title;
  final String description;
  final int colorHex;
  final String iconKey;
  final int order;
  final String status;
  final int chapterCount;
  final List<String> allowedSeries;

  const StudioSubject({
    required this.id,
    required this.classLevel,
    required this.title,
    required this.description,
    required this.colorHex,
    required this.iconKey,
    required this.order,
    required this.status,
    required this.chapterCount,
    this.allowedSeries = const [],
  });

  bool get isPublished => status == 'published';
}

class StudioChapter {
  final String id;
  final String subjectId;
  final String classLevel;
  final String title;
  final String description;
  final int order;
  final int lessonsCount;

  const StudioChapter({
    required this.id,
    required this.subjectId,
    required this.classLevel,
    required this.title,
    required this.description,
    required this.order,
    required this.lessonsCount,
  });
}

class StudioLesson {
  final String id;
  final String subjectId;
  final String chapterId;
  final String classLevel;
  final String title;
  final String summary;
  final int estimatedMinutes;
  final int order;
  final String status; // 'draft' | 'inReview' | 'published' | 'archived'
  final List<StudioContentBlock> contentBlocks;
  final StudioContentOrigin origin;
  final String scope;
  final String updatedAt;

  const StudioLesson({
    required this.id,
    required this.subjectId,
    required this.chapterId,
    required this.classLevel,
    required this.title,
    required this.summary,
    required this.estimatedMinutes,
    required this.order,
    required this.status,
    this.contentBlocks = const [],
    this.origin = const StudioContentOrigin(),
    this.scope = 'global',
    required this.updatedAt,
  });

  bool get isPublished => status == 'published';
  bool get isDraft => status == 'draft';
  bool get isInReview => status == 'inReview';
  bool get isFromNotebookLm => origin.source == ContentOriginSource.notebooklm;

  Map<String, dynamic> toDualWritePayload() {
    return {
      'title': title,
      'summary': summary,
      'estimatedMinutes': estimatedMinutes,
      'order': order,
      'status': status,
      'schemaVersion': 2,
      'scope': {'type': scope},
      'origin': origin.toMap(),
      'contentBlocks': contentBlocks.map((b) => b.toMap()).toList(),
      'contentSections': contentBlocks
          .where((b) => b.type == ContentBlockType.text || b.type == ContentBlockType.callout)
          .map((b) => {'title': b.title, 'body': b.body})
          .toList(),
      'updatedAt': updatedAt,
    };
  }
}
