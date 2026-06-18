import 'learn_chapter.dart';

class LearnChapterSummary {
  const LearnChapterSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.lessonsCount,
    required this.completion,
  });

  final String id;
  final String title;
  final String description;
  final int lessonsCount;
  final double completion;
}

class LearnSubject {
  const LearnSubject({
    required this.id,
    required this.title,
    required this.description,
    required this.colorHex,
    required this.iconKey,
    required this.chapters,
  });

  final String id;
  final String title;
  final String description;
  final int colorHex;
  final String iconKey;
  final List<LearnChapterSummary> chapters;

  int get lessonsCount =>
      chapters.fold<int>(0, (sum, chapter) => sum + chapter.lessonsCount);

  double get completion {
    if (chapters.isEmpty) {
      return 0;
    }

    final total = chapters.fold<double>(
      0,
      (sum, chapter) => sum + chapter.completion,
    );
    return total / chapters.length;
  }
}

class LearnSubjectDetail {
  const LearnSubjectDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.colorHex,
    required this.iconKey,
    required this.chapters,
  });

  final String id;
  final String title;
  final String description;
  final int colorHex;
  final String iconKey;
  final List<LearnChapter> chapters;
}
