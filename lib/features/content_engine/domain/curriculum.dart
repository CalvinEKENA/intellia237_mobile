import 'package:flutter/foundation.dart';

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
  });

  final String country;

  /// Classe telle qu'écrite par le pack (ex. « Terminale D »).
  final String level;
  final String subject;
  final String? module;
  final int chapterNumber;
  final String chapterTitle;

  /// Clé de classe normalisée (ex. `terminale-d`), comparable au profil élève.
  String get levelKey => normalizeLevelKey(level);

  /// Clé de matière normalisée (ex. `mathematiques`).
  String get subjectKey => normalizeKey(subject);
}

/// Minuscules, sans accents, mots reliés par des tirets.
String normalizeKey(String value) {
  const accents = {
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'á': 'a',
    'ç': 'c',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'í': 'i',
    'ô': 'o',
    'ö': 'o',
    'ó': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ú': 'u',
    'ÿ': 'y',
    'œ': 'oe',
    'æ': 'ae',
  };
  final lower = value.toLowerCase().trim();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(accents[char] ?? char);
  }
  return buffer
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
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
