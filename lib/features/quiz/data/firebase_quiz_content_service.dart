import 'package:cloud_functions/cloud_functions.dart';

import '../domain/quiz_result_payload.dart';
import 'quiz_public_content_cache.dart';

/// Student-facing gateway for quiz content.
///
/// Quiz documents are deliberately read through Cloud Functions. The server
/// projects an allow-listed public payload and never returns answer keys in the
/// quiz body. Staff authoring screens keep their own restricted Firestore path.
class FirebaseQuizContentService {
  FirebaseQuizContentService({
    FirebaseFunctions? functions,
    QuizPublicContentCache? cache,
  }) : _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1'),
       _cache = cache ?? QuizPublicContentCache();

  final FirebaseFunctions _functions;
  final QuizPublicContentCache _cache;

  Future<List<Map<String, dynamic>>> listPublishedQuizzes({
    required String classLevel,
    required String? series,
  }) async {
    try {
      final response = await _functions
          .httpsCallable('listPublishedQuizzes')
          .call(<String, dynamic>{'classLevel': classLevel, 'series': series});
      final data = Map<String, dynamic>.from(response.data as Map);
      final items = data['quizzes'] as List<dynamic>? ?? const [];
      final quizzes = items
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
      await _bestEffort(
        _cache.writeList(
          classLevel: classLevel,
          series: series,
          quizzes: quizzes,
        ),
      );
      return quizzes;
    } on FirebaseFunctionsException catch (error) {
      final cached = await _cachedList(classLevel: classLevel, series: series);
      if (cached != null) return cached;
      throw QuizContentException.fromFunctions(error);
    }
  }

  Future<Map<String, dynamic>> getPublishedQuiz(String quizId) async {
    try {
      final response = await _functions.httpsCallable('getPublishedQuiz').call(
        <String, dynamic>{'quizId': quizId},
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      final quiz = Map<String, dynamic>.from(data['quiz'] as Map);
      await _bestEffort(_cache.writeQuiz(quizId, quiz));
      return quiz;
    } on FirebaseFunctionsException catch (error) {
      final cached = await _cachedQuiz(quizId);
      if (cached != null) return cached;
      throw QuizContentException.fromFunctions(error);
    }
  }

  /// Checks one answer only for a quiz explicitly configured as training.
  /// This call never writes rewards; the grouped submission remains the sole
  /// authority for the final score and academic points.
  Future<QuizQuestionCorrection> checkTrainingAnswer({
    required String quizId,
    required String questionId,
    required String answer,
  }) async {
    try {
      final response = await _functions
          .httpsCallable('checkTrainingQuizAnswer')
          .call(<String, dynamic>{
            'quizId': quizId,
            'questionId': questionId,
            'answer': answer,
          });
      final data = Map<String, dynamic>.from(response.data as Map);
      return QuizQuestionCorrection.fromMap(
        Map<String, dynamic>.from(data['correction'] as Map),
      );
    } on FirebaseFunctionsException catch (error) {
      throw QuizContentException.fromFunctions(error);
    }
  }

  Future<List<Map<String, dynamic>>?> _cachedList({
    required String classLevel,
    required String? series,
  }) async {
    try {
      return await _cache.readList(classLevel: classLevel, series: series);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _cachedQuiz(String quizId) async {
    try {
      return await _cache.readQuiz(quizId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _bestEffort(Future<void> operation) async {
    try {
      await operation;
    } catch (_) {
      // A cache failure must never hide fresh server content.
    }
  }
}

class QuizContentException implements Exception {
  const QuizContentException(this.message);

  final String message;

  factory QuizContentException.fromFunctions(FirebaseFunctionsException error) {
    final message = switch (error.code) {
      'not-found' => 'Quiz introuvable ou indisponible.',
      'failed-precondition' =>
        'Cette vérification est réservée au mode entraînement.',
      'permission-denied' => 'Ce quiz ne correspond pas à ton profil.',
      'invalid-argument' => 'La réponse envoyée est invalide.',
      'unauthenticated' => 'Connecte-toi pour accéder au quiz.',
      'unavailable' =>
        'Connexion insuffisante. Réessaie lorsque le réseau est disponible.',
      _ => 'Impossible de charger le quiz pour le moment.',
    };
    return QuizContentException(message);
  }

  @override
  String toString() => message;
}
