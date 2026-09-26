import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../../core/academics/class_key.dart';
import '../domain/pack_catalog.dart';
import 'content_pack_parser.dart';

// ── Source distante ─────────────────────────────────────────────────────

/// D'où viennent le catalogue et les bundles distants.
///
/// Internet ne sert qu'à découvrir et télécharger : une fois un pack validé
/// et mis en cache, plus aucun appel n'est nécessaire.
abstract interface class RemoteContentGateway {
  /// Octets du catalogue, ou `null` si le réseau n'est pas disponible.
  Future<Uint8List?> fetchCatalog();

  /// Octets d'un bundle ; lève en cas d'échec.
  Future<Uint8List> fetchBundle(String path);
}

// ── Cache persistant ────────────────────────────────────────────────────

/// Une version de pack présente sur l'appareil.
@immutable
class CachedPack {
  const CachedPack({
    required this.version,
    required this.sha256,
    required this.classKeys,
  });

  final int version;
  final String sha256;
  final List<String> classKeys;

  Map<String, Object?> toJson() => {
    'version': version,
    'sha256': sha256,
    'class_keys': classKeys,
  };

  static CachedPack? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final version = raw['version'];
    final sha = raw['sha256'];
    if (version is! int || sha is! String) return null;
    return CachedPack(
      version: version,
      sha256: sha,
      classKeys: [
        for (final key in (raw['class_keys'] as List?) ?? const [])
          if (key is String) key,
      ],
    );
  }
}

/// Version active d'un pack et, pour le retour arrière, la précédente.
@immutable
class CachedPackSlot {
  const CachedPackSlot({required this.active, this.previous});

  final CachedPack active;
  final CachedPack? previous;

  Map<String, Object?> toJson() => {
    'active': active.toJson(),
    if (previous != null) 'previous': previous!.toJson(),
  };

  static CachedPackSlot? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final active = CachedPack.fromJson(raw['active']);
    if (active == null) return null;
    return CachedPackSlot(
      active: active,
      previous: CachedPack.fromJson(raw['previous']),
    );
  }
}

/// Index du cache : quels packs, quelles versions, lesquels sont retirés.
@immutable
class ContentCacheIndex {
  const ContentCacheIndex({this.packs = const {}, this.withdrawn = const {}});

  static const empty = ContentCacheIndex();

  final Map<String, CachedPackSlot> packs;

  /// Packs retirés par le catalogue : conservés, jamais proposés.
  final Set<String> withdrawn;

  Map<String, Object?> toJson() => {
    'version': 1,
    'packs': {for (final e in packs.entries) e.key: e.value.toJson()},
    'withdrawn': withdrawn.toList()..sort(),
  };

  static ContentCacheIndex fromJson(Object? raw) {
    if (raw is! Map) return empty;
    final packs = <String, CachedPackSlot>{};
    final rawPacks = raw['packs'];
    if (rawPacks is Map) {
      for (final entry in rawPacks.entries) {
        final slot = CachedPackSlot.fromJson(entry.value);
        if (slot != null) packs['${entry.key}'] = slot;
      }
    }
    return ContentCacheIndex(
      packs: packs,
      withdrawn: {
        for (final id in (raw['withdrawn'] as List?) ?? const [])
          if (id is String) id,
      },
    );
  }
}

/// Stockage local des bundles validés.
abstract interface class ContentPackCache {
  Future<ContentCacheIndex> readIndex();
  Future<void> writeIndex(ContentCacheIndex index);
  Future<Uint8List?> readBundle(String id, int version);
  Future<void> writeBundle(String id, int version, Uint8List bytes);
  Future<void> deleteBundle(String id, int version);
}

/// Cache en mémoire (tests).
class InMemoryContentPackCache implements ContentPackCache {
  ContentCacheIndex index = ContentCacheIndex.empty;
  final bundles = <String, Uint8List>{};

  @override
  Future<ContentCacheIndex> readIndex() async => index;

  @override
  Future<void> writeIndex(ContentCacheIndex index) async => this.index = index;

  @override
  Future<Uint8List?> readBundle(String id, int version) async =>
      bundles['$id@$version'];

  @override
  Future<void> writeBundle(String id, int version, Uint8List bytes) async =>
      bundles['$id@$version'] = bytes;

  @override
  Future<void> deleteBundle(String id, int version) async =>
      bundles.remove('$id@$version');
}

// ── Validation d'un bundle ──────────────────────────────────────────────

String sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();

/// Transforme un bundle en pack brut pour le parseur commun.
RawContentPack rawFromBundle(PackBundle bundle) => RawContentPack(
  directory: 'remote/${bundle.id}/v${bundle.version}',
  manifest: {
    ...?bundle.documents['manifest'],
    'content_id': bundle.id,
    'version': bundle.version,
    'class_keys': [for (final key in bundle.classKeys) key.key],
  },
  source: bundle.documents['source'],
  pedagogy: bundle.documents['pedagogy'],
  runtime: bundle.documents['runtime'],
  validation: bundle.documents['validation'],
);

/// Pourquoi un pack distant n'a pas été activé.
enum PackRejection {
  incompatibleEngine,
  downloadFailed,
  checksumMismatch,
  unreadableBundle,
  identityMismatch,
  invalidPack,
}

@immutable
class ContentSyncReport {
  const ContentSyncReport({
    this.online = true,
    this.catalogValid = true,
    this.catalogVersion,
    this.added = const [],
    this.updated = const [],
    this.unchanged = const [],
    this.withdrawn = const [],
    this.rejected = const {},
  });

  /// Réseau indisponible : rien n'a changé, tout reste utilisable.
  static const offline = ContentSyncReport(online: false);

  final bool online;
  final bool catalogValid;
  final int? catalogVersion;
  final List<String> added;
  final List<String> updated;
  final List<String> unchanged;
  final List<String> withdrawn;
  final Map<String, PackRejection> rejected;

  bool get changed =>
      added.isNotEmpty || updated.isNotEmpty || withdrawn.isNotEmpty;
}

/// Découvre, télécharge, vérifie et active les packs de la classe de l'élève.
///
/// Un pack n'est activé que si : il est publié pour cette classe, le moteur
/// le sait lire, son empreinte correspond, il se lit et son rapport de
/// validation le permet. Sinon la dernière version valide reste en place.
class ContentSyncService {
  ContentSyncService({
    required this.gateway,
    required this.cache,
    this.parser = const ContentPackParser(),
  });

  final RemoteContentGateway gateway;
  final ContentPackCache cache;
  final ContentPackParser parser;

  Future<ContentSyncReport> sync(ClassKey student) async {
    final Uint8List? catalogBytes;
    try {
      catalogBytes = await gateway.fetchCatalog();
    } catch (_) {
      return ContentSyncReport.offline;
    }
    if (catalogBytes == null) return ContentSyncReport.offline;
    final catalog = RemoteCatalog.tryParse(
      utf8.decode(catalogBytes, allowMalformed: true),
    );
    if (catalog == null) {
      // Un catalogue illisible ne touche à rien.
      return const ContentSyncReport(catalogValid: false);
    }

    var index = await cache.readIndex();
    final packs = {...index.packs};
    final withdrawnIds = {...index.withdrawn};
    final added = <String>[];
    final updated = <String>[];
    final unchanged = <String>[];
    final withdrawn = <String>[];
    final rejected = <String, PackRejection>{};

    for (final entry in catalog.packs) {
      if (entry.status == PackStatus.withdrawn) {
        if (packs.containsKey(entry.id) && withdrawnIds.add(entry.id)) {
          withdrawn.add(entry.id);
        }
        continue;
      }
      if (entry.status != PackStatus.published || !entry.servesClass(student)) {
        continue; // Jamais téléchargé pour une autre classe.
      }
      withdrawnIds.remove(entry.id);
      final current = packs[entry.id]?.active;
      if (current != null && current.version >= entry.version) {
        unchanged.add(entry.id);
        continue;
      }
      if (!entry.compatible) {
        rejected[entry.id] = PackRejection.incompatibleEngine;
        continue;
      }
      final Uint8List bytes;
      try {
        bytes = await gateway.fetchBundle(entry.path);
      } catch (_) {
        rejected[entry.id] = PackRejection.downloadFailed;
        continue;
      }
      if (sha256Hex(bytes) != entry.sha256) {
        rejected[entry.id] = PackRejection.checksumMismatch;
        continue;
      }
      final bundle = PackBundle.tryParse(
        utf8.decode(bytes, allowMalformed: true),
      );
      if (bundle == null) {
        rejected[entry.id] = PackRejection.unreadableBundle;
        continue;
      }
      if (bundle.id != entry.id || bundle.version != entry.version) {
        rejected[entry.id] = PackRejection.identityMismatch;
        continue;
      }
      final chapter = parser.parse(rawFromBundle(bundle));
      if (!chapter.isPlayable) {
        rejected[entry.id] = PackRejection.invalidPack;
        continue;
      }
      await cache.writeBundle(entry.id, entry.version, bytes);
      final older = packs[entry.id]?.previous;
      packs[entry.id] = CachedPackSlot(
        active: CachedPack(
          version: entry.version,
          sha256: entry.sha256,
          classKeys: [for (final key in entry.classKeys) key.key],
        ),
        previous: current,
      );
      // Seules la version active et la précédente sont gardées.
      if (older != null) await cache.deleteBundle(entry.id, older.version);
      (current == null ? added : updated).add(entry.id);
    }

    index = ContentCacheIndex(packs: packs, withdrawn: withdrawnIds);
    await cache.writeIndex(index);
    return ContentSyncReport(
      catalogVersion: catalog.catalogVersion,
      added: added,
      updated: updated,
      unchanged: unchanged,
      withdrawn: withdrawn,
      rejected: rejected,
    );
  }
}
