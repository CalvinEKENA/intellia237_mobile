import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/quiz_attempt.dart';
import '../domain/quiz_model.dart';
import '../domain/quiz_question.dart';
import '../domain/quiz_result_payload.dart';
import '../domain/quiz_type.dart';
import 'firestore_quiz_attempt_service.dart';
import 'quiz_repository.dart';

/// Implémentation Firestore de [QuizRepository].
///
/// Structure Firestore :
///   quizzes/{quizId}
///     title, subjectId, subjectLabel, description,
///     difficultyLabel, timerSeconds,
///     classLevels: ['3eme', 'Seconde', ...],
///     series: ['A', 'C'] (vide = toutes),
///     status: 'draft' | 'published' | 'ai_generated',
///     questions: [{id, type, prompt, ...}]
class FirestoreQuizRepository implements QuizRepository {
  FirestoreQuizRepository({
    FirebaseFirestore? firestore,
    FirestoreQuizAttemptService? attemptService,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _attemptService = attemptService ?? FirestoreQuizAttemptService();

  final FirebaseFirestore _db;
  final FirestoreQuizAttemptService _attemptService;

  // ───── fetchQuizzes ─────────────────────────────────────────

  @override
  Future<List<QuizModel>> fetchQuizzes({
    required String classLevel,
    required String? series,
  }) async {
    final snap = await _db
        .collection('quizzes')
        .where('status', isEqualTo: 'published')
        .where('classLevels', arrayContains: classLevel)
        .get();

    final quizzes = <QuizModel>[];
    for (final doc in snap.docs) {
      final data = doc.data();

      // Filter by series if specified
      final allowedSeries = List<String>.from(data['series'] as List? ?? []);
      if (allowedSeries.isNotEmpty) {
        if (series == null || !allowedSeries.contains(series)) continue;
      }

      quizzes.add(_quizFromData(doc.id, data));
    }
    return quizzes;
  }

  // ───── fetchQuizById ────────────────────────────────────────

  @override
  Future<QuizModel> fetchQuizById(String quizId) async {
    final doc = await _db.collection('quizzes').doc(quizId).get();
    if (!doc.exists || doc.data() == null) {
      throw StateError('Quiz introuvable: $quizId');
    }
    return _quizFromData(doc.id, doc.data()!);
  }

  // ───── saveAttempt ──────────────────────────────────────────

  @override
  Future<QuizResultPayload> saveAttempt(QuizAttempt attempt) {
    return _attemptService.saveAttempt(attempt);
  }

  // ───── Private helpers ───────────────────────────────────────

  QuizModel _quizFromData(String id, Map<String, dynamic> data) {
    final rawQuestions = data['questions'] as List<dynamic>? ?? [];

    final questions = rawQuestions.map((q) {
      final m = q as Map<String, dynamic>;
      final typeStr = m['type'] as String? ?? 'qcm';
      final type = switch (typeStr) {
        'trueFalse' => QuizQuestionType.trueFalse,
        'shortAnswer' => QuizQuestionType.shortAnswer,
        _ => QuizQuestionType.qcm,
      };

      return QuizQuestion(
        id: m['id'] as String? ?? '',
        type: type,
        prompt: m['prompt'] as String? ?? '',
        options: List<String>.from(m['options'] as List? ?? []),
        correctOptionIndex: m['correctOptionIndex'] as int?,
        correctBooleanValue: m['correctBooleanValue'] as bool?,
        acceptedAnswers: List<String>.from(m['acceptedAnswers'] as List? ?? []),
        explanation: m['explanation'] as String? ?? '',
        xpReward: (m['xpReward'] as int?) ?? 10,
      );
    }).toList();

    return QuizModel(
      id: id,
      title: data['title'] as String? ?? '',
      subjectId: data['subjectId'] as String? ?? '',
      subjectLabel: data['subjectLabel'] as String? ?? '',
      description: data['description'] as String? ?? '',
      difficultyLabel: data['difficultyLabel'] as String? ?? 'Intermédiaire',
      timerSeconds: data['timerSeconds'] as int?,
      questions: questions,
    );
  }
}
