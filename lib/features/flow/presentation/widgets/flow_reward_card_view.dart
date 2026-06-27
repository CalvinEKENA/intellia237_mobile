import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../application/flow_controller.dart';
import '../../domain/flow_card.dart';
import 'flow_card_scaffold.dart';

/// Carte de palier : célèbre la progression (XP, niveau, série) avec sobriété.
class FlowRewardCardView extends ConsumerWidget {
  const FlowRewardCardView({required this.card, super.key});
  final FlowRewardCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(flowControllerProvider);
    final accent = card.subject.accent;

    return FlowCardScaffold(
      subject: card.subject,
      kicker: card.kicker,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _medal(accent),
          const SizedBox(height: IntelliaSpacing.xl),
          Text(
            card.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: IntelliaColors.textPrimary,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 460.ms).slideY(
            begin: 0.12,
            end: 0,
            delay: 200.ms,
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          Text(
            card.message,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 15.5,
              height: 1.55,
              fontWeight: FontWeight.w500,
              color: IntelliaColors.textSecondary,
            ),
          ).animate().fadeIn(delay: 320.ms, duration: 460.ms),
          const SizedBox(height: IntelliaSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _stat('${progress.xp}', 'XP', IntelliaColors.xpGold),
              _divider(),
              _stat('Niv. ${progress.level}', 'Niveau', accent),
              _divider(),
              _stat(
                '${progress.streakDays} j',
                'Série',
                IntelliaColors.warning,
              ),
            ],
          ).animate().fadeIn(delay: 440.ms, duration: 460.ms),
        ],
      ),
    );
  }

  Widget _medal(Color accent) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [accent.withValues(alpha: 0.28), Colors.transparent],
            ),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(
          begin: 0.9,
          end: 1.1,
          duration: 1800.ms,
          curve: Curves.easeInOut,
        ),
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: card.subject.gradient,
            boxShadow: IntelliaShadows.glow(accent, intensity: 0.4),
          ),
          child: const Icon(
            Icons.emoji_events_rounded,
            size: 44,
            color: Colors.white,
          ),
        ).animate().scale(
          begin: const Offset(0.4, 0.4),
          end: const Offset(1, 1),
          duration: 560.ms,
          curve: Curves.easeOutBack,
        ),
      ],
    );
  }

  Widget _stat(String value, String label, Color color) => Column(
    children: [
      Text(
        value,
        style: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: IntelliaColors.textTertiary,
        ),
      ),
    ],
  );

  Widget _divider() => Container(
    width: 1,
    height: 30,
    margin: const EdgeInsets.symmetric(horizontal: IntelliaSpacing.lg),
    color: Colors.black.withValues(alpha: 0.08),
  );
}
