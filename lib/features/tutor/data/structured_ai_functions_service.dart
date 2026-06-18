import 'package:cloud_functions/cloud_functions.dart';

class GeneratedQuizResult {
  const GeneratedQuizResult({
    required this.traceId,
    required this.quizId,
    required this.quiz,
  });

  final String traceId;
  final String quizId;
  final Map<String, dynamic> quiz;

  factory GeneratedQuizResult.fromMap(Map<String, dynamic> map) {
    return GeneratedQuizResult(
      traceId: map['traceId'] as String? ?? '',
      quizId: map['quizId'] as String? ?? '',
      quiz: Map<String, dynamic>.from(map['quiz'] as Map? ?? const {}),
    );
  }
}

class GeneratedSummaryResult {
  const GeneratedSummaryResult({
    required this.traceId,
    required this.summaryId,
    required this.summary,
  });

  final String traceId;
  final String summaryId;
  final Map<String, dynamic> summary;

  factory GeneratedSummaryResult.fromMap(Map<String, dynamic> map) {
    return GeneratedSummaryResult(
      traceId: map['traceId'] as String? ?? '',
      summaryId: map['summaryId'] as String? ?? '',
      summary: Map<String, dynamic>.from(map['summary'] as Map? ?? const {}),
    );
  }
}

class StructuredAiFunctionsService {
  StructuredAiFunctionsService({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(
              region: 'europe-west1',
            );

  final FirebaseFunctions _functions;

  Future<GeneratedQuizResult> generateQuiz({
    required String courseId,
    required int count,
    required String difficulty,
  }) async {
    final callable = _functions.httpsCallable('generateQuiz');
    final result = await callable.call(<String, dynamic>{
      'courseId': courseId,
      'count': count,
      'difficulty': difficulty,
    });

    return GeneratedQuizResult.fromMap(
      Map<String, dynamic>.from(result.data as Map),
    );
  }

  Future<GeneratedSummaryResult> generateSummary({
    required String courseId,
    required String level,
  }) async {
    final callable = _functions.httpsCallable('generateSummary');
    final result = await callable.call(<String, dynamic>{
      'courseId': courseId,
      'level': level,
    });

    return GeneratedSummaryResult.fromMap(
      Map<String, dynamic>.from(result.data as Map),
    );
  }
}
