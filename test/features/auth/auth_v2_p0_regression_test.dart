import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Non-régression des quatre P0 de la revue de 7ea5cf0 (refonte Auth V2).
///
/// Reproduction sur 7ea5cf0, avant correction :
/// docs/release/evidence/auth_v2_p0_repro_7ea5cf0_output.txt.
///
/// Les comportements sont prouvés sur les vrais écrans par
/// google_access_journey_test.dart (P0-1 à P0-3) et par l'ordre des appels
/// dans google_access_coordinator_test.dart (P0-2). Ce fichier garde le code
/// lui-même contre le retour des causes.
void main() {
  Iterable<File> dartFiles(String root) => Directory(root)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where(
        (file) => !file.path.replaceAll('\\', '/').contains('/generated/'),
      );

  String relative(File file) => file.path.replaceAll('\\', '/');

  test('P0-1 · no screen relies on completeBootstrap to adopt a session', () {
    final offenders = [
      for (final file in dartFiles('lib'))
        if (file.readAsStringSync().contains('completeBootstrap()') &&
            !relative(file).endsWith('auth_controller.dart') &&
            !relative(file).endsWith('bootstrap_screen.dart'))
          relative(file),
    ];
    expect(offenders, isEmpty);
  });

  test('P0-2 · Firebase is never asked to sign a provider in directly', () {
    // `signInWithProvider` / `signInWithPopup` créent l'utilisateur avant
    // toute décision ; la preuve Google est acquise seule.
    final offenders = [
      for (final file in dartFiles('lib'))
        for (final call in const ['signInWithProvider(', 'signInWithPopup('])
          if (file.readAsStringSync().contains(call))
            '${relative(file)}: $call',
    ];
    expect(offenders, isEmpty);
  });

  test(
    'P0-3 · no proof is ever linked onto a Google session from a screen',
    () {
      final offenders = [
        for (final file in dartFiles('lib/features/auth/presentation'))
          for (final pattern in const [
            'EmailAuthProvider.credential(',
            '.linkWithCredential(',
            'FirebaseAuth.instance',
          ])
            if (file.readAsStringSync().contains(pattern))
              '${relative(file)}: $pattern',
      ];
      expect(offenders, isEmpty);
      // Aucune part du code ne fabrique un mot de passe e-mail à rattacher.
      for (final file in dartFiles('lib')) {
        expect(
          file.readAsStringSync(),
          isNot(contains('EmailAuthProvider.credential(')),
          reason: relative(file),
        );
      }
    },
  );

  test('no raw Firebase message and no hand-built +237 number', () {
    final rawMessage = RegExp(r'\$\{\s*\w+\.message\s*\}');
    final handBuilt = RegExp(r"""['"]\+237\$""");
    final offenders = [
      for (final file in dartFiles('lib'))
        for (final (index, line) in file.readAsLinesSync().indexed)
          if (!line.trimLeft().startsWith('//') &&
              !line.trimLeft().startsWith('///') &&
              (rawMessage.hasMatch(line) || handBuilt.hasMatch(line)))
            '${relative(file)}:${index + 1}: ${line.trim()}',
    ];
    expect(offenders, isEmpty);
  });
}
