import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/chapter.dart';
import 'content_pack_parser.dart';

/// D'où viennent les packs. Aucune implémentation n'appelle le réseau.
abstract interface class ContentPackSource {
  /// Dossiers contenant un `manifest.json`.
  Future<List<String>> packDirectories();

  /// Contenu d'un fichier, ou `null` s'il n'existe pas.
  Future<String?> read(String path);
}

/// Packs embarqués dans l'application (`assets/content/…`).
///
/// Chaque dossier de pack doit être déclaré dans `pubspec.yaml` ; un test
/// vérifie qu'aucun pack n'est oublié.
class AssetContentPackSource implements ContentPackSource {
  AssetContentPackSource({AssetBundle? bundle, this.root = 'assets/content/'})
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final String root;

  @override
  Future<List<String>> packDirectories() async {
    final manifest = await AssetManifest.loadFromAssetBundle(_bundle);
    final directories = <String>[
      for (final asset in manifest.listAssets())
        if (asset.startsWith(root) && asset.endsWith('/manifest.json'))
          asset.substring(0, asset.length - '/manifest.json'.length),
    ]..sort();
    return directories;
  }

  @override
  Future<String?> read(String path) async {
    try {
      return await _bundle.loadString(path);
    } on FlutterError {
      return null;
    }
  }
}

/// Catalogue et chargement des chapitres locaux, avec cache mémoire.
class ContentPackRepository {
  ContentPackRepository({
    required ContentPackSource source,
    ContentPackParser parser = const ContentPackParser(),
  }) : _source = source,
       _parser = parser;

  final ContentPackSource _source;
  final ContentPackParser _parser;
  final _chapters = <String, Future<Chapter>>{};
  Future<List<ChapterEntry>>? _catalog;

  static const _defaultFiles = {
    'source': 'source.json',
    'pedagogy': 'pedagogy.json',
    'runtime': 'runtime.json',
    'validation': 'validation_report.json',
  };

  /// Tous les chapitres disponibles (lecture légère).
  Future<List<ChapterEntry>> catalog() => _catalog ??= _loadCatalog();

  Future<List<ChapterEntry>> _loadCatalog() async {
    final entries = <ChapterEntry>[];
    for (final directory in await _source.packDirectories()) {
      final raw = await _raw(directory, full: false);
      if (raw == null) continue;
      final entry = _parser.entry(raw);
      if (entry != null) entries.add(entry);
    }
    entries.sort((a, b) {
      final level = a.curriculum.levelKey.compareTo(b.curriculum.levelKey);
      if (level != 0) return level;
      final subject = a.curriculum.subjectKey.compareTo(
        b.curriculum.subjectKey,
      );
      if (subject != 0) return subject;
      return a.curriculum.chapterNumber.compareTo(b.curriculum.chapterNumber);
    });
    return entries;
  }

  /// Matières d'une classe, avec leurs chapitres.
  Future<List<Subject>> subjectsFor(String levelKey) async {
    final bySubject = <String, List<ChapterEntry>>{};
    for (final entry in await catalog()) {
      if (entry.curriculum.levelKey != levelKey) continue;
      bySubject.putIfAbsent(entry.curriculum.subjectKey, () => []).add(entry);
    }
    return [
      for (final chapters in bySubject.values)
        Subject(
          key: chapters.first.curriculum.subjectKey,
          title: chapters.first.curriculum.subject,
          levelKey: levelKey,
          levelLabel: chapters.first.curriculum.level,
          chapters: List.unmodifiable(chapters),
        ),
    ];
  }

  /// Le chapitre complet ; lève [ContentPackNotFound] s'il n'existe pas.
  Future<Chapter> chapter(String contentId) =>
      _chapters[contentId] ??= _loadChapter(contentId);

  Future<Chapter> _loadChapter(String contentId) async {
    final entry = (await catalog()).where((e) => e.contentId == contentId);
    if (entry.isEmpty) throw ContentPackNotFound(contentId);
    final raw = await _raw(entry.first.directory, full: true);
    if (raw == null) throw ContentPackNotFound(contentId);
    return _parser.parse(raw);
  }

  Future<RawContentPack?> _raw(String directory, {required bool full}) async {
    final manifest = _decode(await _source.read('$directory/manifest.json'));
    if (manifest == null) return null;
    final files = {
      ..._defaultFiles,
      ...?(manifest['files'] as Map?)?.map(
        (key, value) => MapEntry('$key', '$value'),
      ),
    };
    Future<Map<String, Object?>?> load(String key) async =>
        _decode(await _source.read('$directory/${files[key]}'));
    return RawContentPack(
      directory: directory,
      manifest: manifest,
      source: await load('source'),
      pedagogy: full ? await load('pedagogy') : null,
      runtime: full ? await load('runtime') : null,
      validation: full ? await load('validation') : null,
    );
  }

  static Map<String, Object?>? _decode(String? text) {
    if (text == null) return null;
    try {
      final value = jsonDecode(text);
      return value is Map<String, Object?> ? value : null;
    } on FormatException {
      return null;
    }
  }
}

class ContentPackNotFound implements Exception {
  const ContentPackNotFound(this.contentId);
  final String contentId;

  @override
  String toString() => 'ContentPackNotFound($contentId)';
}
