import 'package:flutter/foundation.dart';

import 'pedagogy.dart';

/// Règles d'adaptation et de maîtrise déclarées par le pack (`runtime.mastery`).
@immutable
class MasteryConfig {
  const MasteryConfig({
    this.scoreMin = 0,
    this.scoreMax = 100,
    this.unlockNextLessonAt = 70,
    this.suggestHarderAfterConsecutiveCorrect = 3,
    this.showSimpleAfterErrors = 2,
    this.showUltraSimpleAfterAdditionalErrors = 1,
  });

  final int scoreMin;
  final int scoreMax;
  final int unlockNextLessonAt;
  final int suggestHarderAfterConsecutiveCorrect;
  final int showSimpleAfterErrors;
  final int showUltraSimpleAfterAdditionalErrors;
}

/// Maîtrise d'une notion par un élève.
@immutable
class MasteryState {
  const MasteryState({
    required this.conceptId,
    this.score = 0,
    this.attempts = 0,
    this.correct = 0,
    this.errorsSinceExplanationChange = 0,
    this.consecutiveCorrect = 0,
    this.bestDifficulty = 0,
    this.answeredQuestionIds = const {},
  });

  final String conceptId;

  /// 0 à 100.
  final int score;
  final int attempts;
  final int correct;

  /// Erreurs depuis la dernière montée vers une explication plus simple.
  final int errorsSinceExplanationChange;
  final int consecutiveCorrect;

  /// Plus haute difficulté réussie (0 : aucune).
  final int bestDifficulty;
  final Set<String> answeredQuestionIds;

  MasteryState copyWith({
    int? score,
    int? attempts,
    int? correct,
    int? errorsSinceExplanationChange,
    int? consecutiveCorrect,
    int? bestDifficulty,
    Set<String>? answeredQuestionIds,
  }) => MasteryState(
    conceptId: conceptId,
    score: score ?? this.score,
    attempts: attempts ?? this.attempts,
    correct: correct ?? this.correct,
    errorsSinceExplanationChange:
        errorsSinceExplanationChange ?? this.errorsSinceExplanationChange,
    consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
    bestDifficulty: bestDifficulty ?? this.bestDifficulty,
    answeredQuestionIds: answeredQuestionIds ?? this.answeredQuestionIds,
  );

  Map<String, Object?> toJson() => {
    'conceptId': conceptId,
    'score': score,
    'attempts': attempts,
    'correct': correct,
    'errorsSinceExplanationChange': errorsSinceExplanationChange,
    'consecutiveCorrect': consecutiveCorrect,
    'bestDifficulty': bestDifficulty,
    'answered': answeredQuestionIds.toList()..sort(),
  };

  /// Tolérant : un champ absent ou mal formé reprend sa valeur initiale.
  static MasteryState? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final conceptId = raw['conceptId'];
    if (conceptId is! String || conceptId.isEmpty) return null;
    int read(String key) => (raw[key] as num?)?.toInt() ?? 0;
    final answered = raw['answered'];
    return MasteryState(
      conceptId: conceptId,
      score: read('score').clamp(0, 100),
      attempts: read('attempts'),
      correct: read('correct'),
      errorsSinceExplanationChange: read('errorsSinceExplanationChange'),
      consecutiveCorrect: read('consecutiveCorrect'),
      bestDifficulty: read('bestDifficulty'),
      answeredQuestionIds: answered is List
          ? {
              for (final id in answered)
                if (id is String) id,
            }
          : const {},
    );
  }
}

/// Préférence d'explication de l'élève.
@immutable
class ExplanationPreference {
  const ExplanationPreference({
    this.mode = ExplanationMode.standard,
    this.locked = false,
  });

  final ExplanationMode mode;

  /// Verrouillée : le moteur ne propose plus d'autre niveau.
  final bool locked;

  Map<String, Object?> toJson() => {'mode': mode.key, 'locked': locked};

  static ExplanationPreference fromJson(Object? raw) {
    if (raw is! Map) return const ExplanationPreference();
    return ExplanationPreference(
      mode:
          ExplanationMode.fromKey(raw['mode'] as String?) ??
          ExplanationMode.standard,
      locked: raw['locked'] == true,
    );
  }
}

/// Tout ce que le moteur retient d'un élève, indépendamment du stockage.
@immutable
class LearnerContentSnapshot {
  const LearnerContentSnapshot({
    this.preference = const ExplanationPreference(),
    this.concepts = const {},
  });

  static const empty = LearnerContentSnapshot();

  final ExplanationPreference preference;
  final Map<String, MasteryState> concepts;

  MasteryState conceptState(String conceptId) =>
      concepts[conceptId] ?? MasteryState(conceptId: conceptId);

  LearnerContentSnapshot withConcept(MasteryState state) =>
      LearnerContentSnapshot(
        preference: preference,
        concepts: {...concepts, state.conceptId: state},
      );

  LearnerContentSnapshot withPreference(ExplanationPreference preference) =>
      LearnerContentSnapshot(preference: preference, concepts: concepts);

  Map<String, Object?> toJson() => {
    'version': 1,
    'preference': preference.toJson(),
    'concepts': [for (final state in concepts.values) state.toJson()],
  };

  static LearnerContentSnapshot fromJson(Object? raw) {
    if (raw is! Map) return empty;
    final concepts = <String, MasteryState>{};
    final list = raw['concepts'];
    if (list is List) {
      for (final item in list) {
        final state = MasteryState.fromJson(item);
        if (state != null) concepts[state.conceptId] = state;
      }
    }
    return LearnerContentSnapshot(
      preference: ExplanationPreference.fromJson(raw['preference']),
      concepts: concepts,
    );
  }
}

/// Une proposition du moteur : jamais imposée.
sealed class AdaptiveSuggestion {
  const AdaptiveSuggestion();
}

/// Proposer une explication plus simple.
final class SuggestExplanation extends AdaptiveSuggestion {
  const SuggestExplanation(this.mode);
  final ExplanationMode mode;
}

/// Proposer une difficulté supérieure.
final class SuggestHarder extends AdaptiveSuggestion {
  const SuggestHarder(this.difficulty);
  final int difficulty;
}
