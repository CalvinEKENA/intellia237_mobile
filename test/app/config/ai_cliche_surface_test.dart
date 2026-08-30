import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('product Dart surfaces contain no prohibited AI cliché iconography', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    final violations = <String>[];
    final prohibited = RegExp(
      r'auto_awesome|sparkle|sparkling|magic star',
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
