import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/quiz_attempt.dart';
import '../domain/quiz_attempt_summary.dart';
import '../domain/quiz_mode.dart';
import '../domain/quiz_model.dart';
import '../domain/quiz_question.dart';
import '../domain/quiz_result_payload.dart';
import '../domain/quiz_type.dart';
import 'firebase_quiz_content_service.dart';
import 'firestore_quiz_attempt_service.dart';
import 'quiz_diagnostic.dart';
import 'quiz_repository.dart';

/// Student-facing quiz repository.
///
/// Despite the historical class name, published content is now loaded through
/// authenticated Cloud Functions. The backend returns an allow-listed public
/// projection, so answer keys never transit with the quiz payload. Final
/// scoring remains a single grouped server submission.
class FirestoreQuizRepository implements QuizRepository {
  FirestoreQuizRepository({
    FirebaseQuizContentService? contentService,
    FirestoreQuizAttemptService? attemptService,
    FirebaseFirestore? firestore,
  }) : _contentService = contentService ?? FirebaseQuizContentService(),
       _attemptService = attemptService ?? FirestoreQuizAttemptService(),
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseQuizContentService _contentService;
  final FirestoreQuizAttemptService _attemptService;
  final FirebaseFirestore _firestore;

  @override
  Future<List<QuizModel>> fetchQuizzes({
    required String classLevel,
    required String? series,
  }) async {
    final payloads = await _contentService.listPublishedQuizzes(
      classLevel: classLevel,
      series: series,
    );
    return payloads.map(parsePublicQuizPayload).toList(growable: false);
  }

  @override
  Future<QuizModel> fetchQuizById(String quizId) async {
    final payload = await _contentService.getPublishedQuiz(quizId);
    return parsePublicQuizPayload(payload);
  }

  @override
  Future<List<QuizAttemptSummary>> fetchRecentAttempts({
    required String studentId,
    int limit = 5,
  }) async {
    final snapshot = await _firestore
        .collection('quiz_attempts')
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .limit(limit.clamp(1, 20))
        .get();

    return snapshot.docs
        .map((document) => QuizAttemptSummary.fromFirestore(document.data()))
        .toList(growable: false);
  }

  @override
  Future<QuizQuestionCorrection> checkTrainingAnswer({
    required String quizId,
    required String questionId,
    required String answer,
  }) {
    return _contentService.checkTrainingAnswer(
      quizId: quizId,
      questionId: questionId,
      answer: answer,
    );
  }

  @override
  Future<QuizResultPayload> saveAttempt(QuizAttempt attempt) {
    return _attemptService.saveAttempt(attempt);
  }
}

/// Parses the deliberately restricted student payload.
///
/// Correct answers and explanations are intentionally not read here. They are
/// present only in a correction returned by the server after a check or final
/// submission.
QuizModel parsePublicQuizPayload(Map<String, dynamic> data) {
  final id = _requiredQuizString(data, 'id');
  final title = _requiredQuizString(data, 'title');
  final subjectId = _requiredQuizString(data, 'subjectId', subject: true);
  final subjectLabel = _requiredQuizString(data, 'subjectLabel', subject: true);
  final rawQuestionValue = data['questions'];
  if (rawQuestionValue != null && rawQuestionValue is! List) {
    throw const QuizContentException.invalidResponse();
  }
  final rawQuestions = rawQuestionValue as List<dynamic>? ?? const [];
  final questions = rawQuestions
      .whereType<Map>()
      .map((rawQuestion) {
        final question = Map<String, dynamic>.from(rawQuestion);
        final type = switch (question['type']) {
          'trueFalse' => QuizQuestionType.trueFalse,
          'shortAnswer' => QuizQuestionType.shortAnswer,
          _ => QuizQuestionType.qcm,
        };

        return QuizQuestion(
          id: question['id'] as String? ?? '',
          type: type,
          prompt: question['prompt'] as String? ?? '',
          options: List<String>.from(question['options'] as List? ?? const []),
          explanation: '',
          pointsReward: (question['pointsReward'] as num?)?.toInt() ?? 10,
        );
      })
      .toList(growable: false);

  return QuizModel(
    id: id,
    title: title,
    subjectId: subjectId,
    subjectLabel: subjectLabel,
    description: data['description'] as String? ?? '',
    difficultyLabel: data['difficultyLabel'] as String? ?? 'Intermédiaire',
    timerSeconds: (data['timerSeconds'] as num?)?.toInt(),
    mode: QuizModeX.fromWireValue(data['mode']),
    questionCount: (data['questionCount'] as num?)?.toInt() ?? questions.length,
    questions: questions,
  );
}

String _requiredQuizString(
  Map<String, dynamic> data,
  String key, {
  bool subject = false,
}) {
  final value = data[key];
  if (value is! String || value.trim().isEmpty) {
    throw QuizContentException.invalidResponse(subjectMapping: subject);
  }
  return value.trim();
}
