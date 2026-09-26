// Prépare la publication d'un pack, sans rien envoyer.
//
// dart run tool/content/publish_pack.dart \
//   --pack assets/content/terminale_d/mathematiques/ch01_arithmetique \
//   --id maths_td_ch01_arithmetique --version 1 --class terminale-d \
//   [--class terminale-c] [--catalog build/content_publish/catalog.json]
//
// Produit dans build/content_publish/ :
//   * packs/<id>/v<version>/bundle.json (octets exacts à téléverser) ;
//   * catalog.json (catalogue mis à jour) ;
// puis affiche les commandes de téléversement. La validation pédagogique se
// fait avant, avec le moteur de l'application (voir la documentation).

import 'dart:convert';
import 'dart:io';

import 'pack_bundle_builder.dart';

void main(List<String> args) {
  String? value(String name) {
    final index = args.indexOf(name);
    return index >= 0 && index + 1 < args.length ? args[index + 1] : null;
  }

  final classes = <String>[
    for (var i = 0; i < args.length - 1; i++)
      if (args[i] == '--class') args[i + 1],
  ];
  final packDir = value('--pack');
  final id = value('--id');
  final version = int.tryParse(value('--version') ?? '');
  if (packDir == null || id == null || version == null || classes.isEmpty) {
    stderr.writeln(
      'Usage : --pack <dossier> --id <id> --version <n> --class <classe> '
      '[--class <classe>] [--catalog <catalog.json>] [--status draft]',
    );
    exitCode = 64;
    return;
  }

  final documents = readPackDocuments(Directory(packDir));
  final bundle = buildPackBundle(
    id: id,
    version: version,
    classKeys: classes,
    documents: documents,
  );
  final encoded = encodeBundle(bundle);
  final out = Directory('build/content_publish')..createSync(recursive: true);
  final bundleFile =
      File(
          '${out.path}/${bundlePath(id, version).replaceFirst('content/', '')}',
        )
        ..createSync(recursive: true)
        ..writeAsBytesSync(encoded.bytes);

  final curriculum =
      (documents['runtime']?['curriculum'] as Map?) ??
      (documents['source']?['curriculum'] as Map?);
  // Version de moteur exigée par le pack : une application plus ancienne
  // ne téléchargera jamais un bundle qu'elle ne saurait pas lire.
  final minimumEngine = [
    1,
    (documents['manifest']?['minimum_engine_version'] as num?)?.toInt() ?? 0,
    (documents['runtime']?['engine_version_required'] as num?)?.toInt() ?? 0,
  ].reduce((a, b) => a > b ? a : b);
  final catalogPath = value('--catalog') ?? '${out.path}/catalog.json';
  final catalogFile = File(catalogPath);
  final previous = catalogFile.existsSync()
      ? jsonDecode(catalogFile.readAsStringSync()) as Map<String, Object?>
      : null;
  final catalog = upsertCatalog(
    previous,
    catalogEntry(
      id: id,
      version: version,
      classKeys: classes,
      sha256: encoded.sha256,
      sizeBytes: encoded.bytes.length,
      status: value('--status') ?? 'published',
      subject: curriculum?['subject'] as String?,
      chapterTitle:
          (curriculum?['chapter_title'] ??
                  curriculum?['unit_title'] ??
                  curriculum?['sequence_title'])
              as String?,
      minimumEngineVersion: minimumEngine,
    ),
  );
  File(
    '${out.path}/catalog.json',
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(catalog));

  stdout
    ..writeln('Bundle   : ${bundleFile.path}')
    ..writeln('SHA-256  : ${encoded.sha256}')
    ..writeln('Taille   : ${encoded.bytes.length} octets')
    ..writeln('Moteur   : v$minimumEngine minimum')
    ..writeln(
      'Catalogue: ${out.path}/catalog.json '
      '(version ${catalog['catalog_version']})',
    )
    ..writeln()
    ..writeln('Téléversement (avec accord du propriétaire) :')
    ..writeln(
      '  gcloud storage cp "${bundleFile.path}" '
      'gs://edunova-aabd1.firebasestorage.app/${bundlePath(id, version)} '
      '--content-type=application/json',
    )
    ..writeln(
      '  gcloud storage cp "${out.path}/catalog.json" '
      'gs://edunova-aabd1.firebasestorage.app/content/catalog.json '
      '--content-type=application/json --cache-control=no-cache',
    );
}
