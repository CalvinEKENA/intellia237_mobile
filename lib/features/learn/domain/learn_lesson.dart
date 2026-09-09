import 'content_block.dart';

class LessonContentSection {
  const LessonContentSection({required this.title, required this.body});

  final String title;
  final String body;
}

class LessonMiniQuizQuestion {
  const LessonMiniQuizQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String id;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;
}

class LearnLessonPreview {
  const LearnLessonPreview({
    required this.id,
    required this.title,
    required this.summary,
    required this.estimatedMinutes,
    required this.progress,
    required this.isFavorite,
  });

  final String id;
  final String title;
  final String summary;
  final int estimatedMinutes;
  final double progress;
  final bool isFavorite;

  bool get isCompleted => progress >= 1;
}

class LearnLesson extends LearnLessonPreview {
  const LearnLesson({
    required super.id,
    required super.title,
    required super.summary,
    required super.estimatedMinutes,
    required super.progress,
    required super.isFavorite,
    required this.contentSections,
    required this.miniQuiz,
    this.contentBlocks = const [],
    this.schemaVersion = 1,
  });

  /// Legacy text sections (maintained for backward compatibility and offline fallback).
  final List<LessonContentSection> contentSections;

  /// Legacy mini quiz questions (maintained for backward compatibility).
  final List<LessonMiniQuizQuestion> miniQuiz;

  /// Polymorphic V2 content blocks (text, media, quiz, interactive).
  final List<ContentBlock> contentBlocks;

  /// Schema version: 1 for legacy, 2 for Content Studio V2.
  final int schemaVersion;

  /// Returns effective content blocks:
  /// Uses [contentBlocks] if populated; otherwise dynamically projects legacy
  /// [contentSections] into [TextBlock]s so learners get a unified block stream.
  List<ContentBlock> get effectiveBlocks {
    if (contentBlocks.isNotEmpty) return contentBlocks;
    return ContentBlockAdapter.sectionsToBlocks(contentSections);
  }

  LearnLesson copyWith({
    String? title,
    String? summary,
    int? estimatedMinutes,
    double? progress,
    bool? isFavorite,
    List<LessonContentSection>? contentSections,
    List<LessonMiniQuizQuestion>? miniQuiz,
    List<ContentBlock>? contentBlocks,
    int? schemaVersion,
  }) {
    return LearnLesson(
      id: id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      progress: progress ?? this.progress,
      isFavorite: isFavorite ?? this.isFavorite,
      contentSections: contentSections ?? this.contentSections,
      miniQuiz: miniQuiz ?? this.miniQuiz,
      contentBlocks: contentBlocks ?? this.contentBlocks,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }
}
