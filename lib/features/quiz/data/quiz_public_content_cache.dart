import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Small, sanitized cache for unreliable connections.
///
/// Only the answer-free payload returned by the public quiz callables is
/// persisted. Corrections and answer keys are never written here.
class QuizPublicContentCache {
  QuizPublicContentCache({
    Future<SharedPreferences> Function()? preferences,
    this.maxAge = const Duration(days: 14),
  }) : _preferences = preferences ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _preferences;
  final Duration maxAge;

  Future<void> writeList({
    required String classLevel,
    required String? series,
    required List<Map<String, dynamic>> quizzes,
  }) => _write(_listKey(classLevel, series), quizzes);

  Future<List<Map<String, dynamic>>?> readList({
    required String classLevel,
    required String? series,
  }) async {
    final value = await _read(_listKey(classLevel, series));
    if (value is! List) return null;
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Future<void> writeQuiz(String quizId, Map<String, dynamic> quiz) =>
      _write(_quizKey(quizId), quiz);

  Future<Map<String, dynamic>?> readQuiz(String quizId) async {
    final value = await _read(_quizKey(quizId));
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  Future<void> _write(String key, Object value) async {
    final preferences = await _preferences();
    await preferences.setString(
      key,
      jsonEncode(<String, dynamic>{
        'savedAt': DateTime.now().toUtc().toIso8601String(),
        'value': value,
      }),
    );
  }

  Future<Object?> _read(String key) async {
    final preferences = await _preferences();
    final raw = preferences.getString(key);
    if (raw == null) return null;
    try {
      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.tryParse(envelope['savedAt'] as String? ?? '');
      if (savedAt == null ||
          DateTime.now().toUtc().difference(savedAt) > maxAge) {
        await preferences.remove(key);
        return null;
      }
      return envelope['value'];
    } on FormatException {
      await preferences.remove(key);
      return null;
    } on TypeError {
      await preferences.remove(key);
      return null;
    }
  }

  String _listKey(String classLevel, String? series) =>
      'quiz_public_list_v1_${Uri.encodeComponent(classLevel)}_${Uri.encodeComponent(series ?? '_')}';

  String _quizKey(String quizId) =>
      'quiz_public_content_v1_${Uri.encodeComponent(quizId)}';
}
