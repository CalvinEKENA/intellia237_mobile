import 'package:flutter/foundation.dart';

/// D'où vient la réussite. Le moteur ne s'en sert que pour de légères
/// nuances : les règles sont les mêmes partout.
enum RewardSource { practice, feed, quiz, game, integration }

/// Un événement pédagogique abstrait, sans matière ni chapitre.
///
/// Les mesures de maîtrise sont lues dans l'état de maîtrise existant
/// (avant et après la réponse) : le moteur de récompense ne tient aucun
/// score parallèle.
@immutable
class RewardEvent {
  /// Une bonne réponse.
  const RewardEvent.correct({
    required this.source,
    this.difficulty,
    this.maxDifficulty,
    this.masteryBefore,
    this.masteryAfter,
    this.masteryThreshold,
    this.errorsBefore = 0,
    this.difficultyRaised = false,
    this.conceptTitle,
    this.chapterTitle,
    this.chapterCompleted = false,
    this.responseTime,
  });

  /// Un chapitre (ou une grande étape) entièrement réussi.
  const RewardEvent.chapterCompleted({
    required this.source,
    required String this.chapterTitle,
  }) : difficulty = null,
       maxDifficulty = null,
       masteryBefore = null,
       masteryAfter = null,
       masteryThreshold = null,
       errorsBefore = 0,
       difficultyRaised = false,
       conceptTitle = null,
       chapterCompleted = true,
       responseTime = null;

  final RewardSource source;

  /// Difficulté de l'exercice (1 = facile) et plus haute difficulté du
  /// contenu, si elles existent.
  final int? difficulty;
  final int? maxDifficulty;

  /// Score de maîtrise de la notion (0–100) avant et après la réponse.
  final int? masteryBefore;
  final int? masteryAfter;

  /// Seuil à partir duquel la notion est considérée comme maîtrisée.
  final int? masteryThreshold;

  /// Erreurs consécutives sur la notion juste avant cette réussite.
  final int errorsBefore;

  /// Le moteur d'adaptation vient de proposer la difficulté supérieure.
  final bool difficultyRaised;

  /// Nom réel de la notion (« Congruence modulo n »), pour le message.
  final String? conceptTitle;
  final String? chapterTitle;

  /// Cette réponse achève le chapitre.
  final bool chapterCompleted;

  /// Temps de réponse, s'il est connu : une réponse rapide reçoit un retour
  /// minimal pour ne jamais ralentir l'élève.
  final Duration? responseTime;

  bool get crossesMastery {
    final before = masteryBefore;
    final after = masteryAfter;
    final threshold = masteryThreshold;
    return before != null &&
        after != null &&
        threshold != null &&
        before < threshold &&
        after >= threshold;
  }

  bool get isHard {
    final d = difficulty;
    final max = maxDifficulty;
    return d != null && max != null && max >= 3 && d >= max;
  }
}
