import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/quiz_attempt.dart';

class FirestoreQuizAttemptService {
  FirestoreQuizAttemptService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> saveAttempt(QuizAttempt attempt) async {
    final batch = _firestore.batch();
    final attemptRef = _firestore.collection('quiz_attempts').doc();
    batch.set(attemptRef, attempt.toMap());

    final userRef = _firestore.collection('users').doc(attempt.userId);
    batch.set(userRef, <String, dynamic>{
      'xp': FieldValue.increment(attempt.xpAwarded),
      'updatedAt': DateTime.now().toUtc(),
    }, SetOptions(merge: true));

    final profileRef = _firestore
        .collection('student_profiles')
        .doc(attempt.userId);
    batch.set(profileRef, <String, dynamic>{
      'xp': FieldValue.increment(attempt.xpAwarded),
      'updatedAt': DateTime.now().toUtc(),
    }, SetOptions(merge: true));

    await batch.commit();
  }
}
