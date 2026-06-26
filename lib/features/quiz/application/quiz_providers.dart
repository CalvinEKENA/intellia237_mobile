import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_user_id.dart';
import '../../learn/application/learn_providers.dart';
import '../data/firestore_quiz_repository.dart';
import '../data/quiz_repository.dart';
import '../domain/quiz_attempt.dart';
import '../domain/quiz_model.dart';
import '../domain/quiz_result_payload.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return FirestoreQuizRepository();
});

final quizHubProvider = FutureProvider<List<QuizModel>>((ref) async {
  final repository = ref.watch(quizRepositoryProvider);
  final context = await ref.watch(studentAcademicContextProvider.future);

  return repository.fetchQuizzes(
    classLevel: context.classLevel,
    series: context.series,
  );
});

final quizByIdProvider = FutureProvider.family<QuizModel, String>((
  ref,
  quizId,
) {
  return ref.watch(quizRepositoryProvider).fetchQuizById(quizId);
});

final currentQuizUserIdProvider = Provider<String>((ref) {
  return requireAuthenticatedUserId(ref.watch(authControllerProvider));
});

final quizAttemptSaverProvider = Provider<QuizAttemptSaver>((ref) {
  return QuizAttemptSaver(ref);
});

class QuizAttemptSaver {
  QuizAttemptSaver(this._ref);

  final Ref _ref;

  Future<QuizResultPayload> saveAttempt(QuizAttempt attempt) {
    return _ref.read(quizRepositoryProvider).saveAttempt(attempt);
  }
}
