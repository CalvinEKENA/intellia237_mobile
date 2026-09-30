import 'package:flutter/foundation.dart';

import '../../content_engine/domain/mastery.dart';
import '../../content_engine/engine/answer_checker.dart';
import '../domain/pack_quiz.dart';

/// Enregistre une réponse dans la maîtrise de l'élève (la même que celle
/// des leçons) et renvoie les propositions du moteur.
typedef PackQuizRecorder =
    Future<List<AdaptiveSuggestion>> Function(PackQuizItem item, bool correct);

/// Une réponse donnée pendant la séance.
@immutable
class PackQuizAnswer {
  const PackQuizAnswer({
    required this.item,
    required this.response,
    required this.grade,
    required this.hintsUsed,
  });

  final PackQuizItem item;
  final StudentResponse response;
  final GradeResult grade;
  final int hintsUsed;

  bool get correct => grade.correct;

  /// Le pack a écrit un retour pour la proposition choisie.
  bool get hasChoiceFeedback {
    final feedback = item.question.choiceFeedback;
    return switch (response) {
      ChoiceResponse(:final choice) => feedback[choice] != null,
      MultiChoiceResponse(:final choices) => choices.any(
        (choice) => feedback[choice] != null,
      ),
      _ => false,
    };
  }
}

enum PackQuizPhase { intro, question, finished }

/// Une notion de la séance et ce que l'élève y a fait.
@immutable
class PackQuizConceptOutcome {
  const PackQuizConceptOutcome({
    required this.conceptId,
    required this.title,
    required this.correct,
    required this.total,
  });

  final String conceptId;
  final String title;
  final int correct;
  final int total;

  bool get mastered => correct == total;
}

/// Bilan d'une séance : uniquement des questions corrigées par le moteur.
@immutable
class PackQuizResult {
  const PackQuizResult({required this.plan, required this.answers});

  final PackQuizPlan plan;
  final List<PackQuizAnswer> answers;

  int get score => answers.where((answer) => answer.correct).length;
  int get total => plan.length;
  int get percent => total == 0 ? 0 : (score * 100 / total).round();
  bool get perfect => total > 0 && score == total;

  /// Notions vues, dans l'ordre de leur première question.
  List<PackQuizConceptOutcome> get concepts {
    final order = <String>[];
    final titles = <String, String>{};
    final correct = <String, int>{};
    final total = <String, int>{};
    for (final answer in answers) {
      final concept = answer.item.chapter.conceptForQuestion(
        answer.item.question,
      );
      final id = concept?.id ?? 'chapter:${answer.item.chapter.contentId}';
      if (!titles.containsKey(id)) {
        order.add(id);
        titles[id] =
            concept?.title ?? answer.item.chapter.curriculum.chapterTitle;
      }
      total[id] = (total[id] ?? 0) + 1;
      if (answer.correct) correct[id] = (correct[id] ?? 0) + 1;
    }
    return [
      for (final id in order)
        PackQuizConceptOutcome(
          conceptId: id,
          title: titles[id]!,
          correct: correct[id] ?? 0,
          total: total[id]!,
        ),
    ];
  }
}

/// Le déroulé d'une séance de quiz de pack, sans réseau.
///
/// La correction est celle des leçons ([AnswerChecker]) ; chaque réponse est
/// enregistrée par [recorder] dans la même maîtrise ([MasteryState]) que
/// les exercices des leçons : une question réussie ici l'est aussi dans le
/// parcours.
class PackQuizSession extends ChangeNotifier {
  PackQuizSession({
    required this.plan,
    required this.recorder,
    this.checker = const AnswerChecker(),
  });

  final PackQuizPlan plan;
  final PackQuizRecorder recorder;
  final AnswerChecker checker;

  PackQuizPhase _phase = PackQuizPhase.intro;
  int _index = 0;
  final List<PackQuizAnswer> _answers = [];
  PackQuizAnswer? _current;
  int _hintsShown = 0;
  int _streak = 0;
  bool _busy = false;
  bool _disposed = false;

  PackQuizMode get mode => plan.mode;
  PackQuizPhase get phase => _phase;
  int get index => _index;
  int get length => plan.length;
  PackQuizItem? get item =>
      _phase == PackQuizPhase.question && _index < plan.length
      ? plan.items[_index]
      : null;

  /// La réponse à la question en cours, une fois validée (entraînement).
  PackQuizAnswer? get answer => _current;
  int get hintsShown => _hintsShown;
  int get streak => _streak;
  bool get busy => _busy;
  bool get isLast => _index == plan.length - 1;
  List<PackQuizAnswer> get answers => List.unmodifiable(_answers);

  /// Indices du pack encore à montrer (jamais en évaluation).
  bool get canHint =>
      mode == PackQuizMode.training &&
      _current == null &&
      item != null &&
      _hintsShown < item!.question.hints.length;

  /// Change à chaque question : remet la saisie à zéro.
  String get attemptKey => '${plan.set.id}|${plan.attempt}|$_index';

  PackQuizResult get result => PackQuizResult(plan: plan, answers: _answers);

  void start() {
    if (_phase != PackQuizPhase.intro) return;
    _phase = plan.length == 0 ? PackQuizPhase.finished : PackQuizPhase.question;
    _notify();
  }

  void showHint() {
    if (!canHint) return;
    _hintsShown++;
    _notify();
  }

  /// Corrige et enregistre la réponse. En évaluation, passe aussitôt à la
  /// question suivante sans rien révéler.
  Future<PackQuizAnswer?> submit(StudentResponse response) async {
    final current = item;
    if (current == null || _busy || _current != null) return null;
    _busy = true;
    _notify();
    final grade = checker.grade(current.question, response);
    final answer = PackQuizAnswer(
      item: current,
      response: response,
      grade: grade,
      hintsUsed: _hintsShown,
    );
    _answers.add(answer);
    _streak = grade.correct ? _streak + 1 : 0;
    try {
      await recorder(current, grade.correct);
    } finally {
      _busy = false;
      if (mode == PackQuizMode.training) {
        _current = answer;
        _notify();
      } else {
        _advance();
      }
    }
    return answer;
  }

  /// Question suivante (entraînement, après la correction).
  void next() {
    if (_current == null) return;
    _advance();
  }

  void _advance() {
    _current = null;
    _hintsShown = 0;
    if (_index + 1 >= plan.length) {
      _phase = PackQuizPhase.finished;
    } else {
      _index++;
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Une séance terminée, pour l'historique du Hub Quiz (source : pack).
@immutable
class PackQuizHistoryEntry {
  const PackQuizHistoryEntry({
    required this.setId,
    required this.subjectKey,
    required this.title,
    required this.mode,
    required this.score,
    required this.total,
    required this.completedAt,
  });

  /// Toujours `pack` : ces séances ne se mélangent pas aux quiz publiés.
  static const source = 'pack';

  final String setId;
  final String subjectKey;
  final String title;
  final PackQuizMode mode;
  final int score;
  final int total;
  final DateTime completedAt;

  Map<String, Object> toJson() => {
    'source': source,
    'setId': setId,
    'subjectKey': subjectKey,
    'title': title,
    'mode': mode.name,
    'score': score,
    'total': total,
    'completedAt': completedAt.toUtc().toIso8601String(),
  };

  static PackQuizHistoryEntry? fromJson(Object? raw) {
    if (raw is! Map || raw['source'] != source) return null;
    final completedAt = DateTime.tryParse('${raw['completedAt']}');
    final score = raw['score'];
    final total = raw['total'];
    if (completedAt == null || score is! int || total is! int) return null;
    return PackQuizHistoryEntry(
      setId: '${raw['setId']}',
      subjectKey: '${raw['subjectKey']}',
      title: '${raw['title']}',
      mode: PackQuizMode.fromName('${raw['mode']}'),
      score: score,
      total: total,
      completedAt: completedAt,
    );
  }
}
