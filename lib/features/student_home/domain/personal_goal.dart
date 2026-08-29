/// Objectif personnel hebdomadaire de l'élève.
///
/// Décision produit (registre) : l'objectif est choisi par l'élève (motivation
/// auto-déterminée), réaliste (2 à 5 séances), et **jamais culpabilisant** —
/// le compteur repart chaque semaine sans pénalité ni « retard ». Il est
/// stocké localement : aucun schéma serveur requis.
class PersonalGoal {
  const PersonalGoal({
    required this.sessionsPerWeek,
    required this.minutesPerSession,
    this.prioritySubjectId,
    this.prioritySubjectTitle,
  });

  /// Nombre de séances visées par semaine (bornes produit : 2 à 5).
  final int sessionsPerWeek;

  /// Durée moyenne souhaitée d'une séance, en minutes (10 / 20 / 30).
  final int minutesPerSession;

  /// Matière prioritaire (identifiant réel du catalogue), optionnelle.
  final String? prioritySubjectId;

  /// Titre dénormalisé pour l'affichage hors connexion.
  final String? prioritySubjectTitle;

  static const allowedSessions = [2, 3, 5];
  static const allowedMinutes = [10, 20, 30];

  PersonalGoal copyWith({
    int? sessionsPerWeek,
    int? minutesPerSession,
    String? Function()? prioritySubjectId,
    String? Function()? prioritySubjectTitle,
  }) {
    return PersonalGoal(
      sessionsPerWeek: sessionsPerWeek ?? this.sessionsPerWeek,
      minutesPerSession: minutesPerSession ?? this.minutesPerSession,
      prioritySubjectId: prioritySubjectId != null
          ? prioritySubjectId()
          : this.prioritySubjectId,
      prioritySubjectTitle: prioritySubjectTitle != null
          ? prioritySubjectTitle()
          : this.prioritySubjectTitle,
    );
  }

  Map<String, Object?> toJson() => {
    'sessionsPerWeek': sessionsPerWeek,
    'minutesPerSession': minutesPerSession,
    'prioritySubjectId': prioritySubjectId,
    'prioritySubjectTitle': prioritySubjectTitle,
  };

  static PersonalGoal? fromJson(Map<String, dynamic> json) {
    final sessions = (json['sessionsPerWeek'] as num?)?.toInt();
    final minutes = (json['minutesPerSession'] as num?)?.toInt();
    if (sessions == null || minutes == null) return null;
    return PersonalGoal(
      sessionsPerWeek: sessions.clamp(1, 7),
      minutesPerSession: minutes.clamp(5, 120),
      prioritySubjectId: json['prioritySubjectId'] as String?,
      prioritySubjectTitle: json['prioritySubjectTitle'] as String?,
    );
  }
}

/// Progression de la semaine en cours vis-à-vis de l'objectif.
class WeeklyGoalProgress {
  const WeeklyGoalProgress({required this.goal, required this.activeDays});

  final PersonalGoal? goal;

  /// Jours distincts avec au moins une activité pédagogique réelle
  /// (leçon terminée, quiz soumis ou carte Flow validée) cette semaine.
  final int activeDays;

  bool get hasGoal => goal != null;
  bool get achieved => goal != null && activeDays >= goal!.sessionsPerWeek;
}
