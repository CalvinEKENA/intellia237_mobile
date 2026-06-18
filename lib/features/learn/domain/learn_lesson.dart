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
  });

  final List<LessonContentSection> contentSections;
  final List<LessonMiniQuizQuestion> miniQuiz;
}
