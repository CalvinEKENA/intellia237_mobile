import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Rendu riche et **sûr** du Markdown pédagogique : jamais de syntaxe brute
/// affichée à l'élève. Sous-ensemble pris en charge : titres, paragraphes, gras,
/// italique, code en ligne, listes à puces et numérotées, citations, liens
/// (uniquement http/https, ouverts dans une vue intégrée ; tout autre schéma est
/// rendu en texte simple, jamais activable), et formules-texte qui reviennent à
/// la ligne au lieu de déborder.
///
/// Responsive (≥ 320 px), respecte l'échelle de texte (jusqu'à 2.0) via les
/// styles hérités, FR/EN, et défile plutôt que rogner (bloc de code).
class RichLessonText extends StatefulWidget {
  const RichLessonText({
    required this.markdown,
    required this.baseStyle,
    this.linkColor,
    this.launcher,
    super.key,
  });

  final String markdown;
  final TextStyle baseStyle;
  final Color? linkColor;

  /// Ouvre un lien (siège de test). Par défaut : vue navigateur intégrée.
  final Future<bool> Function(Uri url)? launcher;

  @override
  State<RichLessonText> createState() => _RichLessonTextState();
}

class _RichLessonTextState extends State<RichLessonText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final launcher = widget.launcher;
    if (launcher != null) {
      await launcher(uri);
    } else {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Les reconnaisseurs de la construction précédente sont libérés ici : sans
    // cela, un lien recréé à chaque build fuirait.
    _disposeRecognizers();
    final blocks = _parseBlocks(widget.markdown);
    final linkColor = widget.linkColor ?? Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _buildBlock(context, blocks[i], linkColor),
        ],
      ],
    );
  }

  Widget _buildBlock(BuildContext context, _Block block, Color linkColor) {
    final base = widget.baseStyle;
    switch (block.type) {
      case _BlockType.heading:
        final scale = switch (block.level) {
          1 => 1.6,
          2 => 1.35,
          _ => 1.15,
        };
        return Text.rich(
          _inlineSpans(block.text, base, linkColor),
          style: base.copyWith(
            fontSize: (base.fontSize ?? 16) * scale,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
        );
      case _BlockType.paragraph:
        return Text.rich(
          _inlineSpans(block.text, base, linkColor),
          style: base.copyWith(height: 1.5),
        );
      case _BlockType.quote:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: linkColor.withValues(alpha: 0.5),
                width: 3,
              ),
            ),
            color: linkColor.withValues(alpha: 0.06),
          ),
          child: Text.rich(
            _inlineSpans(block.text, base, linkColor),
            style: base.copyWith(height: 1.5, fontStyle: FontStyle.italic),
          ),
        );
      case _BlockType.code:
        // Défile horizontalement plutôt que de déborder (formules, snippets).
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              block.text,
              style: base.copyWith(
                fontFamily: 'monospace',
                fontFeatures: const [FontFeature.tabularFigures()],
                height: 1.4,
              ),
            ),
          ),
        );
      case _BlockType.unordered:
      case _BlockType.ordered:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < block.items.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        block.type == _BlockType.ordered ? '${i + 1}.' : '•',
                        style: base.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Expanded(
                      child: Text.rich(
                        _inlineSpans(block.items[i], base, linkColor),
                        style: base.copyWith(height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
    }
  }

  // ── Inline parsing ────────────────────────────────────────────────────────

  static final _inlinePattern = RegExp(
    r'(`[^`]+`)'
    r'|(\*\*[^*]+\*\*|__[^_]+__)'
    r'|(\*[^*]+\*|_[^_]+_)'
    r'|(\[[^\]]+\]\([^)]+\))',
  );

  TextSpan _inlineSpans(String text, TextStyle base, Color linkColor) {
    final spans = <InlineSpan>[];
    var index = 0;
    for (final match in _inlinePattern.allMatches(text)) {
      if (match.start > index) {
        spans.add(TextSpan(text: text.substring(index, match.start)));
      }
      final token = match.group(0)!;
      if (match.group(1) != null) {
        // Code en ligne.
        spans.add(
          TextSpan(
            text: token.substring(1, token.length - 1),
            style: base.copyWith(
              fontFamily: 'monospace',
              backgroundColor: linkColor.withValues(alpha: 0.08),
            ),
          ),
        );
      } else if (match.group(2) != null) {
        spans.add(
          TextSpan(
            text: token.substring(2, token.length - 2),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
      } else if (match.group(3) != null) {
        spans.add(
          TextSpan(
            text: token.substring(1, token.length - 1),
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      } else {
        spans.add(_linkSpan(token, linkColor));
      }
      index = match.end;
    }
    if (index < text.length) {
      spans.add(TextSpan(text: text.substring(index)));
    }
    return TextSpan(children: spans);
  }

  InlineSpan _linkSpan(String token, Color linkColor) {
    final split = token.indexOf('](');
    final label = token.substring(1, split);
    final url = token.substring(split + 2, token.length - 1);
    final uri = Uri.tryParse(url);
    final safe = uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    if (!safe) {
      // Lien non sûr : on montre le libellé, jamais activable.
      return TextSpan(text: label);
    }
    final recognizer = TapGestureRecognizer()..onTap = () => _open(url);
    _recognizers.add(recognizer);
    return TextSpan(
      text: label,
      style: TextStyle(color: linkColor, decoration: TextDecoration.underline),
      recognizer: recognizer,
    );
  }

  // ── Block parsing ───────────────────────────────────────────────────────

  static final _heading = RegExp(r'^(#{1,3})\s+(.*)$');
  static final _unordered = RegExp(r'^[-*+]\s+(.*)$');
  static final _ordered = RegExp(r'^\d+\.\s+(.*)$');

  List<_Block> _parseBlocks(String markdown) {
    final lines = markdown.replaceAll('\r\n', '\n').split('\n');
    final blocks = <_Block>[];
    var paragraph = <String>[];
    var inCode = false;
    var code = <String>[];

    void flushParagraph() {
      if (paragraph.isNotEmpty) {
        blocks.add(_Block.paragraph(paragraph.join(' ').trim()));
        paragraph = [];
      }
    }

    for (final raw in lines) {
      final line = raw.trimRight();
      if (line.trimLeft().startsWith('```')) {
        if (inCode) {
          blocks.add(_Block.code(code.join('\n')));
          code = [];
          inCode = false;
        } else {
          flushParagraph();
          inCode = true;
        }
        continue;
      }
      if (inCode) {
        code.add(raw);
        continue;
      }
      if (line.trim().isEmpty) {
        flushParagraph();
        continue;
      }
      final heading = _heading.firstMatch(line.trimLeft());
      if (heading != null) {
        flushParagraph();
        blocks.add(
          _Block.heading(heading.group(1)!.length, heading.group(2)!.trim()),
        );
        continue;
      }
      final quoteLine = line.trimLeft();
      if (quoteLine.startsWith('> ') || quoteLine == '>') {
        flushParagraph();
        final text = quoteLine.length > 1 ? quoteLine.substring(1).trim() : '';
        if (blocks.isNotEmpty && blocks.last.type == _BlockType.quote) {
          blocks.last.text = '${blocks.last.text} $text'.trim();
        } else {
          blocks.add(_Block.quote(text));
        }
        continue;
      }
      final ul = _unordered.firstMatch(line.trimLeft());
      if (ul != null) {
        flushParagraph();
        if (blocks.isNotEmpty && blocks.last.type == _BlockType.unordered) {
          blocks.last.items.add(ul.group(1)!.trim());
        } else {
          blocks.add(_Block.list(_BlockType.unordered, ul.group(1)!.trim()));
        }
        continue;
      }
      final ol = _ordered.firstMatch(line.trimLeft());
      if (ol != null) {
        flushParagraph();
        if (blocks.isNotEmpty && blocks.last.type == _BlockType.ordered) {
          blocks.last.items.add(ol.group(1)!.trim());
        } else {
          blocks.add(_Block.list(_BlockType.ordered, ol.group(1)!.trim()));
        }
        continue;
      }
      paragraph.add(line.trim());
    }
    if (inCode && code.isNotEmpty) blocks.add(_Block.code(code.join('\n')));
    flushParagraph();
    return blocks;
  }
}

enum _BlockType { heading, paragraph, quote, code, unordered, ordered }

class _Block {
  _Block.heading(this.level, this.text) : type = _BlockType.heading, items = [];
  _Block.paragraph(this.text)
    : type = _BlockType.paragraph,
      level = 0,
      items = [];
  _Block.quote(this.text) : type = _BlockType.quote, level = 0, items = [];
  _Block.code(this.text) : type = _BlockType.code, level = 0, items = [];
  _Block.list(this.type, String first) : text = '', level = 0, items = [first];

  final _BlockType type;
  String text;
  final int level;
  final List<String> items;
}
