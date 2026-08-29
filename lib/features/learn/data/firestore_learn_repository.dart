import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../domain/learn_chapter.dart';
import '../domain/learn_lesson.dart';
import '../domain/learn_subject.dart';
import 'learn_catalog_cache.dart';
import 'learn_repository.dart';

/// Implémentation Firestore de [LearnRepository].
///
/// Structure Firestore :
///   classes/{classLevel}/subjects/{subjectId}/
///     chapters/{chapterId}/
///       lessons/{lessonId}
///   student_profiles/{userId}/lessonProgress/{subjectId}_{chapterId}_{lessonId}
class FirestoreLearnRepository implements LearnRepository {
  FirestoreLearnRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    LearnCatalogCache? catalogCache,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1'),
       _catalogCache = catalogCache ?? LearnCatalogCache();

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  final LearnCatalogCache _catalogCache;
  final Random _random = Random.secure();

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

  // Le catalogue change peu pendant une session. On met uniquement les
  // documents pédagogiques en cache mémoire ; la progression reste relue à
  // chaque appel afin qu'un résultat fraîchement enregistré soit immédiat.
  Future<List<_CatalogDocument>> _publishedSubjectsCatalog(String classLevel) =>
      _catalogCache.getOrLoad('subjects:$classLevel', () async {
        final snapshot = await _subjects(
          classLevel,
        ).where('status', isEqualTo: 'published').orderBy('order').get();
        final documents = snapshot.docs
            .map((doc) => _CatalogDocument(doc.id, doc.data()))
            .toList(growable: false);
        for (final document in documents) {
          _catalogCache.put<_CatalogDocument>(
            'subject:$classLevel:${document.id}',
            document,
          );
        }
        return documents;
      });

  Future<_CatalogDocument?> _subjectCatalog(
    String classLevel,
    String subjectId,
  ) => _catalogCache.getOrLoad('subject:$classLevel:$subjectId', () async {
    final snapshot = await _subjects(classLevel).doc(subjectId).get();
    final data = snapshot.data();
    return data == null ? null : _CatalogDocument(snapshot.id, data);
  });

  Future<List<_CatalogDocument>> _chaptersCatalog(
    String classLevel,
    String subjectId,
  ) => _catalogCache.getOrLoad('chapters:$classLevel:$subjectId', () async {
    final snapshot = await _chapters(
      classLevel,
      subjectId,
    ).orderBy('order').get();
    final documents = snapshot.docs
        .map((doc) => _CatalogDocument(doc.id, doc.data()))
        .toList(growable: false);
    for (final document in documents) {
      _catalogCache.put<_CatalogDocument>(
        'chapter:$classLevel:$subjectId:${document.id}',
        document,
      );
    }
    return documents;
  });

  Future<_CatalogDocument?> _chapterCatalog(
    String classLevel,
    String subjectId,
    String chapterId,
  ) => _catalogCache.getOrLoad(
    'chapter:$classLevel:$subjectId:$chapterId',
    () async {
      final snapshot = await _chapters(
        classLevel,
        subjectId,
      ).doc(chapterId).get();
      final data = snapshot.data();
      return data == null ? null : _CatalogDocument(snapshot.id, data);
    },
  );

  Future<List<_CatalogDocument>> _publishedLessonsCatalog(
    String classLevel,
    String subjectId,
    String chapterId,
  ) => _catalogCache.getOrLoad(
    'lessons:$classLevel:$subjectId:$chapterId',
    () async {
      final snapshot = await _lessons(
        classLevel,
        subjectId,
        chapterId,
      ).where('status', isEqualTo: 'published').orderBy('order').get();
      final documents = snapshot.docs
          .map((doc) => _CatalogDocument(doc.id, doc.data()))
          .toList(growable: false);
      for (final document in documents) {
        _catalogCache.put<_CatalogDocument>(
          'lesson:$classLevel:$subjectId:$chapterId:${document.id}',
          document,
        );
      }
      return documents;
    },
  );

  Future<_CatalogDocument?> _lessonCatalog(
    String classLevel,
    String subjectId,
    String chapterId,
    String lessonId,
  ) => _catalogCache.getOrLoad(
    'lesson:$classLevel:$subjectId:$chapterId:$lessonId',
    () async {
      final snapshot = await _lessons(
        classLevel,
        subjectId,
        chapterId,
      ).doc(lessonId).get();
      final data = snapshot.data();
      return data == null ? null : _CatalogDocument(snapshot.id, data);
    },
  );

  // ───── fetchSubjects ────────────────────────────────────────

  @override
  Future<List<LearnSubject>> fetchSubjects({
    required String userId,
    required String classLevel,
    required String? series,
  }) async {
    // Ces deux lectures sont indépendantes et démarrent en parallèle.
    final progressFuture = _progress(userId).get();
    final subjectsFuture = _publishedSubjectsCatalog(classLevel);
    final progressSnapshot = await progressFuture;
    final subjectDocuments = await subjectsFuture;
    final progress = _ProgressIndex({
      for (final doc in progressSnapshot.docs) doc.id: doc.data(),
    });

    final visibleSubjects = subjectDocuments
        .where((subject) {
          final allowedSeries = List<String>.from(
            subject.data['allowedSeries'] as List? ?? const [],
          );
          return allowedSeries.isEmpty ||
              (series != null && allowedSeries.contains(series));
        })
        .toList(growable: false);

    // Les anciennes lectures attendaient chaque sous-collection de chapitres
    // l'une après l'autre. Future.wait ramène la latence à celle de la requête
    // la plus lente. Un import peut aussi fournir `chapterSummaries` sur le
    // document matière et supprimer entièrement ces lectures secondaires.
    return Future.wait(
      visibleSubjects.map((subject) async {
        final sd = subject.data;
        final subjectId = subject.id;
        final chapterDocuments =
            _embeddedChapterCatalog(sd) ??
            await _chaptersCatalog(classLevel, subjectId);

        final chapterSummaries = chapterDocuments
            .map((chapter) {
              final cd = chapter.data;
              final lessonsCount = (cd['lessonsCount'] as num?)?.toInt() ?? 0;
              final totalProgress = progress.totalForChapter(
                subjectId,
                chapter.id,
              );
              return LearnChapterSummary(
                id: chapter.id,
                title: cd['title'] as String? ?? '',
                description: cd['description'] as String? ?? '',
                lessonsCount: lessonsCount,
                completion: lessonsCount > 0
                    ? (totalProgress / lessonsCount).clamp(0.0, 1.0)
                    : 0.0,
              );
            })
            .toList(growable: false);

        return LearnSubject(
          id: subjectId,
          title: sd['title'] as String? ?? '',
          description: sd['description'] as String? ?? '',
          colorHex: (sd['colorHex'] as num?)?.toInt() ?? 0xFF1451E1,
          iconKey: sd['iconKey'] as String? ?? 'book',
          chapters: chapterSummaries,
        );
      }),
    );
  }

  // ───── fetchSubjectDetail ─────────────────────────────────

  @override
  Future<LearnSubjectDetail> fetchSubjectDetail({
    required String userId,
    required String classLevel,
    required String? series,
    required String subjectId,
  }) async {
    final prefix = '${subjectId}_';
    final subjectFuture = _subjectCatalog(classLevel, subjectId);
    final chaptersFuture = _chaptersCatalog(classLevel, subjectId);
    final progressFuture = _progress(userId)
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: prefix)
        .where(FieldPath.documentId, isLessThanOrEqualTo: '$prefix\uf8ff')
        .get();

    final subject = await subjectFuture;
    if (subject == null) throw StateError('Matière introuvable: $subjectId');
    final chapterDocuments = await chaptersFuture;
    final progressSnapshot = await progressFuture;
    final progress = _ProgressIndex({
      for (final doc in progressSnapshot.docs) doc.id: doc.data(),
    });

    // Toutes les sous-collections de leçons sont lues en parallèle. Si le
    // chapitre contient `lessonPreviews`, l'import dénormalisé permet de ne
    // faire aucune lecture enfant pour ce chapitre.
    final chapters = await Future.wait(
      chapterDocuments.map((chapter) async {
        final cd = chapter.data;
        final chapterId = chapter.id;
        final lessonDocuments =
            _embeddedLessonCatalog(cd) ??
            await _publishedLessonsCatalog(classLevel, subjectId, chapterId);
        final lessons = lessonDocuments
            .map((lesson) {
              final ld = lesson.data;
              final lessonProgress = progress.forLesson(
                subjectId,
                chapterId,
                lesson.id,
              );
              return LearnLessonPreview(
                id: lesson.id,
                title: ld['title'] as String? ?? '',
                summary: ld['summary'] as String? ?? '',
                estimatedMinutes:
                    (ld['estimatedMinutes'] as num?)?.toInt() ?? 0,
                progress:
                    (lessonProgress?['progress'] as num?)?.toDouble() ?? 0,
                isFavorite: lessonProgress?['isFavorite'] as bool? ?? false,
              );
            })
            .toList(growable: false);

        return LearnChapter(
          id: chapterId,
          subjectId: subjectId,
          title: cd['title'] as String? ?? '',
          description: cd['description'] as String? ?? '',
          lessons: lessons,
        );
      }),
    );

    final sd = subject.data;

    return LearnSubjectDetail(
      id: subjectId,
      title: sd['title'] as String? ?? '',
      description: sd['description'] as String? ?? '',
      colorHex: (sd['colorHex'] as num?)?.toInt() ?? 0xFF1451E1,
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
    final prefix = '${subjectId}_${chapterId}_';
    final chapterFuture = _chapterCatalog(classLevel, subjectId, chapterId);
    final progressFuture = _progress(userId)
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: prefix)
        .where(FieldPath.documentId, isLessThanOrEqualTo: '$prefix\uf8ff')
        .get();

    final chapter = await chapterFuture;
    if (chapter == null) throw StateError('Chapitre introuvable: $chapterId');
    final progressSnapshot = await progressFuture;
    final lessonDocuments =
        _embeddedLessonCatalog(chapter.data) ??
        await _publishedLessonsCatalog(classLevel, subjectId, chapterId);
    final progress = _ProgressIndex({
      for (final doc in progressSnapshot.docs) doc.id: doc.data(),
    });

    final lessons = lessonDocuments
        .map((lesson) {
          final ld = lesson.data;
          final lessonProgress = progress.forLesson(
            subjectId,
            chapterId,
            lesson.id,
          );
          return LearnLessonPreview(
            id: lesson.id,
            title: ld['title'] as String? ?? '',
            summary: ld['summary'] as String? ?? '',
            estimatedMinutes: (ld['estimatedMinutes'] as num?)?.toInt() ?? 0,
            progress: (lessonProgress?['progress'] as num?)?.toDouble() ?? 0,
            isFavorite: lessonProgress?['isFavorite'] as bool? ?? false,
          );
        })
        .toList(growable: false);

    return LearnChapter(
      id: chapterId,
      subjectId: subjectId,
      title: chapter.data['title'] as String? ?? '',
      description: chapter.data['description'] as String? ?? '',
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
    final key = '${subjectId}_${chapterId}_$lessonId';
    final lessonFuture = _lessonCatalog(
      classLevel,
      subjectId,
      chapterId,
      lessonId,
    );
    final progressFuture = _progress(userId).doc(key).get();
    final lesson = await lessonFuture;
    if (lesson == null) throw StateError('Leçon introuvable: $lessonId');
    final progressDocument = await progressFuture;
    final data = lesson.data;
    final p = progressDocument.data();

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
      estimatedMinutes: (data['estimatedMinutes'] as num?)?.toInt() ?? 0,
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
    required String classLevel,
    required String subjectId,
    required String chapterId,
    required String lessonId,
    required double progress,
    String? clientEventId,
  }) async {
    final callable = _functions.httpsCallable('recordLessonProgress');
    try {
      await callable.call(<String, dynamic>{
        'classLevel': classLevel,
        'subjectId': subjectId,
        'chapterId': chapterId,
        'lessonId': lessonId,
        'progress': progress.clamp(0.0, 1.0),
        'clientEventId': clientEventId ?? _newClientEventId(),
      });
    } on FirebaseFunctionsException catch (error) {
      throw LessonProgressException.fromFunctions(error);
    }
  }

  String _newClientEventId() {
    final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    final entropy = _random.nextInt(1 << 32).toRadixString(36);
    return 'lesson_${timestamp}_$entropy';
  }
}

class _CatalogDocument {
  _CatalogDocument(this.id, Map<String, dynamic> data)
    : data = Map<String, dynamic>.unmodifiable(data);

  final String id;
  final Map<String, dynamic> data;
}

List<_CatalogDocument>? _embeddedChapterCatalog(Map<String, dynamic> subject) =>
    _embeddedCatalog(subject['chapterSummaries'], const ['id', 'chapterId']);

List<_CatalogDocument>? _embeddedLessonCatalog(Map<String, dynamic> chapter) =>
    _embeddedCatalog(chapter['lessonPreviews'], const ['id', 'lessonId']);

/// Lit une liste dénormalisée uniquement si elle est entièrement valide.
/// Au moindre élément incomplet, `null` force le repli sur la sous-collection
/// Firestore et évite d'afficher un catalogue partiel.
List<_CatalogDocument>? _embeddedCatalog(Object? raw, List<String> idKeys) {
  if (raw is! List) return null;
  final documents = <_CatalogDocument>[];
  for (final item in raw) {
    if (item is! Map) return null;
    final map = <String, dynamic>{
      for (final entry in item.entries)
        if (entry.key is String) entry.key as String: entry.value,
    };
    String? id;
    for (final key in idKeys) {
      final candidate = map[key];
      if (candidate is String && candidate.isNotEmpty) {
        id = candidate;
        break;
      }
    }
    if (id == null) return null;

    final nested = map['data'];
    final data = nested is Map
        ? <String, dynamic>{
            for (final entry in nested.entries)
              if (entry.key is String) entry.key as String: entry.value,
          }
        : map;
    documents.add(_CatalogDocument(id, data));
  }
  return documents;
}

class _ProgressIndex {
  _ProgressIndex(this._documents) {
    for (final entry in _documents.entries) {
      final data = entry.value;
      final subjectId = data['subjectId'];
      final chapterId = data['chapterId'];
      final value = (data['progress'] as num?)?.toDouble() ?? 0;
      if (subjectId is String && chapterId is String) {
        final key = _chapterKey(subjectId, chapterId);
        _chapterTotals[key] = (_chapterTotals[key] ?? 0) + value;
      } else if (value > 0) {
        _legacyProgress[entry.key] = value;
      }
    }
  }

  final Map<String, Map<String, dynamic>> _documents;
  final Map<String, double> _chapterTotals = {};
  final Map<String, double> _legacyProgress = {};

  Map<String, dynamic>? forLesson(
    String subjectId,
    String chapterId,
    String lessonId,
  ) => _documents['${subjectId}_${chapterId}_$lessonId'];

  double totalForChapter(String subjectId, String chapterId) {
    var total = _chapterTotals[_chapterKey(subjectId, chapterId)] ?? 0;
    final legacyPrefix = '${subjectId}_${chapterId}_';
    for (final entry in _legacyProgress.entries) {
      if (entry.key.startsWith(legacyPrefix)) total += entry.value;
    }
    return total;
  }

  static String _chapterKey(String subjectId, String chapterId) =>
      '$subjectId\u0000$chapterId';
}

class LessonProgressException implements Exception {
  const LessonProgressException(this.message, {required this.code});

  final String message;
  final String code;

  bool get isRetryable => const {
    'aborted',
    'cancelled',
    'deadline-exceeded',
    'internal',
    'resource-exhausted',
    'unavailable',
    'unauthenticated',
    'unknown',
  }.contains(code);

  factory LessonProgressException.fromFunctions(
    FirebaseFunctionsException error,
  ) {
    final message = switch (error.code) {
      'not-found' => 'Leçon introuvable ou indisponible.',
      'failed-precondition' =>
        'Cette progression ne peut pas être enregistrée.',
      'already-exists' => 'Cet événement de progression existe déjà.',
      'permission-denied' =>
        'Vous ne pouvez pas enregistrer cette progression.',
      'invalid-argument' => 'La progression envoyée est invalide.',
      'unauthenticated' => 'Connectez-vous pour enregistrer la progression.',
      _ => 'Impossible d\'enregistrer la progression pour le moment.',
    };

    return LessonProgressException(message, code: error.code);
  }

  @override
  String toString() => message;
}
