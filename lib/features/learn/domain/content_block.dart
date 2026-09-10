import 'learn_lesson.dart';

/// Type of educational content block.
enum ContentBlockType {
  text,
  media,
  quiz,
  interactive;

  static ContentBlockType fromString(String? value) {
    return ContentBlockType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ContentBlockType.text,
    );
  }
}

/// Supported educational media formats.
enum MediaType {
  image,
  audio,
  video,
  pdf;

  static MediaType fromString(String? value) {
    return MediaType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MediaType.image,
    );
  }
}

/// Base abstract class for versioned, polymorphic lesson content blocks.
abstract class ContentBlock {
  const ContentBlock({
    required this.id,
    required this.type,
    required this.order,
  });

  final String id;
  final ContentBlockType type;
  final int order;

  Map<String, dynamic> toFirestore();

  ContentBlock copyWith({String? id, int? order});

  factory ContentBlock.fromFirestore(Map<String, dynamic> data) {
    final rawType = data['type'] as String?;
    final type = ContentBlockType.fromString(rawType);

    switch (type) {
      case ContentBlockType.text:
        return TextBlock.fromFirestore(data);
      case ContentBlockType.media:
        return MediaBlock.fromFirestore(data);
      case ContentBlockType.quiz:
        return QuizBlock.fromFirestore(data);
      case ContentBlockType.interactive:
        return InteractiveBlock.fromFirestore(data);
    }
  }
}

/// Rich text block supporting Markdown and optional title.
class TextBlock extends ContentBlock {
  const TextBlock({
    required super.id,
    required super.order,
    required this.markdown,
    this.title,
  }) : super(type: ContentBlockType.text);

  final String? title;
  final String markdown;

  @override
  Map<String, dynamic> toFirestore() => <String, dynamic>{
    'id': id,
    'type': type.name,
    'order': order,
    if (title != null) 'title': title,
    'markdown': markdown,
  };

  factory TextBlock.fromFirestore(Map<String, dynamic> data) {
    return TextBlock(
      id: data['id'] as String? ?? '',
      order: (data['order'] as num?)?.toInt() ?? 0,
      title: data['title'] as String?,
      markdown: (data['markdown'] ?? data['body']) as String? ?? '',
    );
  }

  @override
  TextBlock copyWith({
    String? id,
    int? order,
    String? title,
    String? markdown,
  }) {
    return TextBlock(
      id: id ?? this.id,
      order: order ?? this.order,
      title: title ?? this.title,
      markdown: markdown ?? this.markdown,
    );
  }
}

/// Media block (image, audio, video, PDF) with canonical Storage path and metadata.
class MediaBlock extends ContentBlock {
  const MediaBlock({
    required super.id,
    required super.order,
    required this.mediaType,
    required this.storagePath,
    this.downloadUrl,
    this.caption,
    this.durationSeconds,
    this.fileSizeBytes,
    this.mimeType,
    this.transcriptionText,
    this.transcriptionVtt,
  }) : super(type: ContentBlockType.media);

  final MediaType mediaType;

  /// Canonical Firestore path in Firebase Storage:
  /// e.g. `/educational_assets/{scopeId}/{classLevel}/{subjectId}/{lessonId}/{assetId}/{fileName}`
  final String storagePath;

  /// Optional / transient download URL
  final String? downloadUrl;

  final String? caption;
  final int? durationSeconds;
  final int? fileSizeBytes;
  final String? mimeType;

  /// Full transcript text (e.g. for audio overview or video)
  final String? transcriptionText;

  /// Timed transcript cues in WebVTT format (ONLY if real timecodes exist; no fake timestamps)
  final String? transcriptionVtt;

  bool get hasTimedTranscript =>
      transcriptionVtt != null && transcriptionVtt!.trim().isNotEmpty;

  @override
  Map<String, dynamic> toFirestore() => <String, dynamic>{
    'id': id,
    'type': type.name,
    'order': order,
    'mediaType': mediaType.name,
    'storagePath': storagePath,
    if (downloadUrl != null) 'downloadUrl': downloadUrl,
    if (caption != null) 'caption': caption,
    if (durationSeconds != null) 'durationSeconds': durationSeconds,
    if (fileSizeBytes != null) 'fileSizeBytes': fileSizeBytes,
    if (mimeType != null) 'mimeType': mimeType,
    if (transcriptionText != null) 'transcriptionText': transcriptionText,
    if (transcriptionVtt != null) 'transcriptionVtt': transcriptionVtt,
  };

  factory MediaBlock.fromFirestore(Map<String, dynamic> data) {
    return MediaBlock(
      id: data['id'] as String? ?? '',
      order: (data['order'] as num?)?.toInt() ?? 0,
      mediaType: MediaType.fromString(data['mediaType'] as String?),
      storagePath: data['storagePath'] as String? ?? '',
      downloadUrl: data['downloadUrl'] as String?,
      caption: data['caption'] as String?,
      durationSeconds: (data['durationSeconds'] as num?)?.toInt(),
      fileSizeBytes: (data['fileSizeBytes'] as num?)?.toInt(),
      mimeType: data['mimeType'] as String?,
      transcriptionText: data['transcriptionText'] as String?,
      transcriptionVtt: data['transcriptionVtt'] as String?,
    );
  }

  @override
  MediaBlock copyWith({
    String? id,
    int? order,
    MediaType? mediaType,
    String? storagePath,
    String? downloadUrl,
    String? caption,
    int? durationSeconds,
    int? fileSizeBytes,
    String? mimeType,
    String? transcriptionText,
    String? transcriptionVtt,
  }) {
    return MediaBlock(
      id: id ?? this.id,
      order: order ?? this.order,
      mediaType: mediaType ?? this.mediaType,
      storagePath: storagePath ?? this.storagePath,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      caption: caption ?? this.caption,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType ?? this.mimeType,
      transcriptionText: transcriptionText ?? this.transcriptionText,
      transcriptionVtt: transcriptionVtt ?? this.transcriptionVtt,
    );
  }
}

/// Quiz block embedded in a lesson (either referencing a quiz or inline questions).
class QuizBlock extends ContentBlock {
  const QuizBlock({
    required super.id,
    required super.order,
    this.quizId,
    this.inlineQuestions = const [],
  }) : super(type: ContentBlockType.quiz);

  final String? quizId;
  final List<LessonMiniQuizQuestion> inlineQuestions;

  @override
  Map<String, dynamic> toFirestore() => <String, dynamic>{
    'id': id,
    'type': type.name,
    'order': order,
    if (quizId != null) 'quizId': quizId,
    'inlineQuestions': inlineQuestions
        .map(
          (q) => {
            'id': q.id,
            'prompt': q.prompt,
            'options': q.options,
            'correctIndex': q.correctIndex,
            'explanation': q.explanation,
          },
        )
        .toList(),
  };

  factory QuizBlock.fromFirestore(Map<String, dynamic> data) {
    final questions = (data['inlineQuestions'] as List<dynamic>? ?? []).map((
      q,
    ) {
      final m = q as Map<String, dynamic>;
      return LessonMiniQuizQuestion(
        id: m['id'] as String? ?? '',
        prompt: m['prompt'] as String? ?? '',
        options: List<String>.from(m['options'] as List? ?? []),
        correctIndex: (m['correctIndex'] as num?)?.toInt() ?? 0,
        explanation: m['explanation'] as String? ?? '',
      );
    }).toList();

    return QuizBlock(
      id: data['id'] as String? ?? '',
      order: (data['order'] as num?)?.toInt() ?? 0,
      quizId: data['quizId'] as String?,
      inlineQuestions: questions,
    );
  }

  @override
  QuizBlock copyWith({
    String? id,
    int? order,
    String? quizId,
    List<LessonMiniQuizQuestion>? inlineQuestions,
  }) {
    return QuizBlock(
      id: id ?? this.id,
      order: order ?? this.order,
      quizId: quizId ?? this.quizId,
      inlineQuestions: inlineQuestions ?? this.inlineQuestions,
    );
  }
}

/// ASTRA / Native interactive component block.
class InteractiveBlock extends ContentBlock {
  const InteractiveBlock({
    required super.id,
    required super.order,
    required this.componentType,
    this.parameters = const {},
    this.assetDependencies = const [],
    this.minAppVersion,
  }) : super(type: ContentBlockType.interactive);

  /// Unique registered component identifier (e.g. 'pythagoras_visual_v1')
  final String componentType;

  /// Component parameters passed to the interactive widget
  final Map<String, dynamic> parameters;

  /// Any asset paths required by the component
  final List<String> assetDependencies;

  /// Minimum mobile app version required to render this native component
  final String? minAppVersion;

  @override
  Map<String, dynamic> toFirestore() => <String, dynamic>{
    'id': id,
    'type': type.name,
    'order': order,
    'componentType': componentType,
    'parameters': parameters,
    'assetDependencies': assetDependencies,
    if (minAppVersion != null) 'minAppVersion': minAppVersion,
  };

  factory InteractiveBlock.fromFirestore(Map<String, dynamic> data) {
    return InteractiveBlock(
      id: data['id'] as String? ?? '',
      order: (data['order'] as num?)?.toInt() ?? 0,
      componentType: data['componentType'] as String? ?? '',
      parameters: Map<String, dynamic>.from(data['parameters'] as Map? ?? {}),
      assetDependencies: List<String>.from(
        data['assetDependencies'] as List? ?? [],
      ),
      minAppVersion: data['minAppVersion'] as String?,
    );
  }

  @override
  InteractiveBlock copyWith({
    String? id,
    int? order,
    String? componentType,
    Map<String, dynamic>? parameters,
    List<String>? assetDependencies,
    String? minAppVersion,
  }) {
    return InteractiveBlock(
      id: id ?? this.id,
      order: order ?? this.order,
      componentType: componentType ?? this.componentType,
      parameters: parameters ?? this.parameters,
      assetDependencies: assetDependencies ?? this.assetDependencies,
      minAppVersion: minAppVersion ?? this.minAppVersion,
    );
  }
}

/// Adapter converting between legacy [LessonContentSection] and V2 [ContentBlock].
class ContentBlockAdapter {
  const ContentBlockAdapter._();

  /// Converts legacy content sections into V2 [TextBlock]s.
  static List<ContentBlock> sectionsToBlocks(
    List<LessonContentSection> sections,
  ) {
    return sections.asMap().entries.map((entry) {
      final index = entry.key;
      final section = entry.value;
      return TextBlock(
        id: 'legacy_section_$index',
        order: index,
        title: section.title.isNotEmpty ? section.title : null,
        markdown: section.body,
      );
    }).toList();
  }

  /// Dual-write projection: projects V2 blocks to legacy [LessonContentSection]s.
  /// ONLY true [TextBlock]s are projected so older clients receive clean markdown
  /// without corrupted placeholders or fake text representations of media.
  static List<LessonContentSection> blocksToSections(
    List<ContentBlock> blocks,
  ) {
    final sortedBlocks = List<ContentBlock>.from(blocks)
      ..sort((a, b) => a.order.compareTo(b.order));

    return sortedBlocks
        .whereType<TextBlock>()
        .map(
          (textBlock) => LessonContentSection(
            title: textBlock.title ?? '',
            body: textBlock.markdown,
          ),
        )
        .toList();
  }
}
