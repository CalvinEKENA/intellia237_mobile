import 'package:flutter/foundation.dart';

import '../../../core/academics/text_key.dart';

export '../../../core/academics/text_key.dart' show normalizeKey;

/// Version d'un schéma de pack : `intellia.runtime-learning-pack.v1`.
///
/// La famille identifie le fichier (source, pédagogie, exécution, rapport) ;
/// la version majeure décide de la compatibilité. Une version majeure plus
/// récente que celle que le moteur connaît est refusée, jamais devinée.
@immutable
class SchemaVersion {
  const SchemaVersion({
    required this.raw,
    required this.family,
    required this.major,
  });

  final String raw;
  final String family;
  final int major;

  static final _pattern = RegExp(r'^intellia\.([a-z0-9-]+)\.v(\d+)(?:\.\d+)*$');

  /// `null` si le texte ne suit pas le format attendu.
  static SchemaVersion? tryParse(String? raw) {
    if (raw == null) return null;
    final match = _pattern.firstMatch(raw.trim());
    if (match == null) return null;
    return SchemaVersion(
      raw: raw.trim(),
      family: match.group(1)!,
      major: int.parse(match.group(2)!),
    );
  }

  @override
  String toString() => raw;
}

/// Place d'un chapitre dans les programmes : pays, classe, matière.
@immutable
class Curriculum {
  const Curriculum({
    required this.country,
    required this.level,
    required this.subject,
    required this.chapterNumber,
    required this.chapterTitle,
    this.module,
    this.moduleNumber,
    this.moduleTitle,
    this.unitNumber,
    this.sequenceNumber,
  });

  final String country;

  /// Classe telle qu'écrite par le pack (ex. « Terminale D »).
  final String level;
  final String subject;
  final String? module;

  /// Numéro et titre de module (programmes organisés en modules et units,
  /// comme l'anglais).
  final int? moduleNumber;
  final String? moduleTitle;

  /// Numéro d'unit ; `null` pour un chapitre. Une unit reprend aussi
  /// [chapterNumber] et [chapterTitle] (numéro et titre dans son module).
  final int? unitNumber;

  /// Numéro de séquence ; `null` hors programmes en modules et séquences
  /// (comme la physique). Comme une unit, une séquence reprend
  /// [chapterNumber] et [chapterTitle] dans son module.
  final int? sequenceNumber;
  final int chapterNumber;
  final String chapterTitle;

  bool get isUnit => unitNumber != null;
  bool get isSequence => sequenceNumber != null;

  /// Clé de classe normalisée (ex. `terminale-d`), comparable au profil élève.
  String get levelKey => normalizeLevelKey(level);

  /// Clé de matière normalisée (ex. `mathematiques`, `anglais`) : un pack
  /// qui nomme sa matière dans sa langue (« English ») rejoint la même
  /// matière.
  String get subjectKey {
    final key = normalizeKey(subject);
    return _subjectAliases[key] ?? key;
  }

  static const _subjectAliases = {
    'english': 'anglais',
    'mathematics': 'mathematiques',
    'maths': 'mathematiques',
  };
}

/// Clé de classe : « Terminale D », « Tle D », « terminale » + série « D »
/// donnent toutes `terminale-d`.
String normalizeLevelKey(String level, {String? series}) {
  var key = normalizeKey(level);
  key = key.replaceFirst(RegExp(r'^tle(?=-|$)'), 'terminale');
  // « D », « Série D », « serie d » : seule la lettre de série compte.
  final seriesKey = series == null
      ? ''
      : normalizeKey(series).replaceFirst(RegExp(r'^serie-'), '');
  if (seriesKey.isNotEmpty && !key.endsWith('-$seriesKey')) {
    key = '$key-$seriesKey';
  }
  return key;
}
