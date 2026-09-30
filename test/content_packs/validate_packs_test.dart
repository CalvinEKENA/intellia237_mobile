import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/content_engine/data/content_pack_parser.dart';
import 'package:intellia237/features/content_engine/domain/content_issue.dart';

import '../../tool/content/pack_bundle_builder.dart';

/// Validation d'un pack avec le moteur de l'application, avant publication.
///
/// Par défaut : tous les packs embarqués. Pour un pack à publier :
///   CONTENT_PACK_DIR=chemin/du/pack flutter test test/content_packs
void main() {
  final extra = Platform.environment['CONTENT_PACK_DIR'];
  final directories = [
    if (extra != null && extra.isNotEmpty) Directory(extra),
    for (final entity in Directory('assets/content').listSync(recursive: true))
      if (entity is File &&
          entity.path.replaceAll(r'\', '/').endsWith('/manifest.json'))
        entity.parent,
  ];

  for (final directory in directories) {
    test('pack publiable : ${directory.path}', () {
      final docs = readPackDocuments(directory);
      final chapter = const ContentPackParser().parse(
        RawContentPack(
          directory: directory.path,
          manifest: docs['manifest']!,
          source: docs['source'],
          pedagogy: docs['pedagogy'],
          runtime: docs['runtime'],
          validation: docs['validation'],
        ),
      );
      for (final issue in chapter.issues) {
        // ignore: avoid_print
        print(issue);
      }
      expect(chapter.isPlayable, isTrue, reason: 'Pack non publiable.');
      expect(
        chapter.issues.where((i) => i.severity == ContentIssueSeverity.error),
        isEmpty,
        reason: chapter.issues.join('\n'),
      );
      expect(chapter.lessons, isNotEmpty);
      expect(chapter.questions.where((q) => q.autoScorable), isNotEmpty);
    });
  }
}
