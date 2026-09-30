// Import déterministe du catalogue des établissements.
//
// Usage, depuis la racine du dépôt :
//   dart run tool/establishments/import_master_catalog.dart
//   dart run tool/establishments/import_master_catalog.dart --xlsx <classeur>
//   dart run tool/establishments/import_master_catalog.dart --check
//
// Lit la seule feuille « Base maîtresse » du classeur (les feuilles par ville
// en sont des vues), écrit l'instantané CSV de la source, puis le catalogue
// versionné (union du catalogue existant, de la Base maîtresse et des
// compléments du propriétaire) et le rapport des rapprochements à relire.
// `--check` échoue si les fichiers versionnés ne correspondent plus.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:intellia237/features/student_registration/data/establishment_catalog.dart';

import 'catalog_builder.dart';
import 'xlsx_reader.dart';

const defaultXlsx =
    'tool/establishments/sources/base_maitresse_lycees_colleges_yaounde_douala_2026_09.xlsx';
const csvSnapshot = 'tool/establishments/sources/base_maitresse_2026_09.csv';
const additionsFile =
    'tool/establishments/sources/owner_additions_2026_09.json';
const catalogAsset =
    'assets/data/establishments/cameroon_secondary_2026_09.json';
const reviewFile = 'tool/establishments/reports/review_signals_2026_09.md';
const catalogVersion = 'cm-secondary-2026.09-master';

/// Résultat de l'import : les trois fichiers générés, par chemin.
class ImportOutput {
  ImportOutput(this.files, this.build);
  final Map<String, String> files;
  final DirectoryBuild build;
}

ImportOutput runImport({String xlsx = defaultXlsx}) {
  final bytes = File(xlsx).readAsBytesSync();
  final workbook = XlsxWorkbook.read(bytes);
  final sheet = workbook.sheets[masterSheet];
  if (sheet == null) throw StateError('Feuille « $masterSheet » absente.');
  final master = MasterRow.fromSheet(sheet);
  final additions =
      jsonDecode(File(additionsFile).readAsStringSync())
          as Map<String, Object?>;
  final build = buildDirectory(
    master: master,
    legacy: EstablishmentCatalog.all,
    additions: additions,
  );
  return ImportOutput({
    csvSnapshot: '${masterRowsToCsv(master)}\n',
    catalogAsset: directoryToJson(
      build,
      version: catalogVersion,
      sourceFile: xlsx.split('/').last,
      sourceSha256: sha256.convert(bytes).toString(),
    ),
    reviewFile: reviewReport(build),
  }, build);
}

void main(List<String> args) {
  String? value(String name) {
    final index = args.indexOf(name);
    return index >= 0 && index + 1 < args.length ? args[index + 1] : null;
  }

  final output = runImport(xlsx: value('--xlsx') ?? defaultXlsx);
  if (args.contains('--check')) {
    final stale = [
      for (final entry in output.files.entries)
        if (!File(entry.key).existsSync() ||
            File(entry.key).readAsStringSync() != entry.value)
          entry.key,
    ];
    if (stale.isNotEmpty) {
      stderr.writeln('À régénérer : ${stale.join(', ')}');
      exitCode = 1;
    } else {
      stdout.writeln('Catalogue à jour.');
    }
    return;
  }
  for (final entry in output.files.entries) {
    File(entry.key)
      ..createSync(recursive: true)
      ..writeAsStringSync(entry.value);
  }
  final build = output.build;
  final byCity = <String, int>{};
  for (final entry in build.entries) {
    byCity.update(
      entry.city ?? '(ville à confirmer)',
      (n) => n + 1,
      ifAbsent: () => 1,
    );
  }
  stdout
    ..writeln('Lignes Base maîtresse : ${build.sourceRows}')
    ..writeln('Établissements : ${build.entries.length}')
    ..writeln(
      'Yaoundé : ${byCity['Yaoundé'] ?? 0} · Douala : ${byCity['Douala'] ?? 0}',
    )
    ..writeln(
      'Reconnus dans le catalogue existant : ${build.legacyMatches.length}',
    )
    ..writeln('Rapprochements à relire : ${build.signals.length}');
}
