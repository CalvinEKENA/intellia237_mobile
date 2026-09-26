import 'package:flutter/foundation.dart';

import '../../../core/academics/class_key.dart';
import '../domain/pedagogy.dart';
import '../domain/question.dart';
import '../domain/visual_kind.dart';

/// Nature d'une carte du fil « Mon Parcours » tirée d'un pack.
enum LearningCardType {
  /// Explication de la notion au niveau standard (ou préféré).
  explanation,

  /// La même notion « comme si j'avais 12 ans ».
  ultraSimple,

  /// Question courte et facile, réponse immédiate.
  flashQuestion,

  /// Question à choix.
  mcq,

  /// Vrai ou faux.
  trueFalse,

  /// Exercice à saisir (niveau intermédiaire).
  exercise,

  /// Réponse rédigée, comparaison au modèle puis confiance déclarée.
  selfEvaluation,

  /// Représentation visuelle de la notion.
  visual,

  /// Jeu jouable du pack.
  game,

  /// Erreur fréquente à éviter.
  commonMistake,

  /// Rappel d'un point essentiel validé de la leçon.
  revision,

  /// Défi au niveau le plus exigeant.
  challenge,

  /// Vérification de maîtrise d'une notion déjà bien travaillée.
  mastery,

  /// Annonce d'un chapitre nouvellement arrivé.
  newContent,

  /// Invitation à interroger le Compagnon sur la notion.
  companionPrompt;

  /// La carte demande-t-elle une réponse de l'élève ?
  bool get asksAnswer => switch (this) {
    flashQuestion ||
    mcq ||
    trueFalse ||
    exercise ||
    selfEvaluation ||
    challenge ||
    mastery => true,
    _ => false,
  };
}

/// Étape de la leçon qu'ouvre « Approfondir » (mêmes indices que l'écran de
/// leçon : comprendre, voir, s'entraîner, jouer, formaliser).
abstract final class LessonStep {
  static const understand = 0;
  static const see = 1;
  static const practice = 2;
  static const play = 3;
  static const formal = 4;
}

/// Une carte du fil, construite uniquement à partir d'un pack validé.
///
/// Aucune donnée n'est rédigée ici : [title] et [body] sont des textes du
/// pack, repris mot pour mot. Les libellés d'interface (« Le savais-tu ? »,
/// « Approfondir »…) viennent des traductions, à l'affichage.
@immutable
class LearningCard {
  const LearningCard({
    required this.id,
    required this.packId,
    required this.contentId,
    required this.classKeys,
    required this.subject,
    required this.chapterId,
    required this.lessonNumber,
    required this.conceptId,
    required this.type,
    required this.difficulty,
    required this.priority,
    required this.estimatedSeconds,
    required this.title,
    required this.sourceVersion,
    this.body,
    this.question,
    this.gameId,
    this.explanationMode,
    this.visual = VisualKind.none,
    this.masteryImpact = 0,
    this.lessonStep = LessonStep.understand,
    this.offlineReady = true,
  });

  /// Identifiant stable : `contentId:conceptId:type:suffixe`. Il ne dépend
  /// que du pack, si bien que l'historique de l'élève survit aux mises à
  /// jour qui ne touchent pas la carte.
  final String id;
  final String packId;
  final String contentId;
  final List<ClassKey> classKeys;
  final String subject;

  /// Chapitre (identifiant de contenu du pack).
  final String chapterId;
  final int lessonNumber;
  final String conceptId;
  final LearningCardType type;
  final int difficulty;

  /// Poids éditorial : plus il est haut, plus la carte remonte à égalité.
  final int priority;
  final int estimatedSeconds;
  final String title;
  final String? body;

  /// Question du pack jouée dans la carte.
  final Question? question;

  /// Jeu ouvert depuis la carte.
  final String? gameId;

  /// Niveau d'explication affiché (cartes d'explication).
  final ExplanationMode? explanationMode;
  final VisualKind visual;

  /// Effet sur le score objectif : 1 pour une question corrigée, 0 pour
  /// une lecture ou une auto-évaluation (signal distinct dans MasteryState).
  final int masteryImpact;

  /// Étape de la leçon qu'ouvre « Approfondir ».
  final int lessonStep;
  final bool offlineReady;

  /// Version du pack dont la carte est tirée.
  final int sourceVersion;

  @override
  bool operator ==(Object other) =>
      other is LearningCard &&
      other.id == id &&
      other.sourceVersion == sourceVersion;

  @override
  int get hashCode => Object.hash(id, sourceVersion);

  @override
  String toString() => 'LearningCard($id)';
}
