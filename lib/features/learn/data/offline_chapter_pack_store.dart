import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Manifeste d'un chapitre volontairement préparé pour une lecture hors ligne.
///
/// Le contenu reste dans le cache persistant Firestore, tandis que ce manifeste
/// permet à l'interface de ne promettre « disponible hors ligne » qu'après le
/// chargement réussi de toutes les leçons du chapitre.
class OfflineChapterPack {
  const OfflineChapterPack({
    required this.classLevel,
    required this.subjectId,
    required this.chapterId,
    required this.lessonIds,
    required this.savedAt,
  });

  final String classLevel;
  final String subjectId;
  final String chapterId;
  final List<String> lessonIds;
  final DateTime savedAt;

  String get key => '$subjectId::$chapterId';

  Map<String, Object> toJson() => {
    'classLevel': classLevel,
    'subjectId': subjectId,
    'chapterId': chapterId,
    'lessonIds': lessonIds,
    'savedAt': savedAt.toUtc().toIso8601String(),
  };

  static OfflineChapterPack? fromJson(Object? value) {
    if (value is! Map) return null;
    final map = Map<String, dynamic>.from(value);
    final classLevel = (map['classLevel'] as String?)?.trim();
    final subjectId = (map['subjectId'] as String?)?.trim();
    final chapterId = (map['chapterId'] as String?)?.trim();
    final savedAt = DateTime.tryParse(map['savedAt'] as String? ?? '');
    if (classLevel == null ||
        classLevel.isEmpty ||
        subjectId == null ||
        subjectId.isEmpty ||
        chapterId == null ||
        chapterId.isEmpty ||
        savedAt == null) {
      return null;
    }
    return OfflineChapterPack(
      classLevel: classLevel,
      subjectId: subjectId,
      chapterId: chapterId,
      lessonIds: (map['lessonIds'] as List? ?? const [])
          .whereType<String>()
          .where((id) => id.trim().isNotEmpty)
          .toList(growable: false),
      savedAt: savedAt,
    );
  }
}

class OfflineChapterPackStore {
  OfflineChapterPackStore(this._preferences);

  final SharedPreferences _preferences;
  static const _keyPrefix = 'intellia_offline_chapter_packs_v1_';

  static Future<OfflineChapterPackStore> open() async =>
      OfflineChapterPackStore(await SharedPreferences.getInstance());

  Future<List<OfflineChapterPack>> readAll(String userId) async {
    final raw = _preferences.getString('$_keyPrefix$userId');
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const [];
      return decoded.values
          .map(OfflineChapterPack.fromJson)
          .whereType<OfflineChapterPack>()
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<OfflineChapterPack?> read({
    required String userId,
    required String subjectId,
    required String chapterId,
  }) async {
    final key = '$subjectId::$chapterId';
    for (final pack in await readAll(userId)) {
      if (pack.key == key) return pack;
    }
    return null;
  }

  Future<void> save({
    required String userId,
    required OfflineChapterPack pack,
  }) async {
    final all = {for (final item in await readAll(userId)) item.key: item};
    all[pack.key] = pack;
    await _write(userId, all.values);
  }

  Future<void> remove({
    required String userId,
    required String subjectId,
    required String chapterId,
  }) async {
    final key = '$subjectId::$chapterId';
    final remaining = (await readAll(userId)).where((item) => item.key != key);
    await _write(userId, remaining);
  }

  Future<void> _write(String userId, Iterable<OfflineChapterPack> packs) async {
    final map = <String, Object>{
      for (final pack in packs) pack.key: pack.toJson(),
    };
    if (map.isEmpty) {
      await _preferences.remove('$_keyPrefix$userId');
      return;
    }
    await _preferences.setString('$_keyPrefix$userId', jsonEncode(map));
  }
}
