import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('product Dart surfaces contain no prohibited AI cliché iconography', () {
    const auditedRoots = [
      'lib/features/onboarding',
      'lib/features/auth',
      'lib/features/student_registration',
    ];
    final files = auditedRoots
        .expand((root) => Directory(root).listSync(recursive: true))
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    final violations = <String>[];
    final prohibited = RegExp(
      r'auto_awesome|sparkle|sparkling|magic[_ ]wand|smart_toy|psychology|neurology',
      caseSensitive: false,
    );

    for (final file in files) {
      if (prohibited.hasMatch(file.readAsStringSync())) {
        violations.add(file.path);
      }
    }

    expect(violations, isEmpty);
  });
}
