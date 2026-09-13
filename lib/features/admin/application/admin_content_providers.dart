import '../../learn/domain/content_audience.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/content_origin.dart';
import '../domain/content_scope.dart';
import '../../learn/domain/learn_lesson.dart';
import 'flow_composer_providers.dart';
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
      final actor = ref.watch(contentActorProvider);
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
          .where(
            (d) =>
                actor?.canWriteInScope(
                  ContentScope.fromFirestore(d.data()['scope']),
                ) ??
                false,
          )
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
      final actor = ref.watch(contentActorProvider);
      final snap = await _db
          .collection('quizzes')
          .where('classLevels', arrayContains: classLevel)
          .get();

      return Future.wait(
        snap.docs
            .where(
              (doc) =>
                  actor?.canWriteInScope(
                    ContentScope.fromFirestore(doc.data()['scope']),
                  ) ??
                  false,
            )
            .map((document) async {
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

  // ── Subjects ─────────────────────────────────────────────

  Future<void> createSubject({
    required String classLevel,
    required String title,
    required String description,
    required int colorHex,
    required String iconKey,
    List<String> allowedSeries = const [],
    ContentAudience? audience,
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
      if (audience != null) 'audience': audience.toFirestore(),
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

  Future<void> deleteSubject(String classLevel, String subjectId) =>
      _deleteContent(classLevel, subjectId);

  // ── Chapters ─────────────────────────────────────────────

  Future<void> createChapter({
    required String classLevel,
    required String subjectId,
    required String title,
    required String description,
  }) async {
    await FirebaseFunctions.instanceFor(
      region: 'europe-west1',
    ).httpsCallable('createCatalogChapter').call<void>({
      'classLevel': classLevel,
      'subjectId': subjectId,
      'title': title,
      'description': description,
    });
    _invalidateCatalog(classLevel, subjectId);
  }

  Future<void> deleteChapter(
    String classLevel,
    String subjectId,
    String chapterId,
  ) => _deleteContent(classLevel, subjectId, chapterId);

  // ── Lessons ──────────────────────────────────────────────

  Future<String> createLesson({
    required String classLevel,
    required String subjectId,
    required String chapterId,
    required String title,
    required String summary,
    required int estimatedMinutes,
    List<LessonContentSection> contentSections = const [],
    List<LessonMiniQuizQuestion> miniQuiz = const [],
    ContentOrigin origin = ContentOrigin.manual,
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
      'aiGenerated': origin.source != ContentSourceType.manual,
      'contentSections': [
        for (final section in contentSections)
          {'title': section.title, 'body': section.body},
      ],
      'miniQuiz': [
        for (final question in miniQuiz)
          {
            'id': question.id,
            'prompt': question.prompt,
            'options': question.options,
            'correctIndex': question.correctIndex,
            'explanation': question.explanation,
          },
      ],
      'origin': origin.toFirestore(),
      'createdBy': _ref.read(contentActorProvider)?.uid,
      'createdAt': FieldValue.serverTimestamp(),
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

  Future<void> _persistLesson(
    AdminLessonModel lesson, {
    required bool publish,
  }) async {
    await FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable(
          'saveLessonPublication',
          options: HttpsCallableOptions(timeout: const Duration(minutes: 2)),
        )
        .call<void>({
          'classLevel': lesson.classLevel,
          'subjectId': lesson.subjectId,
          'chapterId': lesson.chapterId,
          'lessonId': lesson.id,
          'publish': publish,
          'content': lesson.toFirestore(),
        });
    _invalidateCatalog(lesson.classLevel, lesson.subjectId, lesson.chapterId);
  }

  void _invalidateCatalog(
    String classLevel,
    String subjectId, [
    String? chapterId,
  ]) {
    _ref.invalidate(adminSubjectsProvider(classLevel));
    _ref.invalidate(
      adminChaptersProvider((classLevel: classLevel, subjectId: subjectId)),
    );
    _ref.invalidate(adminQuizzesProvider(classLevel));
    _ref.invalidate(adminFlowItemsProvider(classLevel));
    if (chapterId != null) {
      _ref.invalidate(
        adminLessonsProvider((
          classLevel: classLevel,
          subjectId: subjectId,
          chapterId: chapterId,
        )),
      );
    }
  }

  Future<void> saveLesson(AdminLessonModel lesson) =>
      _persistLesson(lesson, publish: false);

  Future<void> publishLesson(AdminLessonModel lesson) =>
      _persistLesson(lesson, publish: true);

  Future<void> _deleteContent(
    String classLevel,
    String subjectId, [
    String? chapterId,
    String? lessonId,
  ]) async {
    await FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable(
          'deleteCatalogContent',
          options: HttpsCallableOptions(timeout: const Duration(minutes: 5)),
        )
        .call<void>({
          'classLevel': classLevel,
          'subjectId': subjectId,
          'chapterId': ?chapterId,
          'lessonId': ?lessonId,
        });
    _invalidateCatalog(classLevel, subjectId, chapterId);
  }

  Future<void> deleteLesson({
    required String classLevel,
    required String subjectId,
    required String chapterId,
    required String lessonId,
  }) => _deleteContent(classLevel, subjectId, chapterId, lessonId);

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
    final existing = quiz.id.isEmpty ? null : (await quizRef.get()).data();
    final scope =
        existing?['scope'] ??
        _ref.read(contentAuthoringScopeProvider).toFirestore();
    final batch = _db.batch();
    batch.set(quizRef, {
      ...?existing,
      ...quiz.toPublicFirestore(),
      'scope': scope,
    });
    batch.set(answerKeyRef, {...quiz.toAnswerKeyFirestore(), 'scope': scope});
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
