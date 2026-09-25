/// Construction d'un bundle de pack INTELLIA237 (`intellia.pack-bundle.v1`).
///
/// Dart pur (aucune dépendance à Flutter) : utilisable en ligne de commande
/// par `tool/content/publish_pack.dart` et par les tests de l'application,
/// qui vérifient ainsi que l'application lit exactement ce qui est publié.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const bundleFormat = 'intellia.pack-bundle.v1';

const _files = {
  'manifest': 'manifest.json',
  'source': 'source.json',
  'pedagogy': 'pedagogy.json',
  'runtime': 'runtime.json',
  'validation': 'validation_report.json',
};

/// Lit les cinq documents d'un dossier de pack, sans les modifier.
Map<String, Map<String, Object?>> readPackDocuments(Directory directory) {
  final manifestFile = File('${directory.path}/manifest.json');
  if (!manifestFile.existsSync()) {
    throw ArgumentError('manifest.json introuvable dans ${directory.path}');
  }
  final manifest =
      jsonDecode(manifestFile.readAsStringSync()) as Map<String, Object?>;
  final declared = (manifest['files'] as Map?)?.map(
    (key, value) => MapEntry('$key', '$value'),
  );
  final documents = <String, Map<String, Object?>>{'manifest': manifest};
  for (final MapEntry(key: role, value: name) in _files.entries) {
    if (role == 'manifest') continue;
    final file = File('${directory.path}/${declared?[role] ?? name}');
    if (!file.existsSync()) {
      throw ArgumentError('$role introuvable : ${file.path}');
    }
    documents[role] =
        jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  }
  return documents;
}

/// Assemble le bundle : les documents sont transportés tels quels.
Map<String, Object?> buildPackBundle({
  required String id,
  required int version,
  required List<String> classKeys,
  required Map<String, Map<String, Object?>> documents,
}) {
  if (!RegExp(r'^[a-z0-9_]+$').hasMatch(id)) {
    throw ArgumentError('Identifiant de pack invalide : $id');
  }
  if (version < 1) throw ArgumentError('La version doit être ≥ 1.');
  if (classKeys.isEmpty) throw ArgumentError('Au moins une classe visée.');
  return {
    'format': bundleFormat,
    'id': id,
    'version': version,
    'class_keys': classKeys,
    'documents': documents,
  };
}

/// Octets exacts publiés (UTF-8, JSON compact) et leur empreinte.
({List<int> bytes, String sha256}) encodeBundle(Map<String, Object?> bundle) {
  final bytes = utf8.encode(jsonEncode(bundle));
  return (bytes: bytes, sha256: sha256.convert(bytes).toString());
}

/// Entrée de catalogue correspondant à un bundle publié.
Map<String, Object?> catalogEntry({
  required String id,
  required int version,
  required List<String> classKeys,
  required String sha256,
  required int sizeBytes,
  String status = 'published',
  String? subject,
  String? chapterTitle,
  int minimumEngineVersion = 1,
}) => {
  'id': id,
  'version': version,
  'class_keys': classKeys,
  'status': status,
  'path': bundlePath(id, version),
  'sha256': sha256,
  'size_bytes': sizeBytes,
  'minimum_engine_version': minimumEngineVersion,
  'subject': ?subject,
  'chapter_title': ?chapterTitle,
};

/// Emplacement d'un bundle dans Firebase Storage.
String bundlePath(String id, int version) =>
    'content/packs/$id/v$version/bundle.json';

/// Ajoute (ou remplace) un pack dans un catalogue, et incrémente sa version.
Map<String, Object?> upsertCatalog(
  Map<String, Object?>? catalog,
  Map<String, Object?> entry,
) {
  final packs = [
    for (final pack in (catalog?['packs'] as List?) ?? const [])
      if (pack is Map && pack['id'] != entry['id'])
        Map<String, Object?>.from(pack),
    entry,
  ]..sort((a, b) => '${a['id']}'.compareTo('${b['id']}'));
  return {
    'catalog_version':
        ((catalog?['catalog_version'] as num?)?.toInt() ?? 0) + 1,
    'packs': packs,
  };
}
