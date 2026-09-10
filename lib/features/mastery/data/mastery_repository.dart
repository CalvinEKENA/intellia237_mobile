import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/quiz_evidence.dart';

abstract interface class MasteryRepository {
  Stream<List<QuizEvidence>> watchQuizEvidence(String learnerId);
}

/// Read-only, existing server-owned summary collection. In particular this
/// does NOT read quiz_attempts, which also contains private corrections.
class FirestoreMasteryRepository implements MasteryRepository {
  FirestoreMasteryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<QuizEvidence>> watchQuizEvidence(String learnerId) => _firestore
      .collection('progress')
      .where('studentId', isEqualTo: learnerId)
      .where('type', isEqualTo: 'quiz')
      .snapshots(includeMetadataChanges: true)
      .map(
        (snapshot) => [
          for (final document in snapshot.docs)
            if (!document.metadata.hasPendingWrites)
              ?parseQuizProgress(document.data(), learnerId: learnerId),
        ],
      );
}

/// Strict allow-list: missing/invalid scores are not silently turned into
/// zeroes. Only the server timestamp is accepted, never client time.
QuizEvidence? parseQuizProgress(
  Map<String, dynamic> data, {
  required String learnerId,
}) {
  if (data['type'] != 'quiz' || data['studentId'] != learnerId) return null;
  final quizId = data['quizId'];
  final subjectId = data['subjectId'];
  final score = _integer(data['score']);
  final maxScore = _integer(data['maxScore']);
  final timestamp = data['updatedAt'];
  if (quizId is! String ||
      subjectId is! String ||
      quizId != quizId.trim() ||
      subjectId != subjectId.trim() ||
      score == null ||
      maxScore == null ||
      timestamp is! Timestamp) {
    return null;
  }
  final evidence = QuizEvidence(
    quizId: quizId,
    subjectId: subjectId,
    correctAnswers: score,
    questionCount: maxScore,
    recordedAt: timestamp.toDate().toUtc(),
  );
  return evidence.isValid ? evidence : null;
}

int? _integer(Object? value) =>
    value is num && value.isFinite && value == value.truncateToDouble()
    ? value.toInt()
    : null;
