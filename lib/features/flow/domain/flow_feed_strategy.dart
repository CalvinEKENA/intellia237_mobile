import 'package:flutter/foundation.dart';

import 'flow_item.dart';

/// Ce que l'application sait de l'élève au moment de composer son fil.
///
/// Tout y est déjà mesuré ailleurs : la classe vient du profil, les matières
/// du catalogue, les cartes vues du contrôleur Flow, la maîtrise des quiz.
/// Rien n'est inventé pour les besoins du classement.
@immutable
class FlowLearnerContext {
  const FlowLearnerContext({
    required this.classLevel,
    this.subjectIds = const <String>[],
    this.seenItemIds = const <String>{},
    this.masteryBySubject = const <String, double>{},
    this.recentSubjectIds = const <String>[],
  });

  final String classLevel;

  /// Matières du programme de l'élève, dans l'ordre du catalogue.
  final List<String> subjectIds;

  /// Publications déjà parcourues, à ne pas resservir en priorité.
  final Set<String> seenItemIds;

  /// Maîtrise estimée par matière, de 0 à 1, quand elle existe.
  final Map<String, double> masteryBySubject;

  /// Matières travaillées récemment, la plus récente en tête.
  final List<String> recentSubjectIds;
}

/// Ordonne les publications d'un fil.
///
/// L'interface existe pour qu'un moteur plus évolué puisse s'y substituer
/// sans toucher au reste : le dépôt, le cache et l'écran n'en connaissent que
/// le contrat.
abstract interface class FlowFeedStrategy {
  List<FlowItem> order(List<FlowItem> items, FlowLearnerContext learner);
}

/// Classement déterministe de première génération.
///
/// Registre de décisions : aucune mécanique d'accroche. On ne cherche pas à
/// retenir l'élève, on cherche à lui présenter d'abord ce qui lui est utile —
/// une matière fragile avant une matière acquise, du contenu neuf avant du
/// déjà-vu. À égalité, l'ordre éditorial tranche, puis l'identifiant, pour
/// que deux passages donnent le même fil.
class DeterministicFlowFeedStrategy implements FlowFeedStrategy {
  const DeterministicFlowFeedStrategy();

  @override
  List<FlowItem> order(List<FlowItem> items, FlowLearnerContext learner) {
    final ranked = [...items]
      ..sort((a, b) => _score(a, learner).compareTo(_score(b, learner)));
    return ranked;
  }

  /// Plus le score est bas, plus la publication remonte.
  ///
  /// Le tri est un composé lexicographique porté par un seul entier : chaque
  /// critère occupe une tranche, si bien que le premier départage avant que
  /// le suivant ne compte.
  int _score(FlowItem item, FlowLearnerContext learner) {
    // 1. Le déjà-vu passe derrière tout le reste.
    final seen = learner.seenItemIds.contains(item.id) ? 1 : 0;

    // 2. Une matière fragile passe devant une matière acquise. Sans mesure
    //    de maîtrise, la matière est traitée comme moyennement acquise :
    //    elle ne prend ni avance ni retard indus.
    final mastery = learner.masteryBySubject[item.subjectId] ?? 0.5;
    final fragility = (mastery.clamp(0.0, 1.0) * 100).round();

    // 3. Une matière travaillée récemment garde un peu d'élan.
    final recentIndex = learner.recentSubjectIds.indexOf(item.subjectId);
    final recency = recentIndex < 0 ? 9 : recentIndex.clamp(0, 9);

    // 4. Une difficulté proche de la maîtrise est préférée à un écart brutal.
    final targetDifficulty = 1 + (mastery.clamp(0.0, 1.0) * 4).round();
    final gap = (item.difficulty - targetDifficulty).abs().clamp(0, 4);

    // 5. Le poids éditorial tranche enfin, puis l'identifiant.
    final priority = (100 - item.priority.clamp(-99, 99)).clamp(0, 199);

    return seen * 100000000 +
        fragility * 1000000 +
        recency * 100000 +
        gap * 10000 +
        priority * 10 +
        (item.id.hashCode & 0x7) ~/ 8;
  }
}

/// Stratégie neutre : conserve l'ordre reçu du serveur.
///
/// Utile pour l'aperçu du Studio, où l'auteur doit voir son fil tel qu'il l'a
/// ordonné, sans reclassement personnel.
class EditorialOrderFlowFeedStrategy implements FlowFeedStrategy {
  const EditorialOrderFlowFeedStrategy();

  @override
  List<FlowItem> order(List<FlowItem> items, FlowLearnerContext learner) =>
      List.unmodifiable(items);
}
