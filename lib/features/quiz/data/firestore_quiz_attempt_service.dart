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
  const QuizSubmissionException(this.code);

  final String code;

  factory QuizSubmissionException.fromFunctions(
    FirebaseFunctionsException error,
  ) {
    return QuizSubmissionException(error.code);
  }

  @override
  String toString() => 'QuizSubmissionException($code)';
}
