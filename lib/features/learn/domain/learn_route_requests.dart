class ChapterRequest {
  const ChapterRequest({required this.subjectId, required this.chapterId});

  final String subjectId;
  final String chapterId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChapterRequest &&
        other.subjectId == subjectId &&
        other.chapterId == chapterId;
  }

  @override
  int get hashCode => Object.hash(subjectId, chapterId);
}

class LessonRequest {
  const LessonRequest({
    required this.subjectId,
    required this.chapterId,
    required this.lessonId,
  });

  final String subjectId;
  final String chapterId;
  final String lessonId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LessonRequest &&
        other.subjectId == subjectId &&
        other.chapterId == chapterId &&
        other.lessonId == lessonId;
  }

  @override
  int get hashCode => Object.hash(subjectId, chapterId, lessonId);
}
