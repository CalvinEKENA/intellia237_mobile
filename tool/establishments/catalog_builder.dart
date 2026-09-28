import 'dart:convert';

import 'package:intellia237/features/student_registration/domain/establishment.dart';
import 'package:intellia237/features/student_registration/domain/school_name_canon.dart';

/// Colonnes attendues de la feuille « Base maîtresse », dans cet ordre.
const masterHeader = [
  'Établissement',
  'Ville',
  'Arrondissement',
  'Statut',
  'Filière / type',
  'Langue / sous-système',
  'Source principale',
  'Confiance',
  'URL source',
];

/// Seule feuille importée : les feuilles par ville en sont des vues.
const masterSheet = 'Base maîtresse';

/// Une ligne de la Base maîtresse, telle qu'écrite.
class MasterRow {
  const MasterRow({
    required this.line,
    required this.name,
    required this.city,
    required this.district,
    required this.status,
    required this.track,
    required this.language,
    required this.source,
    required this.confidence,
    required this.url,
  });

  /// Numéro de ligne dans la feuille (en-tête = 1).
  final int line;
  final String name;
  final String city;
  final String district;
  final String status;
  final String track;
  final String language;
  final String source;
  final String confidence;
  final String url;

  List<String> get cells => [
    name,
    city,
    district,
    status,
    track,
    language,
    source,
    confidence,
    url,
  ];

  static List<MasterRow> fromSheet(List<List<String>> rows) {
    if (rows.isEmpty || !_sameHeader(rows.first)) {
      throw FormatException('En-tête inattendu : ${rows.firstOrNull}');
    }
    return [
      for (final (index, row) in rows.skip(1).indexed)
        if (row.any((cell) => cell.trim().isNotEmpty))
          MasterRow(
            line: index + 2,
            name: _cell(row, 0),
            city: _cell(row, 1),
            district: _cell(row, 2),
            status: _cell(row, 3),
            track: _cell(row, 4),
            language: _cell(row, 5),
            source: _cell(row, 6),
            confidence: _cell(row, 7),
            url: _cell(row, 8),
          ),
    ];
  }

  static bool _sameHeader(List<String> header) =>
      header.length >= masterHeader.length &&
      [
        for (var i = 0; i < masterHeader.length; i++)
          header[i].trim() == masterHeader[i],
      ].every((same) => same);

  static String _cell(List<String> row, int index) =>
      index < row.length ? row[index].trim() : '';
}

/// Instantané CSV de la feuille (UTF-8, séparateur virgule, guillemets
/// doublés) : lisible dans un diff, reproductible.
String masterRowsToCsv(List<MasterRow> rows) {
  String quote(String value) => value.contains(RegExp('[",\n]'))
      ? '"${value.replaceAll('"', '""')}"'
      : value;
  return [
    masterHeader.map(quote).join(','),
    for (final row in rows) row.cells.map(quote).join(','),
  ].join('\n');
}

List<MasterRow> masterRowsFromCsv(String csv) {
  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var quoted = false;
  for (var i = 0; i < csv.length; i++) {
    final char = csv[i];
    if (quoted) {
      if (char == '"' && i + 1 < csv.length && csv[i + 1] == '"') {
        cell.write('"');
        i++;
      } else if (char == '"') {
        quoted = false;
      } else {
        cell.write(char);
      }
    } else if (char == '"') {
      quoted = true;
    } else if (char == ',') {
      row.add(cell.toString());
      cell.clear();
    } else if (char == '\n') {
      row.add(cell.toString());
      cell.clear();
      rows.add(row);
      row = <String>[];
    } else if (char != '\r') {
      cell.write(char);
    }
  }
  if (cell.isNotEmpty || row.isNotEmpty) {
    row.add(cell.toString());
    rows.add(row);
  }
  return MasterRow.fromSheet(rows);
}

/// Un établissement du catalogue généré.
class DirectoryEntry {
  DirectoryEntry({
    required this.id,
    required this.name,
    required this.city,
    required this.region,
    required this.origin,
    this.district,
    this.ownership,
    this.track,
    this.language,
    this.type,
    Iterable<String> aliases = const [],
    this.provenance,
  }) {
    addAliases(aliases);
  }

  final String id;
  String name;
  String? city;
  String? region;
  String? district;
  EstablishmentOwnership? ownership;
  EstablishmentTrack? track;
  EstablishmentSubsystem? language;
  EstablishmentType? type;

  /// `reference`, `legacy`, `reference+legacy` ou `owner`.
  String origin;
  final List<String> aliases = [];
  Map<String, Object?>? provenance;

  String get identity => SchoolNameCanon.identityKey(name, city);

  void addAliases(Iterable<String> values) {
    final known = {
      SchoolNameCanon.fold(name),
      ...aliases.map(SchoolNameCanon.fold),
    };
    for (final value in values) {
      final alias = value.trim();
      if (alias.isEmpty) continue;
      if (known.add(SchoolNameCanon.fold(alias))) aliases.add(alias);
    }
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'aliases': aliases,
    'city': city,
    'region': region,
    'district': district,
    'ownership': ownership?.name,
    'track': track?.name,
    'language': language?.name,
    'type': type?.name,
    'origin': origin,
    'provenance': provenance,
  };
}

/// Un rapprochement que la machine ne tranche pas : à relire par un humain.
class ReviewSignal {
  const ReviewSignal(this.a, this.b, this.reason);

  final DirectoryEntry a;
  final DirectoryEntry b;
  final String reason;
}

class DirectoryBuild {
  DirectoryBuild({
    required this.entries,
    required this.legacyMatches,
    required this.signals,
    required this.sourceRows,
  });

  final List<DirectoryEntry> entries;

  /// Identifiant INTELLIA existant → ligne de la Base maîtresse reconnue.
  final Map<String, MasterRow> legacyMatches;
  final List<ReviewSignal> signals;
  final int sourceRows;
}

/// Union contrôlée : catalogue existant, Base maîtresse, compléments.
///
/// Ordre de résolution : identifiant existant, nom canonique + ville, nom
/// canonique + arrondissement, alias explicite. Une ressemblance approchée
/// n'est qu'un signal : elle ne fusionne jamais.
DirectoryBuild buildDirectory({
  required List<MasterRow> master,
  required List<Establishment> legacy,
  required Map<String, Object?> additions,
}) {
  final cityRegions = {
    for (final entry in (additions['cityRegions'] as Map? ?? const {}).entries)
      entry.key as String: entry.value as String,
  };
  final entries = <DirectoryEntry>[];
  final byIdentity = <String, DirectoryEntry>{};
  final ids = <String>{};

  // A. Le catalogue existant : ses identifiants ne changent jamais.
  for (final school in legacy) {
    final entry = DirectoryEntry(
      id: school.id,
      name: school.officialName,
      city: school.city,
      region: school.region,
      origin: 'legacy',
      language: school.subsystem,
      type: school.type,
      aliases: school.aliases,
    );
    entries.add(entry);
    ids.add(entry.id);
    byIdentity.putIfAbsent(entry.identity, () => entry);
  }

  // B. La Base maîtresse.
  final legacyMatches = <String, MasterRow>{};
  for (final row in master) {
    final key = SchoolNameCanon.identityKey(row.name, row.city);
    final district = _known(row.district);
    final existing =
        byIdentity[key] ??
        (district == null
            ? null
            : entries
                  .where(
                    (e) =>
                        e.district == district &&
                        SchoolNameCanon.canonical(e.name, city: e.city) ==
                            SchoolNameCanon.canonical(row.name, city: row.city),
                  )
                  .firstOrNull);
    final region = cityRegions[row.city];
    if (existing != null && existing.origin == 'legacy') {
      legacyMatches[existing.id] = row;
      final legacyName = existing.name;
      existing
        ..name = row.name
        ..city = row.city
        ..region = existing.region ?? region
        ..origin = 'reference+legacy';
      _applyRow(existing, row);
      existing.addAliases([
        legacyName,
        ...SchoolNameCanon.parentheticals(row.name),
      ]);
      continue;
    }
    if (existing != null) {
      // Même établissement écrit deux fois dans la source : une seule entrée.
      existing.addAliases([
        row.name,
        ...SchoolNameCanon.parentheticals(row.name),
      ]);
      continue;
    }
    final entry = DirectoryEntry(
      id: _uniqueId(_idFor(row.name, row.city, region), ids),
      name: row.name,
      city: row.city,
      region: region,
      origin: 'reference',
      aliases: SchoolNameCanon.parentheticals(row.name),
    );
    _applyRow(entry, row);
    entries.add(entry);
    ids.add(entry.id);
    byIdentity[entry.identity] = entry;
  }

  // C. Alias explicites du propriétaire, sur des établissements existants.
  for (final raw in additions['aliases'] as List? ?? const []) {
    final spec = raw as Map;
    final key = SchoolNameCanon.identityKey(
      spec['name'] as String,
      spec['city'] as String?,
    );
    final target = byIdentity[key];
    if (target == null) {
      throw StateError('Alias sans établissement : ${spec['name']}');
    }
    target.addAliases((spec['aliases'] as List).cast<String>());
  }

  // D. Établissements ajoutés par le propriétaire, s'ils n'existent pas déjà.
  for (final raw in additions['additions'] as List? ?? const []) {
    final spec = raw as Map;
    final name = spec['name'] as String;
    final city = spec['city'] as String?;
    final aliases = (spec['aliases'] as List? ?? const []).cast<String>();
    final key = SchoolNameCanon.identityKey(name, city);
    final existing =
        byIdentity[key] ??
        entries
            .where(
              (e) =>
                  e.city == city &&
                  e.aliases.any(
                    (a) =>
                        SchoolNameCanon.canonical(a) ==
                        SchoolNameCanon.canonical(name),
                  ),
            )
            .firstOrNull;
    if (existing != null) {
      existing.addAliases([name, ...aliases]);
      continue;
    }
    final provenance = spec['provenance'] as Map?;
    final entry = DirectoryEntry(
      id: _uniqueId(spec['id'] as String, ids),
      name: name,
      city: city,
      region: city == null ? null : cityRegions[city],
      district: spec['district'] as String?,
      language: _enum(EstablishmentSubsystem.values, spec['language']),
      type: _typeFor(name, null),
      origin: 'owner',
      aliases: aliases,
      provenance: provenance == null
          ? null
          : {
              'source': provenance['source'],
              'confidence': provenance['confidence'],
            },
    );
    entries.add(entry);
    ids.add(entry.id);
    byIdentity[entry.identity] = entry;
  }

  entries.sort(
    (a, b) =>
        [
              SchoolNameCanon.fold(a.region ?? '~'),
              SchoolNameCanon.fold(a.city ?? '~'),
              SchoolNameCanon.fold(a.name),
              a.id,
            ]
            .join('|')
            .compareTo(
              [
                SchoolNameCanon.fold(b.region ?? '~'),
                SchoolNameCanon.fold(b.city ?? '~'),
                SchoolNameCanon.fold(b.name),
                b.id,
              ].join('|'),
            ),
  );
  return DirectoryBuild(
    entries: entries,
    legacyMatches: legacyMatches,
    signals: _signals(entries),
    sourceRows: master.length,
  );
}

/// Catalogue JSON versionné, prêt pour `assets/`.
String directoryToJson(
  DirectoryBuild build, {
  required String version,
  required String sourceFile,
  required String sourceSha256,
}) {
  final byCity = <String, int>{};
  for (final entry in build.entries) {
    byCity.update(entry.city ?? '', (n) => n + 1, ifAbsent: () => 1);
  }
  return '${const JsonEncoder.withIndent('  ').convert({
    'schema': 'intellia.establishments.v1',
    'version': version,
    'sources': [
      {'file': sourceFile, 'sheet': masterSheet, 'sha256': sourceSha256, 'rows': build.sourceRows},
      {'file': 'tool/establishments/sources/owner_additions_2026_09.json'},
      {'catalogue': 'EstablishmentCatalog (INTELLIA237)', 'matchedIds': build.legacyMatches.keys.toList()..sort()},
    ],
    'count': build.entries.length,
    'establishments': [for (final entry in build.entries) entry.toJson()],
  })}\n';
}

/// Rapport de relecture : les rapprochements laissés à un humain.
String reviewReport(DirectoryBuild build) {
  final buffer = StringBuffer()
    ..writeln('# Établissements — rapprochements à relire')
    ..writeln()
    ..writeln(
      'Généré par `tool/establishments/import_master_catalog.dart`. Aucune de '
      'ces paires n\'a été fusionnée : la ressemblance est un signal, jamais '
      'une preuve.',
    )
    ..writeln()
    ..writeln('| Établissement A | Établissement B | Ville | Signal |')
    ..writeln('|---|---|---|---|');
  for (final signal in build.signals) {
    buffer.writeln(
      '| ${signal.a.name} (`${signal.a.id}`) | ${signal.b.name} '
      '(`${signal.b.id}`) | ${signal.a.city ?? '—'} | ${signal.reason} |',
    );
  }
  return buffer.toString();
}

void _applyRow(DirectoryEntry entry, MasterRow row) {
  entry
    ..district = _known(row.district)
    ..ownership = switch (row.status) {
      'Public' => EstablishmentOwnership.public,
      'Privé' => EstablishmentOwnership.private,
      _ => null,
    }
    ..track = switch (row.track) {
      'Général' => EstablishmentTrack.general,
      'Technique' ||
      'Technique / professionnel' => EstablishmentTrack.technical,
      'Polyvalent' => EstablishmentTrack.polyvalent,
      _ => null,
    }
    // « Bilingue / anglophone » : la source hésite, la langue reste inconnue.
    ..language = switch (row.language) {
      'Francophone' => EstablishmentSubsystem.francophone,
      'Bilingue' => EstablishmentSubsystem.bilingual,
      'Trilingue' => EstablishmentSubsystem.trilingual,
      'Anglophone' => EstablishmentSubsystem.anglophone,
      _ => null,
    };
  entry
    ..type = _typeFor(row.name, entry.ownership)
    ..provenance = {
      'source': row.source,
      'confidence': switch (row.confidence) {
        'Élevé' => 'high',
        'Moyen' => 'medium',
        _ => 'medium',
      },
      'url': row.url.isEmpty ? null : row.url,
      'line': row.line,
      if (_known(row.language) == null || row.language.contains('/'))
        'languageNote': row.language,
    };
}

String? _known(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty || SchoolNameCanon.fold(trimmed) == 'a confirmer'
      ? null
      : trimmed;
}

/// Type déduit du nom seul (« Lycée… », « Collège… », « CETIC… »).
EstablishmentType _typeFor(String name, EstablishmentOwnership? ownership) {
  final words = SchoolNameCanon.tokens(name);
  final first = words.firstOrNull ?? '';
  if (words.contains('technique') ||
      first == 'cetic' ||
      first == 'cetif' ||
      first == 'cet') {
    return EstablishmentType.technicalSchool;
  }
  if (first == 'lycee') return EstablishmentType.lycee;
  if (first == 'college' || first == 'ces' || first == 'cebnb') {
    return EstablishmentType.college;
  }
  return ownership == EstablishmentOwnership.public
      ? EstablishmentType.governmentHighSchool
      : EstablishmentType.privateSecondarySchool;
}

T? _enum<T extends Enum>(List<T> values, Object? name) =>
    values.where((value) => value.name == name).firstOrNull;

String _idFor(String name, String city, String? region) {
  final prefix = switch (region) {
    'Centre' => 'ce',
    'Littoral' => 'lt',
    _ => 'cm',
  };
  var slug = SchoolNameCanon.canonical(name, city: city).replaceAll(' ', '-');
  if (slug.length > 56) {
    slug = slug.substring(0, 56).replaceAll(RegExp(r'-$'), '');
  }
  return '$prefix-${SchoolNameCanon.fold(city).replaceAll(' ', '-')}-$slug';
}

String _uniqueId(String base, Set<String> taken) {
  if (!taken.contains(base)) return base;
  var index = 2;
  while (taken.contains('$base-$index')) {
    index++;
  }
  return '$base-$index';
}

/// Paires d'une même ville dont les noms ne diffèrent que par un
/// qualificatif (« Bilingue », « TSF »…) ou d'une faute : jamais fusionnées.
List<ReviewSignal> _signals(List<DirectoryEntry> entries) {
  final signals = <ReviewSignal>[];
  final byCity = <String, List<DirectoryEntry>>{};
  for (final entry in entries) {
    byCity
        .putIfAbsent(SchoolNameCanon.fold(entry.city ?? ''), () => [])
        .add(entry);
  }
  for (final group in byCity.values) {
    for (var i = 0; i < group.length; i++) {
      for (var j = i + 1; j < group.length; j++) {
        final a = group[i];
        final b = group[j];
        final ta = SchoolNameCanon.canonical(
          a.name,
          city: a.city,
        ).split(' ').toSet();
        final tb = SchoolNameCanon.canonical(
          b.name,
          city: b.city,
        ).split(' ').toSet();
        final small = ta.length <= tb.length ? ta : tb;
        final large = ta.length <= tb.length ? tb : ta;
        final distinctive = small.difference(_generic);
        final extra = large.difference(small);
        if (distinctive.isNotEmpty &&
            large.containsAll(small) &&
            extra.isNotEmpty &&
            extra.length <= 2 &&
            // « Lycée » et « Lycée technique » d'un même lieu : deux
            // établissements distincts, pas une variante d'écriture.
            !extra.every(_distinctKinds.contains)) {
          signals.add(
            ReviewSignal(
              a,
              b,
              'mêmes mots, plus « ${large.difference(small).join(' ')} »',
            ),
          );
        }
      }
    }
  }
  return signals;
}

/// Mots qui font de deux établissements des établissements différents.
const _distinctKinds = {'technique', 'industriel', 'commercial', 'agricole'};

/// Mots trop génériques pour rapprocher deux noms à eux seuls.
const _generic = {
  'lycee', 'college', 'bilingue', 'bilingual', 'technique', 'prive', //
  'privee', 'laic', 'laique', 'catholique', 'protestant', 'islamique',
  'institut', 'complexe', 'scolaire', 'groupe', 'general', 'ecole',
  'enseignement', 'secondaire', 'international', 'academy', 'school',
  'high', 'comprehensive', 'polyvalent', 'industriel', 'commercial',
};
