import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_state.dart';
import '../../auth/application/auth_user_id.dart';
import '../../auth/domain/app_role.dart';
import '../data/firestore_learn_repository.dart';
import '../data/learn_repository.dart';

import '../domain/learn_academic_context.dart';
import '../domain/learn_chapter.dart';
import '../domain/learn_hub_snapshot.dart';
import '../domain/learn_lesson.dart';
import '../domain/learn_route_requests.dart';
import '../domain/learn_subject.dart';

final learnRepositoryProvider = Provider<LearnRepository>((ref) {
  return FirestoreLearnRepository();
});

final studentAcademicContextProvider = FutureProvider<LearnAcademicContext>((
  ref,
) async {
  final auth = ref.watch(authControllerProvider);

  if (auth.status != AuthStatus.authenticated ||
      auth.role != AppRole.student ||
      auth.userId == null) {
    return const LearnAcademicContext(classLevel: 'Terminale', series: 'D');
  }

  final uid = auth.userId!;

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('student_profiles')
        .doc(uid)
        .get();
    final data = snapshot.data();
    if (data == null) {
      return const LearnAcademicContext(classLevel: 'Terminale', series: 'D');
    }

    final classLevel = (data['classLevel'] as String?)?.trim();
    final series = (data['series'] as String?)?.trim();

    return LearnAcademicContext(
      classLevel: (classLevel == null || classLevel.isEmpty)
          ? 'Terminale'
          : classLevel,
      series: (series == null || series.isEmpty) ? null : series,
    );
  } catch (_) {
    return const LearnAcademicContext(classLevel: 'Terminale', series: 'D');
  }
});

final _learnUserIdProvider = Provider<String>((ref) {
  final auth = ref.watch(authControllerProvider);
  return requireAuthenticatedUserId(auth);
});

final learnHubProvider = FutureProvider<LearnHubSnapshot>((ref) async {
  final repository = ref.watch(learnRepositoryProvider);
  final context = await ref.watch(studentAcademicContextProvider.future);
  final userId = ref.watch(_learnUserIdProvider);

  final subjects = await repository.fetchSubjects(
    userId: userId,
    classLevel: context.classLevel,
    series: context.series,
  );

  return LearnHubSnapshot(context: context, subjects: subjects);
});

final subjectDetailProvider = FutureProvider.family<LearnSubjectDetail, String>(
  (ref, subjectId) async {
    final repository = ref.watch(learnRepositoryProvider);
    final context = await ref.watch(studentAcademicContextProvider.future);
    final userId = ref.watch(_learnUserIdProvider);

    return repository.fetchSubjectDetail(
      userId: userId,
      classLevel: context.classLevel,
      series: context.series,
      subjectId: subjectId,
    );
  },
);

final chapterDetailProvider =
    FutureProvider.family<LearnChapter, ChapterRequest>((ref, request) async {
      final repository = ref.watch(learnRepositoryProvider);
      final context = await ref.watch(studentAcademicContextProvider.future);
      final userId = ref.watch(_learnUserIdProvider);

      return repository.fetchChapter(
        userId: userId,
        classLevel: context.classLevel,
        series: context.series,
        subjectId: request.subjectId,
        chapterId: request.chapterId,
      );
    });

final lessonDetailProvider = FutureProvider.family<LearnLesson, LessonRequest>((
  ref,
  request,
) async {
  final repository = ref.watch(learnRepositoryProvider);
  final context = await ref.watch(studentAcademicContextProvider.future);
  final userId = ref.watch(_learnUserIdProvider);

  return repository.fetchLesson(
    userId: userId,
    classLevel: context.classLevel,
    series: context.series,
    subjectId: request.subjectId,
    chapterId: request.chapterId,
    lessonId: request.lessonId,
  );
});

final learnActionsProvider = Provider<LearnActions>((ref) {
  return LearnActions(ref);
});

class LearnActions {
  LearnActions(this._ref);

  final Ref _ref;

  Future<void> toggleFavorite({
    required String subjectId,
    required String chapterId,
    required String lessonId,
  }) async {
    final userId = _ref.read(_learnUserIdProvider);
    final repository = _ref.read(learnRepositoryProvider);

    await repository.toggleLessonFavorite(
      userId: userId,
      subjectId: subjectId,
      chapterId: chapterId,
      lessonId: lessonId,
    );

    _refreshChain(
      subjectId: subjectId,
      chapterId: chapterId,
      lessonId: lessonId,
    );
  }

  Future<void> saveProgress({
    required String subjectId,
    required String chapterId,
    required String lessonId,
    required double progress,
  }) async {
    final context = await _ref.read(studentAcademicContextProvider.future);
    final userId = _ref.read(_learnUserIdProvider);
    final repository = _ref.read(learnRepositoryProvider);

    await repository.setLessonProgress(
      userId: userId,
      classLevel: context.classLevel,
      subjectId: subjectId,
      chapterId: chapterId,
      lessonId: lessonId,
      progress: progress,
    );

    _refreshChain(
      subjectId: subjectId,
      chapterId: chapterId,
      lessonId: lessonId,
    );
  }

  void _refreshChain({
    required String subjectId,
    required String chapterId,
    required String lessonId,
  }) {
    _ref.invalidate(learnHubProvider);
    _ref.invalidate(subjectDetailProvider(subjectId));
    _ref.invalidate(
      chapterDetailProvider(
        ChapterRequest(subjectId: subjectId, chapterId: chapterId),
      ),
    );
    _ref.invalidate(
      lessonDetailProvider(
        LessonRequest(
          subjectId: subjectId,
          chapterId: chapterId,
          lessonId: lessonId,
        ),
      ),
    );
  }
}
