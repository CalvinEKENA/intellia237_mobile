import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../student_home/domain/student_home_snapshot.dart';

/// Mémorise localement la dernière leçon réellement ouverte, par élève.
///
/// Source de vérité du « Reprendre » de l'accueil : fiable hors-ligne,
/// sans schéma serveur supplémentaire. La progression serveur reste
/// l'autorité pédagogique ; ceci n'est qu'un signet de navigation.
class LessonResumeStore {
  LessonResumeStore._(this._prefs);

  static const _keyPrefix = 'lesson_resume_v1_';

  final SharedPreferences _prefs;

  static Future<LessonResumeStore> create() async =>
      LessonResumeStore._(await SharedPreferences.getInstance());

  ResumeTarget? read(String userId) {
    final raw = _prefs.getString('$_keyPrefix$userId');
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final subjectId = map['subjectId'] as String?;
      final chapterId = map['chapterId'] as String?;
      final lessonId = map['lessonId'] as String?;
      if (subjectId == null || chapterId == null || lessonId == null) {
        return null;
      }
      return ResumeTarget(
        subjectId: subjectId,
        chapterId: chapterId,
        lessonId: lessonId,
        lessonTitle: map['lessonTitle'] as String? ?? 'Ta dernière leçon',
        subjectTitle: map['subjectTitle'] as String?,
        progress: ((map['progress'] as num?) ?? 0).toDouble().clamp(0.0, 1.0),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String userId, ResumeTarget target) async {
    await _prefs.setString(
      '$_keyPrefix$userId',
      jsonEncode(<String, Object?>{
        'subjectId': target.subjectId,
        'chapterId': target.chapterId,
        'lessonId': target.lessonId,
        'lessonTitle': target.lessonTitle,
        'subjectTitle': target.subjectTitle,
        'progress': target.progress,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  }

  Future<void> clear(String userId) async {
    await _prefs.remove('$_keyPrefix$userId');
  }
}

final lessonResumeStoreProvider = FutureProvider<LessonResumeStore>((ref) {
  return LessonResumeStore.create();
});
