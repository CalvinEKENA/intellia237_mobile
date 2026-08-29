import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/telemetry/intellia_telemetry.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_user_id.dart';
import '../data/offline_chapter_pack_store.dart';
import '../domain/learn_chapter.dart';
import 'learn_providers.dart';

typedef OfflineChapterKey = ({String subjectId, String chapterId});

final offlineChapterPackStoreProvider = FutureProvider<OfflineChapterPackStore>(
  (ref) {
    return OfflineChapterPackStore.open();
  },
);

final offlineChapterPacksProvider = FutureProvider<List<OfflineChapterPack>>((
  ref,
) async {
  final userId = requireAuthenticatedUserId(ref.watch(authControllerProvider));
  final store = await ref.watch(offlineChapterPackStoreProvider.future);
  return store.readAll(userId);
});

final offlineChapterPackProvider =
    FutureProvider.family<OfflineChapterPack?, OfflineChapterKey>((
      ref,
      key,
    ) async {
      final packs = await ref.watch(offlineChapterPacksProvider.future);
      for (final pack in packs) {
        if (pack.subjectId == key.subjectId &&
            pack.chapterId == key.chapterId) {
          return pack;
        }
      }
      return null;
    });

final offlineLearningActionsProvider = Provider<OfflineLearningActions>(
  OfflineLearningActions.new,
);

class OfflineLearningActions {
  OfflineLearningActions(this._ref);

  final Ref _ref;

  /// Charge chaque leçon avant d'écrire le manifeste. Une interruption réseau
  /// ne crée donc jamais un faux badge « disponible hors ligne ».
  Future<OfflineChapterPack> saveChapter(LearnChapter chapter) async {
    final userId = requireAuthenticatedUserId(
      _ref.read(authControllerProvider),
    );
    final academic = await _ref.read(studentAcademicContextProvider.future);
    final repository = _ref.read(learnRepositoryProvider);

    await Future.wait([
      for (final lesson in chapter.lessons)
        repository.fetchLesson(
          userId: userId,
          classLevel: academic.classLevel,
          series: academic.series,
          subjectId: chapter.subjectId,
          chapterId: chapter.id,
          lessonId: lesson.id,
        ),
    ]);

    final pack = OfflineChapterPack(
      classLevel: academic.classLevel,
      subjectId: chapter.subjectId,
      chapterId: chapter.id,
      lessonIds: [for (final lesson in chapter.lessons) lesson.id],
      savedAt: DateTime.now().toUtc(),
    );
    final store = await _ref.read(offlineChapterPackStoreProvider.future);
    await store.save(userId: userId, pack: pack);
    _invalidate(chapter.subjectId, chapter.id);
    await IntelliaTelemetry.offlinePackSaved(
      lessonCount: chapter.lessons.length,
    );
    return pack;
  }

  Future<void> removeChapter({
    required String subjectId,
    required String chapterId,
  }) async {
    final userId = requireAuthenticatedUserId(
      _ref.read(authControllerProvider),
    );
    final store = await _ref.read(offlineChapterPackStoreProvider.future);
    await store.remove(
      userId: userId,
      subjectId: subjectId,
      chapterId: chapterId,
    );
    _invalidate(subjectId, chapterId);
  }

  void _invalidate(String subjectId, String chapterId) {
    _ref.invalidate(offlineChapterPacksProvider);
    _ref.invalidate(
      offlineChapterPackProvider((subjectId: subjectId, chapterId: chapterId)),
    );
  }
}
