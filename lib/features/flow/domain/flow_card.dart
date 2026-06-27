import 'flow_subject.dart';

/// Type d'illustration animée pour une [FlowAnimationCard].
enum FlowAnimationKind { pendulum, cellDivision, parabola }

/// Une carte du Flow — occupe tout l'écran, vécue en 15 à 45 secondes.
///
/// Hiérarchie scellée (`sealed`) : le rendu fait un `switch` exhaustif sur les
/// variantes, sans cas par défaut.
sealed class FlowCard {
  const FlowCard({
    required this.id,
    required this.subject,
    required this.kicker,
    required this.estimatedSeconds,
    required this.xpReward,
  });

  final String id;
  final FlowSubject subject;

  /// Petit label de tête (« Notion », « Le savais-tu ? », « Mini-quiz »…).
  final String kicker;

  /// Durée cible d'une interaction (15–45 s).
  final int estimatedSeconds;

  /// XP gagnés à la complétion (pour le mini-quiz : si la réponse est juste).
  final int xpReward;
}

/// Une notion clé, énoncée simplement avec 2–3 points essentiels.
final class FlowNotionCard extends FlowCard {
  const FlowNotionCard({
    required super.id,
    required super.subject,
    required this.title,
    required this.insight,
    required this.points,
    super.kicker = 'Notion',
    super.estimatedSeconds = 30,
    super.xpReward = 12,
  });

  final String title;
  final String insight;
  final List<String> points;
}

/// Une question qui pique la curiosité, avec une réponse à révéler.
final class FlowQuestionCard extends FlowCard {
  const FlowQuestionCard({
    required super.id,
    required super.subject,
    required this.question,
    required this.answer,
    super.kicker = 'Question',
    super.estimatedSeconds = 25,
    super.xpReward = 10,
  });

  final String question;
  final String answer;
}

/// Une capsule vidéo (poster + lecture simulée — pas de média réel ici).
final class FlowVideoCard extends FlowCard {
  const FlowVideoCard({
    required super.id,
    required super.subject,
    required this.title,
    required this.description,
    required this.durationLabel,
    super.kicker = 'Capsule vidéo',
    super.estimatedSeconds = 45,
    super.xpReward = 15,
  });

  final String title;
  final String description;
  final String durationLabel;
}

/// Une notion illustrée par une animation conceptuelle (pendule, cellule…).
final class FlowAnimationCard extends FlowCard {
  const FlowAnimationCard({
    required super.id,
    required super.subject,
    required this.title,
    required this.caption,
    required this.kind,
    super.kicker = 'En animation',
    super.estimatedSeconds = 30,
    super.xpReward = 12,
  });

  final String title;
  final String caption;
  final FlowAnimationKind kind;
}

/// Une anecdote / un fait marquant pour ancrer la mémoire.
final class FlowAnecdoteCard extends FlowCard {
  const FlowAnecdoteCard({
    required super.id,
    required super.subject,
    required this.title,
    required this.story,
    super.kicker = 'Le savais-tu ?',
    super.estimatedSeconds = 20,
    super.xpReward = 10,
  });

  final String title;
  final String story;
}

/// Un mini-quiz à une question, joué directement dans le Flow.
final class FlowMiniQuizCard extends FlowCard {
  const FlowMiniQuizCard({
    required super.id,
    required super.subject,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    super.kicker = 'Mini-quiz',
    super.estimatedSeconds = 30,
    super.xpReward = 25,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
}

/// Une carte de récompense / palier (XP cumulés, série, badge).
final class FlowRewardCard extends FlowCard {
  const FlowRewardCard({
    required super.id,
    required super.subject,
    required this.title,
    required this.message,
    super.kicker = 'Palier atteint',
    super.estimatedSeconds = 15,
    super.xpReward = 0,
  });

  final String title;
  final String message;
}
