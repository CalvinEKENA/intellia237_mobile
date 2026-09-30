import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_brand_references.dart' as brand;

void main() {
  test(
    'branding inventory includes active code, excludes worktree caches and local credentials',
    () {
      final temporary = Directory.systemTemp.createTempSync(
        'intellia-brand-test-',
      );
      addTearDown(() {
        final target = temporary.absolute.path;
        final parent = Directory.systemTemp.absolute.path;
        expect(target.startsWith('$parent${Platform.pathSeparator}'), isTrue);
        temporary.deleteSync(recursive: true);
      });
      for (final path in [
        'lib/active.dart',
        'docs/current.md',
        '.kilo/worktrees/old/lib/active.dart',
        '.codex-work/check.log.txt',
        'config/example.local.json',
      ]) {
        final file = File('${temporary.path}/$path');
        file.parent.createSync(recursive: true);
        file.writeAsStringSync('fixture');
      }
      final selected = brand
          .sourceFilesForBrandCheck(temporary)
          .map(
            (f) => f.path
                .substring(temporary.path.length + 1)
                .replaceAll('\\', '/'),
          )
          .toSet();
      expect(selected, {'lib/active.dart', 'docs/current.md'});
    },
  );
}
