import 'dart:convert';
import 'dart:io';

/// Parcourt les fichiers texte du dépôt et relève les jetons qui ont l'allure
/// d'une adresse e-mail : [isLeak] dit lesquels sont des valeurs interdites.
///
/// Sert aux gardes « aucune valeur secrète ou révoquée dans le dépôt public »,
/// sans que le dépôt ne connaisse ces valeurs (elles se reconnaissent par leur
/// condensat).
class RepoScan {
  const RepoScan({required this.scanned, required this.found});

  /// Nombre de fichiers lus.
  final int scanned;

  /// Fichiers qui contiennent une valeur interdite.
  final List<String> found;
}

RepoScan scanRepoForEmails(bool Function(String token) isLeak) {
  final email = RegExp(r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}');
  const roots = [
    'lib',
    'test',
    'tool',
    'docs',
    'functions/src',
    'android/app/src',
    'ios/Runner',
    'web',
    'apps',
  ];
  const rootFiles = [
    'CLAUDE.md',
    'README.md',
    'pubspec.yaml',
    'firebase.json',
    '.firebaserc',
    '.gitignore',
  ];
  const extensions = {
    'dart',
    'ts',
    'js',
    'cjs',
    'mjs',
    'json',
    'md',
    'yaml',
    'yml',
    'kts',
    'gradle',
    'xml',
    'html',
    'txt',
    'sh',
    'ps1',
    'py',
    'arb',
    'properties',
    'rules',
    'plist',
  };
  const skipped = ['node_modules', 'build', '.dart_tool', '.kilo', '.git'];
  final found = <String>[];
  var scanned = 0;

  void scan(File file) {
    final text = file.readAsStringSync(
      encoding: const Utf8Codec(allowMalformed: true),
    );
    scanned++;
    for (final match in email.allMatches(text)) {
      if (isLeak(match.group(0)!)) found.add(file.path);
    }
  }

  for (final root in roots) {
    final directory = Directory(root);
    if (!directory.existsSync()) continue;
    for (final entity in directory.listSync(recursive: true)) {
      if (entity is! File) continue;
      final path = entity.path.replaceAll('\\', '/');
      if (skipped.any((name) => path.split('/').contains(name))) continue;
      final dot = path.lastIndexOf('.');
      if (dot < 0 || !extensions.contains(path.substring(dot + 1))) continue;
      scan(entity);
    }
  }
  for (final name in rootFiles) {
    final file = File(name);
    if (file.existsSync()) scan(file);
  }
  return RepoScan(scanned: scanned, found: found);
}
