import 'package:flutter/foundation.dart';

import '../domain/chapter.dart';
import '../domain/mastery.dart';
import '../domain/question.dart';
import '../engine/adaptive_engine.dart';
import '../engine/answer_checker.dart';

/// Enregistre une réponse et renvoie les propositions du moteur.
typedef AnswerRecorder =
    Future<List<AdaptiveSuggestion>> Function(Question question, bool correct);

/// Une séance d'entraînement : difficulté choisie, question en cours,
/// dernière correction, indices vus. Partagée avec le Compagnon.
class PracticeSession extends ChangeNotifier {
  PracticeSession({
    required this.chapter,
    required this.lessonNumber,
    required this.recorder,
    Set<String> answered = const {},
    int difficulty = 1,
    this.questionsOverride,
    this.checker = const AnswerChecker(),
    this.selector = const QuestionSelector(),
  }) : _answered = {...answered},
       _difficulty = difficulty {
    _reload();
  }

  final Chapter chapter;

  /// Leçon ; `0` pour les défis d'intégration.
  final int lessonNumber;
  final AnswerRecorder recorder;

  /// Questions imposées (défis d'intégration) au lieu de la sélection.
  final List<Question>? questionsOverride;
  final AnswerChecker checker;
  final QuestionSelector selector;

  final Set<String> _answered;
  int _difficulty;
  List<Question> _questions = const [];
  int _index = 0;
  GradeResult? _grade;
  int _hintsShown = 0;
  bool _busy = false;
  List<AdaptiveSuggestion> _suggestions = const [];
  int _session = 0;

  int get difficulty => _difficulty;
  List<Question> get questions => _questions;
  Question? get current =>
      _index < _questions.length ? _questions[_index] : null;
  int get index => _index;
  GradeResult? get lastGrade => _grade;
  bool get answered => _grade != null;
  int get hintsShown => _hintsShown;
  bool get busy => _busy;
  Set<String> get answeredIds => _answered;
  List<AdaptiveSuggestion> get suggestions => _suggestions;

  /// Change chaque fois que la question change (pour remettre la saisie à zéro).
  int get attemptKey => _session * 1000 + _index;

  void _reload() {
    _questions =
        questionsOverride ??
        selector.forLesson(
          chapter,
          lessonNumber: lessonNumber,
          difficulty: _difficulty,
          answered: _answered,
        );
    _index = 0;
    _grade = null;
    _hintsShown = 0;
    _session++;
  }

  /// Changer de difficulté ne dépend jamais du niveau d'explication.
  void chooseDifficulty(int value) {
    if (value == _difficulty) return;
    _difficulty = value;
    _suggestions = const [];
    _reload();
    notifyListeners();
  }

  Future<GradeResult?> submit(StudentResponse response) async {
    final question = current;
    if (question == null || _busy || answered) return null;
    _busy = true;
    notifyListeners();
    final grade = checker.grade(question, response);
    _grade = grade;
    if (grade.correct) _answered.add(question.id);
    try {
      _suggestions = await recorder(question, grade.correct);
    } finally {
      _busy = false;
      notifyListeners();
    }
    return grade;
  }

  /// Réessayer la même question après une erreur.
  void retry() {
    _grade = null;
    _session++;
    notifyListeners();
  }

  void next() {
    if (_index < _questions.length) _index++;
    _grade = null;
    _hintsShown = 0;
    notifyListeners();
  }

  void hintShown() {
    _hintsShown++;
    notifyListeners();
  }

  void dismissSuggestion(AdaptiveSuggestion suggestion) {
    _suggestions = [
      for (final item in _suggestions)
        if (!identical(item, suggestion)) item,
    ];
    notifyListeners();
  }

  /// Aller à une question précise (proposée par « Teste-moi »).
  void focus(Question question) {
    if (question.difficulty != _difficulty && questionsOverride == null) {
      _difficulty = question.difficulty;
      _reload();
    }
    final position = _questions.indexWhere((q) => q.id == question.id);
    if (position >= 0) {
      _index = position;
      _grade = null;
      _hintsShown = 0;
      _session++;
    }
    notifyListeners();
  }
}
