import 'dart:math';

import '../domain/matching_game.dart';

/// One finite board, all relations must be reconstructed. No timer, points,
/// network or language model. Input events are ignored for locked pairs.
class MatchingGameEngine {
  MatchingGameEngine(this.round, {int seed = 0}) {
    left = List.unmodifiable([...round.pairs]..shuffle(Random(seed)));
    right = List.unmodifiable([...round.pairs]..shuffle(Random(seed ^ 0x237)));
  }
  final MatchingRound round;
  late final List<MatchingPair> left;
  late final List<MatchingPair> right;
  final Set<String> _matched = {};
  final Set<String> _failed = {};
  int attempts = 0;
  int errors = 0;
  bool helped = false;
  String? selected;
  Set<String> get matched => Set.unmodifiable(_matched);
  int get firstPass => _matched.difference(_failed).length;
  bool get complete => _matched.length == round.pairs.length;
  bool get independentSuccess => complete && errors == 0 && !helped;

  void select(String id) {
    if (!complete &&
        !_matched.contains(id) &&
        round.pairs.any((p) => p.id == id)) {
      selected = id;
    }
  }

  /// null means the event was not a valid attempt; true/false is a verdict.
  bool? link(String id) {
    final chosen = selected;
    if (complete ||
        chosen == null ||
        _matched.contains(id) ||
        !round.pairs.any((p) => p.id == id)) {
      return null;
    }
    attempts++;
    final correct = chosen == id;
    if (correct) {
      _matched.add(chosen);
      selected = null;
    } else {
      errors++;
      _failed.add(chosen);
    }
    return correct;
  }

  void revealHint() {
    if (!complete) helped = true;
  }
}
