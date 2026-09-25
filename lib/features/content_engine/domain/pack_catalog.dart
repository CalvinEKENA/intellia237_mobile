import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/academics/class_key.dart';

/// Version de ce moteur. Un pack qui exige davantage n'est jamais activé :
/// il attend une mise à jour de l'application, sans rien casser.
const kContentEngineVersion = 1;

/// État de publication d'un pack dans le catalogue distant.
enum PackStatus {
  /// Visible des élèves de ses classes.
  published,

  /// En préparation : jamais téléchargé.
  draft,

  /// Retiré : jamais téléchargé ; une copie locale n'est plus proposée.
  withdrawn;

  static PackStatus fromKey(String? key) => switch (key) {
    'published' || 'ready' => published,
    'withdrawn' || 'disabled' || 'retired' => withdrawn,
    _ => draft,
  };
}

/// Un pack annoncé par le catalogue distant.
@immutable
class CatalogPackEntry {
  const CatalogPackEntry({
    required this.id,
    required this.version,
    required this.classKeys,
    required this.status,
    required this.path,
    required this.sha256,
    this.subject,
    this.chapterTitle,
    this.minimumEngineVersion = 1,
    this.sizeBytes,
  });

  /// Identifiant stable (ex. `maths_td_ch01_arithmetique`).
  final String id;

  /// Version entière croissante du pack.
  final int version;

  /// Classes visées (ex. `terminale-d`, ou `terminale-c` + `terminale-d`).
  final List<ClassKey> classKeys;
  final PackStatus status;

  /// Chemin du bundle dans le stockage distant.
  final String path;

  /// Empreinte SHA-256 (hexadécimal) des octets exacts du bundle.
  final String sha256;
  final String? subject;
  final String? chapterTitle;
  final int minimumEngineVersion;
  final int? sizeBytes;

  bool get compatible => minimumEngineVersion <= kContentEngineVersion;

  /// Annoncé pour un élève de cette classe ?
  bool servesClass(ClassKey? student) =>
      student != null && student.admitsAny(classKeys);
}

/// Le catalogue distant : la seule chose lue à chaque rafraîchissement.
@immutable
class RemoteCatalog {
  const RemoteCatalog({required this.catalogVersion, required this.packs});

  final int catalogVersion;
  final List<CatalogPackEntry> packs;

  /// Lecture tolérante : une entrée illisible est ignorée, jamais devinée.
  /// `null` si le document entier est illisible.
  static RemoteCatalog? tryParse(String text) {
    try {
      final raw = jsonDecode(text);
      if (raw is! Map) return null;
      final packs = <CatalogPackEntry>[];
      for (final item in (raw['packs'] as List?) ?? const []) {
        if (item is! Map) continue;
        final id = item['id'];
        final version = item['version'];
        final path = item['path'] ?? item['url'];
        final sha = item['sha256'];
        if (id is! String || version is! int || path is! String) continue;
        if (sha is! String || !RegExp(r'^[0-9a-f]{64}$').hasMatch(sha)) {
          continue;
        }
        final keys = <ClassKey>[
          for (final key in [
            ...((item['class_keys'] as List?) ?? const []),
            if (item['class_key'] is String) item['class_key'],
          ])
            if (key is String) ...ClassKey.parseTargets(key),
        ];
        if (keys.isEmpty) continue;
        packs.add(
          CatalogPackEntry(
            id: id,
            version: version,
            classKeys: keys,
            status: PackStatus.fromKey(item['status'] as String?),
            path: path,
            sha256: sha,
            subject: item['subject'] as String?,
            chapterTitle: item['chapter_title'] as String?,
            minimumEngineVersion:
                (item['minimum_engine_version'] as num?)?.toInt() ?? 1,
            sizeBytes: (item['size_bytes'] as num?)?.toInt(),
          ),
        );
      }
      return RemoteCatalog(
        catalogVersion: (raw['catalog_version'] as num?)?.toInt() ?? 0,
        packs: packs,
      );
    } on FormatException {
      return null;
    }
  }
}

/// Un pack livré d'un seul tenant : les cinq documents dans un fichier.
///
/// Format `intellia.pack-bundle.v1`. Les documents sont repris tels quels :
/// le bundle ne fait que les transporter.
@immutable
class PackBundle {
  const PackBundle({
    required this.id,
    required this.version,
    required this.classKeys,
    required this.documents,
  });

  static const format = 'intellia.pack-bundle.v1';

  final String id;
  final int version;
  final List<ClassKey> classKeys;

  /// `manifest`, `source`, `pedagogy`, `runtime`, `validation`.
  final Map<String, Map<String, Object?>> documents;

  static PackBundle? tryParse(String text) {
    try {
      final raw = jsonDecode(text);
      if (raw is! Map || raw['format'] != format) return null;
      final id = raw['id'];
      final version = raw['version'];
      final docs = raw['documents'];
      if (id is! String || version is! int || docs is! Map) return null;
      return PackBundle(
        id: id,
        version: version,
        classKeys: [
          for (final key in (raw['class_keys'] as List?) ?? const [])
            if (key is String) ...ClassKey.parseTargets(key),
        ],
        documents: {
          for (final entry in docs.entries)
            if (entry.value is Map)
              '${entry.key}': Map<String, Object?>.from(entry.value as Map),
        },
      );
    } on FormatException {
      return null;
    }
  }
}
