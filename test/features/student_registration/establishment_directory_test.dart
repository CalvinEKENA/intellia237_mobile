import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/student_registration/application/school_directory.dart';
import 'package:intellia237/features/student_registration/data/establishment_catalog.dart';
import 'package:intellia237/features/student_registration/data/reference_establishment_catalog.dart';
import 'package:intellia237/features/student_registration/domain/establishment.dart';
import 'package:intellia237/features/student_registration/domain/school_name_canon.dart';

import '../../../tool/establishments/catalog_builder.dart';
import '../../../tool/establishments/import_master_catalog.dart';
import '../../../tool/establishments/xlsx_reader.dart';

void main() {
  final catalog = ReferenceEstablishmentCatalog.parse(
    File(referenceCatalogAsset).readAsStringSync(),
  );

  List<Establishment> named(String name) => [
    for (final school in catalog)
      if (SchoolNameCanon.fold(school.officialName) ==
          SchoolNameCanon.fold(name))
        school,
  ];

  String first(String query) =>
      EstablishmentSearch.query(query, catalog: catalog).first.establishment.id;

  group('Base maîtresse', () {
    final workbook = XlsxWorkbook.read(File(defaultXlsx).readAsBytesSync());
    final master = MasterRow.fromSheet(workbook.sheets[masterSheet]!);

    test('only the master sheet is imported: 250 rows, 118 + 132', () {
      expect(workbook.sheets.keys, contains(masterSheet));
      expect(workbook.sheets.length, greaterThan(1));
      expect(master, hasLength(250));
      final byCity = <String, int>{};
      for (final row in master) {
        byCity.update(row.city, (n) => n + 1, ifAbsent: () => 1);
      }
      expect(byCity, {'Yaoundé': 118, 'Douala': 132});
    });

    test('the versioned files are exactly what the importer produces', () {
      final output = runImport();
      for (final entry in output.files.entries) {
        expect(
          File(entry.key).readAsStringSync(),
          entry.value,
          reason: '${entry.key} : relancer import_master_catalog.dart',
        );
      }
      expect(output.build.sourceRows, 250);
    });
  });

  group('reference catalogue', () {
    test('unique ids and unique canonical name + city', () {
      expect(catalog.map((s) => s.id).toSet(), hasLength(catalog.length));
      final identities = [
        for (final school in catalog)
          SchoolNameCanon.identityKey(school.officialName, school.city),
      ];
      expect(identities.toSet(), hasLength(identities.length));
      expect(catalog.where((s) => s.isPartner), isEmpty);
    });

    test('keeps every historical id and covers the two cities', () {
      final ids = catalog.map((s) => s.id).toSet();
      for (final legacy in EstablishmentCatalog.all) {
        expect(ids, contains(legacy.id));
      }
      final yaounde = catalog.where((s) => s.city == 'Yaoundé').length;
      final douala = catalog.where((s) => s.city == 'Douala').length;
      expect(yaounde, greaterThanOrEqualTo(118));
      expect(douala, greaterThanOrEqualTo(132));
    });

    test('Marie Albert exists once, under its official name', () {
      final comal = catalog
          .where((s) => s.officialName.contains('Marie Albert'))
          .toList();
      expect(comal, hasLength(1));
      expect(
        comal.single.officialName,
        'Collège Privé Laïc Marie Albert II (COMAL II)',
      );
      expect(comal.single.city, 'Yaoundé');
      for (final query in [
        'Collège MARIE-ALBERT',
        'Marie Albert',
        'Marie-Albert',
        'marie albert 2',
        'COMAL',
        'comal ii',
      ]) {
        expect(first(query), comal.single.id, reason: query);
      }
    });

    test(
      'MBOHMELITES BILINGUAL COLLEGE: Yaoundé VII, found by its aliases',
      () {
        final school = named('MBOHMELITES BILINGUAL COLLEGE').single;
        expect(school.city, 'Yaoundé');
        expect(school.district, 'Yaoundé VII');
        expect(school.provenance?.confidence, EstablishmentConfidence.declared);
        for (final query in ['MBOHM', 'mbohmelites', 'Mbohm Elites']) {
          final results = EstablishmentSearch.query(query, catalog: catalog);
          expect(results.first.establishment.id, school.id, reason: query);
          expect(results.first.isDominant, isTrue, reason: query);
        }
      },
    );

    test('Collège LE SAVOIR: exact name, unknown metadata left empty', () {
      final school = named('Collège LE SAVOIR').single;
      expect(school.officialName, 'Collège LE SAVOIR');
      expect(school.city, isEmpty);
      expect(school.region, isEmpty);
      expect(school.district, isNull);
      expect(school.subsystem, isNull);
      expect(school.ownership, isNull);
      expect(first('Le Savoir'), school.id);
      expect(first('college le savoir'), school.id);
    });

    test('Échos du Savoir stays distinct; Le Savoir Plus is not invented', () {
      final echos = named('Collège Bilingue Échos du Savoir').single;
      final savoir = named('Collège LE SAVOIR').single;
      expect(echos.id, isNot(savoir.id));
      expect(echos.city, 'Douala');
      expect(echos.aliases, isNot(contains('Le Savoir')));
      expect(first('Echos du Savoir'), echos.id);
      expect(
        catalog.where(
          (s) => SchoolNameCanon.fold(s.officialName).contains('savoir plus'),
        ),
        isEmpty,
      );
    });
  });

  group('local search', () {
    test('accents, hyphens, apostrophes and missing spaces', () {
      expect(first('Lecl'), 'ce-yaounde-leclerc');
      expect(first('Ngoa Ekelle'), 'ce-yaounde-ngoa-ekelle');
      expect(first('ngoa-ekellé'), 'ce-yaounde-ngoa-ekelle');
      expect(
        first('Lycée Bilingue d’Application'),
        'ce-yaounde-bilingue-application',
      );
      expect(
        first("lycee bilingue d'application"),
        'ce-yaounde-bilingue-application',
      );
      expect(
        first('lycée bilingue nkolbisson'),
        'ce-yaounde-lycee-bilingue-nkolbisson',
      );
      expect(
        first('bilingue nkol bisson'),
        'ce-yaounde-lycee-bilingue-nkolbisson',
      );
      expect(first('LYCEE GENERAL LECLERC'), 'ce-yaounde-leclerc');
    });

    test('light typos and words in any order', () {
      expect(first('leclrc'), 'ce-yaounde-leclerc');
      expect(first('leclerc yaounde'), 'ce-yaounde-leclerc');
      expect(
        first('nkolbison bilingue lycee'),
        'ce-yaounde-lycee-bilingue-nkolbisson',
      );
    });

    test('district and city narrow the list', () {
      final district = EstablishmentSearch.query(
        'Yaoundé VII',
        catalog: catalog,
        limit: 400,
      );
      expect(district, isNotEmpty);
      expect(
        district.take(5).map((r) => r.establishment.district),
        everyElement('Yaoundé VII'),
      );
      final douala = EstablishmentSearch.query('Douala', catalog: catalog);
      expect(douala.map((r) => r.establishment.city), everyElement('Douala'));
    });

    test('highlights the matching part of the displayed name', () {
      final result = EstablishmentSearch.query(
        'ngoaekelle',
        catalog: catalog,
      ).first;
      expect(
        result.establishment.officialName.substring(
          result.highlightStart,
          result.highlightEnd,
        ),
        'Ngoa-Ekellé',
      );
      expect(
        EstablishmentSearch.highlight('Lycée Général Leclerc', 'general'),
        (6, 13),
      );
      expect(EstablishmentSearch.highlight('Lycée de Tibati', 'xyz'), (0, 0));
    });

    test('broad prefixes rank without a false dominant result', () {
      final broad = EstablishmentSearch.query('Lycée', catalog: catalog);
      expect(broad, hasLength(8));
      expect(broad.first.isDominant, isFalse);
    });

    test('results are deterministic', () {
      List<String> ids() => EstablishmentSearch.query(
        'college',
        catalog: catalog,
        limit: 50,
      ).map((r) => r.establishment.id).toList();
      expect(ids(), orderedEquals(ids()));
    });
  });

  group('unified directory', () {
    Establishment partner(String id, String name, String city) => Establishment(
      id: id,
      officialName: name,
      normalizedName: EstablishmentSearch.normalize(name),
      aliases: const [],
      region: '',
      city: city,
      type: EstablishmentType.lycee,
      subsystem: null,
      educationTypes: EstablishmentEducationType.values,
      status: EstablishmentCatalogStatus.active,
      isPartner: true,
    );

    test('a server partner is merged by exact identity, never fuzzily', () {
      final directory = SchoolDirectory.merge(
        reference: catalog,
        partners: [
          partner('srv-leclerc', 'Lycée Général LECLERC', 'Yaoundé'),
          partner('srv-new', 'Lycée Partenaire Nouveau', 'Bafoussam'),
          // Proche d'un établissement du catalogue, mais pas identique.
          partner('srv-near', 'Lycée Général Leclerc Annexe', 'Yaoundé'),
        ],
      );
      expect(directory.schools, hasLength(catalog.length + 2));
      final leclerc = directory.byId('srv-leclerc')!;
      expect(leclerc.isPartner, isTrue);
      expect(leclerc.referenceId, 'ce-yaounde-leclerc');
      expect(leclerc.officialName, 'Lycée Général Leclerc');
      expect(leclerc.district, 'Yaoundé III');
      expect(directory.byId('ce-yaounde-leclerc'), isNull);
      expect(directory.byId('srv-new')!.isPartner, isTrue);
      expect(directory.byId('srv-near')!.referenceId, isNull);
      expect(
        directory.schools.where((s) => s.isPartner).map((s) => s.id),
        unorderedEquals(['srv-leclerc', 'srv-new', 'srv-near']),
      );
    });

    test('offline, the reference catalogue stays complete, without badge', () {
      final directory = SchoolDirectory.merge(
        reference: catalog,
        partnersPending: true,
      );
      expect(directory.schools, hasLength(catalog.length));
      expect(directory.schools.where((s) => s.isPartner), isEmpty);
      expect(directory.topCities(), ['Douala', 'Yaoundé']);
    });
  });
}
