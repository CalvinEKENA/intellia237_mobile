import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/design_tokens.dart';

class IntelliaBrandMark extends StatelessWidget {
  const IntelliaBrandMark({
    this.size = 64,
    this.showText = true,
    this.textSize = 18,
    super.key,
  });

  final double size;
  final bool showText;
  final double textSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: IntelliaGradients.brand,
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: IntelliaShadows.glow(
              IntelliaColors.brandIndigo,
              intensity: 0.15,
            ),
          ),
          child: Center(
            child: Image.asset(
              'assets/branding/icon-192.png',
              width: size * 0.6,
              height: size * 0.6,
              fit: BoxFit.contain,
              errorBuilder: (ctx, err, stack) => Icon(
                Icons.school_rounded,
                size: size * 0.5,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(height: IntelliaSpacing.xs),
          Text(
            'INTELLIA237',
            style: GoogleFonts.playfairDisplay(
              fontSize: textSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
              color: isDark
                  ? IntelliaColors.textPrimaryDark
                  : IntelliaColors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}
