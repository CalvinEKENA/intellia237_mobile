import 'package:flutter/foundation.dart';

import 'pack_quiz.dart';

/// Les moments d'une séance où le compagnon prend la parole.
enum QuizNarrationEvent {
  sessionStarted,
  questionPresented,
  correct,
  incorrect,
  streak,
  hintRequested,
  halfway,
  lastQuestion,
  sessionCompleted,
  masteryImproved,
  needsReview,
}

/// Une réplique choisie : l'événement, la variante, les valeurs à insérer.
/// Le texte lui-même vit dans les fichiers de traduction.
@immutable
class QuizNarration {
  const QuizNarration({
    required this.companionId,
    required this.event,
    required this.variant,
    this.values = const {},
  });

  /// `kira` ou `leo` : le même compagnon que partout ailleurs.
  final String companionId;
  final QuizNarrationEvent event;

  /// 0, 1 ou 2.
  final int variant;
  final Map<String, Object> values;

  bool get isLeo => companionId == 'leo';
}

/// Kira ou Léo, maître de séance : aucune génération, aucun réseau.
///
/// Chaque événement a trois répliques écrites à l'avance, par compagnon ;
/// la réplique retenue découle du compagnon, de l'événement, de la question
/// et de la tentative : variée d'une question à l'autre, identique si l'on
/// rejoue la même situation. Le compagnon n'explique jamais rien lui-même :
/// les explications et les indices viennent du pack.
abstract final class QuizCompanionNarrator {
  static const variants = 3;

  /// Une série est saluée toutes les trois bonnes réponses.
  static const streakStep = 3;

  static QuizNarration narrate(
    QuizNarrationEvent event, {
    required String companionId,
    String questionId = '',
    int attempt = 0,
    Map<String, Object> values = const {},
  }) {
    final id = companionId == 'leo' ? 'leo' : 'kira';
    return QuizNarration(
      companionId: id,
      event: event,
      variant: stableHash('$id|${event.name}|$questionId|$attempt') % variants,
      values: values,
    );
  }

  /// La réplique à l'arrivée d'une question : mi-parcours et dernière
  /// question ont la leur.
  static QuizNarrationEvent presentationFor({
    required int index,
    required int length,
  }) {
    if (length > 1 && index == length - 1) {
      return QuizNarrationEvent.lastQuestion;
    }
    if (length >= 4 && index == length ~/ 2) return QuizNarrationEvent.halfway;
    return QuizNarrationEvent.questionPresented;
  }

  /// La réplique après une réponse corrigée (entraînement).
  static QuizNarrationEvent afterAnswer({
    required bool correct,
    required int streak,
  }) {
    if (!correct) return QuizNarrationEvent.incorrect;
    if (streak >= streakStep && streak % streakStep == 0) {
      return QuizNarrationEvent.streak;
    }
    return QuizNarrationEvent.correct;
  }
}
