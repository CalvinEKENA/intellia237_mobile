import 'dart:math';

import 'interactive_block.dart';

/// Résultat d'une vérification.
class OrderingCheck {
  const OrderingCheck({required this.correct, this.firstWrongPosition});

  final bool correct;

  /// Première position fausse, comptée à partir de 1.
  final int? firstWrongPosition;
}

/// État d'une activité d'ordre, entièrement local : manipuler, vérifier,
/// recommencer et demander un indice ne demandent aucun réseau.
///
/// Correction par identifiants : chaque carte a un identifiant opaque. Deux
/// cartes au texte identique (« I » dans « I think I can ») sont déclarées
/// interchangeables, explicitement ; hors de ce cas, c'est l'identifiant qui
/// fait foi, jamais le texte seul.
class OrderingSession {
  OrderingSession(this.block, {Random? random, DateTime Function()? clock})
    : _random = random ?? Random(),
      _clock = clock ?? DateTime.now {
    _startedAt = _clock();
    _start();
  }

  final OrderingBlock block;
  final Random _random;
  final DateTime Function() _clock;
  late DateTime _startedAt;

  /// Essais avant de proposer la solution.
  static const attemptsBeforeSolution = 3;

  /// Cartes encore à placer (disposition en ligne).
  final List<String> bank = [];

  /// Réponse en cours : en ligne, les cartes placées ; empilée, l'ordre
  /// complet des étapes.
  final List<String> answer = [];

  int attempts = 0;
  int hintsShown = 0;
  bool completed = false;
  bool correct = false;
  bool solutionRevealed = false;
  OrderingCheck? lastCheck;
  Duration? duration;

  bool get isInline => block.layout == OrderingLayout.inline;

  bool get readyToCheck => !completed && (isInline ? bank.isEmpty : true);

  bool get canRevealSolution =>
      !completed && attempts >= attemptsBeforeSolution;

  void _start() {
    bank.clear();
    answer.clear();
    final start = shuffledNotSolved(block, _random);
    if (isInline) {
      bank.addAll(start);
    } else {
      answer.addAll(start);
    }
    lastCheck = null;
  }

  /// Recommencer : nouvel ordre mélangé, mêmes compteurs d'essais et
  /// d'indices (ils décrivent l'effort réel).
  void reset() {
    if (completed) return;
    _start();
  }

  /// En ligne : placer une carte à la fin de la réponse, ou à [index].
  void place(String id, {int? index}) {
    if (completed || !isInline) return;
    if (!bank.remove(id)) {
      answer.remove(id);
    }
    final at = index == null ? answer.length : index.clamp(0, answer.length);
    answer.insert(at, id);
    lastCheck = null;
  }

  /// En ligne : rendre une carte à la réserve.
  void remove(String id) {
    if (completed || !isInline) return;
    if (answer.remove(id)) {
      bank.add(id);
      lastCheck = null;
    }
  }

  /// Empilée : déplacer une étape.
  void move(int from, int to) {
    if (completed || isInline) return;
    if (from < 0 || from >= answer.length) return;
    final target = to.clamp(0, answer.length - 1);
    final id = answer.removeAt(from);
    answer.insert(target, id);
    lastCheck = null;
  }

  bool _equivalent(String a, String b) =>
      a == b || block.itemById(a).text == block.itemById(b).text;

  OrderingCheck check() {
    if (!readyToCheck) {
      return lastCheck ?? const OrderingCheck(correct: false);
    }
    attempts++;
    int? wrong;
    for (var i = 0; i < block.solution.length; i++) {
      if (i >= answer.length || !_equivalent(answer[i], block.solution[i])) {
        wrong = i + 1;
        break;
      }
    }
    final result = OrderingCheck(
      correct: wrong == null,
      firstWrongPosition: wrong,
    );
    lastCheck = result;
    if (result.correct) {
      correct = true;
      completed = true;
      duration = _clock().difference(_startedAt);
    }
    return result;
  }

  /// Indice suivant : ceux du compagnon d'abord, puis la position à revoir.
  /// `null` quand il n'y a plus rien à dire sans donner la réponse.
  OrderingHint? nextHint() {
    if (completed) return null;
    if (hintsShown < block.hints.length) {
      return OrderingHint.text(block.hints[hintsShown++]);
    }
    final position = lastCheck?.firstWrongPosition;
    if (position != null && hintsShown < InteractiveBlockLimits.hints + 1) {
      hintsShown++;
      return OrderingHint.position(position);
    }
    return null;
  }

  /// Montre la solution après plusieurs essais : l'activité est close sans
  /// être comptée comme réussie.
  void revealSolution() {
    if (completed) return;
    bank.clear();
    answer
      ..clear()
      ..addAll(block.solution);
    solutionRevealed = true;
    completed = true;
    duration = _clock().difference(_startedAt);
  }

  ActivityOutcome toOutcome() => ActivityOutcome(
    blockId: block.id,
    type: block.type,
    correct: correct,
    attempts: attempts,
    hintsUsed: hintsShown.clamp(0, InteractiveBlockLimits.hints),
    solutionRevealed: solutionRevealed,
    duration: duration,
  );
}

/// Indice : un texte du compagnon, ou la position à revoir.
class OrderingHint {
  const OrderingHint.text(String this.text) : position = null;
  const OrderingHint.position(int this.position) : text = null;

  final String? text;
  final int? position;
}

/// Ordre de départ mélangé qui ne présente jamais la solution toute faite
/// (sauf s'il n'existe aucun autre ordre distinct). Source aléatoire
/// injectable pour les tests.
List<String> shuffledNotSolved(OrderingBlock block, Random random) {
  final solutionTexts = [
    for (final id in block.solution) block.itemById(id).text,
  ];
  bool solved(List<String> ids) {
    for (var i = 0; i < ids.length; i++) {
      if (block.itemById(ids[i]).text != solutionTexts[i]) return false;
    }
    return true;
  }

  final ids = [...block.solution];
  for (var attempt = 0; attempt < 24; attempt++) {
    ids.shuffle(random);
    if (!solved(ids)) return ids;
  }
  // Repli déterministe : une rotation d'un cran diffère toujours de la
  // solution dès que deux textes diffèrent.
  final rotated = [...block.solution.skip(1), block.solution.first];
  return rotated;
}
