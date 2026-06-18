import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../domain/student_home_snapshot.dart';

class DailyChallengesSection extends StatefulWidget {
  const DailyChallengesSection({required this.items, super.key});

  final List<DailyChallengeItem> items;

  @override
  State<DailyChallengesSection> createState() => _DailyChallengeSectionState();
}

class _DailyChallengeSectionState extends State<DailyChallengesSection> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _timeUntilMidnight();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _remaining = _timeUntilMidnight());
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Duration _timeUntilMidnight() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    return midnight.difference(now);
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with countdown
        Row(
          children: [
            Text(
              'Défis du jour',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            // Countdown pill
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs + 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.30),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 12,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(_remaining),
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Challenge cards
        for (int i = 0; i < widget.items.length; i++) ...[
          _ChallengeCard(item: widget.items[i], index: i),
          if (i < widget.items.length - 1)
            const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.item, required this.index});

  final DailyChallengeItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            gradient: item.completed
                ? const LinearGradient(
                    colors: [Color(0x1A11AFA5), Color(0x0D11AFA5)],
                  )
                : const LinearGradient(
                    colors: [Color(0x18FFFFFF), Color(0x0CFFFFFF)],
                  ),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: item.completed
                  ? AppColors.accent.withValues(alpha: 0.30)
                  : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              // Completion icon
              item.completed
                  ? Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.20),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: AppColors.accent,
                            size: 20,
                          ),
                        )
                        .animate()
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1.0, 1.0),
                          duration: AppMotion.medium,
                          curve: AppMotion.spring,
                        )
                        .fadeIn(duration: AppMotion.fast)
                  : Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.brand.withValues(alpha: 0.20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: AppColors.brand,
                        size: 20,
                      ),
                    ),

              const SizedBox(width: AppSpacing.sm),

              // Title
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: item.completed
                        ? Colors.white.withValues(alpha: 0.55)
                        : Colors.white,
                    decoration: item.completed
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: Colors.white.withValues(alpha: 0.30),
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // XP badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  gradient: item.completed ? null : AppGradients.heroGold,
                  color: item.completed
                      ? Colors.white.withValues(alpha: 0.10)
                      : null,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '+${item.rewardXp} XP',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: item.completed
                        ? Colors.white.withValues(alpha: 0.40)
                        : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: 80 + index * 60))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.04, end: 0);
  }
}
