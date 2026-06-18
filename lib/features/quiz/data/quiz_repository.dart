import '../domain/quiz_attempt.dart';
import '../domain/quiz_model.dart';

abstract class QuizRepository {
  Future<List<QuizModel>> fetchQuizzes({
    required String classLevel,
    required String? series,
  });

  Future<QuizModel> fetchQuizById(String quizId);

  Future<void> saveAttempt(QuizAttempt attempt);
}
