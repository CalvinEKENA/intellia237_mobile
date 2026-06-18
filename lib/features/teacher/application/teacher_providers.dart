import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/mock_teacher_repository.dart';
import '../data/teacher_repository.dart';
import '../domain/teacher_models.dart';

final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  return MockTeacherRepository();
});

final _teacherUidProvider = Provider<String>((ref) {
  return ref.watch(authControllerProvider).userId ?? 'demo-teacher';
});

final teacherDashboardProvider = FutureProvider<TeacherDashboard>((ref) async {
  final repository = ref.watch(teacherRepositoryProvider);
  final teacherUid = ref.watch(_teacherUidProvider);
  return repository.fetchDashboard(teacherUid: teacherUid);
});

final teacherClassesProvider = FutureProvider<List<TeacherClassOverview>>((
  ref,
) async {
  final repository = ref.watch(teacherRepositoryProvider);
  final teacherUid = ref.watch(_teacherUidProvider);
  return repository.fetchClasses(teacherUid: teacherUid);
});

final teacherClassDetailProvider = FutureProvider.family<TeacherClassDetail, String>((
  ref,
  classId,
) async {
  final repository = ref.watch(teacherRepositoryProvider);
  final teacherUid = ref.watch(_teacherUidProvider);
  return repository.fetchClassDetail(teacherUid: teacherUid, classId: classId);
});

final teacherActionsProvider = Provider<TeacherActions>((ref) {
  return TeacherActions(ref);
});

class TeacherActions {
  TeacherActions(this._ref);

  final Ref _ref;

  Future<void> publishContent({
    required String classId,
    required String subject,
    required String title,
    required String chapterTitle,
    required String summary,
  }) async {
    final uid = _ref.read(_teacherUidProvider);
    await _ref.read(teacherRepositoryProvider).publishContent(
          teacherUid: uid,
          classId: classId,
          subject: subject,
          title: title,
          chapterTitle: chapterTitle,
          summary: summary,
        );
    _invalidateAll();
  }

  Future<void> createQuiz({
    required String classId,
    required String subject,
    required String quizTitle,
    required List<Map<String, dynamic>> questions,
  }) async {
    final uid = _ref.read(_teacherUidProvider);
    await _ref.read(teacherRepositoryProvider).createQuiz(
          teacherUid: uid,
          classId: classId,
          subject: subject,
          quizTitle: quizTitle,
          questions: questions,
        );
    _invalidateAll();
  }

  Future<void> publishAnnouncement({
    required String classId,
    required String title,
    required String message,
  }) async {
    final uid = _ref.read(_teacherUidProvider);
    await _ref.read(teacherRepositoryProvider).publishAnnouncement(
          teacherUid: uid,
          classId: classId,
          title: title,
          message: message,
        );
    _invalidateAll();
  }

  void _invalidateAll() {
    _ref.invalidate(teacherDashboardProvider);
    _ref.invalidate(teacherClassesProvider);
  }
}
