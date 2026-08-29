/// Destination réelle d'une carte de l'accueil.
///
/// Registre de décisions : une carte sans destination réelle ne doit pas être
/// affichée — chaque item éditorial porte donc sa cible explicitement.
enum HomeDestination { learnTab, quizTab, companionTab, flow }

class SubjectOverview {
  const SubjectOverview({
    required this.id,
    required this.title,
    required this.progress,
    required this.colorHex,
    this.iconKey = 'book',
  });

  final String id;
  final String title;
  final double progress;
  final int colorHex;
  final String iconKey;
}

class RecommendationItem {
  const RecommendationItem({
    required this.title,
    required this.subtitle,
    required this.estimatedMinutes,
    this.destination = HomeDestination.learnTab,
  });

  final String title;
  final String subtitle;
  final int estimatedMinutes;
  final HomeDestination destination;
}

class DailyChallengeItem {
  const DailyChallengeItem({
    required this.title,
    required this.rewardPoints,
    required this.completed,
    this.destination = HomeDestination.quizTab,
  });

  final String title;
  final int rewardPoints;
  final bool completed;
  final HomeDestination destination;
}

/// Dernière leçon réellement consultée : identifiants exacts pour un
/// deep link fiable (« Reprendre » ouvre cette leçon, pas un onglet).
class ResumeTarget {
  const ResumeTarget({
    required this.subjectId,
    required this.chapterId,
    required this.lessonId,
    required this.lessonTitle,
    required this.progress,
    this.subjectTitle,
  });

  final String subjectId;
  final String chapterId;
  final String lessonId;
  final String lessonTitle;
  final double progress;
  final String? subjectTitle;
}

/// Statistiques de progression (points, niveau, série) — présentes uniquement quand une
/// source réelle les fournit (agrégats serveur) ou en mode démo explicite.
/// Jamais de valeurs inventées présentées comme réelles.
class StudentGamification {
  const StudentGamification({
    required this.currentPoints,
    required this.level,
    this.streakDays,
    this.motivationText,
  });

  final int currentPoints;
  final int level;
  final int? streakDays;
  final String? motivationText;
}

class StudentHomeSnapshot {
  const StudentHomeSnapshot({
    required this.firstName,
    this.resume,
    this.subjects = const [],
    this.globalProgress,
    this.gamification,
    this.recommendations = const [],
    this.challenges = const [],
    this.isDemoData = false,
  });

  final String firstName;

  /// Reprise réelle, ou null si aucune leçon n'a encore été ouverte.
  final ResumeTarget? resume;

  /// Matières réelles du niveau de l'élève (mêmes identifiants que l'onglet
  /// Apprendre — jamais d'identifiants fictifs pointant vers le vide).
  final List<SubjectOverview> subjects;

  /// Moyenne réelle des complétions par matière (null si aucune matière).
  final double? globalProgress;

  /// Null tant qu'aucune source réelle ne fournit points/niveau/série.
  final StudentGamification? gamification;

  final List<RecommendationItem> recommendations;
  final List<DailyChallengeItem> challenges;

  /// Vrai uniquement pour le repository de démonstration (staging/outillage).
  final bool isDemoData;
}
