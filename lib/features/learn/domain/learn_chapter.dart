import 'learn_lesson.dart';

class LearnChapter {
  const LearnChapter({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.description,
    required this.lessons,
  });

  final String id;
  final String subjectId;
  final String title;
  final String description;
  final List<LearnLessonPreview> lessons;

  double get completion {
    if (lessons.isEmpty) {
      return 0;
    }

    final total = lessons.fold<double>(
      0,
      (sum, lesson) => sum + lesson.progress,
    );
    return total / lessons.length;
  }
}
