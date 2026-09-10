/// Analyse du texte pédagogique renvoyé par le compagnon.
///
/// Registre de décisions : les réponses arrivaient dans un `Text` brut, si
/// bien que `**`, `###` et les backticks s'affichaient tels quels — l'élève
/// voyait la mécanique du modèle au lieu d'une explication. Ce module produit
/// une structure typée que la présentation rend elle-même.
///
/// Principe directeur : **aucun marqueur ne doit jamais atteindre l'écran**.
/// Un balisage incomplet — une étoile ouvrante sans fermante, une clôture de
/// bloc de code manquante — est traité comme du texte ordinaire dont les
/// marqueurs sont retirés, jamais comme une soupe de symboles.
library;

enum RichBlockKind { paragraph, heading, bullet, ordered, quote, code }

/// Un fragment de texte homogène à l'intérieur d'un bloc.
class RichSpan {
  const RichSpan(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.code = false,
    this.link,
  });

  final String text;
  final bool bold;
  final bool italic;
  final bool code;

  /// URL sûre, ou null. Seuls http et https sont conservés.
  final String? link;

  RichSpan copyWith({String? text}) => RichSpan(
    text ?? this.text,
    bold: bold,
    italic: italic,
    code: code,
    link: link,
  );

  @override
  String toString() =>
      'RichSpan("$text"'
      '${bold ? ' bold' : ''}${italic ? ' italic' : ''}'
      '${code ? ' code' : ''}${link == null ? '' : ' link=$link'})';
}

class RichBlock {
  const RichBlock({
    required this.kind,
    required this.spans,
    this.level = 0,
    this.marker,
  });

  final RichBlockKind kind;
  final List<RichSpan> spans;

  /// Niveau de titre (1 à 3 après aplatissement), sinon 0.
  final int level;

  /// Puce ou numéro déjà résolu, pour que la présentation n'ait rien à déduire.
  final String? marker;

  String get plainText => spans.map((span) => span.text).join();
}

abstract final class RichTextDocument {
  /// Découpe une réponse en blocs.
  static List<RichBlock> parse(String source) {
    final normalized = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n');
    final blocks = <RichBlock>[];
    final paragraph = <String>[];
    var orderedIndex = 0;

    void flushParagraph() {
      if (paragraph.isEmpty) return;
      final text = paragraph.join(' ').trim();
      paragraph.clear();
      if (text.isEmpty) return;
      blocks.add(
        RichBlock(kind: RichBlockKind.paragraph, spans: parseInline(text)),
      );
    }

    for (var index = 0; index < lines.length; index++) {
      final raw = lines[index];
      final line = raw.trimRight();
      final trimmed = line.trimLeft();

      if (trimmed.isEmpty) {
        flushParagraph();
        orderedIndex = 0;
        continue;
      }

      // Bloc de code clôturé. Une clôture manquante ne doit pas avaler le
      // reste de la réponse : le bloc s'arrête alors à la fin du texte.
      if (trimmed.startsWith('```')) {
        flushParagraph();
        orderedIndex = 0;
        final body = <String>[];
        index++;
        while (index < lines.length &&
            !lines[index].trimLeft().startsWith('```')) {
          body.add(lines[index]);
          index++;
        }
        final code = body.join('\n').trim();
        if (code.isNotEmpty) {
          blocks.add(
            RichBlock(kind: RichBlockKind.code, spans: [RichSpan(code)]),
          );
        }
        continue;
      }

      final heading = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(trimmed);
      if (heading != null) {
        flushParagraph();
        orderedIndex = 0;
        final text = heading.group(2)!.trim();
        if (text.isEmpty) continue;
        blocks.add(
          RichBlock(
            kind: RichBlockKind.heading,
            // Au-delà de trois niveaux, la hiérarchie n'apporte plus rien de
            // lisible sur un téléphone : elle est aplatie.
            level: heading.group(1)!.length.clamp(1, 3),
            spans: parseInline(text),
          ),
        );
        continue;
      }

      final bullet = RegExp(r'^[-*•]\s+(.*)$').firstMatch(trimmed);
      if (bullet != null) {
        flushParagraph();
        orderedIndex = 0;
        blocks.add(
          RichBlock(
            kind: RichBlockKind.bullet,
            marker: '•',
            spans: parseInline(bullet.group(1)!.trim()),
          ),
        );
        continue;
      }

      final ordered = RegExp(r'^(\d{1,2})[.)]\s+(.*)$').firstMatch(trimmed);
      if (ordered != null) {
        flushParagraph();
        orderedIndex++;
        blocks.add(
          RichBlock(
            kind: RichBlockKind.ordered,
            marker: '$orderedIndex.',
            spans: parseInline(ordered.group(2)!.trim()),
          ),
        );
        continue;
      }

      final quote = RegExp(r'^>\s?(.*)$').firstMatch(trimmed);
      if (quote != null) {
        flushParagraph();
        orderedIndex = 0;
        final text = quote.group(1)!.trim();
        if (text.isEmpty) continue;
        blocks.add(
          RichBlock(kind: RichBlockKind.quote, spans: parseInline(text)),
        );
        continue;
      }

      // Une ligne qui n'est faite que de marqueurs — « ### » seul, une rangée
      // d'étoiles — n'a rien à dire : elle ne doit pas devenir un paragraphe
      // affichant sa propre syntaxe.
      if (stripMarkers(trimmed).trim().isEmpty) continue;
      paragraph.add(trimmed);
    }

    flushParagraph();

    // Une réponse vide de blocs mais non vide de texte reste affichée telle
    // quelle : mieux vaut un paragraphe simple qu'un écran muet.
    if (blocks.isEmpty) {
      final fallback = stripMarkers(normalized).trim();
      if (fallback.isNotEmpty) {
        blocks.add(
          RichBlock(kind: RichBlockKind.paragraph, spans: [RichSpan(fallback)]),
        );
      }
    }
    return blocks;
  }

  /// Analyse les marqueurs internes à une ligne.
  static List<RichSpan> parseInline(String source) {
    final spans = <RichSpan>[];
    final buffer = StringBuffer();
    var bold = false;
    var italic = false;

    void push({bool code = false, String? link, String? text}) {
      final value = text ?? buffer.toString();
      if (text == null) buffer.clear();
      if (value.isEmpty) return;
      spans.add(
        RichSpan(value, bold: bold, italic: italic, code: code, link: link),
      );
    }

    var index = 0;
    while (index < source.length) {
      final rest = source.substring(index);

      // Lien : le texte reste affiché même si l'URL est rejetée.
      final link = RegExp(r'^\[([^\]]+)\]\(([^)\s]+)\)').firstMatch(rest);
      if (link != null) {
        push();
        final url = _safeUrl(link.group(2)!);
        push(text: link.group(1)!, link: url);
        index += link.group(0)!.length;
        continue;
      }

      // Code en ligne : le contenu est littéral, aucun marqueur n'y agit.
      if (rest.startsWith('`')) {
        final end = rest.indexOf('`', 1);
        if (end > 1) {
          push();
          push(text: rest.substring(1, end), code: true);
          index += end + 1;
          continue;
        }
        // Backtick orphelin : il disparaît au lieu de s'afficher.
        index += 1;
        continue;
      }

      if (rest.startsWith('**') || rest.startsWith('__')) {
        final marker = rest.substring(0, 2);
        final closes = source.indexOf(marker, index + 2) != -1;
        if (closes || bold) {
          push();
          bold = !bold;
          index += 2;
          continue;
        }
        // Marqueur ouvrant sans fermeture : retiré, jamais affiché.
        index += 2;
        continue;
      }

      if (rest.startsWith('*') || rest.startsWith('_')) {
        final marker = rest.substring(0, 1);
        // Un marqueur d'emphase colle à son texte. « 3 * 4 » est une
        // multiplication : l'avaler comme de l'italique effacerait l'opérateur
        // et changerait le sens d'un calcul.
        if (italic) {
          final previous = index == 0 ? '' : source[index - 1];
          if (previous.trim().isEmpty) {
            buffer.write(source[index]);
            index += 1;
            continue;
          }
          push();
          italic = false;
          index += 1;
          continue;
        }
        final next = index + 1 < source.length ? source[index + 1] : '';
        final opens = next.isNotEmpty && next.trim().isNotEmpty;
        if (opens && _closesEmphasis(source, marker, index + 1)) {
          push();
          italic = true;
          index += 1;
          continue;
        }
        buffer.write(source[index]);
        index += 1;
        continue;
      }

      buffer.write(source[index]);
      index += 1;
    }

    // Un style resté ouvert se referme implicitement à la fin de la ligne.
    push();
    return spans.isEmpty ? const [RichSpan('')] : spans;
  }

  /// Vrai si un marqueur d'emphase se referme plus loin en collant à son
  /// texte, seule configuration qui décrit réellement de l'italique.
  static bool _closesEmphasis(String source, String marker, int from) {
    for (var i = from; i < source.length; i++) {
      if (source[i] != marker) continue;
      final previous = source[i - 1];
      if (previous.trim().isNotEmpty && previous != marker) return true;
    }
    return false;
  }

  /// Retire tout marqueur résiduel d'un texte rendu en clair.
  static String stripMarkers(String source) => source
      .replaceAll(RegExp(r'^\s{0,3}#{1,6}\s*', multiLine: true), '')
      .replaceAll(RegExp(r'^\s*[-*•]\s*$', multiLine: true), '')
      .replaceAll(RegExp(r'\*\*|__'), '')
      .replaceAll(RegExp(r'`{1,3}'), '')
      .replaceAll(RegExp(r'^\s*>\s?', multiLine: true), '');

  /// N'accepte qu'un schéma navigable et sûr.
  static String? _safeUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme) return null;
    return const {'http', 'https'}.contains(uri.scheme.toLowerCase())
        ? uri.toString()
        : null;
  }
}
