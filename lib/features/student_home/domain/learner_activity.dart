import 'student_home_snapshot.dart';

/// Où en est l'élève dans son parcours, d'après ses **traces réelles**.
///
/// Registre de décisions : un compagnon ne félicite jamais pour un travail
/// qui n'a pas eu lieu. Le statut ne se déduit donc pas d'un booléen
/// « onboarding terminé », ni de la simple existence d'un catalogue de
/// matières, mais uniquement de preuves d'apprentissage observables.
enum LearnerActivityStatus {
  /// Aucune trace d'apprentissage : ni leçon ouverte, ni progression, ni
  /// carte Flow validée, ni point gagné. L'accueil doit accueillir, pas
  /// prétendre reprendre.
  firstSession,

  /// Au moins une trace réelle existe : la reprise et la régularité
  /// deviennent des affirmations vérifiables.
  returning,
}

/// Faisceau de signaux d'apprentissage réellement observés pour un élève.
///
/// Chaque champ correspond à une trace produite par une action de l'élève.
/// La moyenne de complétion d'un catalogue vide, elle, n'en est pas une :
/// `globalProgress` vaut 0 dès qu'une matière existe, même intacte.
class LearnerActivity {
  const LearnerActivity({
    this.hasResumePoint = false,
    this.lessonProgress = 0,
    this.earnedPoints = 0,
    this.streakDays = 0,
    this.completedFlowCards = 0,
    this.quizAttempts = 0,
    this.lastActivityAt,
  });

  /// Une leçon a réellement été ouverte (signet de reprise présent).
  final bool hasResumePoint;

  /// Moyenne de complétion des matières, entre 0 et 1. Seule une valeur
  /// strictement positive prouve un travail effectué.
  final double lessonProgress;

  /// Points d'agrégat serveur réellement gagnés.
  final int earnedPoints;

  /// Série de jours consécutifs reconnue par le serveur.
  final int streakDays;

  /// Cartes Flow validées par le serveur.
  final int completedFlowCards;

  /// Tentatives de quiz enregistrées.
  final int quizAttempts;

  /// Dernière activité d'apprentissage datée, quand une source fiable existe.
  final DateTime? lastActivityAt;

  /// Vrai dès qu'une seule trace d'apprentissage existe.
  bool get hasLearningEvidence =>
      hasResumePoint ||
      lessonProgress > 0 ||
      earnedPoints > 0 ||
      streakDays > 0 ||
      completedFlowCards > 0 ||
      quizAttempts > 0;

  LearnerActivityStatus get status => hasLearningEvidence
      ? LearnerActivityStatus.returning
      : LearnerActivityStatus.firstSession;

  bool get isFirstSession => status == LearnerActivityStatus.firstSession;

  /// Lit les signaux portés par l'instantané d'accueil.
  ///
  /// [completedFlowCards] et [quizAttempts] viennent de sources distinctes et
  /// restent optionnels : leur absence ne peut jamais créer une fausse
  /// reprise, seulement manquer une reprise réelle, ce qui est le sens
  /// prudent de l'erreur.
  factory LearnerActivity.fromSnapshot(
    StudentHomeSnapshot snapshot, {
    int completedFlowCards = 0,
    int quizAttempts = 0,
  }) {
    final gamification = snapshot.gamification;
    return LearnerActivity(
      hasResumePoint: snapshot.resume != null,
      lessonProgress: snapshot.globalProgress ?? 0,
      earnedPoints: gamification?.currentPoints ?? 0,
      streakDays: gamification?.streakDays ?? 0,
      completedFlowCards: completedFlowCards,
      quizAttempts: quizAttempts,
      lastActivityAt: snapshot.resume?.updatedAt,
    );
  }
}
