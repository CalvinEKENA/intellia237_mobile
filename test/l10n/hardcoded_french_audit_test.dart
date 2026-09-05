import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/hardcoded_french_audit.dart';

void main() {
  test('hardcoded-French detector catches UI literals and ignores English', () {
    expect(findFrenchLiteralsInLine("Text('Réessayer')"), ['Réessayer']);
    expect(findFrenchLiteralsInLine("const Text('Try again')"), isEmpty);
    expect(findFrenchLiteralsInLine('// Réessayer is localized'), isEmpty);
  });

  test('hardcoded-French allowlist stays intentionally small', () {
    expect(findFrenchLiteralsInLine("Text('Léo')"), isEmpty);
    expect(findFrenchLiteralsInLine("Text('Paramètres')"), ['Paramètres']);
  });

  test('localized priority surfaces cannot reintroduce French literals', () {
    final priorityFindings = scanHardcodedFrench(Directory('lib')).where(
      (finding) =>
          finding.contains('/features/auth/') ||
          finding.contains('/features/notifications/') ||
          finding.contains('/features/profile/'),
    );
    expect(priorityFindings, isEmpty);
  });
}
