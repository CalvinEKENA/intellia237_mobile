import '../../content_engine/domain/chapter.dart';
import '../../content_engine/feed/learning_card.dart';
import 'flow_subject.dart';

/// Type d'illustration animée pour une [FlowAnimationCard].
enum FlowAnimationKind {
  pendulum,
  cellDivision,
  parabola,

  /// SVT 6e : germination de 9 graines à 10 °C, 18 °C et 40 °C.
  germinationTemperature,

  /// SVT 6e : germination selon l'arrosage (peu, normal, beaucoup d'eau).
  germinationWatering;

  /// Composants natifs publiables depuis le Studio (type `interactiveNative`).
  /// Clés versionnées : une évolution incompatible devient `_v2`.
  static const Map<String, FlowAnimationKind> byComponentKey = {
    'svt_germination_temperature_v1': germinationTemperature,
    'svt_germination_watering_v1': germinationWatering,
  };
}

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
    required this.pointsReward,
  });

  final String id;
  final FlowSubject subject;

  /// Petit label de tête (« Notion », « Le savais-tu ? », « Mini-quiz »…).
  final String kicker;

  /// Durée cible d'une interaction (15–45 s).
  final int estimatedSeconds;

  /// Points gagnés à la complétion (pour le mini-quiz : si la réponse est juste).
  final int pointsReward;
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
    super.pointsReward = 12,
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
    super.pointsReward = 10,
  });

  final String question;
  final String answer;
}

/// Une capsule portant la même référence média que la leçon.
final class FlowVideoCard extends FlowCard {
  const FlowVideoCard({
    required super.id,
    required super.subject,
    required this.title,
    required this.description,
    required this.durationLabel,
    this.storagePath,
    this.fileSizeBytes,
    super.kicker = 'Capsule vidéo',
    super.estimatedSeconds = 45,
    super.pointsReward = 15,
  });

  final String title;
  final String description;
  final String durationLabel;
  final String? storagePath;
  final int? fileSizeBytes;
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
    super.pointsReward = 12,
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
    this.imagePath,
    super.kicker = 'Le savais-tu ?',
    super.estimatedSeconds = 20,
    super.pointsReward = 10,
  });

  final String title;
  final String story;

  /// Chemin canonique d'une image publiée (carte « image » du Studio).
  final String? imagePath;
}

/// Un mini-quiz à une question, joué directement dans le Flow.
sealed class FlowExerciseCard extends FlowCard {
  const FlowExerciseCard({
    required super.id,
    required super.subject,
    required super.kicker,
    required super.estimatedSeconds,
    required super.pointsReward,
    required this.explanation,
  });

  final String explanation;
}

final class FlowMiniQuizCard extends FlowExerciseCard {
  const FlowMiniQuizCard({
    required super.id,
    required super.subject,
    required this.question,
    required this.options,
    required this.correctIndex,
    required super.explanation,
    super.kicker = 'Mini-quiz',
    super.estimatedSeconds = 30,
    super.pointsReward = 25,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
}

/// Affirmation à valider en vrai ou faux.
final class FlowTrueFalseCard extends FlowExerciseCard {
  const FlowTrueFalseCard({
    required super.id,
    required super.subject,
    required this.statement,
    required this.correctValue,
    required super.explanation,
    super.kicker = 'Vrai ou faux',
    super.estimatedSeconds = 20,
    super.pointsReward = 18,
  });

  final String statement;
  final bool correctValue;
}

/// Réponse courte, tolérante à la casse, aux accents et aux espaces.
final class FlowFillBlankCard extends FlowExerciseCard {
  const FlowFillBlankCard({
    required super.id,
    required super.subject,
    required this.prompt,
    required this.acceptedAnswers,
    required super.explanation,
    this.hint,
    super.kicker = 'Complète',
    super.estimatedSeconds = 30,
    super.pointsReward = 22,
  });

  final String prompt;
  final List<String> acceptedAnswers;
  final String? hint;

  bool accepts(String answer) {
    final normalized = _normalizeFlowAnswer(answer);
    return normalized.isNotEmpty &&
        acceptedAnswers.any(
          (candidate) => _normalizeFlowAnswer(candidate) == normalized,
        );
  }
}

/// Éléments à remettre dans l'ordre. [items] contient l'ordre attendu.
final class FlowOrderingCard extends FlowExerciseCard {
  const FlowOrderingCard({
    required super.id,
    required super.subject,
    required this.instruction,
    required this.items,
    required super.explanation,
    super.kicker = 'Remets dans l’ordre',
    super.estimatedSeconds = 40,
    super.pointsReward = 25,
  });

  final String instruction;
  final List<String> items;

  bool accepts(List<String> answer) {
    if (answer.length != items.length) return false;
    for (var i = 0; i < items.length; i++) {
      if (answer[i] != items[i]) return false;
    }
    return true;
  }
}

String _normalizeFlowAnswer(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[’‘`´]'), "'")
    .replaceAll(RegExp(r'[^a-z0-9àâäéèêëîïôöùûüçœ]+'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .replaceAll(RegExp('[àâä]'), 'a')
    .replaceAll(RegExp('[éèêë]'), 'e')
    .replaceAll(RegExp('[îï]'), 'i')
    .replaceAll(RegExp('[ôö]'), 'o')
    .replaceAll(RegExp('[ùûü]'), 'u')
    .replaceAll('ç', 'c')
    .replaceAll('œ', 'oe')
    .trim();

/// Une carte de récompense / palier (points cumulés, série, badge).
final class FlowRewardCard extends FlowCard {
  const FlowRewardCard({
    required super.id,
    required super.subject,
    required this.title,
    required this.message,
    super.kicker = 'Palier atteint',
    super.estimatedSeconds = 15,
    super.pointsReward = 0,
  });

  final String title;
  final String message;
}

/// Une carte tirée d'un pack de la Content Engine (toutes les classes).
///
/// Le fil publié et les packs partagent le même pager, le même HUD et la
/// même progression locale : ce n'est pas un second fil, c'est une nouvelle
/// source de cartes. Les réponses passent par le moteur de maîtrise des
/// packs, jamais par le serveur de points du fil publié.
final class FlowLearningCard extends FlowCard {
  FlowLearningCard({required this.learning, required this.chapter})
    : super(
        id: 'pack:${learning.id}',
        subject:
            FlowSubjects.fromLabel(learning.subject) ??
            FlowSubjects.fromLabel(chapter.curriculum.subject) ??
            FlowSubjects.maths,
        kicker: learning.type.name,
        estimatedSeconds: learning.estimatedSeconds,
        pointsReward: 0,
      );

  final LearningCard learning;
  final Chapter chapter;
}
