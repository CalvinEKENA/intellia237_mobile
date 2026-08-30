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

  /// Stable catalog key used by the existing Firestore course and quiz pool.
  ///
  /// These values deliberately preserve the historical production schema.
  /// UI labels such as `6ème` and `1ère` must never be used as document IDs or
  /// authoritative backend filters.
  String get catalogKey => switch (this) {
    SchoolClass.sixieme => '6eme',
    SchoolClass.cinquieme => '5eme',
    SchoolClass.quatrieme => '4eme',
    SchoolClass.troisieme => '3eme',
    SchoolClass.seconde => 'Seconde',
    SchoolClass.premiere => 'Premiere',
    SchoolClass.terminale => 'Terminale',
    SchoolClass.form1 => 'Form1',
    SchoolClass.form2 => 'Form2',
    SchoolClass.form3 => 'Form3',
    SchoolClass.form4 => 'Form4',
    SchoolClass.form5 => 'Form5',
    SchoolClass.lowerSixth => 'LowerSixth',
    SchoolClass.upperSixth => 'UpperSixth',
  };

  String get _stableLevelSlug => switch (this) {
    SchoolClass.sixieme => '6e',
    SchoolClass.cinquieme => '5e',
    SchoolClass.quatrieme => '4e',
    SchoolClass.troisieme => '3e',
    SchoolClass.seconde => '2nde',
    SchoolClass.premiere => '1ere',
    SchoolClass.terminale => 'terminale',
    SchoolClass.form1 => 'form1',
    SchoolClass.form2 => 'form2',
    SchoolClass.form3 => 'form3',
    SchoolClass.form4 => 'form4',
    SchoolClass.form5 => 'form5',
    SchoolClass.lowerSixth => 'lower_sixth',
    SchoolClass.upperSixth => 'upper_sixth',
  };

  /// Canonical identifier: subsystem and education type remain independent
  /// dimensions instead of being inferred from a translated label.
  String academicLevelId(EducationType educationType) {
    final subsystemId = subsystem == EducationalSubsystem.francophone
        ? 'fr'
        : 'en';
    return '${subsystemId}_${educationType.name}_$_stableLevelSlug';
  }

  /// Explicit compatibility mapper for historical profile and catalog values.
  static SchoolClass? fromStoredValue(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return null;
    final normalized = _normalizeAcademicValue(raw);

    for (final schoolClass in SchoolClass.values) {
      if (normalized == _normalizeAcademicValue(schoolClass.label) ||
          normalized == _normalizeAcademicValue(schoolClass.catalogKey) ||
          normalized.endsWith(
            _normalizeAcademicValue(schoolClass._stableLevelSlug),
          )) {
        return schoolClass;
      }
    }

    return switch (normalized) {
      'sixieme' => SchoolClass.sixieme,
      'cinquieme' => SchoolClass.cinquieme,
      'quatrieme' => SchoolClass.quatrieme,
      'troisieme' => SchoolClass.troisieme,
      'premiere' => SchoolClass.premiere,
      'tle' => SchoolClass.terminale,
      _ => null,
    };
  }

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
      switch (fromStoredValue(classLabel)) {
        SchoolClass.sixieme ||
        SchoolClass.cinquieme ||
        SchoolClass.quatrieme ||
        SchoolClass.troisieme => 'bepc',
        SchoolClass.seconde || SchoolClass.premiere => 'proba',
        SchoolClass.terminale => 'bac',
        SchoolClass.form1 ||
        SchoolClass.form2 ||
        SchoolClass.form3 ||
        SchoolClass.form4 ||
        SchoolClass.form5 => 'gce-ol',
        SchoolClass.lowerSixth || SchoolClass.upperSixth => 'gce-al',
        _ => null,
      };
}

String _normalizeAcademicValue(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll('é', 'e')
    .replaceAll('è', 'e')
    .replaceAll('ê', 'e')
    .replaceAll('ë', 'e')
    .replaceAll(RegExp(r'[^a-z0-9]'), '');

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
