import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/learn/data/offline_chapter_pack_store.dart';
import 'package:intellia237/features/learn/data/offline_progress_queue.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('le manifeste hors ligne est isolé par élève et remplaçable', () async {
    SharedPreferences.setMockInitialValues(const {});
    final store = await OfflineChapterPackStore.open();
    final pack = OfflineChapterPack(
      classLevel: 'Terminale',
      subjectId: 'maths',
      chapterId: 'fonctions',
      lessonIds: const ['l1', 'l2'],
      savedAt: DateTime.utc(2026, 7, 16),
    );

    await store.save(userId: 'student-a', pack: pack);

    expect(
      (await store.read(
        userId: 'student-a',
        subjectId: 'maths',
        chapterId: 'fonctions',
      ))?.lessonIds,
      ['l1', 'l2'],
    );
    expect(await store.readAll('student-b'), isEmpty);

    await store.remove(
      userId: 'student-a',
      subjectId: 'maths',
      chapterId: 'fonctions',
    );
    expect(await store.readAll('student-a'), isEmpty);
  });

  test(
    'la file hors ligne fusionne une leçon en gardant le progrès maximal',
    () async {
      SharedPreferences.setMockInitialValues(const {});
      final queue = await OfflineProgressQueue.open();

      await queue.enqueue(
        userId: 'student-a',
        item: QueuedLessonProgress(
          clientEventId: 'event-1',
          classLevel: 'Terminale',
          subjectId: 'maths',
          chapterId: 'fonctions',
          lessonId: 'l1',
          progress: 0.8,
          queuedAt: DateTime.utc(2026, 7, 16),
        ),
      );
      await queue.enqueue(
        userId: 'student-a',
        item: QueuedLessonProgress(
          clientEventId: 'event-2',
          classLevel: 'Terminale',
          subjectId: 'maths',
          chapterId: 'fonctions',
          lessonId: 'l1',
          progress: 0.4,
          queuedAt: DateTime.utc(2026, 7, 16, 1),
        ),
      );

      final pending = await queue.readAll('student-a');
      expect(pending, hasLength(1));
      expect(pending.single.progress, 0.8);
      expect(pending.single.clientEventId, 'event-2');
    },
  );
}
