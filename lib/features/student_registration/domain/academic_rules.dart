/// Classes disponibles sur INTELLIA237, alignees sur la Web App.
enum SchoolClass {
  sixieme,
  cinquieme,
  quatrieme,
  troisieme,
  seconde,
  premiere,
  terminale,
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

  String get label => switch (this) {
    SchoolClass.sixieme => '6ème',
    SchoolClass.cinquieme => '5ème',
    SchoolClass.quatrieme => '4ème',
    SchoolClass.troisieme => '3ème',
    SchoolClass.seconde => '2nde',
    SchoolClass.premiere => '1ère',
    SchoolClass.terminale => 'Terminale',
  };

  List<SchoolSeries> get allowedSeries => switch (this) {
    SchoolClass.sixieme ||
    SchoolClass.cinquieme ||
    SchoolClass.quatrieme ||
    SchoolClass.troisieme => const <SchoolSeries>[],
    SchoolClass.seconde => [SchoolSeries.a, SchoolSeries.c],
    SchoolClass.premiere => [SchoolSeries.a, SchoolSeries.c, SchoolSeries.d],
    SchoolClass.terminale => [SchoolSeries.a, SchoolSeries.c, SchoolSeries.d],
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
  };

  /// Identifiant de niveau pour filtrer les tuteurs IA.
  String get tutorLevel => switch (this) {
    SchoolClass.sixieme ||
    SchoolClass.cinquieme ||
    SchoolClass.quatrieme ||
    SchoolClass.troisieme => 'bepc',
    SchoolClass.seconde || SchoolClass.premiere => 'proba',
    SchoolClass.terminale => 'bac',
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
        _ => null,
      };
}

extension SchoolSeriesX on SchoolSeries {
  String get label => switch (this) {
    SchoolSeries.a => 'A',
    SchoolSeries.c => 'C',
    SchoolSeries.d => 'D',
  };
}
