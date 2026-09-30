import 'package:flutter/foundation.dart';

import 'text_key.dart';

/// Une classe du système éducatif, avec sa série quand elle compte :
/// `sixieme`, `troisieme`, `seconde`, `premiere-d`, `terminale-c`…
///
/// Clé unique de tout le filtrage : un élève ne voit un contenu que si sa
/// classe est admise par la cible du contenu. Rien n'est propre à une classe
/// particulière : les alias sont une table, la règle est la même partout.
@immutable
class ClassKey {
  const ClassKey(this.level, {this.series});

  /// Niveau canonique (`sixieme`, …, `terminale`, `form1`, `upper-sixth`).
  final String level;

  /// Série en minuscule (`c`, `d`, `a`…), ou `null` pour tout le niveau.
  final String? series;

  String get key => series == null ? level : '$level-$series';

  /// Niveaux connus et leurs écritures courantes.
  static const _levels = <String, List<String>>{
    'sixieme': ['sixieme', '6eme', '6e', '6ieme'],
    'cinquieme': ['cinquieme', '5eme', '5e'],
    'quatrieme': ['quatrieme', '4eme', '4e'],
    'troisieme': ['troisieme', '3eme', '3e'],
    'seconde': ['seconde', '2nde', '2de'],
    'premiere': ['premiere', '1ere', '1re'],
    'terminale': ['terminale', 'tle', 'term'],
    'form1': ['form1', 'form-1'],
    'form2': ['form2', 'form-2'],
    'form3': ['form3', 'form-3'],
    'form4': ['form4', 'form-4'],
    'form5': ['form5', 'form-5'],
    'lower-sixth': ['lower-sixth', 'lowersixth'],
    'upper-sixth': ['upper-sixth', 'uppersixth'],
  };

  /// Niveau canonique d'une écriture libre, ou `null` si inconnue.
  static String? canonicalLevel(String? raw) {
    if (raw == null) return null;
    final key = normalizeKey(raw);
    for (final entry in _levels.entries) {
      if (entry.value.contains(key)) return entry.key;
    }
    return null;
  }

  /// Classe d'un élève d'après son profil (classe + série éventuelle).
  static ClassKey? fromProfile(String? classLevel, {String? series}) {
    final level = canonicalLevel(classLevel);
    if (level == null) return null;
    final seriesKey = _seriesKey(series);
    return ClassKey(level, series: seriesKey);
  }

  static String? _seriesKey(String? raw) {
    if (raw == null) return null;
    final key = normalizeKey(raw).replaceFirst(RegExp(r'^serie-'), '');
    return key.isEmpty ? null : key;
  }

  /// Lit une ou plusieurs cibles : `terminale-d`, `Terminale D`, `6eme`,
  /// `terminale-c-d` (C et D), `premiere`. Vide si illisible.
  static List<ClassKey> parseTargets(String raw) {
    final key = normalizeKey(raw);
    for (final entry in _levels.entries) {
      for (final alias in entry.value) {
        if (key == alias) return [ClassKey(entry.key)];
        if (key.startsWith('$alias-')) {
          final rest = key.substring(alias.length + 1);
          final parts = rest.split('-').where((p) => p.isNotEmpty).toList();
          if (parts.isEmpty) return [ClassKey(entry.key)];
          if (parts.first == 'serie') parts.removeAt(0);
          return [for (final part in parts) ClassKey(entry.key, series: part)];
        }
      }
    }
    return const [];
  }

  /// Vrai si un contenu destiné à [target] convient à cet élève.
  ///
  /// Même niveau obligatoire. Une cible sans série vaut pour toutes les
  /// séries du niveau ; une cible avec série exige la même série.
  bool admits(ClassKey target) =>
      target.level == level &&
      (target.series == null || target.series == series);

  /// Vrai si l'une des cibles convient.
  bool admitsAny(Iterable<ClassKey> targets) => targets.any(admits);

  @override
  bool operator ==(Object other) =>
      other is ClassKey && other.level == level && other.series == series;

  @override
  int get hashCode => Object.hash(level, series);

  @override
  String toString() => key;
}
