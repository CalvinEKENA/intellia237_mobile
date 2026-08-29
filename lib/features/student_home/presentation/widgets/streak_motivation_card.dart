import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/design_tokens.dart';

/// Carte de série (streak) — îlot sombre volontaire sur l'accueil clair :
/// c'est un moment de fierté, le contraste blanc/or sur navy est garanti.
/// Aucune boucle d'animation permanente : le nombre est net et stable.
class StreakMotivationCard extends StatelessWidget {
  const StreakMotivationCard({
    required this.streakDays,
    required this.message,
    super.key,
  });

  final int streakDays;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Série de $streakDays jour${streakDays > 1 ? 's' : ''}. $message',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(IntelliaRadii.medium),
        child: CustomPaint(
          painter: _DiagonalStripePainter(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(IntelliaSpacing.lg),
            decoration: BoxDecoration(
              gradient: AppGradients.heroNavy,
              borderRadius: BorderRadius.circular(IntelliaRadii.medium),
            ),
            child: Row(
              children: [
                // Fire icon badge
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: IntelliaColors.warning.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: IntelliaColors.warning.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: IntelliaColors.warning,
                    size: 32,
                  ),
                ),
                const SizedBox(width: IntelliaSpacing.md),

                // Streak count + message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$streakDays',
                        style: GoogleFonts.manrope(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -2,
                          color: IntelliaColors.warning,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'jour${streakDays > 1 ? 's' : ''} de série',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: IntelliaSpacing.xxs),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.92),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fine grille de diagonales gold très subtiles en arrière-plan (statique).
class _DiagonalStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = IntelliaColors.warning.withValues(alpha: 0.07)
      ..strokeWidth = 1;

    const spacing = 20.0;
    for (double x = -size.height; x < size.width + size.height; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DiagonalStripePainter old) => false;
}
