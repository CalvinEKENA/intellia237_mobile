import 'package:flutter/foundation.dart';

import 'visual_kind.dart';

/// Niveau d'explication : un axe **indépendant** de la difficulté.
///
/// Un élève peut faire un exercice « Défi Bac » avec l'explication « Comme si
/// j'avais 12 ans » : changer d'explication ne change jamais la difficulté.
enum ExplanationMode {
  /// Terminale : notation complète, vocabulaire du programme.
  standard('standard'),

  /// Phrases courtes, une étape à la fois.
  simple('simple'),

  /// « Comme si j'avais 12 ans » : intuition, analogie, puis pont vers la formule.
  ultraSimple('ultra_simple');

  const ExplanationMode(this.key);

  /// Clé utilisée dans les packs.
  final String key;

  static ExplanationMode? fromKey(String? key) {
    for (final mode in values) {
      if (mode.key == key) return mode;
    }
    return null;
  }

  /// Le niveau plus simple suivant, `null` au plus simple.
  ExplanationMode? get simpler => switch (this) {
    standard => simple,
    simple => ultraSimple,
    ultraSimple => null,
  };
}

/// Un niveau de difficulté d'exercice (1 Facile, 2 Intermédiaire, 3 Défi Bac…).
///
/// Ouvert : un futur pack peut déclarer d'autres niveaux ; le moteur ne
/// suppose que leur ordre.
@immutable
class DifficultyLevel implements Comparable<DifficultyLevel> {
  const DifficultyLevel(this.value, {this.label, this.focus});

  final int value;

  /// Libellé donné par le pack (ex. « Difficile / Défi Bac »).
  final String? label;
  final String? focus;

  @override
  int compareTo(DifficultyLevel other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) =>
      other is DifficultyLevel && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'DifficultyLevel($value)';
}

/// Une notion, avec ses explications à chaque niveau.
@immutable
class Concept {
  const Concept({
    required this.id,
    required this.title,
    required this.explanations,
    this.lessonNumber,
    this.prerequisites = const [],
    this.visualModel,
    this.visualKind = VisualKind.none,
    this.commonMistakes = const [],
    this.aliases = const [],
  });

  final String id;
  final int? lessonNumber;
  final String title;
  final List<String> prerequisites;

  /// Seules les explications présentes dans le pack : aucune n'est inventée.
  final Map<ExplanationMode, String> explanations;

  /// Description libre du modèle visuel (ex. « Horloge circulaire modulo n. »).
  final String? visualModel;

  /// Primitive visuelle générique retenue pour cette notion.
  final VisualKind visualKind;
  final List<String> commonMistakes;

  /// Mots-clés supplémentaires pour retrouver la notion (facultatif).
  final List<String> aliases;

  /// L'explication demandée si elle existe, sinon `null` (jamais inventée).
  String? explanation(ExplanationMode mode) => explanations[mode];

  /// Les niveaux réellement disponibles, du plus formel au plus simple.
  List<ExplanationMode> get availableModes => [
    for (final mode in ExplanationMode.values)
      if (explanations.containsKey(mode)) mode,
  ];
}

/// Une leçon du chapitre.
@immutable
class Lesson {
  const Lesson({
    required this.number,
    required this.title,
    this.conceptId,
    this.verifiedCore = const [],
    this.sourceSituation,
    this.sourcePages = const [],
  });

  final int number;
  final String title;
  final String? conceptId;

  /// Énoncés vérifiés sur la source (couche de provenance).
  final List<String> verifiedCore;
  final String? sourceSituation;
  final List<String> sourcePages;
}
