import '../domain/learn_chapter.dart';
import '../domain/learn_lesson.dart';
import '../domain/learn_subject.dart';

abstract class LearnRepository {
  Future<List<LearnSubject>> fetchSubjects({
    required String userId,
    required String classLevel,
    required String? series,
  });

  Future<LearnSubjectDetail> fetchSubjectDetail({
    required String userId,
    required String classLevel,
    required String? series,
    required String subjectId,
  });

  Future<LearnChapter> fetchChapter({
    required String userId,
    required String classLevel,
    required String? series,
    required String subjectId,
    required String chapterId,
  });

  Future<LearnLesson> fetchLesson({
    required String userId,
    required String classLevel,
    required String? series,
    required String subjectId,
    required String chapterId,
    required String lessonId,
  });

  Future<void> toggleLessonFavorite({
    required String userId,
    required String subjectId,
    required String chapterId,
    required String lessonId,
  });

  Future<void> setLessonProgress({
    required String userId,
    required String classLevel,
    required String subjectId,
    required String chapterId,
    required String lessonId,
    required double progress,
  });
}
