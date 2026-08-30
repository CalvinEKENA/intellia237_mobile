import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';

import '../domain/quiz_result_payload.dart';
import 'quiz_diagnostic.dart';
import 'quiz_public_content_cache.dart';

abstract interface class QuizFunctionsGateway {
  Future<Object?> call(String name, Map<String, dynamic> payload);
}

class FirebaseQuizFunctionsGateway implements QuizFunctionsGateway {
  FirebaseQuizFunctionsGateway({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFunctions _functions;

  @override
  Future<Object?> call(String name, Map<String, dynamic> payload) async {
    try {
      final response = await _functions
          .httpsCallable(name)
          .call(payload)
          .timeout(const Duration(seconds: 12));
      return response.data;
    } on FirebaseFunctionsException catch (error) {
      throw QuizCallableFailure(
        code: error.code,
        message: error.message,
        details: error.details,
      );
    } on TimeoutException {
      throw const QuizCallableFailure(code: 'deadline-exceeded');
    }
  }
}

/// Loads the validated, answer-free quiz projection.
///
/// Resilience order is deliberately fixed: published callable content, then
/// the last sanitized cache. Generative content is never requested merely by
/// opening the hub.
class FirebaseQuizContentService {
  FirebaseQuizContentService({
    FirebaseFunctions? functions,
    QuizFunctionsGateway? gateway,
    QuizPublicContentCache? cache,
  }) : _gateway = gateway ?? FirebaseQuizFunctionsGateway(functions: functions),
       _cache = cache ?? QuizPublicContentCache();

  final QuizFunctionsGateway _gateway;
  final QuizPublicContentCache _cache;

  Future<List<Map<String, dynamic>>> listPublishedQuizzes({
    required String classLevel,
    required String? series,
  }) async {
    QuizContentException? failure;
    try {
      final raw = await _gateway.call('listPublishedQuizzes', {
        'classLevel': classLevel,
        'series': series,
      });
      final data = _stringMap(raw);
      final rawItems = data['quizzes'];
      if (rawItems is! List) {
        throw const QuizContentException.invalidResponse();
      }
      final quizzes = <Map<String, dynamic>>[];
      for (final item in rawItems) {
        if (item is! Map) {
          throw const QuizContentException.invalidResponse();
        }
        quizzes.add(Map<String, dynamic>.from(item));
      }
      await _bestEffort(
        _cache.writeList(
          classLevel: classLevel,
          series: series,
          quizzes: quizzes,
        ),
      );
      return quizzes;
    } on QuizCallableFailure catch (error) {
      failure = QuizContentException.fromCallable(error);
    } on QuizContentException catch (error) {
      failure = error;
    } on Object {
      failure = const QuizContentException.invalidResponse();
    }

    final cached = await _cachedList(classLevel: classLevel, series: series);
    if (cached != null) return cached;
    throw failure;
  }

  Future<Map<String, dynamic>> getPublishedQuiz(String quizId) async {
    QuizContentException? failure;
    try {
      final raw = await _gateway.call('getPublishedQuiz', {'quizId': quizId});
      final data = _stringMap(raw);
      final rawQuiz = data['quiz'];
      if (rawQuiz is! Map) {
        throw const QuizContentException.invalidResponse();
      }
      final quiz = Map<String, dynamic>.from(rawQuiz);
      await _bestEffort(_cache.writeQuiz(quizId, quiz));
      return quiz;
    } on QuizCallableFailure catch (error) {
      failure = QuizContentException.fromCallable(error);
    } on QuizContentException catch (error) {
      failure = error;
    } on Object {
      failure = const QuizContentException.invalidResponse();
    }

    final cached = await _cachedQuiz(quizId);
    if (cached != null) return cached;
    throw failure;
  }

  Future<QuizQuestionCorrection> checkTrainingAnswer({
    required String quizId,
    required String questionId,
    required String answer,
  }) async {
    try {
      final raw = await _gateway.call('checkTrainingQuizAnswer', {
        'quizId': quizId,
        'questionId': questionId,
        'answer': answer,
      });
      final data = _stringMap(raw);
      final correction = data['correction'];
      if (correction is! Map) {
        throw const QuizContentException.invalidResponse();
      }
      return QuizQuestionCorrection.fromMap(
        Map<String, dynamic>.from(correction),
      );
    } on QuizCallableFailure catch (error) {
      throw QuizContentException.fromCallable(error);
    } on QuizContentException {
      rethrow;
    } on Object {
      throw const QuizContentException.invalidResponse();
    }
  }

  Map<String, dynamic> _stringMap(Object? value) {
    if (value is! Map) {
      throw const QuizContentException.invalidResponse();
    }
    return Map<String, dynamic>.from(value);
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
