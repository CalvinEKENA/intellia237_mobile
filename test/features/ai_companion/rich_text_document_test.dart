import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/ai_companion/domain/rich_text_document.dart';

/// Les réponses arrivaient dans un `Text` brut : `**`, `###` et les backticks
/// s'affichaient tels quels et l'élève voyait la mécanique du modèle au lieu
/// d'une explication.
///
/// L'invariant central de ces tests : **aucun marqueur ne doit jamais
/// atteindre l'écran**, y compris quand le balisage est incomplet.
void main() {
  String rendered(String source) =>
      RichTextDocument.parse(source).map((block) => block.plainText).join('\n');

  void expectNoRawMarkers(String source) {
    final text = rendered(source);
    expect(text, isNot(contains('**')), reason: 'gras brut visible : $text');
    expect(text, isNot(contains('###')), reason: 'titre brut visible : $text');
    expect(text, isNot(contains('```')), reason: 'clôture brute : $text');
  }

  group('structure des blocs', () {
    test('un titre devient un titre, sans dièses', () {
      final blocks = RichTextDocument.parse('### Les équations');

      expect(blocks, hasLength(1));
      expect(blocks.single.kind, RichBlockKind.heading);
      expect(blocks.single.plainText, 'Les équations');
      expect(blocks.single.level, 3);
    });

    test('les niveaux de titre sont aplatis à trois', () {
      expect(RichTextDocument.parse('###### Petit').single.level, 3);
      expect(RichTextDocument.parse('# Grand').single.level, 1);
    });

    test('les puces deviennent une liste', () {
      final blocks = RichTextDocument.parse('- un\n- deux\n* trois');

      expect(blocks, hasLength(3));
      expect(blocks.every((b) => b.kind == RichBlockKind.bullet), isTrue);
      expect(blocks.map((b) => b.plainText), ['un', 'deux', 'trois']);
      expect(blocks.first.marker, '•');
    });

    test('la numérotation est renumérotée proprement', () {
      final blocks = RichTextDocument.parse('1. un\n2. deux\n5. trois');

      expect(blocks.map((b) => b.marker), ['1.', '2.', '3.']);
      expect(blocks.every((b) => b.kind == RichBlockKind.ordered), isTrue);
    });

    test('une citation garde son texte sans chevron', () {
      final block = RichTextDocument.parse('> Une définition').single;

      expect(block.kind, RichBlockKind.quote);
      expect(block.plainText, 'Une définition');
    });

    test('un bloc de code conserve ses retours à la ligne', () {
      final block = RichTextDocument.parse(
        '```\nint x = 1;\nprint(x);\n```',
      ).single;

      expect(block.kind, RichBlockKind.code);
      expect(block.plainText, 'int x = 1;\nprint(x);');
    });

    test('les lignes consécutives forment un seul paragraphe', () {
      final blocks = RichTextDocument.parse(
        'Une phrase\nqui continue.\n\nUne autre.',
      );

      expect(blocks, hasLength(2));
      expect(blocks.first.plainText, 'Une phrase qui continue.');
    });
  });

  group('styles internes', () {
    test('le gras est porté par le style, pas par des étoiles', () {
      final spans = RichTextDocument.parseInline('Le **discriminant** compte');

      expect(spans.map((s) => s.text).join(), 'Le discriminant compte');
      expect(spans.firstWhere((s) => s.text == 'discriminant').bold, isTrue);
    });

    test('l’italique fonctionne avec étoile et tiret bas', () {
      for (final source in ['un *mot* ici', 'un _mot_ ici']) {
        final spans = RichTextDocument.parseInline(source);
        expect(spans.map((s) => s.text).join(), 'un mot ici');
        expect(spans.firstWhere((s) => s.text == 'mot').italic, isTrue);
      }
    });

    test('le code en ligne est littéral', () {
      final spans = RichTextDocument.parseInline('appelle `f(x) = **2**`');
      final code = spans.firstWhere((s) => s.code);

      expect(code.text, 'f(x) = **2**');
      expect(code.bold, isFalse);
    });

    test('seuls les liens http et https sont navigables', () {
      final safe = RichTextDocument.parseInline(
        '[cours](https://intellia237.cm/lecon)',
      );
      expect(safe.single.link, 'https://intellia237.cm/lecon');

      final unsafe = RichTextDocument.parseInline(
        '[danger](javascript:alert(1))',
      );
      expect(unsafe.every((span) => span.link == null), isTrue);
      // Le texte reste lisible même quand l'URL est rejetée.
      expect(unsafe.map((span) => span.text).join(), contains('danger'));
    });
  });

  group('balisage malformé : jamais de soupe de symboles', () {
    test('une étoile ouvrante sans fermeture disparaît', () {
      expectNoRawMarkers('Voici **un début sans fin');
      expect(rendered('Voici **un début sans fin'), 'Voici un début sans fin');
    });

    test('un backtick orphelin disparaît', () {
      expect(rendered('valeur ` isolée'), 'valeur  isolée');
    });

    test('un bloc de code non refermé n’avale pas la réponse', () {
      final blocks = RichTextDocument.parse('Texte\n```\nint x = 1;');

      expect(blocks.first.plainText, 'Texte');
      expect(blocks.last.kind, RichBlockKind.code);
      expectNoRawMarkers('Texte\n```\nint x = 1;');
    });

    test('un titre sans texte ne crée pas de bloc vide', () {
      expect(RichTextDocument.parse('###'), isEmpty);
    });

    test('une réponse chargée de marqueurs reste propre', () {
      const messy =
          '### **Titre** \n'
          '- **Point** un\n'
          '- *Point* deux\n'
          '\n'
          'Un paragraphe avec `code` et **gras** et une ** étoile perdue.\n'
          '> Une **citation**\n'
          '1. Étape\n';

      expectNoRawMarkers(messy);
      final blocks = RichTextDocument.parse(messy);
      expect(
        blocks.map((b) => b.kind),
        containsAll([
          RichBlockKind.heading,
          RichBlockKind.bullet,
          RichBlockKind.paragraph,
          RichBlockKind.quote,
          RichBlockKind.ordered,
        ]),
      );
    });

    test('un texte sans structure reste affiché', () {
      final blocks = RichTextDocument.parse('Juste une phrase.');

      expect(blocks, hasLength(1));
      expect(blocks.single.plainText, 'Juste une phrase.');
    });

    test('une réponse vide ne produit aucun bloc', () {
      expect(RichTextDocument.parse('   \n  \n'), isEmpty);
    });
  });

  group('notation mathématique', () {
    test('les exposants typographiques traversent intacts', () {
      const source = 'On résout x² + 2x − 3 = 0 avec Δ = b² − 4ac.';

      expect(rendered(source), source);
    });

    test('les astérisques de multiplication restent des opérateurs', () {
      // Les avaler comme de l'italique effacerait l'opérateur du calcul.
      expectNoRawMarkers('Calcule 3 * 4 * 5.');
      expect(rendered('Calcule 3 * 4 * 5.'), 'Calcule 3 * 4 * 5.');
    });
  });
}
