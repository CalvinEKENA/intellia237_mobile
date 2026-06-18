import '../domain/quiz_attempt.dart';
import '../domain/quiz_model.dart';
import '../domain/quiz_result_payload.dart';

abstract class QuizRepository {
  Future<List<QuizModel>> fetchQuizzes({
    required String classLevel,
    required String? series,
  });

  Future<QuizModel> fetchQuizById(String quizId);

  Future<QuizResultPayload> saveAttempt(QuizAttempt attempt);
}
