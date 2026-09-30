import 'package:flutter/foundation.dart';

import 'companion_reply_action.dart';

/// Ce que le compagnon attend après sa dernière réponse.
enum CompanionAwaiting {
  nothing,

  /// Il a demandé une matière pour apprendre.
  subjectToStudy,

  /// Il a demandé une matière pour un quiz.
  subjectToQuiz,

  /// Il a demandé la matière qui bloque.
  subjectToUnblock,
}

/// Petite mémoire de conversation, locale et déterministe : juste de quoi
/// comprendre « Anglais » après « Quelle matière ? » et ne pas répéter la
/// même phrase deux fois de suite.
@immutable
class CompanionConversationState {
  const CompanionConversationState({
    this.turn = 0,
    this.lastIntent,
    this.lastSubjectKey,
    this.lastSubjectTurn = -10,
    this.awaiting = CompanionAwaiting.nothing,
    this.pendingActions = const [],
    this.recentVariants = const {},
  });

  static const initial = CompanionConversationState();

  /// Messages de l'élève déjà traités.
  final int turn;
  final String? lastIntent;

  /// Dernière matière évoquée, et à quel tour.
  final String? lastSubjectKey;
  final int lastSubjectTurn;
  final CompanionAwaiting awaiting;

  /// Actions proposées au dernier tour : un « oui » les reprend.
  final List<CompanionReplyAction> pendingActions;

  /// Dernières variantes utilisées, par clé de réponse.
  final Map<String, List<int>> recentVariants;

  /// Matière évoquée récemment (deux tours au plus).
  String? get recentSubjectKey =>
      turn - lastSubjectTurn <= 2 ? lastSubjectKey : null;

  CompanionConversationState next({
    required String intent,
    String? subjectKey,
    CompanionAwaiting awaiting = CompanionAwaiting.nothing,
    List<CompanionReplyAction> pendingActions = const [],
    Map<String, List<int>>? recentVariants,
  }) => CompanionConversationState(
    turn: turn + 1,
    lastIntent: intent,
    lastSubjectKey: subjectKey ?? lastSubjectKey,
    lastSubjectTurn: subjectKey != null ? turn + 1 : lastSubjectTurn,
    awaiting: awaiting,
    pendingActions: pendingActions,
    recentVariants: recentVariants ?? this.recentVariants,
  );
}
