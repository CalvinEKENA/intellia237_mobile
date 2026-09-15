import '../../family_access/domain/family_access_models.dart';

class ParentChildProfile {
  const ParentChildProfile({
    required this.id,
    required this.firstName,
    required this.classLevel,
    required this.series,
    required this.globalProgress,
    required this.studyMinutesToday,
    required this.studyMinutesTarget,
    required this.strongSubjects,
    required this.weakSubjects,
    required this.weeklyProgress,
    this.hasProgressData = false,
    this.hasStudyTimeData = false,
    this.exploredLessonCount,
    this.coverageIsPartial = false,
    this.lastName,
    this.establishmentId,
    this.establishmentName,
    this.access,
    this.subscription,
    this.offerAvailable = false,
    this.pendingFirstSignIn = false,
  });

  /// Enfant dont le parent a ouvert l'accès : il n'a pas encore de profil.
  factory ParentChildProfile.pending(ParentChildSummary summary) =>
      ParentChildProfile(
        id: summary.studentId,
        firstName: summary.firstName,
        classLevel: summary.classLevel,
        series: summary.series,
        globalProgress: 0,
        studyMinutesToday: 0,
        studyMinutesTarget: 0,
        strongSubjects: const [],
        weakSubjects: const [],
        weeklyProgress: const [],
        access: summary.access,
        subscription: summary.subscription,
        pendingFirstSignIn: true,
      );

  final String id;
  final String firstName;
  final String classLevel;
  final String? series;
  final double globalProgress;
  final int studyMinutesToday;
  final int studyMinutesTarget;
  final List<String> strongSubjects;
  final List<String> weakSubjects;
  final List<double> weeklyProgress;
  final bool hasProgressData;
  final bool hasStudyTimeData;

  /// Coverage only. Null means that this optional source is unavailable.
  final int? exploredLessonCount;
  final bool coverageIsPartial;

  final String? lastName;

  /// École de CET enfant. Un parent n'a pas d'école : chaque enfant a la
  /// sienne, et deux enfants peuvent être dans deux écoles différentes.
  final String? establishmentId;
  final String? establishmentName;

  /// Comment l'enfant se connecte, résolu par le serveur. Null : inconnu
  /// (service indisponible), jamais « aucun accès ».
  final ChildAccessMethods? access;

  /// Abonnement qui couvre cet enfant. Null : inconnu.
  final ChildSubscription? subscription;

  /// Une offre Mobile Money existe pour l'école de cet enfant.
  final bool offerAvailable;

  /// Accès ouvert par le parent, profil scolaire pas encore rempli.
  final bool pendingFirstSignIn;

  String get classLabel {
    if (series == null || series!.isEmpty) {
      return classLevel;
    }
    return '$classLevel - Série $series';
  }

  String get fullName => [
    firstName,
    lastName ?? '',
  ].where((part) => part.trim().isNotEmpty).join(' ');

  /// Enrichit ce profil avec la projection serveur de l'enfant.
  ParentChildProfile withSummary(ParentChildSummary summary) =>
      ParentChildProfile(
        id: id,
        firstName: firstName,
        classLevel: classLevel,
        series: series,
        globalProgress: globalProgress,
        studyMinutesToday: studyMinutesToday,
        studyMinutesTarget: studyMinutesTarget,
        strongSubjects: strongSubjects,
        weakSubjects: weakSubjects,
        weeklyProgress: weeklyProgress,
        hasProgressData: hasProgressData,
        hasStudyTimeData: hasStudyTimeData,
        exploredLessonCount: exploredLessonCount,
        coverageIsPartial: coverageIsPartial,
        lastName: summary.lastName.isEmpty ? lastName : summary.lastName,
        establishmentId: summary.establishmentId.isEmpty
            ? establishmentId
            : summary.establishmentId,
        establishmentName: summary.establishmentName.isEmpty
            ? establishmentName
            : summary.establishmentName,
        access: summary.access,
        subscription: summary.subscription,
        offerAvailable: summary.offerAvailable,
        pendingFirstSignIn: summary.pendingFirstSignIn,
      );
}
