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

  _ratchet();
}

/// Cliquet : aucune fonctionnalité ne gagne de chaîne française en dur. Les
/// plafonds ne font que baisser ; une fonctionnalité absente de la table doit
/// rester à zéro. Inventaire et priorités : docs/i18n/HARDCODED_FRENCH_INVENTORY.md.
const _hardcodedFrenchCeilings = <String, int>{
  'admin': 153,
  'campus': 158,
  'flow': 5,
  'learn': 28,
  'onboarding': 28,
  'student_registration': 5,
};

String _featureOf(String finding) {
  final match = RegExp(r'lib/features/([^/]+)/').firstMatch(finding);
  return match?.group(1) ?? 'core';
}

void _ratchet() {
  test('no feature gains hardcoded French strings', () {
    final counts = <String, int>{};
    for (final finding in scanHardcodedFrench(Directory('lib'))) {
      final feature = _featureOf(finding);
      counts[feature] = (counts[feature] ?? 0) + 1;
    }
    for (final entry in counts.entries) {
      expect(
        entry.value,
        lessThanOrEqualTo(_hardcodedFrenchCeilings[entry.key] ?? 0),
        reason:
            '${entry.key} : ${entry.value} chaînes françaises en dur. '
            'Passez par les ARB (FR + EN).',
      );
    }
  });
}
