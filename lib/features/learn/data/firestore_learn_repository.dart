import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/learn_chapter.dart';
import '../domain/learn_lesson.dart';
import '../domain/learn_subject.dart';
import 'learn_repository.dart';

/// Implémentation Firestore de [LearnRepository].
///
/// Structure Firestore :
///   classes/{classLevel}/subjects/{subjectId}/
///     chapters/{chapterId}/
///       lessons/{lessonId}
///   student_profiles/{userId}/lessonProgress/{subjectId}_{chapterId}_{lessonId}
class FirestoreLearnRepository implements LearnRepository {
  FirestoreLearnRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // ───── Helpers ─────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _subjects(String cls) =>
      _db.collection('classes').doc(cls).collection('subjects');

  CollectionReference<Map<String, dynamic>> _chapters(
    String cls,
    String subjectId,
  ) => _subjects(cls).doc(subjectId).collection('chapters');

  CollectionReference<Map<String, dynamic>> _lessons(
    String cls,
    String subjectId,
    String chapterId,
  ) => _chapters(cls, subjectId).doc(chapterId).collection('lessons');

  CollectionReference<Map<String, dynamic>> _progress(String userId) => _db
      .collection('student_profiles')
      .doc(userId)
      .collection('lessonProgress');

  // ───── fetchSubjects ────────────────────────────────────────

  @override
  Future<List<LearnSubject>> fetchSubjects({
    required String userId,
    required String classLevel,
    required String? series,
  }) async {
    // Fetch all user progress in one batch
    final progressSnap = await _progress(userId).get();
    final progressMap = {for (final d in progressSnap.docs) d.id: d.data()};

    // Fetch published subjects sorted by order
    final subjectsSnap = await _subjects(
      classLevel,
    ).where('status', isEqualTo: 'published').orderBy('order').get();

    final subjects = <LearnSubject>[];

    for (final subjectDoc in subjectsSnap.docs) {
      final sd = subjectDoc.data();
      final subjectId = subjectDoc.id;

      // Filter by series if applicable
      final allowedSeries = List<String>.from(
        sd['allowedSeries'] as List? ?? [],
      );
      if (allowedSeries.isNotEmpty) {
        if (series == null || !allowedSeries.contains(series)) continue;
      }

      // Fetch chapters
      final chaptersSnap = await _chapters(
        classLevel,
        subjectId,
      ).orderBy('order').get();

      final chapterSummaries = <LearnChapterSummary>[];
      for (final chapterDoc in chaptersSnap.docs) {
        final cd = chapterDoc.data();
        final chapterId = chapterDoc.id;
        final lessonsCount = (cd['lessonsCount'] as int?) ?? 0;

        // Compute completion from cached progress map
        double totalProgress = 0;
        final prefix = '${subjectId}_${chapterId}_';
        for (final entry in progressMap.entries) {
          if (entry.key.startsWith(prefix)) {
            totalProgress += (entry.value['progress'] as num?)?.toDouble() ?? 0;
          }
        }
        final completion = lessonsCount > 0
            ? (totalProgress / lessonsCount).clamp(0.0, 1.0)
            : 0.0;

        chapterSummaries.add(
          LearnChapterSummary(
            id: chapterId,
            title: cd['title'] as String? ?? '',
            description: cd['description'] as String? ?? '',
            lessonsCount: lessonsCount,
            completion: completion,
          ),
        );
      }

      subjects.add(
        LearnSubject(
          id: subjectId,
          title: sd['title'] as String? ?? '',
          description: sd['description'] as String? ?? '',
          colorHex: (sd['colorHex'] as int?) ?? 0xFF1451E1,
          iconKey: sd['iconKey'] as String? ?? 'book',
          chapters: chapterSummaries,
        ),
      );
    }

    return subjects;
  }

  // ───── fetchSubjectDetail ─────────────────────────────────

  @override
  Future<LearnSubjectDetail> fetchSubjectDetail({
    required String userId,
    required String classLevel,
    required String? series,
    required String subjectId,
  }) async {
    final subjectDoc = await _subjects(classLevel).doc(subjectId).get();
    final sd = subjectDoc.data();
    if (sd == null) throw StateError('Matière introuvable: $subjectId');

    // Batch fetch progress for this subject
    final progressSnap = await _progress(userId)
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: '${subjectId}_')
        .where(FieldPath.documentId, isLessThan: '${subjectId}a')
        .get();
    final progressMap = {for (final d in progressSnap.docs) d.id: d.data()};

    final chaptersSnap = await _chapters(
      classLevel,
      subjectId,
    ).orderBy('order').get();

    final chapters = <LearnChapter>[];
    for (final chapterDoc in chaptersSnap.docs) {
      final cd = chapterDoc.data();
      final chapterId = chapterDoc.id;

      final lessonsSnap = await _lessons(
        classLevel,
        subjectId,
        chapterId,
      ).where('status', isEqualTo: 'published').orderBy('order').get();

      final lessons = lessonsSnap.docs.map((lessonDoc) {
        final ld = lessonDoc.data();
        final lessonId = lessonDoc.id;
        final key = '${subjectId}_${chapterId}_$lessonId';
        final p = progressMap[key];
        return LearnLessonPreview(
          id: lessonId,
          title: ld['title'] as String? ?? '',
          summary: ld['summary'] as String? ?? '',
          estimatedMinutes: (ld['estimatedMinutes'] as int?) ?? 0,
          progress: (p?['progress'] as num?)?.toDouble() ?? 0,
          isFavorite: p?['isFavorite'] as bool? ?? false,
        );
      }).toList();

      chapters.add(
        LearnChapter(
          id: chapterId,
          subjectId: subjectId,
          title: cd['title'] as String? ?? '',
          description: cd['description'] as String? ?? '',
          lessons: lessons,
        ),
      );
    }

    return LearnSubjectDetail(
      id: subjectId,
      title: sd['title'] as String? ?? '',
      description: sd['description'] as String? ?? '',
      colorHex: (sd['colorHex'] as int?) ?? 0xFF1451E1,
      iconKey: sd['iconKey'] as String? ?? 'book',
      chapters: chapters,
    );
  }

  // ───── fetchChapter ─────────────────────────────────────────

  @override
  Future<LearnChapter> fetchChapter({
    required String userId,
    required String classLevel,
    required String? series,
    required String subjectId,
    required String chapterId,
  }) async {
    final chapterDoc = await _chapters(
      classLevel,
      subjectId,
    ).doc(chapterId).get();
    final cd = chapterDoc.data();
    if (cd == null) throw StateError('Chapitre introuvable: $chapterId');

    // Fetch progress for this chapter
    final prefix = '${subjectId}_${chapterId}_';
    final progressSnap = await _progress(userId)
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: prefix)
        .where(FieldPath.documentId, isLessThan: '$prefix~')
        .get();
    final progressMap = {for (final d in progressSnap.docs) d.id: d.data()};

    final lessonsSnap = await _lessons(
      classLevel,
      subjectId,
      chapterId,
    ).where('status', isEqualTo: 'published').orderBy('order').get();

    final lessons = lessonsSnap.docs.map((lessonDoc) {
      final ld = lessonDoc.data();
      final lessonId = lessonDoc.id;
      final key = '${subjectId}_${chapterId}_$lessonId';
      final p = progressMap[key];
      return LearnLessonPreview(
        id: lessonId,
        title: ld['title'] as String? ?? '',
        summary: ld['summary'] as String? ?? '',
        estimatedMinutes: (ld['estimatedMinutes'] as int?) ?? 0,
        progress: (p?['progress'] as num?)?.toDouble() ?? 0,
        isFavorite: p?['isFavorite'] as bool? ?? false,
      );
    }).toList();

    return LearnChapter(
      id: chapterId,
      subjectId: subjectId,
      title: cd['title'] as String? ?? '',
      description: cd['description'] as String? ?? '',
      lessons: lessons,
    );
  }

  // ───── fetchLesson ──────────────────────────────────────────

  @override
  Future<LearnLesson> fetchLesson({
    required String userId,
    required String classLevel,
    required String? series,
    required String subjectId,
    required String chapterId,
    required String lessonId,
  }) async {
    final lessonDoc = await _lessons(
      classLevel,
      subjectId,
      chapterId,
    ).doc(lessonId).get();
    final data = lessonDoc.data();
    if (data == null) throw StateError('Leçon introuvable: $lessonId');

    // User progress
    final key = '${subjectId}_${chapterId}_$lessonId';
    final progressDoc = await _progress(userId).doc(key).get();
    final p = progressDoc.data();

    // contentSections
    final sections = (data['contentSections'] as List<dynamic>? ?? []).map((s) {
      final m = s as Map<String, dynamic>;
      return LessonContentSection(
        title: m['title'] as String? ?? '',
        body: m['body'] as String? ?? '',
      );
    }).toList();

    // miniQuiz
    final miniQuiz = (data['miniQuiz'] as List<dynamic>? ?? []).map((q) {
      final m = q as Map<String, dynamic>;
      return LessonMiniQuizQuestion(
        id: m['id'] as String? ?? '',
        prompt: m['prompt'] as String? ?? '',
        options: List<String>.from(m['options'] as List? ?? []),
        correctIndex: (m['correctIndex'] as int?) ?? 0,
        explanation: m['explanation'] as String? ?? '',
      );
    }).toList();

    return LearnLesson(
      id: lessonId,
      title: data['title'] as String? ?? '',
      summary: data['summary'] as String? ?? '',
      estimatedMinutes: (data['estimatedMinutes'] as int?) ?? 0,
      progress: (p?['progress'] as num?)?.toDouble() ?? 0,
      isFavorite: p?['isFavorite'] as bool? ?? false,
      contentSections: sections,
      miniQuiz: miniQuiz,
    );
  }

  // ───── toggleLessonFavorite ─────────────────────────────────

  @override
  Future<void> toggleLessonFavorite({
    required String userId,
    required String subjectId,
    required String chapterId,
    required String lessonId,
  }) async {
    final key = '${subjectId}_${chapterId}_$lessonId';
    final ref = _progress(userId).doc(key);
    final doc = await ref.get();
    final current = doc.data()?['isFavorite'] as bool? ?? false;
    await ref.set(<String, dynamic>{
      'isFavorite': !current,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ───── setLessonProgress ────────────────────────────────────

  @override
  Future<void> setLessonProgress({
    required String userId,
    required String subjectId,
    required String chapterId,
    required String lessonId,
    required double progress,
  }) async {
    final key = '${subjectId}_${chapterId}_$lessonId';
    await _progress(userId).doc(key).set(<String, dynamic>{
      'progress': progress.clamp(0.0, 1.0),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
