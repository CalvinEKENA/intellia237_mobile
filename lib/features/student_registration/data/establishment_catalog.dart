import '../domain/establishment.dart';

/// Bundled Cameroon secondary-school seed.
///
/// The schema mirrors the national-register dimensions and is deliberately
/// local: discovery never issues a network request for each keystroke. New
/// register exports can be appended without changing the search/UI contract.
abstract final class EstablishmentCatalog {
  static const version = 'cm-secondary-2026.09';

  static final List<Establishment> all = <Establishment>[
    // Adamaoua
    _e(
      'ad-ngaoundere-classique',
      'Lycée Classique et Moderne de Ngaoundéré',
      'Adamaoua',
      'Ngaoundéré',
      aliases: ['LCM Ngaoundéré'],
    ),
    _e(
      'ad-ngaoundere-bilingue',
      'Lycée Bilingue de Ngaoundéré',
      'Adamaoua',
      'Ngaoundéré',
      subsystem: EstablishmentSubsystem.bilingual,
      aliases: ['LB Ngaoundéré'],
    ),
    _e(
      'ad-ngaoundere-technique',
      'Lycée Technique de Ngaoundéré',
      'Adamaoua',
      'Ngaoundéré',
      type: EstablishmentType.technicalSchool,
      educationTypes: _technical,
    ),
    _e('ad-meiganga', 'Lycée de Meiganga', 'Adamaoua', 'Meiganga'),
    _e(
      'ad-meiganga-bilingue',
      'Lycée Bilingue de Meiganga',
      'Adamaoua',
      'Meiganga',
      subsystem: EstablishmentSubsystem.bilingual,
    ),
    _e('ad-tibati', 'Lycée de Tibati', 'Adamaoua', 'Tibati'),
    _e('ad-banyo', 'Lycée de Banyo', 'Adamaoua', 'Banyo'),
    _e('ad-tignere', 'Lycée de Tignère', 'Adamaoua', 'Tignère'),
    _e('ad-belel', 'Lycée de Belel', 'Adamaoua', 'Belel'),
    _e(
      'ad-protestant-ngaoundere',
      'Collège Protestant de Ngaoundéré',
      'Adamaoua',
      'Ngaoundéré',
      type: EstablishmentType.privateSecondarySchool,
    ),

    // Centre
    _e(
      'ce-yaounde-leclerc',
      'Lycée Général Leclerc',
      'Centre',
      'Yaoundé',
      aliases: ['Leclerc', 'LGL', 'Lycée Leclerc'],
    ),
    _e(
      'ce-yaounde-biyem-assi',
      'Lycée de Biyem-Assi',
      'Centre',
      'Yaoundé',
      aliases: ['Lycée Biyem Assi'],
    ),
    _e(
      'ce-yaounde-ngoa-ekelle',
      'Lycée de Ngoa-Ekellé',
      'Centre',
      'Yaoundé',
      aliases: ['Lycée Ngoa Ekelle'],
    ),
    _e(
      'ce-yaounde-bilingue-application',
      'Lycée Bilingue d’Application de Yaoundé',
      'Centre',
      'Yaoundé',
      subsystem: EstablishmentSubsystem.bilingual,
      aliases: ['LBA Yaoundé'],
    ),
    _e('ce-yaounde-ekounou', 'Lycée d’Ekounou', 'Centre', 'Yaoundé'),
    _e('ce-yaounde-nkol-eton', 'Lycée de Nkol-Eton', 'Centre', 'Yaoundé'),
    _e('ce-yaounde-mballa-ii', 'Lycée de Mballa II', 'Centre', 'Yaoundé'),
    _e(
      'ce-yaounde-vogt',
      'Collège François-Xavier Vogt',
      'Centre',
      'Yaoundé',
      type: EstablishmentType.privateSecondarySchool,
      aliases: ['Collège Vogt', 'Vogt'],
    ),
    _e(
      'ce-yaounde-retraite',
      'Collège de la Retraite',
      'Centre',
      'Yaoundé',
      type: EstablishmentType.privateSecondarySchool,
    ),
    _e(
      'ce-yaounde-charles-atangana',
      'Lycée Technique Charles Atangana',
      'Centre',
      'Yaoundé',
      type: EstablishmentType.technicalSchool,
      educationTypes: _technical,
    ),

    // Est
    _e('es-bertoua-classique', 'Lycée Classique de Bertoua', 'Est', 'Bertoua'),
    _e(
      'es-bertoua-bilingue',
      'Lycée Bilingue de Bertoua',
      'Est',
      'Bertoua',
      subsystem: EstablishmentSubsystem.bilingual,
    ),
    _e(
      'es-bertoua-technique',
      'Lycée Technique de Bertoua',
      'Est',
      'Bertoua',
      type: EstablishmentType.technicalSchool,
      educationTypes: _technical,
    ),
    _e('es-batouri', 'Lycée de Batouri', 'Est', 'Batouri'),
    _e('es-yokadouma', 'Lycée de Yokadouma', 'Est', 'Yokadouma'),
    _e('es-abong-mbang', 'Lycée d’Abong-Mbang', 'Est', 'Abong-Mbang'),
    _e('es-belabo', 'Lycée de Bélabo', 'Est', 'Bélabo'),
    _e('es-garoua-boulai', 'Lycée de Garoua-Boulaï', 'Est', 'Garoua-Boulaï'),
    _e('es-lomie', 'Lycée de Lomié', 'Est', 'Lomié'),
    _e('es-doume', 'Lycée de Doumé', 'Est', 'Doumé'),

    // Extrême-Nord
    _e(
      'en-maroua-classique',
      'Lycée Classique et Moderne de Maroua',
      'Extrême-Nord',
      'Maroua',
      aliases: ['LCM Maroua'],
    ),
    _e(
      'en-maroua-bilingue',
      'Lycée Bilingue de Maroua',
      'Extrême-Nord',
      'Maroua',
      subsystem: EstablishmentSubsystem.bilingual,
    ),
    _e(
      'en-maroua-technique',
      'Lycée Technique de Maroua',
      'Extrême-Nord',
      'Maroua',
      type: EstablishmentType.technicalSchool,
      educationTypes: _technical,
    ),
    _e('en-mokolo', 'Lycée de Mokolo', 'Extrême-Nord', 'Mokolo'),
    _e('en-kousseri', 'Lycée de Kousséri', 'Extrême-Nord', 'Kousséri'),
    _e('en-mora', 'Lycée de Mora', 'Extrême-Nord', 'Mora'),
    _e('en-yagoua', 'Lycée de Yagoua', 'Extrême-Nord', 'Yagoua'),
    _e('en-kaele', 'Lycée de Kaélé', 'Extrême-Nord', 'Kaélé'),
    _e('en-guidiguis', 'Lycée de Guidiguis', 'Extrême-Nord', 'Guidiguis'),
    _e('en-waza', 'Lycée de Waza', 'Extrême-Nord', 'Waza'),

    // Littoral
    _e('lt-douala-joss', 'Lycée Joss', 'Littoral', 'Douala', aliases: ['Joss']),
    _e('lt-douala-akwa', 'Lycée d’Akwa', 'Littoral', 'Douala'),
    _e(
      'lt-douala-deido',
      'Lycée Bilingue de Deido',
      'Littoral',
      'Douala',
      subsystem: EstablishmentSubsystem.bilingual,
    ),
    _e('lt-douala-new-bell', 'Lycée de New-Bell', 'Littoral', 'Douala'),
    _e(
      'lt-douala-mongo-joseph',
      'Lycée Mongo Joseph',
      'Littoral',
      'Douala',
      aliases: ['Mongo Joseph'],
    ),
    _e(
      'lt-douala-bassa-technique',
      'Lycée Technique de Douala-Bassa',
      'Littoral',
      'Douala',
      type: EstablishmentType.technicalSchool,
      educationTypes: _technical,
    ),
    _e(
      'lt-douala-libermann',
      'Collège Libermann',
      'Littoral',
      'Douala',
      type: EstablishmentType.privateSecondarySchool,
      aliases: ['Libermann'],
    ),
    _e(
      'lt-douala-chevreul',
      'Collège Chevreul',
      'Littoral',
      'Douala',
      type: EstablishmentType.privateSecondarySchool,
    ),
    _e(
      'lt-nkongsamba-manzengue',
      'Lycée de Manengouba',
      'Littoral',
      'Nkongsamba',
      aliases: ['Lycée du Manengouba'],
    ),
    _e(
      'lt-edéa-bilingue',
      'Lycée Bilingue d’Édéa',
      'Littoral',
      'Édéa',
      subsystem: EstablishmentSubsystem.bilingual,
    ),

    // Nord
    _e(
      'no-garoua-classique',
      'Lycée Classique et Moderne de Garoua',
      'Nord',
      'Garoua',
      aliases: ['LCM Garoua'],
    ),
    _e(
      'no-garoua-bilingue',
      'Lycée Bilingue de Garoua',
      'Nord',
      'Garoua',
      subsystem: EstablishmentSubsystem.bilingual,
    ),
    _e(
      'no-garoua-technique',
      'Lycée Technique de Garoua',
      'Nord',
      'Garoua',
      type: EstablishmentType.technicalSchool,
      educationTypes: _technical,
    ),
    _e('no-pitoa', 'Lycée de Pitoa', 'Nord', 'Pitoa'),
    _e('no-guider', 'Lycée de Guider', 'Nord', 'Guider'),
    _e('no-poli', 'Lycée de Poli', 'Nord', 'Poli'),
    _e('no-tchollire', 'Lycée de Tcholliré', 'Nord', 'Tcholliré'),
    _e('no-lagdo', 'Lycée de Lagdo', 'Nord', 'Lagdo'),
    _e('no-rey-bouba', 'Lycée de Rey-Bouba', 'Nord', 'Rey-Bouba'),
    _e('no-ngong', 'Lycée de Ngong', 'Nord', 'Ngong'),

    // Nord-Ouest
    _e(
      'nw-bamenda-gbhs',
      'Government Bilingual High School Bamenda',
      'Nord-Ouest',
      'Bamenda',
      type: EstablishmentType.governmentHighSchool,
      subsystem: EstablishmentSubsystem.bilingual,
      aliases: ['GBHS Bamenda'],
    ),
    _e(
      'nw-bamenda-ghs',
      'Government High School Bamenda',
      'Nord-Ouest',
      'Bamenda',
      type: EstablishmentType.governmentHighSchool,
      subsystem: EstablishmentSubsystem.anglophone,
      aliases: ['GHS Bamenda'],
    ),
    _e(
      'nw-mankon-sacred-heart',
      'Sacred Heart College Mankon',
      'Nord-Ouest',
      'Bamenda',
      type: EstablishmentType.privateSecondarySchool,
      subsystem: EstablishmentSubsystem.anglophone,
      aliases: ['SHC Mankon'],
    ),
    _e(
      'nw-mankon-lourdes',
      'Our Lady of Lourdes College Mankon',
      'Nord-Ouest',
      'Bamenda',
      type: EstablishmentType.privateSecondarySchool,
      subsystem: EstablishmentSubsystem.anglophone,
    ),
    _e(
      'nw-bambili-ccast',
      'Cameroon College of Arts, Science and Technology Bambili',
      'Nord-Ouest',
      'Bambili',
      type: EstablishmentType.technicalSchool,
      subsystem: EstablishmentSubsystem.anglophone,
      educationTypes: _mixed,
      aliases: ['CCAST Bambili'],
    ),
    _e(
      'nw-mankon-pss',
      'Presbyterian Secondary School Mankon',
      'Nord-Ouest',
      'Bamenda',
      type: EstablishmentType.privateSecondarySchool,
      subsystem: EstablishmentSubsystem.anglophone,
      aliases: ['PSS Mankon'],
    ),
    _e(
      'nw-kumbo-gbhs',
      'Government Bilingual High School Kumbo',
      'Nord-Ouest',
      'Kumbo',
      type: EstablishmentType.governmentHighSchool,
      subsystem: EstablishmentSubsystem.bilingual,
      aliases: ['GBHS Kumbo'],
    ),
    _e(
      'nw-jakiri-gbhs',
      'Government Bilingual High School Jakiri',
      'Nord-Ouest',
      'Jakiri',
      type: EstablishmentType.governmentHighSchool,
      subsystem: EstablishmentSubsystem.bilingual,
    ),
    _e(
      'nw-wum-ghs',
      'Government High School Wum',
      'Nord-Ouest',
      'Wum',
      type: EstablishmentType.governmentHighSchool,
      subsystem: EstablishmentSubsystem.anglophone,
    ),
    _e(
      'nw-ndop-gbhs',
      'Government Bilingual High School Ndop',
      'Nord-Ouest',
      'Ndop',
      type: EstablishmentType.governmentHighSchool,
      subsystem: EstablishmentSubsystem.bilingual,
    ),

    // Ouest
    _e(
      'ou-bafoussam-classique',
      'Lycée Classique de Bafoussam',
      'Ouest',
      'Bafoussam',
    ),
    _e(
      'ou-bafoussam-bilingue',
      'Lycée Bilingue de Bafoussam',
      'Ouest',
      'Bafoussam',
      subsystem: EstablishmentSubsystem.bilingual,
    ),
    _e(
      'ou-bafoussam-technique',
      'Lycée Technique de Bafoussam',
      'Ouest',
      'Bafoussam',
      type: EstablishmentType.technicalSchool,
      educationTypes: _technical,
    ),
    _e(
      'ou-dschang-classique',
      'Lycée Classique de Dschang',
      'Ouest',
      'Dschang',
    ),
    _e(
      'ou-dschang-bilingue',
      'Lycée Bilingue de Dschang',
      'Ouest',
      'Dschang',
      subsystem: EstablishmentSubsystem.bilingual,
    ),
    _e(
      'ou-foumban-classique',
      'Lycée Classique de Foumban',
      'Ouest',
      'Foumban',
    ),
    _e(
      'ou-foumban-bilingue',
      'Lycée Bilingue de Foumban',
      'Ouest',
      'Foumban',
      subsystem: EstablishmentSubsystem.bilingual,
    ),
    _e('ou-bafang', 'Lycée de Bafang', 'Ouest', 'Bafang'),
    _e('ou-bangangte', 'Lycée Classique de Bangangté', 'Ouest', 'Bangangté'),
    _e(
      'ou-mbouda-bilingue',
      'Lycée Bilingue de Mbouda',
      'Ouest',
      'Mbouda',
      subsystem: EstablishmentSubsystem.bilingual,
    ),

    // Sud
    _e(
      'su-ebolowa-classique',
      'Lycée Classique et Moderne d’Ebolowa',
      'Sud',
      'Ebolowa',
      aliases: ['LCM Ebolowa'],
    ),
    _e(
      'su-ebolowa-bilingue',
      'Lycée Bilingue d’Ebolowa',
      'Sud',
      'Ebolowa',
      subsystem: EstablishmentSubsystem.bilingual,
    ),
    _e(
      'su-ebolowa-technique',
      'Lycée Technique d’Ebolowa',
      'Sud',
      'Ebolowa',
      type: EstablishmentType.technicalSchool,
      educationTypes: _technical,
    ),
    _e('su-kribi-classique', 'Lycée Classique de Kribi', 'Sud', 'Kribi'),
    _e(
      'su-kribi-bilingue',
      'Lycée Bilingue de Kribi',
      'Sud',
      'Kribi',
      subsystem: EstablishmentSubsystem.bilingual,
    ),
    _e('su-ambam', 'Lycée d’Ambam', 'Sud', 'Ambam'),
    _e('su-sangmelima', 'Lycée Classique de Sangmélima', 'Sud', 'Sangmélima'),
    _e('su-lolodorf', 'Lycée de Lolodorf', 'Sud', 'Lolodorf'),
    _e('su-mvangan', 'Lycée de Mvangan', 'Sud', 'Mvangan'),
    _e('su-meyomessala', 'Lycée de Meyomessala', 'Sud', 'Meyomessala'),

    // Sud-Ouest
    _e(
      'sw-limbe-ghs',
      'Government High School Limbe',
      'Sud-Ouest',
      'Limbe',
      type: EstablishmentType.governmentHighSchool,
      subsystem: EstablishmentSubsystem.anglophone,
      aliases: ['GHS Limbe'],
    ),
    _e(
      'sw-limbe-gbhs',
      'Government Bilingual High School Limbe',
      'Sud-Ouest',
      'Limbe',
      type: EstablishmentType.governmentHighSchool,
      subsystem: EstablishmentSubsystem.bilingual,
      aliases: ['GBHS Limbe'],
    ),
    _e(
      'sw-limbe-saker',
      'Saker Baptist College',
      'Sud-Ouest',
      'Limbe',
      type: EstablishmentType.privateSecondarySchool,
      subsystem: EstablishmentSubsystem.anglophone,
      aliases: ['Saker'],
    ),
    _e(
      'sw-buea-molyko',
      'Government Bilingual High School Molyko',
      'Sud-Ouest',
      'Buea',
      type: EstablishmentType.governmentHighSchool,
      subsystem: EstablishmentSubsystem.bilingual,
      aliases: ['GBHS Molyko'],
    ),
    _e(
      'sw-buea-baptist',
      'Baptist High School Buea',
      'Sud-Ouest',
      'Buea',
      type: EstablishmentType.privateSecondarySchool,
      subsystem: EstablishmentSubsystem.anglophone,
    ),
    _e(
      'sw-sasse-st-joseph',
      'Saint Joseph’s College Sasse',
      'Sud-Ouest',
      'Buea',
      type: EstablishmentType.privateSecondarySchool,
      subsystem: EstablishmentSubsystem.anglophone,
      aliases: ['Sasse College'],
    ),
    _e(
      'sw-kumba-ghs',
      'Government High School Kumba',
      'Sud-Ouest',
      'Kumba',
      type: EstablishmentType.governmentHighSchool,
      subsystem: EstablishmentSubsystem.anglophone,
      aliases: ['GHS Kumba'],
    ),
    _e(
      'sw-kumba-gbhs',
      'Government Bilingual High School Kumba',
      'Sud-Ouest',
      'Kumba',
      type: EstablishmentType.governmentHighSchool,
      subsystem: EstablishmentSubsystem.bilingual,
      aliases: ['GBHS Kumba'],
    ),
    _e(
      'sw-kumba-pss',
      'Presbyterian Secondary School Kumba',
      'Sud-Ouest',
      'Kumba',
      type: EstablishmentType.privateSecondarySchool,
      subsystem: EstablishmentSubsystem.anglophone,
      aliases: ['PSS Kumba'],
    ),
    _e(
      'sw-mamfe-gbhs',
      'Government Bilingual High School Mamfe',
      'Sud-Ouest',
      'Mamfe',
      type: EstablishmentType.governmentHighSchool,
      subsystem: EstablishmentSubsystem.bilingual,
      aliases: ['GBHS Mamfe'],
    ),
  ];

  static Map<String, int> get countByRegion {
    final result = <String, int>{};
    for (final establishment in all) {
      result.update(
        establishment.region,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    return result;
  }

  static Map<String, int> get countByCity {
    final result = <String, int>{};
    for (final establishment in all) {
      result.update(
        establishment.city,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    return result;
  }
}

const _general = <EstablishmentEducationType>[
  EstablishmentEducationType.general,
];
const _technical = <EstablishmentEducationType>[
  EstablishmentEducationType.technical,
];
const _mixed = <EstablishmentEducationType>[
  EstablishmentEducationType.general,
  EstablishmentEducationType.technical,
];

Establishment _e(
  String id,
  String name,
  String region,
  String city, {
  List<String> aliases = const <String>[],
  EstablishmentType type = EstablishmentType.lycee,
  EstablishmentSubsystem subsystem = EstablishmentSubsystem.francophone,
  List<EstablishmentEducationType> educationTypes = _general,
}) {
  return Establishment(
    id: id,
    officialName: name,
    normalizedName: EstablishmentSearch.normalize(name),
    aliases: aliases,
    region: region,
    city: city,
    type: type,
    subsystem: subsystem,
    educationTypes: educationTypes,
    status: EstablishmentCatalogStatus.active,
  );
}

abstract final class EstablishmentSearch {
  static String normalize(String input) {
    const accents = <String, String>{
      'à': 'a',
      'â': 'a',
      'ä': 'a',
      'á': 'a',
      'ç': 'c',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'î': 'i',
      'ï': 'i',
      'í': 'i',
      'ô': 'o',
      'ö': 'o',
      'ó': 'o',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ú': 'u',
      'ÿ': 'y',
      'œ': 'oe',
    };
    var value = input.toLowerCase().replaceAll('’', "'");
    accents.forEach(
      (source, target) => value = value.replaceAll(source, target),
    );
    value = value
        .replaceAll(RegExp(r"['`´]"), ' ')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
    return value.replaceAll(RegExp(r'\s+'), ' ');
  }

  static List<EstablishmentSearchResult> query(
    String rawQuery, {
    int limit = 8,
  }) {
    final query = normalize(rawQuery);
    if (query.isEmpty) return const <EstablishmentSearchResult>[];

    final scored = <({Establishment establishment, int score})>[];
    for (final establishment in EstablishmentCatalog.all) {
      if (establishment.status != EstablishmentCatalogStatus.active) continue;
      final score = _score(establishment, query);
      if (score > 0) scored.add((establishment: establishment, score: score));
    }
    scored.sort((a, b) {
      final score = b.score.compareTo(a.score);
      return score != 0
          ? score
          : a.establishment.officialName.compareTo(
              b.establishment.officialName,
            );
    });

    final visible = scored.take(limit).toList(growable: false);
    final dominant =
        visible.isNotEmpty &&
        (visible.first.score >= 850 ||
            visible.length == 1 ||
            visible.first.score - visible[1].score >= 90);
    return <EstablishmentSearchResult>[
      for (var index = 0; index < visible.length; index++)
        EstablishmentSearchResult(
          establishment: visible[index].establishment,
          score: visible[index].score,
          highlightStart: _highlightSpan(
            visible[index].establishment.officialName,
            query,
          ).$1,
          highlightEnd: _highlightSpan(
            visible[index].establishment.officialName,
            query,
          ).$2,
          isDominant: index == 0 && dominant,
        ),
    ];
  }

  static int _score(Establishment establishment, String query) {
    final names = <String>[
      establishment.normalizedName,
      ...establishment.aliases.map(normalize),
    ];
    var best = 0;
    for (final candidate in names) {
      if (candidate == query) best = best < 1000 ? 1000 : best;
      if (candidate.startsWith(query)) best = best < 880 ? 880 : best;
      if (candidate.split(' ').any((word) => word.startsWith(query))) {
        best = best < 760 ? 760 : best;
      }
      if (candidate.contains(query)) best = best < 650 ? 650 : best;

      final compactQuery = query.replaceAll(' ', '');
      if (compactQuery.length >= 3) {
        final distance = _boundedDistance(compactQuery, candidate);
        final threshold = compactQuery.length <= 5 ? 1 : 2;
        if (distance <= threshold) {
          final fuzzy = 560 - distance * 45;
          best = best < fuzzy ? fuzzy : best;
        }
      }
    }

    final normalizedCity = normalize(establishment.city);
    final normalizedRegion = normalize(establishment.region);
    if (normalizedCity == query) best = best < 720 ? 720 : best;
    if (normalizedCity.startsWith(query)) best = best < 540 ? 540 : best;
    if (normalizedRegion == query) best = best < 420 ? 420 : best;

    final queryTokens = query.split(' ');
    final searchable = '${names.join(' ')} $normalizedCity $normalizedRegion';
    if (queryTokens.every(searchable.contains)) best += queryTokens.length * 18;
    return best;
  }

  static int _boundedDistance(String query, String candidate) {
    var best = query.length + 1;
    final words = candidate.split(RegExp(r'\s+'));
    final compactCandidate = candidate.replaceAll(' ', '');
    for (final word in <String>[compactCandidate, ...words]) {
      final sample = word.length > query.length + 2
          ? word.substring(0, query.length + 2)
          : word;
      final distance = _levenshtein(query, sample);
      if (distance < best) best = distance;
    }
    return best;
  }

  static int _levenshtein(String left, String right) {
    var previous = List<int>.generate(right.length + 1, (index) => index);
    for (var i = 1; i <= left.length; i++) {
      final current = List<int>.filled(right.length + 1, 0)..[0] = i;
      for (var j = 1; j <= right.length; j++) {
        final cost = left.codeUnitAt(i - 1) == right.codeUnitAt(j - 1) ? 0 : 1;
        current[j] = <int>[
          current[j - 1] + 1,
          previous[j] + 1,
          previous[j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
      previous = current;
    }
    return previous.last;
  }

  static (int, int) _highlightSpan(String original, String query) {
    final queryToken = query.split(' ').last;
    for (var start = 0; start < original.length; start++) {
      for (var end = start + 1; end <= original.length; end++) {
        final normalized = normalize(original.substring(start, end));
        if (normalized == query || normalized == queryToken) {
          return (start, end);
        }
      }
    }
    return (0, 0);
  }
}
