import 'flow_composer_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/quiz/domain/quiz_question.dart';
import '../data/admin_catalog_denormalization.dart';
import '../domain/admin_content_models.dart';

final _db = FirebaseFirestore.instance;

// ─────────────────────────────────────────────────────────────────────────────
// Class selector
// ─────────────────────────────────────────────────────────────────────────────

final selectedAdminClassProvider = StateProvider<String>(
  (ref) => kAllClassLevels.first,
);

// ─────────────────────────────────────────────────────────────────────────────
// Subjects
// ─────────────────────────────────────────────────────────────────────────────

final adminSubjectsProvider =
    FutureProvider.family<List<AdminSubjectModel>, String>((
      ref,
      classLevel,
    ) async {
      final subjectsSnap = await _db
          .collection('classes')
          .doc(classLevel)
          .collection('subjects')
          .orderBy('order')
          .get();

      final subjects = <AdminSubjectModel>[];
      for (final doc in subjectsSnap.docs) {
        final data = doc.data();
        final embedded = data['chapterSummaries'];
        // Les nouveaux documents sont lus sans requête N+1. Le count reste
        // uniquement un chemin de compatibilité pour les anciennes matières.
        final chapterCount = embedded is List
            ? readCatalogEntries(embedded).length
            : (await _db
                          .collection('classes')
                          .doc(classLevel)
                          .collection('subjects')
                          .doc(doc.id)
                          .collection('chapters')
                          .count()
                          .get())
                      .count ??
                  0;

        subjects.add(
          AdminSubjectModel.fromFirestore(
            doc.id,
            classLevel,
            data,
            chapterCount,
          ),
        );
      }
      return subjects;
    });

// ─────────────────────────────────────────────────────────────────────────────
// Chapters
// ─────────────────────────────────────────────────────────────────────────────

final adminChaptersProvider =
    FutureProvider.family<
      List<AdminChapterModel>,
      ({String classLevel, String subjectId})
    >((ref, args) async {
      final snap = await _db
          .collection('classes')
          .doc(args.classLevel)
          .collection('subjects')
          .doc(args.subjectId)
          .collection('chapters')
          .orderBy('order')
          .get();

      return snap.docs
          .map(
            (d) => AdminChapterModel.fromFirestore(
              d.id,
              args.subjectId,
              args.classLevel,
              d.data(),
            ),
          )
          .toList();
    });

// ─────────────────────────────────────────────────────────────────────────────
// Lessons
// ─────────────────────────────────────────────────────────────────────────────

final adminLessonsProvider =
    FutureProvider.family<
      List<AdminLessonModel>,
      ({String classLevel, String subjectId, String chapterId})
    >((ref, args) async {
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
          .map(
            (d) => AdminLessonModel.fromFirestore(
              d.id,
              args.subjectId,
              args.chapterId,
              args.classLevel,
              d.data(),
            ),
          )
          .toList();
    });

// ─────────────────────────────────────────────────────────────────────────────
// Quizzes
// ─────────────────────────────────────────────────────────────────────────────

final adminQuizzesProvider =
    FutureProvider.family<List<AdminQuizModel>, String>((
      ref,
      classLevel,
    ) async {
      final snap = await _db
          .collection('quizzes')
          .where('classLevels', arrayContains: classLevel)
          .get();

      return Future.wait(
        snap.docs.map((document) async {
          final answerKey = await _db
              .collection('quiz_answer_keys')
              .doc(document.id)
              .get();
          return AdminQuizModel.fromFirestore(
            document.id,
            document.data(),
            answerKeyData: answerKey.data(),
          );
        }),
      );
    });

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
    String cls,
    String subjectId,
  ) => _subjectsRef(cls).doc(subjectId).collection('chapters');

  CollectionReference<Map<String, dynamic>> _lessonsRef(
    String cls,
    String subjectId,
    String chapterId,
  ) => _chaptersRef(cls, subjectId).doc(chapterId).collection('lessons');

  Map<String, dynamic> _chapterSummary({
    required String id,
    required Map<String, dynamic> data,
    int? lessonsCount,
  }) => <String, dynamic>{
    'id': id,
    'title': data['title'] as String? ?? '',
    'description': data['description'] as String? ?? '',
    'lessonsCount':
        lessonsCount ?? (data['lessonsCount'] as num?)?.toInt() ?? 0,
    'order': (data['order'] as num?)?.toInt() ?? 0,
  };

  Map<String, dynamic> _lessonPreview({
    required String id,
    required Map<String, dynamic> data,
  }) => <String, dynamic>{
    'id': id,
    'classLevel': data['classLevel'] as String? ?? '',
    'subjectId': data['subjectId'] as String? ?? '',
    'chapterId': data['chapterId'] as String? ?? '',
    'title': data['title'] as String? ?? '',
    'summary': data['summary'] as String? ?? '',
    'estimatedMinutes': (data['estimatedMinutes'] as num?)?.toInt() ?? 0,
    'order': (data['order'] as num?)?.toInt() ?? 0,
  };

  Future<List<Map<String, dynamic>>> _legacyChapterSummaries(
    String classLevel,
    String subjectId,
  ) async {
    final snapshot = await _chaptersRef(
      classLevel,
      subjectId,
    ).orderBy('order').get();
    return snapshot.docs
        .map(
          (document) => _chapterSummary(id: document.id, data: document.data()),
        )
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _legacyPublishedLessonPreviews(
    String classLevel,
    String subjectId,
    String chapterId,
  ) async {
    final snapshot = await _lessonsRef(
      classLevel,
      subjectId,
      chapterId,
    ).where('status', isEqualTo: 'published').orderBy('order').get();
    return snapshot.docs
        .map(
          (document) => _lessonPreview(id: document.id, data: document.data()),
        )
        .toList(growable: false);
  }

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
      'chapterSummaries': <Map<String, dynamic>>[],
    });
    _ref.invalidate(adminSubjectsProvider(classLevel));
  }

  Future<void> updateSubjectStatus(
    String classLevel,
    String subjectId,
    String status,
  ) async {
    await _subjectsRef(classLevel).doc(subjectId).update({'status': status});
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
    final legacySummaries = await _legacyChapterSummaries(
      classLevel,
      subjectId,
    );
    final subjectRef = _subjectsRef(classLevel).doc(subjectId);
    final chapterRef = _chaptersRef(classLevel, subjectId).doc();

    await _db.runTransaction((transaction) async {
      final subjectSnapshot = await transaction.get(subjectRef);
      final subjectData = subjectSnapshot.data();
      if (subjectData == null) {
        throw StateError('Matière introuvable: $subjectId');
      }
      final current = subjectData.containsKey('chapterSummaries')
          ? subjectData['chapterSummaries']
          : legacySummaries;
      final entries = readCatalogEntries(current);
      final order =
          entries.fold<int>(
            -1,
            (maximum, entry) =>
                ((entry['order'] as num?)?.toInt() ?? 0) > maximum
                ? (entry['order'] as num?)?.toInt() ?? 0
                : maximum,
          ) +
          1;
      final chapterData = <String, dynamic>{
        'classLevel': classLevel,
        'subjectId': subjectId,
        'title': title,
        'description': description,
        'order': order,
        'lessonsCount': 0,
        'lessonPreviews': <Map<String, dynamic>>[],
      };

      transaction.set(chapterRef, chapterData);
      transaction.update(subjectRef, {
        'chapterSummaries': upsertCatalogEntry(
          current,
          _chapterSummary(id: chapterRef.id, data: chapterData),
        ),
      });
    });
    _ref.invalidate(adminSubjectsProvider(classLevel));
    _ref.invalidate(
      adminChaptersProvider((classLevel: classLevel, subjectId: subjectId)),
    );
  }

  Future<void> deleteChapter(
    String classLevel,
    String subjectId,
    String chapterId,
  ) async {
    final legacySummaries = await _legacyChapterSummaries(
      classLevel,
      subjectId,
    );
    final subjectRef = _subjectsRef(classLevel).doc(subjectId);
    final chapterRef = _chaptersRef(classLevel, subjectId).doc(chapterId);
    await _db.runTransaction((transaction) async {
      final subjectSnapshot = await transaction.get(subjectRef);
      final subjectData = subjectSnapshot.data();
      if (subjectData == null) {
        throw StateError('Matière introuvable: $subjectId');
      }
      final current = subjectData.containsKey('chapterSummaries')
          ? subjectData['chapterSummaries']
          : legacySummaries;
      transaction.delete(chapterRef);
      transaction.update(subjectRef, {
        'chapterSummaries': removeCatalogEntry(current, chapterId),
      });
    });
    _ref.invalidate(adminSubjectsProvider(classLevel));
    _ref.invalidate(
      adminChaptersProvider((classLevel: classLevel, subjectId: subjectId)),
    );
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
    final existing = await _lessonsRef(classLevel, subjectId, chapterId).get();
    final order = existing.docs.length;
    final ref = _lessonsRef(classLevel, subjectId, chapterId).doc();
    await ref.set(<String, dynamic>{
      'classLevel': classLevel,
      'subjectId': subjectId,
      'chapterId': chapterId,
      'title': title,
      'summary': summary,
      'estimatedMinutes': estimatedMinutes,
      'order': order,
      'status': 'draft',
      'aiGenerated': false,
      'contentSections': [],
      'miniQuiz': [],
      // Une leçon naît dans le périmètre de son auteur : les règles refusent
      // le programme national à qui ne l'administre pas.
      'scope': _ref.read(contentAuthoringScopeProvider).toFirestore(),
    });

    _ref.invalidate(
      adminLessonsProvider((
        classLevel: classLevel,
        subjectId: subjectId,
        chapterId: chapterId,
      )),
    );
    return ref.id;
  }

  Future<void> saveLesson(AdminLessonModel lesson) async {
    final legacyPreviewsFuture = _legacyPublishedLessonPreviews(
      lesson.classLevel,
      lesson.subjectId,
      lesson.chapterId,
    );
    final legacySummariesFuture = _legacyChapterSummaries(
      lesson.classLevel,
      lesson.subjectId,
    );
    final legacyPreviews = await legacyPreviewsFuture;
    final legacySummaries = await legacySummariesFuture;
    final subjectRef = _subjectsRef(lesson.classLevel).doc(lesson.subjectId);
    final chapterRef = _chaptersRef(
      lesson.classLevel,
      lesson.subjectId,
    ).doc(lesson.chapterId);
    final lessonRef = _lessonsRef(
      lesson.classLevel,
      lesson.subjectId,
      lesson.chapterId,
    ).doc(lesson.id);

    await _db.runTransaction((transaction) async {
      final chapterSnapshot = await transaction.get(chapterRef);
      final subjectSnapshot = await transaction.get(subjectRef);
      final chapterData = chapterSnapshot.data();
      final subjectData = subjectSnapshot.data();
      if (chapterData == null) {
        throw StateError('Chapitre introuvable: ${lesson.chapterId}');
      }
      if (subjectData == null) {
        throw StateError('Matière introuvable: ${lesson.subjectId}');
      }

      final currentPreviews = chapterData.containsKey('lessonPreviews')
          ? chapterData['lessonPreviews']
          : legacyPreviews;
      final lessonData = <String, dynamic>{
        ...lesson.toFirestore(),
        'classLevel': lesson.classLevel,
        'subjectId': lesson.subjectId,
        'chapterId': lesson.chapterId,
      };
      final previews = syncPublishedLessonPreview(
        current: currentPreviews,
        preview: _lessonPreview(id: lesson.id, data: lessonData),
        isPublished: lesson.isPublished,
      );
      final currentSummaries = subjectData.containsKey('chapterSummaries')
          ? subjectData['chapterSummaries']
          : legacySummaries;
      final summaries = upsertCatalogEntry(
        currentSummaries,
        _chapterSummary(
          id: lesson.chapterId,
          data: chapterData,
          lessonsCount: previews.length,
        ),
      );

      transaction.update(lessonRef, lessonData);
      transaction.update(chapterRef, {
        'lessonPreviews': previews,
        'lessonsCount': previews.length,
      });
      transaction.update(subjectRef, {'chapterSummaries': summaries});
    });
    _ref.invalidate(adminSubjectsProvider(lesson.classLevel));
    _ref.invalidate(
      adminChaptersProvider((
        classLevel: lesson.classLevel,
        subjectId: lesson.subjectId,
      )),
    );
    _ref.invalidate(
      adminLessonsProvider((
        classLevel: lesson.classLevel,
        subjectId: lesson.subjectId,
        chapterId: lesson.chapterId,
      )),
    );
  }

  Future<void> publishLesson(AdminLessonModel lesson) =>
      saveLesson(lesson.copyWith(status: 'published'));

  Future<void> deleteLesson({
    required String classLevel,
    required String subjectId,
    required String chapterId,
    required String lessonId,
  }) async {
    final legacyPreviewsFuture = _legacyPublishedLessonPreviews(
      classLevel,
      subjectId,
      chapterId,
    );
    final legacySummariesFuture = _legacyChapterSummaries(
      classLevel,
      subjectId,
    );
    final legacyPreviews = await legacyPreviewsFuture;
    final legacySummaries = await legacySummariesFuture;
    final subjectRef = _subjectsRef(classLevel).doc(subjectId);
    final chapterRef = _chaptersRef(classLevel, subjectId).doc(chapterId);
    final lessonRef = _lessonsRef(
      classLevel,
      subjectId,
      chapterId,
    ).doc(lessonId);

    await _db.runTransaction((transaction) async {
      final chapterSnapshot = await transaction.get(chapterRef);
      final subjectSnapshot = await transaction.get(subjectRef);
      final chapterData = chapterSnapshot.data();
      final subjectData = subjectSnapshot.data();
      if (chapterData == null) {
        throw StateError('Chapitre introuvable: $chapterId');
      }
      if (subjectData == null) {
        throw StateError('Matière introuvable: $subjectId');
      }

      final currentPreviews = chapterData.containsKey('lessonPreviews')
          ? chapterData['lessonPreviews']
          : legacyPreviews;
      final previews = removeCatalogEntry(currentPreviews, lessonId);
      final currentSummaries = subjectData.containsKey('chapterSummaries')
          ? subjectData['chapterSummaries']
          : legacySummaries;
      final summaries = upsertCatalogEntry(
        currentSummaries,
        _chapterSummary(
          id: chapterId,
          data: chapterData,
          lessonsCount: previews.length,
        ),
      );

      transaction.delete(lessonRef);
      transaction.update(chapterRef, {
        'lessonPreviews': previews,
        'lessonsCount': previews.length,
      });
      transaction.update(subjectRef, {'chapterSummaries': summaries});
    });
    _ref.invalidate(adminSubjectsProvider(classLevel));
    _ref.invalidate(
      adminChaptersProvider((classLevel: classLevel, subjectId: subjectId)),
    );
    _ref.invalidate(
      adminLessonsProvider((
        classLevel: classLevel,
        subjectId: subjectId,
        chapterId: chapterId,
      )),
    );
  }

  // ── AI generation ─────────────────────────────────────────

  /// Génère un cours complet (sections) pour une leçon puis la sauvegarde.
  Future<AdminLessonModel> generateLessonContent(
    AdminLessonModel lesson,
  ) async {
    throw UnsupportedError(
      'La génération IA côté client a été supprimée. '
      'Utilisez le backend Firebase sécurisé pour ce flux.',
    );
  }

  /// Génère des questions de quiz à partir d'une leçon.
  Future<List<QuizQuestion>> generateQuizQuestions(
    AdminLessonModel lesson,
  ) async {
    throw UnsupportedError(
      'La génération IA côté client a été supprimée. '
      'Utilisez le backend Firebase sécurisé pour ce flux.',
    );
  }

  // ── Quizzes ───────────────────────────────────────────────

  Future<void> saveQuiz(AdminQuizModel quiz) async {
    final quizRef = quiz.id.isEmpty
        ? _db.collection('quizzes').doc()
        : _db.collection('quizzes').doc(quiz.id);
    final answerKeyRef = _db.collection('quiz_answer_keys').doc(quizRef.id);
    final batch = _db.batch();
    batch.set(quizRef, quiz.toPublicFirestore());
    batch.set(answerKeyRef, quiz.toAnswerKeyFirestore());
    await batch.commit();
    for (final cl in quiz.classLevels) {
      _ref.invalidate(adminQuizzesProvider(cl));
    }
  }

  Future<void> deleteQuiz(AdminQuizModel quiz) async {
    final batch = _db.batch();
    batch.delete(_db.collection('quizzes').doc(quiz.id));
    batch.delete(_db.collection('quiz_answer_keys').doc(quiz.id));
    await batch.commit();
    for (final cl in quiz.classLevels) {
      _ref.invalidate(adminQuizzesProvider(cl));
    }
  }
}

final adminContentActionsProvider = Provider<AdminContentActions>((ref) {
  return AdminContentActions(ref);
});
