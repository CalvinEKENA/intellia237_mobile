import 'dart:convert';
import 'dart:io';

import 'package:intellia237/features/content_engine/data/content_pack_parser.dart';
import 'package:intellia237/features/content_engine/data/content_pack_repository.dart';
import 'package:intellia237/features/content_engine/domain/chapter.dart';

/// Le pack pilote, lu tel qu'il est versionné (jamais modifié par les tests).
const pilotDirectory =
    'assets/content/terminale_d/mathematiques/ch01_arithmetique';

Map<String, Object?> readPackJson(String file, {String? directory}) =>
    jsonDecode(File('${directory ?? pilotDirectory}/$file').readAsStringSync())
        as Map<String, Object?>;

RawContentPack pilotRaw() => RawContentPack(
  directory: pilotDirectory,
  manifest: readPackJson('manifest.json'),
  source: readPackJson('source.json'),
  pedagogy: readPackJson('pedagogy.json'),
  runtime: readPackJson('runtime.json'),
  validation: readPackJson('validation_report.json'),
);

Chapter pilotChapter() => const ContentPackParser().parse(pilotRaw());

/// Copie profonde et modifiable d'un document JSON (pour fabriquer des cas
/// invalides sans toucher au fichier source).
Map<String, Object?> deepCopy(Map<String, Object?> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, Object?>;

/// Source de packs lue sur le disque, sans bundle ni réseau.
class DiskContentPackSource implements ContentPackSource {
  DiskContentPackSource({this.root = 'assets/content'});

  final String root;
  final reads = <String>[];

  @override
  Future<List<String>> packDirectories() async => [
    for (final entity in Directory(root).listSync(recursive: true))
      if (entity is File &&
          entity.path.replaceAll('\\', '/').endsWith('/manifest.json'))
        entity.parent.path.replaceAll('\\', '/'),
  ]..sort();

  @override
  Future<String?> read(String path) async {
    reads.add(path);
    final file = File(path);
    return file.existsSync() ? file.readAsStringSync() : null;
  }
}
