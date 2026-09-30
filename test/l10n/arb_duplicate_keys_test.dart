import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Une clé en double dans un ARB ne casse rien à la génération : la
/// dernière écrase silencieusement la première, et un texte existant change
/// ailleurs dans l'application. Chaque clé n'existe donc qu'une fois.
///
/// `jsonDecode` garde la dernière valeur sans rien dire : on lit donc les
/// clés de premier niveau en suivant la structure du fichier.
List<String> duplicateArbKeys(String source) {
  final seen = <String>{};
  final duplicates = <String>[];
  var depth = 0;
  var index = 0;
  while (index < source.length) {
    final char = source[index];
    if (char == '"') {
      final start = ++index;
      while (source[index] != '"') {
        if (source[index] == r'\') index++;
        index++;
      }
      final text = source.substring(start, index);
      index++;
      var next = index;
      while (next < source.length && ' \t\r\n'.contains(source[next])) {
        next++;
      }
      final isKey = next < source.length && source[next] == ':';
      if (isKey && depth == 1 && !seen.add(text)) duplicates.add(text);
      continue;
    }
    if (char == '{' || char == '[') depth++;
    if (char == '}' || char == ']') depth--;
    index++;
  }
  return duplicates;
}

void main() {
  test('le détecteur voit un doublon de premier niveau, pas les imbriqués', () {
    expect(
      duplicateArbKeys(
        '{\n  "a": "x",\n  "@a": {"placeholders": {"n": {"type": "int"}}},\n'
        '  "b": "y \\"q\\"",\n  "@b": {"placeholders": {"n": {"type": "int"}}},\n'
        '"a": "z"\n}',
      ),
      ['a'],
    );
  });

  for (final file in ['lib/l10n/app_fr.arb', 'lib/l10n/app_en.arb']) {
    test('$file : aucune clé en double', () {
      expect(duplicateArbKeys(File(file).readAsStringSync()), isEmpty);
    });
  }
}
