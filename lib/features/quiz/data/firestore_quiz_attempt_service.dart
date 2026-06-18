import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';

import '../domain/quiz_attempt.dart';
import '../domain/quiz_result_payload.dart';

class FirestoreQuizAttemptService {
  FirestoreQuizAttemptService({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFunctions _functions;
  final Random _random = Random.secure();

  Future<QuizResultPayload> saveAttempt(QuizAttempt attempt) async {
    final callable = _functions.httpsCallable('submitQuizAttempt');
    final clientAttemptId = _newClientAttemptId();

    try {
      final response = await callable.call(
        attempt.toCallablePayload(clientAttemptId: clientAttemptId),
      );

      return QuizResultPayload.fromMap(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on FirebaseFunctionsException catch (error) {
      throw QuizSubmissionException.fromFunctions(error);
    }
  }

  String _newClientAttemptId() {
    final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    final entropy = _random.nextInt(1 << 32).toRadixString(36);
    return 'attempt_${timestamp}_$entropy';
  }
}

class QuizSubmissionException implements Exception {
  const QuizSubmissionException(this.message);

  final String message;

  factory QuizSubmissionException.fromFunctions(
    FirebaseFunctionsException error,
  ) {
    final message = switch (error.code) {
      'not-found' => 'Quiz introuvable ou indisponible.',
      'failed-precondition' => 'Ce quiz ne peut pas encore etre soumis.',
      'already-exists' => 'Cette tentative a deja ete utilisee.',
      'permission-denied' => 'Vous ne pouvez pas soumettre ce quiz.',
      'invalid-argument' => 'La tentative contient des reponses invalides.',
      'unauthenticated' => 'Connectez-vous pour valider le quiz.',
      _ => 'Impossible de valider le quiz pour le moment.',
    };

    return QuizSubmissionException(message);
  }

  @override
  String toString() => message;
}
