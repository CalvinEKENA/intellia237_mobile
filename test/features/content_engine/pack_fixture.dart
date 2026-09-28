import 'dart:convert';
import 'dart:io';

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/content_engine/application/subject_journey.dart';

import 'package:intellia237/features/content_engine/data/content_delivery.dart';
import 'package:intellia237/features/content_engine/data/content_pack_parser.dart';
import 'package:intellia237/features/content_engine/data/content_pack_repository.dart';
import 'package:intellia237/features/content_engine/domain/chapter.dart';
import 'package:intellia237/features/learn/application/learn_providers.dart';
import 'package:intellia237/features/learn/domain/learn_academic_context.dart';
import 'package:intellia237/features/learn/domain/learn_hub_snapshot.dart';

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

/// Aucun réseau : le catalogue distant est inaccessible.
class OfflineGateway implements RemoteContentGateway {
  const OfflineGateway();

  @override
  Future<Uint8List?> fetchCatalog() async => null;

  @override
  Future<Uint8List> fetchBundle(String path) =>
      Future.error(StateError('hors ligne'));
}

/// Attend que les parcours par matière soient calculés.
///
/// Le conteneur vit dans le temps simulé du test : sa réponse n'arrive qu'au
/// prochain `pump`. On alterne donc une vraie attente (lecture des packs sur
/// disque) et un `pump`, sans jamais attendre `.future` dans `runAsync`.
Future<void> settleSubjectJourneys(
  WidgetTester tester,
  ProviderContainer container,
) async {
  for (var i = 0; i < 100; i++) {
    if (container.read(subjectJourneysProvider).hasValue) break;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  expect(container.read(subjectJourneysProvider).hasValue, isTrue);
  await tester.pump();
}

/// Catalogue en ligne vide : le Hall d'Apprendre ne montre que les
/// matières des packs, sans jamais toucher au réseau.
Override emptyLearnCatalogue() => learnHubProvider.overrideWith(
  (ref) async => const LearnHubSnapshot(
    context: LearnAcademicContext(classLevel: 'Terminale', series: 'D'),
    subjects: [],
  ),
);
