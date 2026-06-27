import 'package:flutter/foundation.dart';

/// XP nécessaires pour franchir un niveau (palier régulier, lisible).
const int kXpPerLevel = 500;

/// État de progression du Flow (XP, niveau, série, badges, complétion).
///
/// Immutable. Le [FlowController] en produit de nouvelles instances via
/// [copyWith]. Pas de dépendance à Firebase : état de session côté UX.
@immutable
class FlowProgressState {
  const FlowProgressState({
    this.xp = 0,
    this.streakDays = 0,
    this.seenCardIds = const <String>{},
    this.completedCardIds = const <String>{},
    this.subjectsSeen = const <String>{},
    this.correctQuizCount = 0,
    this.unlockedBadgeIds = const <String>{},
  });

  final int xp;
  final int streakDays;
  final Set<String> seenCardIds;
  final Set<String> completedCardIds;
  final Set<String> subjectsSeen;
  final int correctQuizCount;
  final Set<String> unlockedBadgeIds;

  int get level => xp ~/ kXpPerLevel + 1;
  int get xpIntoLevel => xp % kXpPerLevel;

  /// Avancement [0,1] dans le niveau courant.
  double get levelProgress => xpIntoLevel / kXpPerLevel;

  int get completedCount => completedCardIds.length;

  FlowProgressState copyWith({
    int? xp,
    int? streakDays,
    Set<String>? seenCardIds,
    Set<String>? completedCardIds,
    Set<String>? subjectsSeen,
    int? correctQuizCount,
    Set<String>? unlockedBadgeIds,
  }) {
    return FlowProgressState(
      xp: xp ?? this.xp,
      streakDays: streakDays ?? this.streakDays,
      seenCardIds: seenCardIds ?? this.seenCardIds,
      completedCardIds: completedCardIds ?? this.completedCardIds,
      subjectsSeen: subjectsSeen ?? this.subjectsSeen,
      correctQuizCount: correctQuizCount ?? this.correctQuizCount,
      unlockedBadgeIds: unlockedBadgeIds ?? this.unlockedBadgeIds,
    );
  }
}
