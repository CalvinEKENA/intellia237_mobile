import '../domain/quiz_attempt.dart';
import '../domain/quiz_model.dart';
import '../domain/quiz_question.dart';
import '../domain/quiz_result_payload.dart';
import '../domain/quiz_type.dart';
import 'firestore_quiz_attempt_service.dart';
import 'quiz_repository.dart';

class MockQuizRepository implements QuizRepository {
  MockQuizRepository({FirestoreQuizAttemptService? attemptService})
    : _attemptService = attemptService ?? FirestoreQuizAttemptService();

  final FirestoreQuizAttemptService _attemptService;

  @override
  Future<List<QuizModel>> fetchQuizzes({
    required String classLevel,
    required String? series,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return _quizSeeds
        .where((quiz) => quiz.allowedClasses.contains(classLevel))
        .where((quiz) {
          if (quiz.allowedSeries.isEmpty) {
            return true;
          }
          return series != null && quiz.allowedSeries.contains(series);
        })
        .map((seed) => seed.quiz)
        .toList(growable: false);
  }

  @override
  Future<QuizModel> fetchQuizById(String quizId) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    final seed = _quizSeeds.firstWhere(
      (item) => item.quiz.id == quizId,
      orElse: () => throw StateError('Quiz introuvable: $quizId'),
    );
    return seed.quiz;
  }

  @override
  Future<QuizResultPayload> saveAttempt(QuizAttempt attempt) async {
    try {
      return await _attemptService.saveAttempt(attempt);
    } catch (_) {
      final quiz = _quizSeeds
          .firstWhere(
            (item) => item.quiz.id == attempt.quizId,
            orElse: () => _quizSeeds.first,
          )
          .quiz;
      return QuizResultPayload(
        quizId: quiz.id,
        quizTitle: quiz.title,
        subjectLabel: quiz.subjectLabel,
        score: 0,
        maxScore: quiz.questions.length,
        xpAwarded: 0,
        corrections: const [],
      );
    }
  }

  static final List<_QuizSeed> _quizSeeds = [
    _QuizSeed(
      allowedClasses: const [
        '6eme',
        '5eme',
        '4eme',
        '3eme',
        'Seconde',
        'Premiere',
        'Terminale',
      ],
      quiz: QuizModel(
        id: 'quiz_math_equations',
        title: 'Sprint Equations',
        subjectId: 'math',
        subjectLabel: 'Mathematiques',
        description: 'Entrainement rapide sur equations et logique.',
        difficultyLabel: 'Intermediaire',
        timerSeconds: 180,
        questions: const [
          QuizQuestion(
            id: 'm1',
            type: QuizQuestionType.qcm,
            prompt: 'Resoudre 4x + 8 = 0',
            options: ['x = -2', 'x = 2', 'x = -8'],
            correctOptionIndex: 0,
            explanation: '4x = -8 donc x = -2.',
            xpReward: 10,
          ),
          QuizQuestion(
            id: 'm2',
            type: QuizQuestionType.trueFalse,
            prompt: 'L\'equation x + 5 = x admet une solution.',
            correctBooleanValue: false,
            explanation: 'On obtient 5 = 0, impossible.',
            xpReward: 8,
          ),
          QuizQuestion(
            id: 'm3',
            type: QuizQuestionType.shortAnswer,
            prompt: 'Donne la solution de 2x = 14',
            acceptedAnswers: ['7', 'x=7', 'x = 7'],
            explanation: '2x = 14 implique x = 7.',
            xpReward: 12,
          ),
        ],
      ),
    ),
    _QuizSeed(
      allowedClasses: const ['Seconde', 'Premiere', 'Terminale'],
      allowedSeries: const ['A', 'C', 'D'],
      quiz: QuizModel(
        id: 'quiz_phys_ohm',
        title: 'Mission Loi d\'Ohm',
        subjectId: 'phys',
        subjectLabel: 'Physique-Chimie',
        description: 'Calcule rapidement U, R et I dans des circuits simples.',
        difficultyLabel: 'Accessible',
        timerSeconds: 240,
        questions: const [
          QuizQuestion(
            id: 'p1',
            type: QuizQuestionType.qcm,
            prompt: 'Si U = 12V et I = 3A, R vaut:',
            options: ['4 ohms', '9 ohms', '36 ohms'],
            correctOptionIndex: 0,
            explanation: 'R = U / I = 12 / 3 = 4.',
            xpReward: 9,
          ),
          QuizQuestion(
            id: 'p2',
            type: QuizQuestionType.trueFalse,
            prompt: 'La relation U = R x I est la loi d\'Ohm.',
            correctBooleanValue: true,
            explanation:
                'Oui, c\'est la relation fondamentale de la loi d\'Ohm.',
            xpReward: 7,
          ),
          QuizQuestion(
            id: 'p3',
            type: QuizQuestionType.shortAnswer,
            prompt: 'Si R = 5 ohms et I = 2A, U = ?',
            acceptedAnswers: ['10', '10v', '10 v', 'u=10', 'u = 10'],
            explanation: 'U = R x I = 10 volts.',
            xpReward: 11,
          ),
        ],
      ),
    ),
    _QuizSeed(
      allowedClasses: const [
        '6eme',
        '5eme',
        '4eme',
        '3eme',
        'Seconde',
        'Premiere',
        'Terminale',
      ],
      quiz: QuizModel(
        id: 'quiz_fr_argument',
        title: 'Defi Argumentation',
        subjectId: 'fr',
        subjectLabel: 'Francais',
        description: 'Valide les bases de l\'argumentation claire et concise.',
        difficultyLabel: 'Debutant+',
        questions: const [
          QuizQuestion(
            id: 'f1',
            type: QuizQuestionType.qcm,
            prompt: 'Un paragraphe argumente commence idealement par:',
            options: [
              'Un exemple',
              'Une idee directrice',
              'Une citation longue',
            ],
            correctOptionIndex: 1,
            explanation: 'L\'idee directrice guide tout le paragraphe.',
            xpReward: 8,
          ),
          QuizQuestion(
            id: 'f2',
            type: QuizQuestionType.trueFalse,
            prompt: 'Une argumentation solide peut se passer d\'exemples.',
            correctBooleanValue: false,
            explanation:
                'Les exemples renforcent la credibilite et la comprehension.',
            xpReward: 8,
          ),
          QuizQuestion(
            id: 'f3',
            type: QuizQuestionType.shortAnswer,
            prompt: 'Ecris un mot cle associe a l\'argumentation.',
            acceptedAnswers: ['idee', 'exemple', 'preuve', 'argument'],
            explanation: 'Idee, preuve, argument ou exemple sont pertinents.',
            xpReward: 10,
          ),
        ],
      ),
    ),
  ];
}

class _QuizSeed {
  const _QuizSeed({
    required this.allowedClasses,
    this.allowedSeries = const [],
    required this.quiz,
  });

  final List<String> allowedClasses;
  final List<String> allowedSeries;
  final QuizModel quiz;
}
