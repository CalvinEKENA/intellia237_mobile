import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Git preserves canonical LF for content packs on every platform', () {
    expect(
      File('.gitattributes').readAsStringSync(),
      contains('assets/content/**/*.json text eol=lf'),
    );
  });

  test('every declared checksum matches the shipped UTF-8 asset bytes', () {
    var checked = 0;
    for (final file in Directory(
      'assets/content',
    ).listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.json')) continue;
      final bytes = file.readAsBytesSync();
      expect(utf8.decode(bytes).contains('\r\n'), isFalse, reason: file.path);
      if (!file.path.endsWith('manifest.json')) continue;
      final manifest = jsonDecode(utf8.decode(bytes)) as Map;
      final hashes = manifest['sha256'];
      if (hashes is! Map) continue;
      for (final entry in hashes.entries) {
        final asset = File('${file.parent.path}/${entry.key}');
        expect(
          sha256.convert(asset.readAsBytesSync()).toString(),
          entry.value,
          reason: asset.path,
        );
        checked++;
      }
    }
    expect(checked, greaterThanOrEqualTo(24));
  });
}
