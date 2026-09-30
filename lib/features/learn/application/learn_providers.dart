import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_status.dart';
import '../../../core/telemetry/intellia_telemetry.dart';
import '../../../core/telemetry/startup_trace.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_user_id.dart';
import '../../auth/domain/app_role.dart';
import '../../student_registration/domain/academic_level_identity.dart';
import '../data/firestore_learn_repository.dart';
import '../data/learn_repository.dart';
import '../data/offline_progress_queue.dart';
import '../data/student_academic_profile_source.dart';

import '../domain/learn_academic_context.dart';
import '../domain/learn_chapter.dart';
import '../domain/learn_hub_snapshot.dart';
import '../domain/learn_lesson.dart';
import '../domain/learn_route_requests.dart';
import '../domain/learn_subject.dart';

final learnRepositoryProvider = Provider<LearnRepository>((ref) {
  // Une nouvelle publication reconstruit le dépôt (caches vidés). La
  // première révision lue n'est qu'un point de départ : la recevoir ne
  // relance pas le catalogue déjà en cours de lecture.
  ref.listen(learnCatalogRevisionProvider, (previous, next) {
    final before = previous?.valueOrNull;
    final after = next.valueOrNull;
    if (before != null && after != null && before != after) {
      ref.invalidateSelf();
    }
  });
  final establishmentId = ref.watch(
    authControllerProvider.select((auth) => auth.establishmentId),
  );
  return FirestoreLearnRepository(establishmentId: establishmentId);
});

// Parent indexes are updated in the publication commit. A catalog change
// rebuilds the repository, clearing both empty previews and cached lessons.
final learnCatalogRevisionProvider = StreamProvider.autoDispose<String>((
  ref,
) async* {
  await ref.watch(studentAcademicContextProvider.future);
  yield* FirebaseFirestore.instance
      .doc('content_catalog_state/revision')
      .snapshots()
      .map((snapshot) => snapshot.data()?['updatedAt'].toString() ?? 'initial')
      .distinct();
});

/// Profil académique de l'élève : sa classe décide de tout le reste
/// (catalogue, packs, quiz).
///
/// Registre de décisions (QA appareil, 28/09/2026) : sur réseau lent, la
/// lecture en ligne du profil (jusqu'à 8 s) retenait Apprendre, Quiz et les
/// packs embarqués eux-mêmes. Au premier chargement, le dernier profil
/// connu de l'appareil (cache local de Firestore) est servi aussitôt, puis
/// confirmé en ligne en arrière-plan ; une différence remplace la valeur.
/// Un rafraîchissement explicite (changement de classe, « Réessayer »)
/// relit toujours le serveur.
final studentAcademicContextProvider = FutureProvider<LearnAcademicContext>((
  ref,
) async {
  // Seule l'identité compte : un chargement ou une erreur d'authentification
  // ne relance pas la lecture du profil.
  final (authenticated, role, userId) = ref.watch(
    authControllerProvider.select(
      (auth) => (auth.isAuthenticated, auth.role, auth.userId),
    ),
  );

  if (!authenticated || role != AppRole.student || userId == null) {
    throw const AcademicProfileException(
      kind: AcademicProfileFailureKind.missing,
      normalizedErrorCode: 'unauthenticated',
      diagnosticId: 'ACADEMIC-PROFILE-201',
    );
  }

  final source = ref.watch(studentAcademicProfileSourceProvider);
  final memory = ref.watch(_academicProfileMemoryProvider);
  final confirmed = memory.takeConfirmed(userId);
  if (confirmed != null) return confirmed;

  if (source case final CachedStudentAcademicProfileSource cache
      when memory.isFirstLoad(userId)) {
    final cached = await StartupTrace.measure(
      'academic-profile (cache)',
      () => cache.fetchCached(userId),
    );
    final known = cached == null ? null : _tryAcademicContext(cached);
    if (known != null) {
      var disposed = false;
      ref.onDispose(() => disposed = true);
      unawaited(
        StartupTrace.measure(
              'academic-profile (confirmation en ligne)',
              () => source.fetch(userId),
            )
            .then((data) {
              final fresh = studentAcademicContextFromProfile(data);
              if (disposed ||
                  _academicSignature(fresh) == _academicSignature(known)) {
                return;
              }
              memory.confirm(userId, fresh);
              ref.invalidateSelf();
            })
            .catchError((Object _) {
              // Hors ligne ou lent : le profil connu reste en place.
            }),
      );
      return known;
    }
  }

  final data = await StartupTrace.measure(
    'academic-profile',
    () => source.fetch(userId),
  );
  return studentAcademicContextFromProfile(data);
});

LearnAcademicContext? _tryAcademicContext(Map<String, dynamic> data) {
  try {
    return studentAcademicContextFromProfile(data);
  } catch (_) {
    return null;
  }
}

String _academicSignature(LearnAcademicContext context) => [
  context.classLevel,
  context.series,
  context.catalogClassLevel,
  context.academicLevelId,
  context.displayClassLevel,
  context.educationalSubsystem,
  context.educationType,
  context.tutorId,
].join('|');

/// Ce que le profil académique retient entre deux évaluations : les
/// identités déjà chargées une fois, et une réponse en ligne à appliquer.
class _AcademicProfileMemory {
  final Set<String> _loaded = {};
  final Map<String, LearnAcademicContext> _confirmed = {};

  /// Vrai au tout premier chargement de [uid] (et le retient).
  bool isFirstLoad(String uid) => _loaded.add(uid);

  void confirm(String uid, LearnAcademicContext context) =>
      _confirmed[uid] = context;

  LearnAcademicContext? takeConfirmed(String uid) => _confirmed.remove(uid);
}

final _academicProfileMemoryProvider = Provider<_AcademicProfileMemory>(
  (ref) => _AcademicProfileMemory(),
);

/// Pure profile contract used by post-registration and compatibility tests.
LearnAcademicContext studentAcademicContextFromProfile(
  Map<String, dynamic> data,
) {
  final storedClassLevel = (data['classLevel'] as String?)?.trim();
  final preferences = data['preferences'];
  final preferenceMap = preferences is Map
      ? Map<String, dynamic>.from(preferences)
      : const <String, dynamic>{};
  final identity = AcademicLevelIdentity.resolve(
    academicLevelId: preferenceMap['academicLevelId'] as String?,
    storedClassLevel: storedClassLevel,
    educationalSubsystem: preferenceMap['educationalSubsystem'] as String?,
    educationType: preferenceMap['educationType'] as String?,
  );
  if (storedClassLevel == null ||
      storedClassLevel.isEmpty ||
      identity == null) {
    throw const AcademicProfileException(
      kind: AcademicProfileFailureKind.invalid,
      normalizedErrorCode: 'academic-class-mapping',
      diagnosticId: 'ACADEMIC-CLASS-205',
    );
  }

  final series = (data['series'] as String?)?.trim();
  final tutorId = (data['tutorId'] as String?)?.trim();
  return LearnAcademicContext(
    classLevel: storedClassLevel,
    series: series == null || series.isEmpty ? null : series,
    catalogClassLevel: identity.catalogKey,
    academicLevelId: identity.stableId,
    displayClassLevel: identity.displayLabel,
    educationalSubsystem: identity.subsystem.name,
    educationType: identity.educationType.name,
    tutorId: tutorId == null || tutorId.isEmpty ? null : tutorId,
  );
}

final _learnUserIdProvider = Provider<String>((ref) {
  ref.watch(
    authControllerProvider.select(
      (auth) => (auth.isAuthenticated, auth.userId),
    ),
  );
  return requireAuthenticatedUserId(ref.read(authControllerProvider));
});

final learnHubProvider = FutureProvider<LearnHubSnapshot>((ref) async {
  final repository = ref.watch(learnRepositoryProvider);
  final context = await ref.watch(studentAcademicContextProvider.future);
  final userId = ref.watch(_learnUserIdProvider);

  final subjects = await StartupTrace.measure(
    'learn-hub (catalogue en ligne)',
    () => repository.fetchSubjects(
      userId: userId,
      classLevel: context.quizAndCatalogClassLevel,
      series: context.series,
    ),
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
      classLevel: context.quizAndCatalogClassLevel,
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
        classLevel: context.quizAndCatalogClassLevel,
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
    classLevel: context.quizAndCatalogClassLevel,
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
    if (!auth.isAuthenticated ||
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
