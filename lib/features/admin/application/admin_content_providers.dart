import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/quiz/domain/quiz_question.dart';
import '../domain/admin_content_models.dart';

final _db = FirebaseFirestore.instance;

// ─────────────────────────────────────────────────────────────────────────────
// Class selector
// ─────────────────────────────────────────────────────────────────────────────

final selectedAdminClassProvider =
    StateProvider<String>((ref) => kAllClassLevels.first);

// ─────────────────────────────────────────────────────────────────────────────
// Subjects
// ─────────────────────────────────────────────────────────────────────────────

final adminSubjectsProvider =
    FutureProvider.family<List<AdminSubjectModel>, String>(
  (ref, classLevel) async {
    final subjectsSnap = await _db
        .collection('classes')
        .doc(classLevel)
        .collection('subjects')
        .orderBy('order')
        .get();

    final subjects = <AdminSubjectModel>[];
    for (final doc in subjectsSnap.docs) {
      // Count chapters
      final chaptersCount = await _db
          .collection('classes')
          .doc(classLevel)
          .collection('subjects')
          .doc(doc.id)
          .collection('chapters')
          .count()
          .get();

      subjects.add(AdminSubjectModel.fromFirestore(
        doc.id,
        classLevel,
        doc.data(),
        chaptersCount.count ?? 0,
      ));
    }
    return subjects;
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// Chapters
// ─────────────────────────────────────────────────────────────────────────────

final adminChaptersProvider =
    FutureProvider.family<List<AdminChapterModel>, ({String classLevel, String subjectId})>(
  (ref, args) async {
    final snap = await _db
        .collection('classes')
        .doc(args.classLevel)
        .collection('subjects')
        .doc(args.subjectId)
        .collection('chapters')
        .orderBy('order')
        .get();

    return snap.docs
        .map((d) => AdminChapterModel.fromFirestore(
              d.id,
              args.subjectId,
              args.classLevel,
              d.data(),
            ))
        .toList();
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// Lessons
// ─────────────────────────────────────────────────────────────────────────────

final adminLessonsProvider = FutureProvider.family<List<AdminLessonModel>,
    ({String classLevel, String subjectId, String chapterId})>(
  (ref, args) async {
    final snap = await _db
        .collection('classes')
        .doc(args.classLevel)
        .collection('subjects')
        .doc(args.subjectId)
        .collection('chapters')
        .doc(args.chapterId)
        .collection('lessons')
        .orderBy('order')
        .get();

    return snap.docs
        .map((d) => AdminLessonModel.fromFirestore(
              d.id,
              args.subjectId,
              args.chapterId,
              args.classLevel,
              d.data(),
            ))
        .toList();
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// Quizzes
// ─────────────────────────────────────────────────────────────────────────────

final adminQuizzesProvider =
    FutureProvider.family<List<AdminQuizModel>, String>(
  (ref, classLevel) async {
    final snap = await _db
        .collection('quizzes')
        .where('classLevels', arrayContains: classLevel)
        .get();

    return snap.docs
        .map((d) => AdminQuizModel.fromFirestore(d.id, d.data()))
        .toList();
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// CRUD notifier — Subjects
// ─────────────────────────────────────────────────────────────────────────────

class AdminContentActions {
  AdminContentActions(this._ref);

  final Ref _ref;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _subjectsRef(String cls) =>
      _db.collection('classes').doc(cls).collection('subjects');

  CollectionReference<Map<String, dynamic>> _chaptersRef(
          String cls, String subjectId) =>
      _subjectsRef(cls).doc(subjectId).collection('chapters');

  CollectionReference<Map<String, dynamic>> _lessonsRef(
          String cls, String subjectId, String chapterId) =>
      _chaptersRef(cls, subjectId).doc(chapterId).collection('lessons');

  // ── Subjects ─────────────────────────────────────────────

  Future<void> createSubject({
    required String classLevel,
    required String title,
    required String description,
    required int colorHex,
    required String iconKey,
    List<String> allowedSeries = const [],
  }) async {
    final existing = await _subjectsRef(classLevel).get();
    final order = existing.docs.length;
    await _subjectsRef(classLevel).doc().set(<String, dynamic>{
      'title': title,
      'description': description,
      'colorHex': colorHex,
      'iconKey': iconKey,
      'order': order,
      'status': 'draft',
      'allowedSeries': allowedSeries,
    });
    _ref.invalidate(adminSubjectsProvider(classLevel));
  }

  Future<void> updateSubjectStatus(
      String classLevel, String subjectId, String status) async {
    await _subjectsRef(classLevel)
        .doc(subjectId)
        .update({'status': status});
    _ref.invalidate(adminSubjectsProvider(classLevel));
  }

  Future<void> deleteSubject(String classLevel, String subjectId) async {
    await _subjectsRef(classLevel).doc(subjectId).delete();
    _ref.invalidate(adminSubjectsProvider(classLevel));
  }

  // ── Chapters ─────────────────────────────────────────────

  Future<void> createChapter({
    required String classLevel,
    required String subjectId,
    required String title,
    required String description,
  }) async {
    final existing = await _chaptersRef(classLevel, subjectId).get();
    final order = existing.docs.length;
    await _chaptersRef(classLevel, subjectId).doc().set(<String, dynamic>{
      'title': title,
      'description': description,
      'order': order,
      'lessonsCount': 0,
    });
    _ref.invalidate(adminChaptersProvider(
        (classLevel: classLevel, subjectId: subjectId)));
  }

  Future<void> deleteChapter(
      String classLevel, String subjectId, String chapterId) async {
    await _chaptersRef(classLevel, subjectId).doc(chapterId).delete();
    _ref.invalidate(adminChaptersProvider(
        (classLevel: classLevel, subjectId: subjectId)));
  }

  // ── Lessons ──────────────────────────────────────────────

  Future<String> createLesson({
    required String classLevel,
    required String subjectId,
    required String chapterId,
    required String title,
    required String summary,
    required int estimatedMinutes,
  }) async {
    final existing =
        await _lessonsRef(classLevel, subjectId, chapterId).get();
    final order = existing.docs.length;
    final ref = _lessonsRef(classLevel, subjectId, chapterId).doc();
    await ref.set(<String, dynamic>{
      'title': title,
      'summary': summary,
      'estimatedMinutes': estimatedMinutes,
      'order': order,
      'status': 'draft',
      'aiGenerated': false,
      'contentSections': [],
      'miniQuiz': [],
    });

    // Increment lessonsCount on chapter (denormalized)
    await _chaptersRef(classLevel, subjectId)
        .doc(chapterId)
        .update({'lessonsCount': FieldValue.increment(1)});

    _ref.invalidate(adminLessonsProvider((
      classLevel: classLevel,
      subjectId: subjectId,
      chapterId: chapterId,
    )));
    return ref.id;
  }

  Future<void> saveLesson(AdminLessonModel lesson) async {
    await _lessonsRef(lesson.classLevel, lesson.subjectId, lesson.chapterId)
        .doc(lesson.id)
        .update(lesson.toFirestore());
    _ref.invalidate(adminLessonsProvider((
      classLevel: lesson.classLevel,
      subjectId: lesson.subjectId,
      chapterId: lesson.chapterId,
    )));
  }

  Future<void> publishLesson(AdminLessonModel lesson) =>
      saveLesson(lesson.copyWith(status: 'published'));

  Future<void> deleteLesson({
    required String classLevel,
    required String subjectId,
    required String chapterId,
    required String lessonId,
  }) async {
    await _lessonsRef(classLevel, subjectId, chapterId).doc(lessonId).delete();
    await _chaptersRef(classLevel, subjectId)
        .doc(chapterId)
        .update({'lessonsCount': FieldValue.increment(-1)});
    _ref.invalidate(adminLessonsProvider((
      classLevel: classLevel,
      subjectId: subjectId,
      chapterId: chapterId,
    )));
  }

  // ── AI generation ─────────────────────────────────────────

  /// Génère un cours complet (sections) pour une leçon puis la sauvegarde.
  Future<AdminLessonModel> generateLessonContent(
      AdminLessonModel lesson) async {
    throw UnsupportedError(
      'La génération IA côté client a été supprimée. '
      'Utilisez le backend Firebase sécurisé pour ce flux.',
    );
  }

  /// Génère des questions de quiz à partir d'une leçon.
  Future<List<QuizQuestion>> generateQuizQuestions(
      AdminLessonModel lesson) async {
    throw UnsupportedError(
      'La génération IA côté client a été supprimée. '
      'Utilisez le backend Firebase sécurisé pour ce flux.',
    );
  }

  // ── Quizzes ───────────────────────────────────────────────

  Future<void> saveQuiz(AdminQuizModel quiz) async {
    if (quiz.id.isEmpty) {
      await _db.collection('quizzes').doc().set(quiz.toFirestore());
    } else {
      await _db.collection('quizzes').doc(quiz.id).set(quiz.toFirestore());
    }
    for (final cl in quiz.classLevels) {
      _ref.invalidate(adminQuizzesProvider(cl));
    }
  }

  Future<void> deleteQuiz(AdminQuizModel quiz) async {
    await _db.collection('quizzes').doc(quiz.id).delete();
    for (final cl in quiz.classLevels) {
      _ref.invalidate(adminQuizzesProvider(cl));
    }
  }

}

final adminContentActionsProvider = Provider<AdminContentActions>((ref) {
  return AdminContentActions(ref);
});
