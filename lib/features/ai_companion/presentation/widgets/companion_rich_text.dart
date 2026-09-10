import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../domain/rich_text_document.dart';

/// Rend une réponse de compagnon comme une explication, pas comme une sortie
/// de modèle.
///
/// La direction visuelle est celle du Cahier : du texte posé sur le fond,
/// beaucoup d'air, aucune bulle colorée, aucun dégradé décoratif. La structure
/// vient de la typographie et de l'espacement, jamais d'un encadré.
class CompanionRichText extends StatefulWidget {
  const CompanionRichText({
    required this.text,
    required this.baseStyle,
    this.accentColor,
    this.onOpenLink,
    super.key,
  });

  final String text;
  final TextStyle baseStyle;

  /// Encre du compagnon : sert aux liens, aux puces et au filet de citation.
  final Color? accentColor;

  final ValueChanged<String>? onOpenLink;

  @override
  State<CompanionRichText> createState() => _CompanionRichTextState();
}

class _CompanionRichTextState extends State<CompanionRichText> {
  /// Les reconnaisseurs de tap survivent au-delà du `build` et doivent être
  /// libérés explicitement, sous peine de fuite à chaque reconstruction.
  final _recognizers = <TapGestureRecognizer>[];

  TextStyle get baseStyle => widget.baseStyle;
  Color? get accentColor => widget.accentColor;
  ValueChanged<String>? get onOpenLink => widget.onOpenLink;

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final blocks = RichTextDocument.parse(widget.text);
    if (blocks.isEmpty) return const SizedBox.shrink();

    final accent = accentColor ?? baseStyle.color ?? Colors.black;
    final children = <Widget>[];
    for (var index = 0; index < blocks.length; index++) {
      if (index > 0) {
        children.add(SizedBox(height: _gapBefore(blocks[index].kind)));
      }
      children.add(_buildBlock(context, blocks[index], accent));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  double _gapBefore(RichBlockKind kind) => switch (kind) {
    RichBlockKind.heading => 14,
    RichBlockKind.paragraph => 10,
    RichBlockKind.code => 10,
    RichBlockKind.quote => 10,
    RichBlockKind.bullet || RichBlockKind.ordered => 4,
  };

  Widget _buildBlock(BuildContext context, RichBlock block, Color accent) {
    switch (block.kind) {
      case RichBlockKind.heading:
        return Text.rich(
          _spansOf(block, baseStyle, accent),
          style: baseStyle.copyWith(
            // Un titre se distingue par la graisse et une hauteur d'œil à
            // peine supérieure : grossir davantage ferait « page web ».
            fontSize: baseStyle.fontSize! + (block.level == 1 ? 3 : 1.5),
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        );

      case RichBlockKind.paragraph:
        return Text.rich(_spansOf(block, baseStyle, accent), style: baseStyle);

      case RichBlockKind.bullet:
      case RichBlockKind.ordered:
        return Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: block.kind == RichBlockKind.bullet ? 18 : 26,
                child: Text(
                  block.marker ?? '•',
                  style: baseStyle.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Text.rich(
                  _spansOf(block, baseStyle, accent),
                  style: baseStyle,
                ),
              ),
            ],
          ),
        );

      case RichBlockKind.quote:
        return Container(
          padding: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: accent.withValues(alpha: 0.45), width: 2),
            ),
          ),
          child: Text.rich(
            _spansOf(block, baseStyle, accent),
            style: baseStyle.copyWith(fontStyle: FontStyle.italic),
          ),
        );

      case RichBlockKind.code:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (baseStyle.color ?? Colors.black).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          // Un bloc de code est la seule zone autorisée à défiler
          // horizontalement : la conversation, elle, ne bouge pas.
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              block.plainText,
              style: baseStyle.copyWith(
                fontFamily: 'monospace',
                fontSize: baseStyle.fontSize! - 1,
                height: 1.45,
              ),
            ),
          ),
        );
    }
  }

  TextSpan _spansOf(RichBlock block, TextStyle style, Color accent) {
    return TextSpan(
      children: [
        for (final span in block.spans) _inlineSpan(span, style, accent),
      ],
    );
  }

  InlineSpan _inlineSpan(RichSpan span, TextStyle style, Color accent) {
    var resolved = style;
    if (span.bold) resolved = resolved.copyWith(fontWeight: FontWeight.w700);
    if (span.italic) resolved = resolved.copyWith(fontStyle: FontStyle.italic);
    if (span.code) {
      resolved = resolved.copyWith(
        fontFamily: 'monospace',
        fontSize: (style.fontSize ?? 14) - 0.5,
        backgroundColor: (style.color ?? Colors.black).withValues(alpha: 0.06),
      );
    }
    if (span.link != null) {
      resolved = resolved.copyWith(
        color: accent,
        decoration: TextDecoration.underline,
        decorationColor: accent.withValues(alpha: 0.5),
      );
      final url = span.link!;
      return TextSpan(
        text: span.text,
        style: resolved,
        recognizer: onOpenLink == null ? null : _recognizerFor(url),
      );
    }
    return TextSpan(text: span.text, style: resolved);
  }

  TapGestureRecognizer _recognizerFor(String url) {
    final recognizer = TapGestureRecognizer()..onTap = () => onOpenLink!(url);
    _recognizers.add(recognizer);
    return recognizer;
  }
}
