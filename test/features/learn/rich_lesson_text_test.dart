import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/learn/presentation/widgets/rich_lesson_text.dart';

const _markdown = '''
# Titre principal

Un paragraphe avec du **gras**, de l'*italique* et du `code` en ligne.

## Sous-titre

- Premier point
- Deuxième point

1. Étape une
2. Étape deux

> Une citation importante.

Un lien [sûr](https://intellia237.example) et un lien [dangereux](javascript:alert(1)).

```
E = m * c^2
```
''';

TextStyle _base() => const TextStyle(fontSize: 16);

Future<void> _pump(
  WidgetTester tester, {
  Size size = const Size(360, 900),
  double textScale = 1.0,
  String markdown = _markdown,
  Future<bool> Function(Uri)? launcher,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            child: RichLessonText(
              markdown: markdown,
              baseStyle: _base(),
              launcher: launcher,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Concatène tout le texte rendu (Text + Text.rich) pour vérifier l'absence de
/// syntaxe brute.
String _renderedText(WidgetTester tester) {
  final buffer = StringBuffer();
  for (final element in find.byType(Text).evaluate()) {
    final widget = element.widget as Text;
    buffer.write(widget.data ?? widget.textSpan?.toPlainText() ?? '');
    buffer.write('\n');
  }
  return buffer.toString();
}

void main() {
  testWidgets('renders content and never leaks raw Markdown syntax', (
    tester,
  ) async {
    await _pump(tester);
    final text = _renderedText(tester);

    // Le contenu est présent…
    expect(text, contains('Titre principal'));
    expect(text, contains('gras'));
    expect(text, contains('italique'));
    expect(text, contains('Premier point'));
    expect(text, contains('Étape une'));
    expect(text, contains('Une citation importante.'));
    expect(text, contains('E = m * c^2'));

    // …mais aucun marqueur Markdown brut n'apparaît à l'élève.
    expect(text.contains('**'), isFalse);
    expect(text.contains('](http'), isFalse);
    expect(text.contains('# Titre'), isFalse);
    expect(text.contains('```'), isFalse);
    expect(RegExp(r'(^|\n)- ').hasMatch(text), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a safe http link launches when tapped', (tester) async {
    final launched = <Uri>[];
    await _pump(
      tester,
      markdown: '[Ouvrir la ressource](https://intellia237.example/page)',
      launcher: (uri) async {
        launched.add(uri);
        return true;
      },
    );
    // Le lien occupe la ligne : on tape près de son début.
    final origin = tester.getTopLeft(find.byType(RichText).first);
    await tester.tapAt(origin + const Offset(12, 10));
    await tester.pump();

    expect(launched, isNotEmpty);
    expect(launched.first.scheme, 'https');
  });

  testWidgets('an unsafe link scheme is inert and shows only its label', (
    tester,
  ) async {
    final launched = <Uri>[];
    await _pump(
      tester,
      markdown: '[Clique ici](javascript:alert(1))',
      launcher: (uri) async {
        launched.add(uri);
        return true;
      },
    );
    expect(_renderedText(tester), contains('Clique ici'));
    expect(_renderedText(tester).contains('javascript'), isFalse);

    final origin = tester.getTopLeft(find.byType(RichText).first);
    await tester.tapAt(origin + const Offset(12, 10));
    await tester.pump();
    expect(launched, isEmpty);
  });

  for (final size in const [Size(320, 900), Size(600, 900)]) {
    for (final scale in const [1.0, 1.5, 2.0]) {
      testWidgets('no overflow at ${size.width.toInt()}px @${scale}x', (
        tester,
      ) async {
        await _pump(tester, size: size, textScale: scale);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
