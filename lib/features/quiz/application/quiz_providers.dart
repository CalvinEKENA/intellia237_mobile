import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_user_id.dart';
import '../../learn/application/learn_providers.dart';
import '../../learn/data/student_academic_profile_source.dart';
import '../data/firestore_quiz_repository.dart';
import '../data/quiz_diagnostic.dart';
import '../data/quiz_repository.dart';
import '../domain/quiz_attempt.dart';
import '../domain/quiz_attempt_summary.dart';
import '../domain/quiz_model.dart';
import '../domain/quiz_result_payload.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return FirestoreQuizRepository();
});

final quizHubProvider = FutureProvider<List<QuizModel>>((ref) async {
  final repository = ref.watch(quizRepositoryProvider);
  try {
    final context = await ref.watch(studentAcademicContextProvider.future);

    return await repository.fetchQuizzes(
      classLevel: context.quizAndCatalogClassLevel,
      series: context.series,
    );
  } on AcademicProfileException catch (error, stackTrace) {
    final failure = QuizContentException.fromAcademic(error);
    _logQuizFailure(failure, stackTrace);
    throw failure;
  } on QuizContentException catch (error, stackTrace) {
    _logQuizFailure(error, stackTrace);
    rethrow;
  }
});

final quizByIdProvider = FutureProvider.family<QuizModel, String>((
  ref,
  quizId,
) {
  return ref.watch(quizRepositoryProvider).fetchQuizById(quizId);
});

final quizAttemptHistoryProvider = FutureProvider<List<QuizAttemptSummary>>((
  ref,
) async {
  final auth = ref.watch(authControllerProvider);
  final studentId = auth.userId;
  if (!auth.isAuthenticated || studentId == null || studentId.trim().isEmpty) {
    return const [];
  }

  return ref
      .watch(quizRepositoryProvider)
      .fetchRecentAttempts(studentId: studentId, limit: 5);
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

void _logQuizFailure(QuizContentException error, StackTrace stackTrace) {
  debugPrint(
    '[INTELLIA237][quiz] '
    'quizOperation=${error.operation.code} '
    'normalizedErrorCode=${error.normalizedErrorCode} '
    'diagnosticId=${error.diagnosticId}',
  );
  if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
}
