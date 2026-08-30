/// Classes disponibles sur INTELLIA237, alignees sur la Web App.
enum SchoolClass {
  sixieme,
  cinquieme,
  quatrieme,
  troisieme,
  seconde,
  premiere,
  terminale,
  form1,
  form2,
  form3,
  form4,
  form5,
  lowerSixth,
  upperSixth,
}

enum InterfaceLanguage { french, english }

enum EducationalSubsystem { francophone, anglophone }

enum EducationType { general, technical }

enum LearnerAccountLinkage { individual, parentManaged, establishmentManaged }

enum EstablishmentAffiliationStatus {
  none,
  selectedUnverified,
  pendingVerification,
  verified,
  rejected,
}

class EstablishmentAffiliation {
  const EstablishmentAffiliation({
    required this.name,
    this.candidateId,
    this.status = EstablishmentAffiliationStatus.selectedUnverified,
  });

  final String name;
  final String? candidateId;
  final EstablishmentAffiliationStatus status;

  /// A user selection is descriptive only. Only a server-verified link may
  /// authorise private establishment data.
  bool get grantsPrivateAccess =>
      status == EstablishmentAffiliationStatus.verified;
}

/// Series disponibles a partir de la Seconde.
enum SchoolSeries { a, c, d }

extension SchoolClassX on SchoolClass {
  static const ordered = <SchoolClass>[
    SchoolClass.sixieme,
    SchoolClass.cinquieme,
    SchoolClass.quatrieme,
    SchoolClass.troisieme,
    SchoolClass.seconde,
    SchoolClass.premiere,
    SchoolClass.terminale,
  ];

  static const orderedAnglophone = <SchoolClass>[
    SchoolClass.form1,
    SchoolClass.form2,
    SchoolClass.form3,
    SchoolClass.form4,
    SchoolClass.form5,
    SchoolClass.lowerSixth,
    SchoolClass.upperSixth,
  ];

  static List<SchoolClass> forSubsystem(EducationalSubsystem subsystem) =>
      subsystem == EducationalSubsystem.francophone
      ? ordered
      : orderedAnglophone;

  EducationalSubsystem get subsystem => switch (this) {
    SchoolClass.sixieme ||
    SchoolClass.cinquieme ||
    SchoolClass.quatrieme ||
    SchoolClass.troisieme ||
    SchoolClass.seconde ||
    SchoolClass.premiere ||
    SchoolClass.terminale => EducationalSubsystem.francophone,
    SchoolClass.form1 ||
    SchoolClass.form2 ||
    SchoolClass.form3 ||
    SchoolClass.form4 ||
    SchoolClass.form5 ||
    SchoolClass.lowerSixth ||
    SchoolClass.upperSixth => EducationalSubsystem.anglophone,
  };

  String get label => switch (this) {
    SchoolClass.sixieme => '6ème',
    SchoolClass.cinquieme => '5ème',
    SchoolClass.quatrieme => '4ème',
    SchoolClass.troisieme => '3ème',
    SchoolClass.seconde => '2nde',
    SchoolClass.premiere => '1ère',
    SchoolClass.terminale => 'Terminale',
    SchoolClass.form1 => 'Form 1',
    SchoolClass.form2 => 'Form 2',
    SchoolClass.form3 => 'Form 3',
    SchoolClass.form4 => 'Form 4',
    SchoolClass.form5 => 'Form 5',
    SchoolClass.lowerSixth => 'Lower Sixth',
    SchoolClass.upperSixth => 'Upper Sixth',
  };

  List<SchoolSeries> get allowedSeries => switch (this) {
    SchoolClass.sixieme ||
    SchoolClass.cinquieme ||
    SchoolClass.quatrieme ||
    SchoolClass.troisieme => const <SchoolSeries>[],
    SchoolClass.seconde => [SchoolSeries.a, SchoolSeries.c],
    SchoolClass.premiere => [SchoolSeries.a, SchoolSeries.c, SchoolSeries.d],
    SchoolClass.terminale => [SchoolSeries.a, SchoolSeries.c, SchoolSeries.d],
    SchoolClass.form1 ||
    SchoolClass.form2 ||
    SchoolClass.form3 ||
    SchoolClass.form4 ||
    SchoolClass.form5 ||
    SchoolClass.lowerSixth ||
    SchoolClass.upperSixth => const <SchoolSeries>[],
  };

  bool get requiresSeries => allowedSeries.isNotEmpty;

  /// Libelle du champ serie selon la classe.
  String get seriesFieldLabel => switch (this) {
    SchoolClass.sixieme ||
    SchoolClass.cinquieme ||
    SchoolClass.quatrieme ||
    SchoolClass.troisieme => 'Série',
    SchoolClass.seconde => 'Série',
    SchoolClass.premiere => 'Série',
    SchoolClass.terminale => 'Série',
    SchoolClass.form1 ||
    SchoolClass.form2 ||
    SchoolClass.form3 ||
    SchoolClass.form4 ||
    SchoolClass.form5 ||
    SchoolClass.lowerSixth ||
    SchoolClass.upperSixth => 'Stream',
  };

  /// Identifiant de niveau pour filtrer les tuteurs IA.
  String get tutorLevel => switch (this) {
    SchoolClass.sixieme ||
    SchoolClass.cinquieme ||
    SchoolClass.quatrieme ||
    SchoolClass.troisieme => 'bepc',
    SchoolClass.seconde || SchoolClass.premiere => 'proba',
    SchoolClass.terminale => 'bac',
    SchoolClass.form1 || SchoolClass.form2 || SchoolClass.form3 => 'gce-ol',
    SchoolClass.form4 || SchoolClass.form5 => 'gce-ol',
    SchoolClass.lowerSixth => 'gce-al',
    SchoolClass.upperSixth => 'gce-al',
  };

  /// Retourne le tutorLevel a partir d'un classLevel stocke.
  static String? tutorLevelFromClassLabel(String? classLabel) =>
      switch (classLabel) {
        '6ème' => 'bepc',
        '5ème' => 'bepc',
        '4ème' => 'bepc',
        '3ème' => 'bepc',
        '2nde' => 'proba',
        '1ère' => 'proba',
        '1ere' => 'proba',
        'Première' => 'proba',
        'Terminale' => 'bac',
        'Tle' => 'bac',
        'Form 1' || 'Form 2' || 'Form 3' || 'Form 4' || 'Form 5' => 'gce-ol',
        'Lower Sixth' || 'Upper Sixth' => 'gce-al',
        _ => null,
      };
}

extension InterfaceLanguageX on InterfaceLanguage {
  String get code => this == InterfaceLanguage.french ? 'fr' : 'en';
}

extension EducationalSubsystemX on EducationalSubsystem {
  String get storageValue => name;
}

extension SchoolSeriesX on SchoolSeries {
  String get label => switch (this) {
    SchoolSeries.a => 'A',
    SchoolSeries.c => 'C',
    SchoolSeries.d => 'D',
  };
}
