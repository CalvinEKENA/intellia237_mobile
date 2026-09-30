import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/core/assets/intellia_assets.dart';

/// Garde-fou du clip du lancement INTELLIA AWAKENS : un fichier de
/// production, léger, sans son, déclaré, et rien d'autre dans son dossier.
void main() {
  const directory = 'assets/branding/cinematic/';

  /// Plafond : le clip validé pèse 357 404 octets ; au-delà de 400 Ko, c'est
  /// un autre fichier qui a été posé, à revoir avec le propriétaire.
  const budgetBytes = 400 * 1024;

  late File clip;
  late List<int> bytes;

  setUpAll(() {
    clip = File(IntelliaBrandAssets.launchMatter);
    bytes = clip.existsSync() ? clip.readAsBytesSync() : const [];
  });

  test('le clip est là, dans le dossier de production', () {
    expect(IntelliaBrandAssets.launchMatter, startsWith(directory));
    expect(clip.existsSync(), isTrue);
  });

  test('le poids reste dans le budget', () {
    expect(bytes, isNotEmpty);
    expect(bytes.length, lessThanOrEqualTo(budgetBytes));
  });

  test('c’est un MP4 H.264 sans piste audio', () {
    expect(String.fromCharCodes(bytes.sublist(4, 8)), 'ftyp');
    final text = String.fromCharCodes(bytes);
    expect(text, contains('avc1'), reason: 'H.264');
    expect(text, isNot(contains('mp4a')), reason: 'aucun son');
    expect(text, isNot(contains('hvc1')));
  });

  test('le clip de la traversée Authentification → Home : léger, sans son, '
      'de 0,8 s', () {
    const asset = IntelliaBrandAssets.authHomeMatter;
    expect(asset, startsWith(directory));
    final file = File(asset);
    expect(file.existsSync(), isTrue);
    final data = file.readAsBytesSync();
    // 239 410 octets ; au-delà de 300 Ko, c'est un autre fichier.
    expect(data.length, lessThanOrEqualTo(300 * 1024));
    expect(String.fromCharCodes(data.sublist(4, 8)), 'ftyp');
    final text = String.fromCharCodes(data);
    expect(text, contains('avc1'), reason: 'H.264');
    expect(text, isNot(contains('mp4a')), reason: 'aucun son');
    expect(text, isNot(contains('hvc1')));
    expect(asset, isNot(equals(IntelliaBrandAssets.launchMatter)));
  });

  test('le dossier ne contient que les clips validés', () {
    final files = Directory(directory)
        .listSync()
        .whereType<File>()
        .map((file) => file.uri.pathSegments.last)
        .toList();
    files.sort();
    expect(files, ['auth_home_matter.mp4', 'splash_awaken_e.mp4']);
  });

  test('il est déclaré dans pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- $directory'));
  });

  test('aucune trace du dossier d’aperçu temporaire', () {
    expect(
      Directory('assets/branding/cinematic_preview').existsSync(),
      isFalse,
    );
    expect(File('lib/main_cinematic_preview.dart').existsSync(), isFalse);
    expect(Directory('lib/cinematic_preview').existsSync(), isFalse);
    expect(
      File('pubspec.yaml').readAsStringSync(),
      isNot(contains('cinematic_preview')),
    );
  });

  test('le logo officiel n’a pas été touché : le clip ne le remplace pas', () {
    // Le clip est une matière ; le logo reste le PNG officiel.
    expect(File(IntelliaBrandAssets.logo).existsSync(), isTrue);
    expect(
      IntelliaBrandAssets.launchMatter,
      isNot(equals(IntelliaBrandAssets.logo)),
    );
  });
}
