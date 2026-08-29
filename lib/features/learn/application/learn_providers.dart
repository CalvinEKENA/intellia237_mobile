import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_status.dart';
import '../../../core/telemetry/intellia_telemetry.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_state.dart';
import '../../auth/application/auth_user_id.dart';
import '../../auth/domain/app_role.dart';
import '../data/firestore_learn_repository.dart';
import '../data/learn_repository.dart';
import '../data/offline_progress_queue.dart';

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

final offlineProgressQueueProvider = FutureProvider<OfflineProgressQueue>((
  ref,
) {
  return OfflineProgressQueue.open();
});

enum LessonProgressSaveStatus { synced, queued }

class OfflineProgressSyncResult {
  const OfflineProgressSyncResult({
    required this.synced,
    required this.discarded,
    required this.remaining,
  });

  final int synced;
  final int discarded;
  final int remaining;
}

class LearnActions {
  LearnActions(this._ref);

  final Ref _ref;
  final Random _random = Random.secure();
  bool _isSyncing = false;

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

  Future<LessonProgressSaveStatus> saveProgress({
    required String subjectId,
    required String chapterId,
    required String lessonId,
    required double progress,
  }) async {
    final context = await _ref.read(studentAcademicContextProvider.future);
    final userId = _ref.read(_learnUserIdProvider);
    final repository = _ref.read(learnRepositoryProvider);
    final clientEventId = _newClientEventId();

    if (_ref.read(isOfflineProvider)) {
      await _queueProgress(
        userId: userId,
        classLevel: context.classLevel,
        subjectId: subjectId,
        chapterId: chapterId,
        lessonId: lessonId,
        progress: progress,
        clientEventId: clientEventId,
      );
      return LessonProgressSaveStatus.queued;
    }

    try {
      await repository.setLessonProgress(
        userId: userId,
        classLevel: context.classLevel,
        subjectId: subjectId,
        chapterId: chapterId,
        lessonId: lessonId,
        progress: progress,
        clientEventId: clientEventId,
      );
    } on LessonProgressException catch (error) {
      if (!error.isRetryable) rethrow;
      await _queueProgress(
        userId: userId,
        classLevel: context.classLevel,
        subjectId: subjectId,
        chapterId: chapterId,
        lessonId: lessonId,
        progress: progress,
        clientEventId: clientEventId,
      );
      return LessonProgressSaveStatus.queued;
    }

    _refreshChain(
      subjectId: subjectId,
      chapterId: chapterId,
      lessonId: lessonId,
    );
    return LessonProgressSaveStatus.synced;
  }

  /// Rejoue séquentiellement les écritures en attente. Chaque événement garde
  /// son identifiant original : un timeout après écriture ne peut donc jamais
  /// doubler la progression ou la récompense côté serveur.
  Future<OfflineProgressSyncResult> flushQueuedProgress() async {
    if (_isSyncing || _ref.read(isOfflineProvider)) {
      return const OfflineProgressSyncResult(
        synced: 0,
        discarded: 0,
        remaining: 0,
      );
    }

    final auth = _ref.read(authControllerProvider);
    if (auth.status != AuthStatus.authenticated ||
        auth.role != AppRole.student ||
        auth.userId == null) {
      return const OfflineProgressSyncResult(
        synced: 0,
        discarded: 0,
        remaining: 0,
      );
    }

    _isSyncing = true;
    final userId = auth.userId!;
    var synced = 0;
    var discarded = 0;
    try {
      final queue = await _ref.read(offlineProgressQueueProvider.future);
      final repository = _ref.read(learnRepositoryProvider);
      final pending = await queue.readAll(userId);
      for (final item in pending) {
        try {
          await repository.setLessonProgress(
            userId: userId,
            classLevel: item.classLevel,
            subjectId: item.subjectId,
            chapterId: item.chapterId,
            lessonId: item.lessonId,
            progress: item.progress,
            clientEventId: item.clientEventId,
          );
          await queue.remove(userId, item.clientEventId);
          synced += 1;
          _refreshChain(
            subjectId: item.subjectId,
            chapterId: item.chapterId,
            lessonId: item.lessonId,
          );
        } on LessonProgressException catch (error) {
          if (error.isRetryable) break;
          // Le contenu a été supprimé, dépublié ou la requête locale est
          // invalide : la conserver bloquerait indéfiniment toute la file.
          await queue.remove(userId, item.clientEventId);
          discarded += 1;
        }
      }
      final remaining = (await queue.readAll(userId)).length;
      return OfflineProgressSyncResult(
        synced: synced,
        discarded: discarded,
        remaining: remaining,
      );
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _queueProgress({
    required String userId,
    required String classLevel,
    required String subjectId,
    required String chapterId,
    required String lessonId,
    required double progress,
    required String clientEventId,
  }) async {
    final queue = await _ref.read(offlineProgressQueueProvider.future);
    await queue.enqueue(
      userId: userId,
      item: QueuedLessonProgress(
        clientEventId: clientEventId,
        classLevel: classLevel,
        subjectId: subjectId,
        chapterId: chapterId,
        lessonId: lessonId,
        progress: progress.clamp(0.0, 1.0),
        queuedAt: DateTime.now().toUtc(),
      ),
    );
    await IntelliaTelemetry.offlineActionQueued(kind: 'lesson_progress');
  }

  String _newClientEventId() {
    final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    final entropy = _random.nextInt(1 << 32).toRadixString(36);
    return 'lesson_${timestamp}_$entropy';
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
