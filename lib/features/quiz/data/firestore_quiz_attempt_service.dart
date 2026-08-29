import 'package:cloud_functions/cloud_functions.dart';

import '../domain/quiz_attempt.dart';
import '../domain/quiz_result_payload.dart';

class FirestoreQuizAttemptService {
  FirestoreQuizAttemptService({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFunctions _functions;

  Future<QuizResultPayload> saveAttempt(QuizAttempt attempt) async {
    final callable = _functions.httpsCallable('submitQuizAttempt');

    try {
      final response = await callable.call(attempt.toCallablePayload());

      return QuizResultPayload.fromMap(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on FirebaseFunctionsException catch (error) {
      throw QuizSubmissionException.fromFunctions(error);
    }
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
      'failed-precondition' => 'Ce quiz ne peut pas encore être soumis.',
      'already-exists' => 'Cette tentative a déjà été utilisée.',
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
