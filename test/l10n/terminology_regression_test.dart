import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('French localization exposes no user-visible academic terminology', () {
    final frenchArb = File('lib/l10n/app_fr.arb').readAsStringSync();
    expect(frenchArb.toLowerCase(), isNot(contains('académi')));
  });

  test('presentation string literals expose no academic terminology', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.contains(
        '${Platform.pathSeparator}generated${Platform.pathSeparator}',
      )) {
        continue;
      }
      final content = entity.readAsStringSync();
      final literalPattern = RegExp(
        r'''(['"])[^\r\n]*académi[^\r\n]*\1''',
        caseSensitive: false,
      );
      if (literalPattern.hasMatch(content)) offenders.add(entity.path);
    }
    expect(offenders, isEmpty, reason: 'User-visible remnants: $offenders');
  });
}
