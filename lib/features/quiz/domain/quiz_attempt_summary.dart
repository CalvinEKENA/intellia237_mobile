import 'package:cloud_firestore/cloud_firestore.dart';

/// Projection minimale d'une tentative déjà validée par le serveur.
///
/// Les réponses et les corrigés sont volontairement absents : l'historique
/// n'en a pas besoin et ne doit jamais les recopier dans un cache UI.
class QuizAttemptSummary {
  const QuizAttemptSummary({
    required this.quizId,
    required this.quizTitle,
    required this.subjectLabel,
    required this.score,
    required this.maxScore,
    required this.pointsAwarded,
    required this.submittedAt,
  });

  final String quizId;
  final String quizTitle;
  final String subjectLabel;
  final int score;
  final int maxScore;
  final int pointsAwarded;
  final DateTime? submittedAt;

  factory QuizAttemptSummary.fromFirestore(Map<String, dynamic> data) {
    return QuizAttemptSummary(
      quizId: data['quizId'] as String? ?? '',
      quizTitle: data['quizTitle'] as String? ?? 'Quiz',
      subjectLabel: data['subjectLabel'] as String? ?? 'Matière non précisée',
      score: (data['score'] as num?)?.toInt() ?? 0,
      maxScore: (data['maxScore'] as num?)?.toInt() ?? 0,
      pointsAwarded:
          ((data['pointsAwarded'] ?? data['xpAwarded']) as num?)?.toInt() ?? 0,
      submittedAt:
          _dateTime(data['createdAt']) ??
          _dateTime(data['updatedAt']) ??
          _dateTime(data['startedAtClient']),
    );
  }
}

DateTime? _dateTime(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
