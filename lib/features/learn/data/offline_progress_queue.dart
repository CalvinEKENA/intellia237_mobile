import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class QueuedLessonProgress {
  const QueuedLessonProgress({
    required this.clientEventId,
    required this.classLevel,
    required this.subjectId,
    required this.chapterId,
    required this.lessonId,
    required this.progress,
    required this.queuedAt,
  });

  final String clientEventId;
  final String classLevel;
  final String subjectId;
  final String chapterId;
  final String lessonId;
  final double progress;
  final DateTime queuedAt;

  String get lessonKey => '$subjectId::$chapterId::$lessonId';

  Map<String, Object> toJson() => {
    'clientEventId': clientEventId,
    'classLevel': classLevel,
    'subjectId': subjectId,
    'chapterId': chapterId,
    'lessonId': lessonId,
    'progress': progress.clamp(0, 1),
    'queuedAt': queuedAt.toUtc().toIso8601String(),
  };

  static QueuedLessonProgress? fromJson(Object? value) {
    if (value is! Map) return null;
    final map = Map<String, dynamic>.from(value);
    final eventId = (map['clientEventId'] as String?)?.trim();
    final classLevel = (map['classLevel'] as String?)?.trim();
    final subjectId = (map['subjectId'] as String?)?.trim();
    final chapterId = (map['chapterId'] as String?)?.trim();
    final lessonId = (map['lessonId'] as String?)?.trim();
    final queuedAt = DateTime.tryParse(map['queuedAt'] as String? ?? '');
    final progress = map['progress'];
    if ([
          eventId,
          classLevel,
          subjectId,
          chapterId,
          lessonId,
        ].any((item) => item == null || item.isEmpty) ||
        queuedAt == null ||
        progress is! num) {
      return null;
    }
    return QueuedLessonProgress(
      clientEventId: eventId!,
      classLevel: classLevel!,
      subjectId: subjectId!,
      chapterId: chapterId!,
      lessonId: lessonId!,
      progress: progress.toDouble().clamp(0, 1),
      queuedAt: queuedAt,
    );
  }
}

/// File locale bornée et idempotente des progressions saisies sans réseau.
class OfflineProgressQueue {
  OfflineProgressQueue(this._preferences);

  final SharedPreferences _preferences;
  static const _keyPrefix = 'intellia_offline_progress_v1_';
  static const maxEntries = 100;

  static Future<OfflineProgressQueue> open() async =>
      OfflineProgressQueue(await SharedPreferences.getInstance());

  Future<List<QueuedLessonProgress>> readAll(String userId) async {
    final raw = _preferences.getString('$_keyPrefix$userId');
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .map(QueuedLessonProgress.fromJson)
          .whereType<QueuedLessonProgress>()
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> enqueue({
    required String userId,
    required QueuedLessonProgress item,
  }) async {
    final items = await readAll(userId);
    final existing = items.where((entry) => entry.lessonKey == item.lessonKey);
    final bestProgress = existing.fold<double>(
      item.progress,
      (best, entry) => entry.progress > best ? entry.progress : best,
    );
    final merged = [
      ...items.where((entry) => entry.lessonKey != item.lessonKey),
      QueuedLessonProgress(
        clientEventId: item.clientEventId,
        classLevel: item.classLevel,
        subjectId: item.subjectId,
        chapterId: item.chapterId,
        lessonId: item.lessonId,
        progress: bestProgress,
        queuedAt: item.queuedAt,
      ),
    ];
    final bounded = merged.length <= maxEntries
        ? merged
        : merged.sublist(merged.length - maxEntries);
    await _write(userId, bounded);
  }

  Future<void> remove(String userId, String clientEventId) async {
    final remaining = (await readAll(
      userId,
    )).where((item) => item.clientEventId != clientEventId);
    await _write(userId, remaining);
  }

  Future<void> _write(
    String userId,
    Iterable<QueuedLessonProgress> items,
  ) async {
    final list = items.map((item) => item.toJson()).toList(growable: false);
    if (list.isEmpty) {
      await _preferences.remove('$_keyPrefix$userId');
      return;
    }
    await _preferences.setString('$_keyPrefix$userId', jsonEncode(list));
  }
}
