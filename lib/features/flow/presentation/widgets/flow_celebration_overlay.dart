import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../application/flow_controller.dart';

/// Célébration discrète d'une récompense (XP, badge).
///
/// Pas de confetti ni de bruit : un éclat XP qui monte, ou une carte badge
/// sobre — dans l'esprit Apple / Brilliant. S'auto-efface.
class FlowCelebrationOverlay extends StatefulWidget {
  const FlowCelebrationOverlay({
    required this.award,
    required this.onDone,
    super.key,
  });

  final FlowAward award;
  final VoidCallback onDone;

  @override
  State<FlowCelebrationOverlay> createState() => _FlowCelebrationOverlayState();
}

class _FlowCelebrationOverlayState extends State<FlowCelebrationOverlay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final hasBadge = widget.award.newBadges.isNotEmpty;
    _timer = Timer(
      Duration(milliseconds: hasBadge ? 2400 : 1400),
      widget.onDone,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badge = widget.award.newBadges.isNotEmpty
        ? widget.award.newBadges.first
        : null;

    return IgnorePointer(
      child: Center(
        child: badge != null
            ? _badgeCard(badge.icon, badge.title, badge.accent)
            : _xpBurst(widget.award.xpGained),
      ),
    );
  }

  Widget _xpBurst(int xp) {
    return Text(
          '+$xp XP',
          style: GoogleFonts.montserrat(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: IntelliaColors.xpGold,
            shadows: [
              Shadow(
                color: IntelliaColors.xpGold.withValues(alpha: 0.5),
                blurRadius: 18,
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 220.ms)
        .scale(
          begin: const Offset(0.6, 0.6),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
        )
        .then(delay: 500.ms)
        .moveY(begin: 0, end: -40, duration: 600.ms, curve: Curves.easeOut)
        .fadeOut(duration: 600.ms);
  }

  Widget _badgeCard(IconData icon, String title, Color accent) {
    return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: IntelliaSpacing.lg,
            vertical: IntelliaSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: IntelliaColors.surfaceSolid.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(IntelliaRadii.extraLarge),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
            boxShadow: IntelliaShadows.premium,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [accent, accent.withValues(alpha: 0.7)],
                  ),
                  boxShadow: IntelliaShadows.glow(accent, intensity: 0.4),
                ),
                child: Icon(icon, size: 32, color: Colors.white),
              ),
              const SizedBox(height: IntelliaSpacing.sm),
              Text(
                'Badge débloqué',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: IntelliaColors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: IntelliaColors.textPrimary,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 260.ms)
        .scale(
          begin: const Offset(0.7, 0.7),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
        )
        .then(delay: 1600.ms)
        .fadeOut(duration: 400.ms);
  }
}
