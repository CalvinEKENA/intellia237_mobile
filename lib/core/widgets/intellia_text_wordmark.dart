import 'package:flutter/material.dart';

import '../../app/theme/design_tokens.dart';

class Intellia237TextWordmark extends StatelessWidget {
  const Intellia237TextWordmark({
    this.style,
    this.wordmarkColor,
    this.prefix = '',
    this.suffix = '',
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
    super.key,
  });

  final TextStyle? style;
  final Color? wordmarkColor;
  final String prefix;
  final String suffix;
  final TextAlign textAlign;
  final int? maxLines;

  // Le drapeau vient des jetons de marque : le splash, le bandeau de
  // l'onboarding et ce wordmark montraient trois trios différents.
  static const green = IntelliaFlag.green;
  static const red = IntelliaFlag.red;
  static const yellow = IntelliaFlag.yellow;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle =
        style ??
        const TextStyle(color: Color(0xFF183E72), fontWeight: FontWeight.w900);
    return Text.rich(
      TextSpan(
        style: effectiveStyle,
        children: [
          TextSpan(text: prefix),
          TextSpan(
            text: 'INTELLIA',
            style: TextStyle(color: wordmarkColor),
          ),
          const TextSpan(
            text: '2',
            style: TextStyle(color: green),
          ),
          const TextSpan(
            text: '3',
            style: TextStyle(color: red),
          ),
          const TextSpan(
            text: '7',
            style: TextStyle(color: yellow),
          ),
          TextSpan(text: suffix),
        ],
      ),
      textAlign: textAlign,
      maxLines: maxLines,
    );
  }
}
