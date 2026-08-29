import '../domain/quiz_attempt.dart';
import '../domain/quiz_attempt_summary.dart';
import '../domain/quiz_model.dart';
import '../domain/quiz_result_payload.dart';

abstract class QuizRepository {
  Future<List<QuizModel>> fetchQuizzes({
    required String classLevel,
    required String? series,
  });

  Future<QuizModel> fetchQuizById(String quizId);

  Future<List<QuizAttemptSummary>> fetchRecentAttempts({
    required String studentId,
    int limit = 5,
  });

  Future<QuizQuestionCorrection> checkTrainingAnswer({
    required String quizId,
    required String questionId,
    required String answer,
  });

  Future<QuizResultPayload> saveAttempt(QuizAttempt attempt);
}
