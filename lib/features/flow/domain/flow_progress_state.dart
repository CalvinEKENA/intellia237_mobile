import 'package:flutter/foundation.dart';

/// Points nécessaires pour franchir un niveau (palier régulier, lisible).
const int kPointsPerLevel = 500;

/// État local du Flow et miroir du dernier total validé par le serveur.
///
/// [sessionPoints] ne contient que les points confirmés pendant la session
/// courante. [verifiedTotalPoints] est le total académique canonique renvoyé
/// par Cloud Functions ; il reste nullable tant qu'aucune validation n'a été
/// possible.
@immutable
class FlowProgressState {
  const FlowProgressState({
    this.sessionPoints = 0,
    this.verifiedTotalPoints,
    this.pendingValidationCount = 0,
    this.isSyncing = false,
    this.streakDays = 0,
    this.seenCardIds = const <String>{},
    this.completedCardIds = const <String>{},
    this.subjectsSeen = const <String>{},
    this.correctQuizCount = 0,
    this.unlockedBadgeIds = const <String>{},
    this.verifiedCardIds = const <String>{},
    this.verifiedSubjectIds = const <String>{},
    this.creditedEventIds = const <String>{},
  });

  final int sessionPoints;
  final int? verifiedTotalPoints;
  final int pendingValidationCount;
  final bool isSyncing;
  final int streakDays;
  final Set<String> seenCardIds;
  final Set<String> completedCardIds;
  final Set<String> subjectsSeen;
  final int correctQuizCount;
  final Set<String> unlockedBadgeIds;
  final Set<String> verifiedCardIds;
  final Set<String> verifiedSubjectIds;
  final Set<String> creditedEventIds;

  int get level => (verifiedTotalPoints ?? 0) ~/ kPointsPerLevel + 1;
  int get pointsIntoLevel => (verifiedTotalPoints ?? 0) % kPointsPerLevel;

  /// Avancement [0,1] dans le niveau courant.
  double get levelProgress => pointsIntoLevel / kPointsPerLevel;

  int get completedCount => completedCardIds.length;

  FlowProgressState copyWith({
    int? sessionPoints,
    int? verifiedTotalPoints,
    int? pendingValidationCount,
    bool? isSyncing,
    int? streakDays,
    Set<String>? seenCardIds,
    Set<String>? completedCardIds,
    Set<String>? subjectsSeen,
    int? correctQuizCount,
    Set<String>? unlockedBadgeIds,
    Set<String>? verifiedCardIds,
    Set<String>? verifiedSubjectIds,
    Set<String>? creditedEventIds,
  }) {
    return FlowProgressState(
      sessionPoints: sessionPoints ?? this.sessionPoints,
      verifiedTotalPoints: verifiedTotalPoints ?? this.verifiedTotalPoints,
      pendingValidationCount:
          pendingValidationCount ?? this.pendingValidationCount,
      isSyncing: isSyncing ?? this.isSyncing,
      streakDays: streakDays ?? this.streakDays,
      seenCardIds: seenCardIds ?? this.seenCardIds,
      completedCardIds: completedCardIds ?? this.completedCardIds,
      subjectsSeen: subjectsSeen ?? this.subjectsSeen,
      correctQuizCount: correctQuizCount ?? this.correctQuizCount,
      unlockedBadgeIds: unlockedBadgeIds ?? this.unlockedBadgeIds,
      verifiedCardIds: verifiedCardIds ?? this.verifiedCardIds,
      verifiedSubjectIds: verifiedSubjectIds ?? this.verifiedSubjectIds,
      creditedEventIds: creditedEventIds ?? this.creditedEventIds,
    );
  }
}
