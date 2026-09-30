import 'package:flutter/foundation.dart';

/// Source-authored one-to-one relations. Labels are never answer identifiers.
@immutable
class MatchingPair {
  const MatchingPair({
    required this.id,
    required this.left,
    required this.right,
    required this.explanation,
    required this.sourceAnchor,
  });
  final String id;
  final String left;
  final String right;
  final String explanation;
  final String sourceAnchor;
}

@immutable
class MatchingRound {
  const MatchingRound({
    required this.id,
    required this.difficulty,
    required this.conceptId,
    required this.prompt,
    required this.pairs,
    this.hint,
  });
  final String id;
  final int difficulty;
  final String conceptId;
  final String prompt;
  final List<MatchingPair> pairs;
  final String? hint;
}
