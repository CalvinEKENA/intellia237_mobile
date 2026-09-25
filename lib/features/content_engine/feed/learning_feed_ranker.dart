import 'package:flutter/foundation.dart';

import '../domain/mastery.dart';
import '../domain/pedagogy.dart';
import 'learning_card.dart';
import 'learning_card_history.dart';

/// Ce que le classement sait de l'élève au moment de composer le fil.
///
/// Un instantané : les réponses données pendant la séance ne réordonnent pas
/// le fil sous ses doigts (même règle que le fil publié).
@immutable
class LearningFeedContext {
  const LearningFeedContext({
    required this.now,
    this.mastery = const {},
    this.preference = const ExplanationPreference(),
    this.history = LearningCardHistory.empty,
    this.unlockAt = 70,
  });

  final DateTime now;
  final Map<String, MasteryState> mastery;
  final ExplanationPreference preference;
  final LearningCardHistory history;

  /// Seuil de maîtrise qui ouvre la leçon suivante.
  final int unlockAt;

  int scoreOf(String conceptId) => mastery[conceptId]?.score ?? 0;
}

/// Classe les cartes « Mon Parcours » tirées des packs.
///
/// Registre de décisions :
/// - l'élève avance au fil du programme : la notion en cours (la première
///   non maîtrisée de chaque chapitre) passe devant les suivantes ;
/// - après des erreurs récentes sur une notion, une séquence de remédiation
///   ouvre le fil : explication plus simple → visuel → question facile →
///   exercice intermédiaire ;
/// - le déjà-vu attend : une carte lue revient après un délai, une question
///   réussie revient en révision espacée (1, 3, 7 puis 14 jours) ;
/// - le fil reste varié : jamais deux cartes du même type de suite, ni plus
///   de trois cartes de la même notion d'affilée, quand d'autres existent ;
/// - à égalité, l'identifiant tranche : même état, même fil.
class LearningFeedRanker {
  const LearningFeedRanker();

  /// Délai avant de reproposer une carte de lecture déjà vue.
  static const readCooldown = Duration(hours: 20);

  /// Délai avant de reproposer une question manquée.
  static const retryCooldown = Duration(hours: 2);

  /// Intervalles de révision d'une question réussie.
  static const spacing = [
    Duration(days: 1),
    Duration(days: 3),
    Duration(days: 7),
    Duration(days: 14),
  ];

  /// Une erreur compte comme « récente » pendant ce délai.
  static const recentErrorWindow = Duration(hours: 48);

  List<LearningCard> rank(
    List<LearningCard> cards,
    LearningFeedContext context, {
    int limit = 60,
  }) {
    if (cards.isEmpty) return const [];
    final frontier = _frontierLessons(cards, context);
    final struggling = _strugglingConcepts(cards, context);

    final eligible = <LearningCard>[];
    final resting = <LearningCard>[];
    for (final card in cards) {
      if (!_relevant(card, context, struggling)) continue;
      (_due(card, context) ? eligible : resting).add(card);
    }

    int score(LearningCard card) => _score(card, context, frontier, struggling);
    int compare(LearningCard a, LearningCard b) {
      final byScore = score(a).compareTo(score(b));
      return byScore != 0 ? byScore : a.id.compareTo(b.id);
    }

    eligible.sort(compare);

    // 1. Remédiation d'abord, dans un ordre pédagogique voulu.
    final ordered = <LearningCard>[];
    for (final conceptId in struggling) {
      ordered.addAll(_remediation(conceptId, eligible, context));
    }
    final rest = [
      for (final card in eligible)
        if (!ordered.contains(card)) card,
    ];

    // 2. Puis le reste, varié.
    ordered.addAll(_diversify(rest, ordered.isEmpty ? null : ordered.last));

    // 3. Si tout a déjà été vu récemment, le fil ne se vide pas : les cartes
    //    au repos reviennent, les plus anciennes d'abord.
    if (ordered.length < limit && resting.isNotEmpty) {
      resting.sort((a, b) {
        final at = context.history.of(a.id).lastShownAt;
        final bt = context.history.of(b.id).lastShownAt;
        final byTime = (at ?? DateTime(0)).compareTo(bt ?? DateTime(0));
        return byTime != 0 ? byTime : compare(a, b);
      });
      ordered.addAll(
        _diversify(resting, ordered.isEmpty ? null : ordered.last),
      );
    }
    return List.unmodifiable(ordered.take(limit));
  }

  /// Leçon en cours de chaque chapitre : la première dont la notion n'a pas
  /// atteint le seuil d'ouverture.
  Map<String, int> _frontierLessons(
    List<LearningCard> cards,
    LearningFeedContext context,
  ) {
    final lessonsByChapter = <String, Map<int, String>>{};
    for (final card in cards) {
      if (card.type == LearningCardType.newContent) continue;
      lessonsByChapter.putIfAbsent(
        card.chapterId,
        () => {},
      )[card.lessonNumber] = card.conceptId;
    }
    return {
      for (final entry in lessonsByChapter.entries)
        entry.key: () {
          final lessons = entry.value.keys.toList()..sort();
          for (final lesson in lessons) {
            if (context.scoreOf(entry.value[lesson]!) < context.unlockAt) {
              return lesson;
            }
          }
          return lessons.isEmpty ? 1 : lessons.last;
        }(),
    };
  }

  /// Notions manquées récemment, les plus récentes d'abord.
  List<String> _strugglingConcepts(
    List<LearningCard> cards,
    LearningFeedContext context,
  ) {
    final latest = <String, DateTime>{};
    for (final card in cards) {
      final entry = context.history.of(card.id);
      final at = entry.lastAnsweredAt;
      if (at == null || entry.incorrect == 0) continue;
      if (context.now.difference(at) > recentErrorWindow) continue;
      // Une notion depuis réussie n'est plus en difficulté.
      final state = context.mastery[card.conceptId];
      if (state != null && state.consecutiveCorrect >= 2) continue;
      final previous = latest[card.conceptId];
      if (previous == null || at.isAfter(previous)) {
        latest[card.conceptId] = at;
      }
    }
    for (final state in context.mastery.values) {
      if (state.errorsSinceExplanationChange >= 2 &&
          state.consecutiveCorrect == 0) {
        latest.putIfAbsent(state.conceptId, () => DateTime(0));
      }
    }
    final ids = latest.keys.toList()
      ..sort((a, b) {
        final byTime = latest[b]!.compareTo(latest[a]!);
        return byTime != 0 ? byTime : a.compareTo(b);
      });
    return ids;
  }

  bool _relevant(
    LearningCard card,
    LearningFeedContext context,
    List<String> struggling,
  ) {
    final score = context.scoreOf(card.conceptId);
    return switch (card.type) {
      // « Comme si j'avais 12 ans » : quand la notion résiste, ou quand
      // l'élève a choisi ce niveau d'explication.
      LearningCardType.ultraSimple =>
        struggling.contains(card.conceptId) ||
            context.preference.mode == ExplanationMode.ultraSimple,
      LearningCardType.mastery => score >= 60,
      LearningCardType.challenge => score >= 40,
      _ => true,
    };
  }

  /// La carte peut-elle revenir maintenant ?
  bool _due(LearningCard card, LearningFeedContext context) {
    final entry = context.history.of(card.id);
    if (entry.seen == 0 && entry.answered == 0) return true;
    final now = context.now;
    if (card.type.asksAnswer && entry.answered > 0) {
      final last = entry.lastAnsweredAt ?? entry.lastShownAt;
      if (last == null) return true;
      if (entry.lastAnswerWrong) return now.difference(last) >= retryCooldown;
      final step = (entry.correct - 1).clamp(0, spacing.length - 1);
      return now.difference(last) >= spacing[step];
    }
    final last = entry.lastShownAt;
    return last == null || now.difference(last) >= readCooldown;
  }

  /// Plus le score est bas, plus la carte remonte.
  int _score(
    LearningCard card,
    LearningFeedContext context,
    Map<String, int> frontier,
    List<String> struggling,
  ) {
    final entry = context.history.of(card.id);

    // Un chapitre nouvellement arrivé s'annonce en tête.
    final fresh = card.type == LearningCardType.newContent ? 0 : 1;

    // Le neuf avant le déjà-vu (une révision due reste derrière le neuf).
    final seen = entry.seen == 0 && entry.answered == 0 ? 0 : 1;

    // Distance à la leçon en cours : devant, la leçon en cours ; derrière,
    // les suivantes (on ne saute pas le programme) puis les acquises.
    final current = frontier[card.chapterId] ?? 1;
    final offset = card.lessonNumber - current;
    final distance = offset >= 0
        ? offset.clamp(0, 9)
        : (3 - offset).clamp(0, 9);

    // Difficulté proche de ce que la maîtrise permet.
    final mastery = context.scoreOf(card.conceptId);
    final target = mastery < 40 ? 1 : (mastery < 75 ? 2 : 3);
    final gap = card.type.asksAnswer
        ? (card.difficulty - target).abs().clamp(0, 4)
        : 0;

    final weakness = struggling.contains(card.conceptId) ? 0 : 1;
    final priority = (100 - card.priority).clamp(0, 99);

    return fresh * 100000000 +
        seen * 10000000 +
        weakness * 1000000 +
        distance * 100000 +
        gap * 10000 +
        priority * 10;
  }

  /// Séquence de remédiation d'une notion, prise dans les cartes éligibles.
  List<LearningCard> _remediation(
    String conceptId,
    List<LearningCard> eligible,
    LearningFeedContext context,
  ) {
    LearningCard? pick(bool Function(LearningCard card) test) {
      for (final card in eligible) {
        if (card.conceptId == conceptId && test(card)) return card;
      }
      return null;
    }

    final simple =
        pick((c) => c.type == LearningCardType.ultraSimple) ??
        pick((c) => c.type == LearningCardType.explanation);
    final visual = pick((c) => c.type == LearningCardType.visual);
    final easy = pick(
      (c) =>
          c.type.asksAnswer &&
          c.difficulty <= 1 &&
          c.type != LearningCardType.challenge,
    );
    final middle = pick(
      (c) =>
          c.type.asksAnswer &&
          c.difficulty == 2 &&
          c.type != LearningCardType.challenge &&
          c.type != LearningCardType.mastery,
    );
    return [?simple, ?visual, ?easy, ?middle];
  }

  /// Ordre varié : on prend la meilleure carte qui ne répète ni le type de
  /// la précédente, ni une notion déjà servie trois fois d'affilée, ni une
  /// troisième question de suite. Si aucune ne convient, la meilleure.
  List<LearningCard> _diversify(List<LearningCard> ranked, LearningCard? tail) {
    final pool = [...ranked];
    final out = <LearningCard>[];
    final recent = <LearningCard>[?tail];
    while (pool.isNotEmpty) {
      var index = pool.indexWhere((card) => _fits(card, recent));
      if (index < 0) index = 0;
      final card = pool.removeAt(index);
      out.add(card);
      recent.add(card);
      if (recent.length > 3) recent.removeAt(0);
    }
    return out;
  }

  bool _fits(LearningCard card, List<LearningCard> recent) {
    if (recent.isEmpty) return true;
    final last = recent.last;
    if (last.type == card.type) return false;
    if (recent.length >= 3 &&
        recent.every((c) => c.conceptId == card.conceptId)) {
      return false;
    }
    if (card.type.asksAnswer &&
        recent.length >= 2 &&
        recent.skip(recent.length - 2).every((c) => c.type.asksAnswer)) {
      return false;
    }
    return true;
  }
}
