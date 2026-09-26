import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/academics/class_key.dart';
import '../domain/chapter.dart';
import '../domain/pack_catalog.dart';
import 'content_delivery.dart';
import 'content_pack_parser.dart';

/// D'où viennent les packs embarqués. Aucune implémentation n'appelle le
/// réseau.
abstract interface class ContentPackSource {
  /// Dossiers contenant un `manifest.json`.
  Future<List<String>> packDirectories();

  /// Contenu d'un fichier, ou `null` s'il n'existe pas.
  Future<String?> read(String path);
}

/// Packs embarqués dans l'application (`assets/content/…`) : le secours.
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

/// Catalogue et chargement des chapitres, quelle que soit leur provenance.
///
/// Priorité, pour chaque pack :
/// 1. la version distante validée la plus récente, en cache sur l'appareil ;
/// 2. la version distante précédente (retour arrière automatique si la
///    version active ne se relit plus) ;
/// 3. le pack embarqué dans l'application ;
/// 4. sinon, indisponible.
///
/// Le reste du moteur ne sait pas d'où viennent les données.
class ContentPackRepository {
  ContentPackRepository({
    required ContentPackSource source,
    ContentPackCache? cache,
    ContentPackParser parser = const ContentPackParser(),
  }) : _source = source,
       _cache = cache,
       _parser = parser;

  final ContentPackSource _source;
  final ContentPackCache? _cache;
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
    final byId = <String, ChapterEntry>{};
    for (final directory in await _source.packDirectories()) {
      final raw = await _raw(directory, full: false);
      if (raw == null) continue;
      final entry = _parser.entry(raw);
      if (entry != null) byId[entry.contentId] = entry;
    }
    for (final entry in await _remoteEntries()) {
      final embedded = byId[entry.contentId];
      if (embedded == null || entry.version >= embedded.version) {
        byId[entry.contentId] = entry;
      }
    }
    return byId.values.toList()..sort((a, b) {
      final subject = a.curriculum.subjectKey.compareTo(
        b.curriculum.subjectKey,
      );
      if (subject != 0) return subject;
      final module = (a.curriculum.moduleNumber ?? 0).compareTo(
        b.curriculum.moduleNumber ?? 0,
      );
      if (module != 0) return module;
      return a.curriculum.chapterNumber.compareTo(b.curriculum.chapterNumber);
    });
  }

  /// Packs distants actifs et lisibles (les retirés ne sont pas proposés).
  Future<List<ChapterEntry>> _remoteEntries() async {
    final cache = _cache;
    if (cache == null) return const [];
    final index = await cache.readIndex();
    final entries = <ChapterEntry>[];
    for (final MapEntry(key: id, value: slot) in index.packs.entries) {
      if (index.withdrawn.contains(id)) continue;
      var bundle = await _readBundle(id, slot.active);
      if (bundle == null && slot.previous != null) {
        bundle = await _readBundle(id, slot.previous!);
      }
      if (bundle == null) continue;
      final entry = _parser.entry(rawFromBundle(bundle));
      if (entry == null) continue;
      entries.add(
        ChapterEntry(
          contentId: id,
          directory: 'remote/$id/v${bundle.version}',
          curriculum: entry.curriculum,
          lessonCount: entry.lessonCount,
          classKeys: entry.classKeys,
          version: bundle.version,
          origin: PackOrigin.remote,
        ),
      );
    }
    return entries;
  }

  /// Un bundle en cache, seulement si ses octets n'ont pas changé.
  Future<PackBundle?> _readBundle(String id, CachedPack pack) async {
    final bytes = await _cache!.readBundle(id, pack.version);
    if (bytes == null || sha256Hex(bytes) != pack.sha256) return null;
    return PackBundle.tryParse(utf8.decode(bytes, allowMalformed: true));
  }

  /// Matières proposées à un élève : seulement les packs de sa classe.
  Future<List<Subject>> subjectsFor(ClassKey? student) async {
    if (student == null) return const [];
    final bySubject = <String, List<ChapterEntry>>{};
    for (final entry in await catalog()) {
      if (!entry.servesClass(student)) continue;
      bySubject.putIfAbsent(entry.curriculum.subjectKey, () => []).add(entry);
    }
    return [
      for (final chapters in bySubject.values)
        Subject(
          key: chapters.first.curriculum.subjectKey,
          title: chapters.first.curriculum.subject,
          classKey: student,
          levelLabel: chapters.first.curriculum.level,
          chapters: List.unmodifiable(chapters),
        ),
    ];
  }

  /// Chapitres complets de la classe de l'élève, prêts pour le fil.
  Future<List<Chapter>> chaptersFor(ClassKey? student) async {
    final chapters = <Chapter>[];
    for (final subject in await subjectsFor(student)) {
      for (final entry in subject.chapters) {
        try {
          final chapter = await this.chapter(entry.contentId);
          if (chapter.isPlayable) chapters.add(chapter);
        } on ContentPackNotFound {
          // Pack devenu illisible : il est simplement absent.
        }
      }
    }
    return chapters;
  }

  /// Le chapitre complet ; lève [ContentPackNotFound] s'il n'existe pas.
  Future<Chapter> chapter(String contentId) =>
      _chapters[contentId] ??= _loadChapter(contentId);

  Future<Chapter> _loadChapter(String contentId) async {
    // 1–2. Distant actif, puis précédent.
    final cache = _cache;
    if (cache != null) {
      final index = await cache.readIndex();
      final slot = index.packs[contentId];
      if (slot != null && !index.withdrawn.contains(contentId)) {
        for (final pack in [slot.active, ?slot.previous]) {
          final bundle = await _readBundle(contentId, pack);
          if (bundle == null) continue;
          final chapter = _parser.parse(rawFromBundle(bundle));
          if (chapter.isPlayable) return chapter;
        }
      }
    }
    // 3. Embarqué.
    for (final directory in await _source.packDirectories()) {
      final light = await _raw(directory, full: false);
      if (light == null || _parser.entry(light)?.contentId != contentId) {
        continue;
      }
      final raw = await _raw(directory, full: true);
      if (raw != null) return _parser.parse(raw);
    }
    // 4. Indisponible.
    throw ContentPackNotFound(contentId);
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
