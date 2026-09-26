import 'package:flutter/foundation.dart';

import 'haptic_pattern.dart';

/// Niveau de récompense (du plus discret au plus rare).
enum RewardTier {
  /// A. Bonne réponse ordinaire.
  ordinary,

  /// Progrès net de la maîtrise (sans franchir le seuil).
  progress,

  /// B. Série de réussites.
  streak,

  /// Difficulté supérieure débloquée.
  levelUp,

  /// D. Réussite après plusieurs erreurs.
  recovery,

  /// C. Exercice le plus difficile réussi.
  hardWin,

  /// E. Notion maîtrisée.
  mastery,

  /// F. Chapitre terminé, grande étape.
  milestone,
}

/// Force de la mise en scène effectivement jouée.
enum RewardIntensity { minimal, light, medium, rich, grand }

/// Effet visuel. Tous partagent la même identité : traits fins, lueur
/// discrète, mouvement doux.
enum RewardVisual {
  /// Coche qui se dessine.
  check,

  /// Légère impulsion de la carte.
  pulse,

  /// Petite montée (le score avance).
  scoreRise,

  /// Pas de progression qui avance.
  progressStep,

  /// Trait lumineux qui parcourt la carte.
  lightTrace,

  /// Halo très discret.
  halo,

  /// Contraction puis déploiement de la carte, avec halo.
  unfold,

  /// Anneau de maîtrise qui se complète, micro-particules.
  masteryRing,

  /// Jalon : courte scène plein écran.
  milestone,
}

/// Micro-message de la bibliothèque (localisé à l'affichage).
enum RewardMessage {
  exact,
  wellSeen,
  yes,
  veryClean,
  gotIt,
  niceProgress,
  streak,
  levelUp,
  gotItThisTime,
  foundIt,
  realStep,
  challengeMet,
  conceptMastered,
  chapterDone,
}

/// Ce que l'élève verra et sentira.
@immutable
class RewardPattern {
  const RewardPattern({
    required this.tier,
    required this.intensity,
    required this.visual,
    required this.haptic,
    required this.duration,
    this.message,
    this.streakCount,
    this.conceptTitle,
    this.chapterTitle,
    this.mayUseName = false,
  });

  final RewardTier tier;
  final RewardIntensity intensity;
  final RewardVisual visual;
  final HapticPattern haptic;
  final Duration duration;

  /// `null` : retour purement visuel (la réussite reste lisible par le
  /// verdict affiché à côté).
  final RewardMessage? message;
  final int? streakCount;
  final String? conceptTitle;
  final String? chapterTitle;

  /// Le prénom peut accompagner le message (la décision finale revient à la
  /// règle du prénom partagée avec le Compagnon).
  final bool mayUseName;

  bool get isRich =>
      intensity == RewardIntensity.rich || intensity == RewardIntensity.grand;

  @override
  String toString() =>
      'RewardPattern(${tier.name}, ${intensity.name}, ${visual.name}, '
      '${haptic.name}, ${message?.name})';
}
