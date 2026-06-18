import '../domain/teacher_models.dart';

abstract class TeacherRepository {
  Future<TeacherDashboard> fetchDashboard({
    required String teacherUid,
  });

  Future<List<TeacherClassOverview>> fetchClasses({
    required String teacherUid,
  });

  Future<TeacherClassDetail> fetchClassDetail({
    required String teacherUid,
    required String classId,
  });

  Future<void> publishContent({
    required String teacherUid,
    required String classId,
    required String subject,
    required String title,
    required String chapterTitle,
    required String summary,
  });

  Future<void> createQuiz({
    required String teacherUid,
    required String classId,
    required String subject,
    required String quizTitle,
    required List<Map<String, dynamic>> questions,
  });

  Future<void> publishAnnouncement({
    required String teacherUid,
    required String classId,
    required String title,
    required String message,
  });
}
