import '../../student_registration/domain/academic_rules.dart';

/// Une matière du programme officiel, indépendamment de tout contenu publié.
///
/// Registre de décisions : le catalogue de matières d'un élève et les preuves
/// de maîtrise disponibles sont deux choses distinctes. Le profil dérivait sa
/// liste des seules matières *publiées* dans Firestore, si bien qu'un élève ne
/// voyait que « Anglais » et « SVT » — les deux matières effectivement
/// alimentées en contenu — au lieu de son programme réel.
class CurriculumSubject {
  const CurriculumSubject({
    required this.id,
    required this.frenchLabel,
    required this.englishLabel,
    this.iconKey = 'book',
    this.colorHex = 0xFF1451E1,
  });

  /// Identifiant stable, normalisé, indépendant de la langue d'affichage.
  final String id;
  final String frenchLabel;
  final String englishLabel;
  final String iconKey;
  final int colorHex;

  String label({required bool english}) => english ? englishLabel : frenchLabel;
}

/// Les matières INTELLIA237, nommées une seule fois.
abstract final class CurriculumSubjects {
  static const maths = CurriculumSubject(
    id: 'maths',
    frenchLabel: 'Mathématiques',
    englishLabel: 'Mathematics',
    iconKey: 'maths',
    colorHex: 0xFF1451E1,
  );

  /// Sciences de la Vie et de la Terre, Éducation à l'Environnement,
  /// Hygiène et Biotechnologie.
  static const svteehb = CurriculumSubject(
    id: 'svteehb',
    frenchLabel: 'SVTEEHB',
    englishLabel: 'Biology and Earth Sciences',
    iconKey: 'science',
    colorHex: 0xFF12805C,
  );

  static const pct = CurriculumSubject(
    id: 'pct',
    frenchLabel: 'Physique, Chimie et Technologie',
    englishLabel: 'Physics, Chemistry and Technology',
    iconKey: 'science',
    colorHex: 0xFF8A4B1F,
  );

  static const physique = CurriculumSubject(
    id: 'physique',
    frenchLabel: 'Physique',
    englishLabel: 'Physics',
    iconKey: 'science',
    colorHex: 0xFF8A4B1F,
  );

  static const chimie = CurriculumSubject(
    id: 'chimie',
    frenchLabel: 'Chimie',
    englishLabel: 'Chemistry',
    iconKey: 'science',
    colorHex: 0xFF6B3FA0,
  );

  static const informatique = CurriculumSubject(
    id: 'informatique',
    frenchLabel: 'Informatique',
    englishLabel: 'Computer Science',
    iconKey: 'code',
    colorHex: 0xFF315B93,
  );

  static const francais = CurriculumSubject(
    id: 'francais',
    frenchLabel: 'Langue française',
    englishLabel: 'French',
    iconKey: 'french',
    colorHex: 0xFF7C3AED,
  );

  static const litterature = CurriculumSubject(
    id: 'litterature',
    frenchLabel: 'Littérature',
    englishLabel: 'Literature',
    iconKey: 'french',
    colorHex: 0xFF7C3AED,
  );

  static const anglais = CurriculumSubject(
    id: 'anglais',
    frenchLabel: 'Anglais',
    englishLabel: 'English',
    iconKey: 'language',
    colorHex: 0xFF2E6FA8,
  );

  /// Langues et Cultures Nationales.
  static const lcn = CurriculumSubject(
    id: 'lcn',
    frenchLabel: 'Langues et Cultures Nationales',
    englishLabel: 'National Languages and Cultures',
    iconKey: 'language',
    colorHex: 0xFF8A671B,
  );

  /// Deuxième langue vivante. Le choix concret — espagnol, allemand, italien,
  /// chinois, arabe — est une configuration d'établissement, pas une matière
  /// de maîtrise distincte.
  static const lv2 = CurriculumSubject(
    id: 'lv2',
    frenchLabel: 'Langue vivante 2',
    englishLabel: 'Second Modern Language',
    iconKey: 'language',
    colorHex: 0xFF75639C,
  );

  static const latin = CurriculumSubject(
    id: 'latin',
    frenchLabel: 'Latin',
    englishLabel: 'Latin',
    iconKey: 'language',
    colorHex: 0xFF75639C,
  );

  static const histoire = CurriculumSubject(
    id: 'histoire',
    frenchLabel: 'Histoire',
    englishLabel: 'History',
    iconKey: 'history',
    colorHex: 0xFFB3561E,
  );

  static const geographie = CurriculumSubject(
    id: 'geographie',
    frenchLabel: 'Géographie',
    englishLabel: 'Geography',
    iconKey: 'geography',
    colorHex: 0xFF1F7A8C,
  );

  static const histoireGeographie = CurriculumSubject(
    id: 'histoire_geographie',
    frenchLabel: 'Histoire-Géographie',
    englishLabel: 'History and Geography',
    iconKey: 'history',
    colorHex: 0xFFB3561E,
  );

  /// Éducation à la Citoyenneté et à la Morale.
  static const ecm = CurriculumSubject(
    id: 'ecm',
    frenchLabel: 'Éducation à la Citoyenneté et à la Morale',
    englishLabel: 'Citizenship and Moral Education',
    iconKey: 'civics',
    colorHex: 0xFF2F7D4C,
  );

  static const philosophie = CurriculumSubject(
    id: 'philosophie',
    frenchLabel: 'Philosophie',
    englishLabel: 'Philosophy',
    iconKey: 'book',
    colorHex: 0xFF52306B,
  );
}

/// Programme officiel par niveau et série.
///
/// ## Ce que ce catalogue ne couvre volontairement pas
///
/// **L'EPS et les enseignements essentiellement pratiques ou artistiques** en
/// sont exclus : INTELLIA237 ne porte aucun contenu pédagogique canonique
/// correspondant, et une matière affichée sans rien derrière serait une
/// promesse vide.
///
/// **Les séries ABI, SH et TI** ne sont pas représentables : l'énumération
/// canonique [SchoolSeries] ne connaît que A, C et D, et ces valeurs pilotent
/// déjà l'inscription, les clés de catalogue Firestore et les règles de
/// sécurité en production. Introduire ici des séries que le reste du produit
/// ignore créerait une taxonomie parallèle. Le besoin est réel et reste ouvert.
///
/// **Le sous-système anglophone** n'a aucune donnée curriculaire dans le
/// projet : ni matières par Form, ni combinaisons O-Level ou A-Level. Rien
/// n'est inventé ici ; les élèves anglophones conservent exactement le
/// comportement actuel — les matières réellement publiées — et le manque est
/// documenté plutôt que comblé au jugé.
abstract final class CurriculumCatalog {
  /// Matières du programme pour un niveau et une série donnés.
  ///
  /// Renvoie une liste vide quand le programme n'est pas connu : l'appelant
  /// se replie alors sur les matières publiées, sans jamais rien inventer.
  static List<CurriculumSubject> forLevel({
    required SchoolClass schoolClass,
    SchoolSeries? series,
  }) {
    if (schoolClass.subsystem == EducationalSubsystem.anglophone) {
      return const <CurriculumSubject>[];
    }
    return switch (schoolClass) {
      SchoolClass.sixieme || SchoolClass.cinquieme => _lowerFirstCycle,
      SchoolClass.quatrieme || SchoolClass.troisieme => _upperFirstCycle,
      SchoolClass.seconde => _seconde(series),
      SchoolClass.premiere => _secondCycle(series, isFinalYear: false),
      SchoolClass.terminale => _secondCycle(series, isFinalYear: true),
      _ => const <CurriculumSubject>[],
    };
  }

  // ── Premier cycle ────────────────────────────────────────────────────────

  static const _lowerFirstCycle = <CurriculumSubject>[
    CurriculumSubjects.maths,
    CurriculumSubjects.svteehb,
    CurriculumSubjects.informatique,
    CurriculumSubjects.francais,
    CurriculumSubjects.anglais,
    CurriculumSubjects.lcn,
    CurriculumSubjects.histoire,
    CurriculumSubjects.geographie,
    CurriculumSubjects.ecm,
  ];

  /// PCT, la LV2 et le texte suivi apparaissent au cours du premier cycle.
  static const _upperFirstCycle = <CurriculumSubject>[
    CurriculumSubjects.maths,
    CurriculumSubjects.svteehb,
    CurriculumSubjects.pct,
    CurriculumSubjects.informatique,
    CurriculumSubjects.francais,
    CurriculumSubjects.litterature,
    CurriculumSubjects.anglais,
    CurriculumSubjects.lcn,
    CurriculumSubjects.lv2,
    CurriculumSubjects.histoire,
    CurriculumSubjects.geographie,
    CurriculumSubjects.ecm,
  ];

  // ── Second cycle ─────────────────────────────────────────────────────────

  static List<CurriculumSubject> _seconde(SchoolSeries? series) {
    return switch (series) {
      SchoolSeries.c => const [
        CurriculumSubjects.maths,
        CurriculumSubjects.physique,
        CurriculumSubjects.chimie,
        CurriculumSubjects.svteehb,
        CurriculumSubjects.informatique,
        CurriculumSubjects.francais,
        CurriculumSubjects.anglais,
        CurriculumSubjects.histoireGeographie,
        CurriculumSubjects.ecm,
        CurriculumSubjects.lv2,
      ],
      // La Seconde A et, faute de série renseignée, le tronc littéraire.
      _ => const [
        CurriculumSubjects.francais,
        CurriculumSubjects.litterature,
        CurriculumSubjects.anglais,
        CurriculumSubjects.lv2,
        CurriculumSubjects.histoire,
        CurriculumSubjects.geographie,
        CurriculumSubjects.latin,
        CurriculumSubjects.maths,
        CurriculumSubjects.svteehb,
        CurriculumSubjects.informatique,
        CurriculumSubjects.ecm,
      ],
    };
  }

  /// Première et Terminale.
  ///
  /// La philosophie n'apparaît qu'en Terminale : c'est la règle du cursus, et
  /// l'afficher en Première annoncerait une matière que l'élève n'a pas.
  static List<CurriculumSubject> _secondCycle(
    SchoolSeries? series, {
    required bool isFinalYear,
  }) {
    final philosophy = isFinalYear
        ? const [CurriculumSubjects.philosophie]
        : const <CurriculumSubject>[];

    return switch (series) {
      SchoolSeries.c => [
        CurriculumSubjects.maths,
        CurriculumSubjects.physique,
        CurriculumSubjects.chimie,
        CurriculumSubjects.svteehb,
        CurriculumSubjects.informatique,
        CurriculumSubjects.francais,
        CurriculumSubjects.litterature,
        CurriculumSubjects.anglais,
        CurriculumSubjects.histoireGeographie,
        ...philosophy,
      ],
      SchoolSeries.d => [
        CurriculumSubjects.svteehb,
        CurriculumSubjects.maths,
        CurriculumSubjects.physique,
        CurriculumSubjects.chimie,
        CurriculumSubjects.francais,
        CurriculumSubjects.litterature,
        CurriculumSubjects.anglais,
        CurriculumSubjects.histoireGeographie,
        CurriculumSubjects.informatique,
        ...philosophy,
      ],
      // Série A (A4) et repli littéraire quand la série n'est pas renseignée.
      _ => [
        CurriculumSubjects.litterature,
        CurriculumSubjects.francais,
        CurriculumSubjects.anglais,
        CurriculumSubjects.lv2,
        CurriculumSubjects.histoireGeographie,
        CurriculumSubjects.ecm,
        CurriculumSubjects.maths,
        CurriculumSubjects.svteehb,
        CurriculumSubjects.informatique,
        ...philosophy,
      ],
    };
  }

  /// Rapproche une matière publiée d'une matière du programme.
  ///
  /// Les identifiants Firestore ont été saisis au fil des imports : « SVT »,
  /// « Sciences de la Vie et de la Terre » et « svteehb » désignent la même
  /// matière. Sans cette normalisation, la fusion afficherait des doublons.
  static String normalizeId(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ùûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');

    return _aliases[normalized] ?? normalized;
  }

  static const _aliases = <String, String>{
    'math': 'maths',
    'mathematique': 'maths',
    'mathematiques': 'maths',
    'mathematics': 'maths',
    'svt': 'svteehb',
    'sciencesdelavieetdelaterre': 'svteehb',
    'biology': 'svteehb',
    'physics': 'physique',
    'chemistry': 'chimie',
    'physiquechimie': 'pct',
    'physiquechimietechnologie': 'pct',
    'french': 'francais',
    'languefrancaise': 'francais',
    'literature': 'litterature',
    'english': 'anglais',
    'history': 'histoire',
    'geography': 'geographie',
    'histoiregeo': 'histoire_geographie',
    'histoiregeographie': 'histoire_geographie',
    'philosophy': 'philosophie',
    'computerscience': 'informatique',
    'info': 'informatique',
    'languesetculturesnationales': 'lcn',
    'languevivante2': 'lv2',
  };
}
