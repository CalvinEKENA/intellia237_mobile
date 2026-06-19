/// Classes disponibles sur INTELLIA237.
/// Seules les classes préparant au BEPC, Probatoire et Baccalauréat
/// sont proposées — conforme au système scolaire camerounais.
enum SchoolClass { troisieme, premiere, terminale }

/// Options de série / langue selon la classe.
/// — 3ème      : Allemand | Espagnol (2ème langue vivante)
/// — Première  : A | C
/// — Terminale : A | C | D
enum SchoolSeries { allemand, espagnol, a, c, d }

extension SchoolClassX on SchoolClass {
  static const ordered = <SchoolClass>[
    SchoolClass.troisieme,
    SchoolClass.premiere,
    SchoolClass.terminale,
  ];

  String get label => switch (this) {
    SchoolClass.troisieme => '3ème',
    SchoolClass.premiere => 'Première',
    SchoolClass.terminale => 'Terminale',
  };

  List<SchoolSeries> get allowedSeries => switch (this) {
    SchoolClass.troisieme => [SchoolSeries.allemand, SchoolSeries.espagnol],
    SchoolClass.premiere => [SchoolSeries.a, SchoolSeries.c],
    SchoolClass.terminale => [SchoolSeries.a, SchoolSeries.c, SchoolSeries.d],
  };

  /// Toutes les classes ont une option de série/langue.
  bool get requiresSeries => true;

  /// Libellé du champ série selon la classe.
  String get seriesFieldLabel => switch (this) {
    SchoolClass.troisieme => 'Langue vivante 2',
    SchoolClass.premiere => 'Série',
    SchoolClass.terminale => 'Série',
  };

  /// Identifiant de niveau pour filtrer les tuteurs IA.
  String get tutorLevel => switch (this) {
    SchoolClass.troisieme => 'bepc',
    SchoolClass.premiere => 'proba',
    SchoolClass.terminale => 'bac',
  };

  /// Retourne le tutorLevel à partir d'un classLevel stocké (ex: '3ème').
  static String? tutorLevelFromClassLabel(String? classLabel) =>
      switch (classLabel) {
        '3ème' => 'bepc',
        'Première' => 'proba',
        'Terminale' => 'bac',
        _ => null,
      };
}

extension SchoolSeriesX on SchoolSeries {
  String get label => switch (this) {
    SchoolSeries.allemand => 'Allemand',
    SchoolSeries.espagnol => 'Espagnol',
    SchoolSeries.a => 'A',
    SchoolSeries.c => 'C',
    SchoolSeries.d => 'D',
  };
}
