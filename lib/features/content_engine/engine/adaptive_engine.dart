import '../domain/chapter.dart';
import '../domain/mastery.dart';
import '../domain/pedagogy.dart';
import '../domain/question.dart';

/// Choisit les questions d'une séance, toujours dans le même ordre.
class QuestionSelector {
  const QuestionSelector();

  /// Questions utilisables d'une leçon à une difficulté, dans l'ordre du pack.
  /// Les questions déjà réussies passent après les autres.
  List<Question> forLesson(
    Chapter chapter, {
    required int lessonNumber,
    required int difficulty,
    Set<String> answered = const {},
  }) {
    final pool = [
      for (final question in chapter.questions)
        if (question.lessonNumber == lessonNumber &&
            question.difficulty == difficulty &&
            question.isPracticeReady)
          question,
    ];
    return [
      ...pool.where((question) => !answered.contains(question.id)),
      ...pool.where((question) => answered.contains(question.id)),
    ];
  }

  /// Difficultés qui ont au moins une question utilisable pour cette leçon.
  List<int> availableDifficulties(Chapter chapter, int lessonNumber) {
    final values = {
      for (final question in chapter.questions)
        if (question.lessonNumber == lessonNumber && question.isPracticeReady)
          question.difficulty,
    }.toList()..sort();
    return values;
  }

  /// Prochaine question pour « Teste-moi » : la première non encore réussie
  /// à la difficulté demandée, puis aux autres difficultés dans l'ordre.
  Question? next(
    Chapter chapter, {
    required int lessonNumber,
    required int difficulty,
    Set<String> answered = const {},
    String? excludeId,
  }) {
    final order = [
      difficulty,
      for (final level in chapter.difficulties)
        if (level.value != difficulty) level.value,
    ];
    for (final level in order) {
      for (final question in forLesson(
        chapter,
        lessonNumber: lessonNumber,
        difficulty: level,
      )) {
        if (question.id != excludeId && !answered.contains(question.id)) {
          return question;
        }
      }
    }
    return null;
  }
}

/// Résultat d'une réponse pour la maîtrise.
class AdaptiveOutcome {
  const AdaptiveOutcome({required this.state, this.suggestions = const []});

  final MasteryState state;

  /// Propositions à faire à l'élève — jamais appliquées d'office.
  final List<AdaptiveSuggestion> suggestions;
}

/// Règles d'adaptation du pack, appliquées notion par notion.
///
/// * N erreurs sur une notion → proposer l'explication « simple » ;
/// * une erreur de plus → proposer « Comme si j'avais 12 ans » ;
/// * K réussites consécutives → proposer la difficulté supérieure ;
/// * rien n'est imposé ; une préférence verrouillée n'est jamais remise en
///   question ; l'explication ne change jamais la difficulté.
class AdaptiveEngine {
  const AdaptiveEngine(this.config, {this.maxDifficulty = 3});

  final MasteryConfig config;
  final int maxDifficulty;

  AdaptiveOutcome record({
    required MasteryState state,
    required Question question,
    required bool correct,
    required ExplanationPreference preference,
  }) {
    if (!question.autoScorable) return AdaptiveOutcome(state: state);
    final attempts = state.attempts + 1;
    var next = state.copyWith(
      attempts: attempts,
      correct: state.correct + (correct ? 1 : 0),
      score: _score(state.score, question.difficulty, correct),
      consecutiveCorrect: correct ? state.consecutiveCorrect + 1 : 0,
      errorsSinceExplanationChange: correct
          ? state.errorsSinceExplanationChange
          : state.errorsSinceExplanationChange + 1,
      bestDifficulty: correct && question.difficulty > state.bestDifficulty
          ? question.difficulty
          : state.bestDifficulty,
      answeredQuestionIds: correct
          ? {...state.answeredQuestionIds, question.id}
          : state.answeredQuestionIds,
    );

    final suggestions = <AdaptiveSuggestion>[];
    if (!correct && !preference.locked) {
      final explanation = _explanationFor(next, preference.mode);
      if (explanation != null) suggestions.add(explanation);
    }
    if (correct &&
        next.consecutiveCorrect >=
            config.suggestHarderAfterConsecutiveCorrect &&
        question.difficulty < maxDifficulty) {
      suggestions.add(SuggestHarder(question.difficulty + 1));
      next = next.copyWith(consecutiveCorrect: 0);
    }
    return AdaptiveOutcome(state: next, suggestions: suggestions);
  }

  /// La confiance nourrit la révision, sans gonfler un score ni enregistrer
  /// une erreur. Refaire une question remplace seulement son dernier signal.
  MasteryState recordSelfEvaluation({
    required MasteryState state,
    required Question question,
    required SelfEvaluation evaluation,
  }) {
    if (!question.requiresSelfEvaluation) return state;
    return state.copyWith(
      selfEvaluations: {...state.selfEvaluations, question.id: evaluation},
    );
  }

  /// L'élève a changé d'explication : le compteur d'erreurs repart de zéro.
  MasteryState explanationChanged(MasteryState state) =>
      state.copyWith(errorsSinceExplanationChange: 0);

  SuggestExplanation? _explanationFor(
    MasteryState state,
    ExplanationMode current,
  ) {
    final errors = state.errorsSinceExplanationChange;
    switch (current) {
      case ExplanationMode.standard:
        if (errors >= config.showSimpleAfterErrors) {
          return const SuggestExplanation(ExplanationMode.simple);
        }
      case ExplanationMode.simple:
        if (errors >= config.showUltraSimpleAfterAdditionalErrors) {
          return const SuggestExplanation(ExplanationMode.ultraSimple);
        }
      case ExplanationMode.ultraSimple:
        break;
    }
    return null;
  }

  /// Score 0–100 : une réussite rapproche de 100 d'autant plus que la
  /// question est difficile ; une erreur retire un peu, sans effondrer.
  int _score(int score, int difficulty, bool correct) {
    final range = config.scoreMax - config.scoreMin;
    final gain = (range * (0.08 + 0.06 * difficulty)).round();
    final loss = (range * 0.05).round();
    final next = correct ? score + gain : score - loss;
    return next.clamp(config.scoreMin, config.scoreMax);
  }

  /// Leçon débloquée : la première, ou dès que la notion précédente
  /// atteint le seuil du pack.
  bool isLessonUnlocked(
    Chapter chapter,
    int lessonNumber,
    Map<String, MasteryState> states,
  ) {
    final ordered = chapter.lessons;
    final index = ordered.indexWhere((lesson) => lesson.number == lessonNumber);
    if (index <= 0) return true;
    final previousConcept = ordered[index - 1].conceptId;
    if (previousConcept == null) return true;
    return (states[previousConcept]?.score ?? 0) >= config.unlockNextLessonAt;
  }
}
