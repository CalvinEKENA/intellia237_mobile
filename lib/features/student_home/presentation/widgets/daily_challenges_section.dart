import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/widgets/intellia_pressable.dart';
import '../../../../core/widgets/tab_presentation.dart';
import '../../domain/student_home_snapshot.dart';

class DailyChallengesSection extends StatefulWidget {
  const DailyChallengesSection({
    required this.items,
    required this.onItemTap,
    super.key,
  });

  final List<DailyChallengeItem> items;
  final ValueChanged<DailyChallengeItem> onItemTap;

  @override
  State<DailyChallengesSection> createState() => _DailyChallengeSectionState();
}

class _DailyChallengeSectionState extends State<DailyChallengesSection> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _timeUntilMidnight();
    // Précision minute (au lieu d'un rebuild par seconde) : le compte à
    // rebours indique un horizon, pas un chrono — 60× moins de rebuilds.
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() => _remaining = _timeUntilMidnight());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration _timeUntilMidnight() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    return midnight.difference(now);
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h <= 0) return '$m min';
    return '$h h ${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with countdown
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.dailyChallenges,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: s.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: IntelliaSpacing.sm),
            // Countdown pill — or profond lisible sur la surface courante.
            Semantics(
              label: context.l10n.challengesRenewIn(
                _formatDuration(_remaining),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: IntelliaSpacing.sm,
                  vertical: IntelliaSpacing.xxs + 2,
                ),
                decoration: BoxDecoration(
                  color: s.numberAccentSoft,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, size: 12, color: s.numberAccent),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(_remaining),
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: s.numberAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: IntelliaSpacing.sm),

        // Challenge cards
        for (int i = 0; i < widget.items.length; i++) ...[
          _ChallengeCard(
            item: widget.items[i],
            index: i,
            onTap: () => widget.onItemTap(widget.items[i]),
          ),
          if (i < widget.items.length - 1)
            const SizedBox(height: IntelliaSpacing.xs),
        ],
      ],
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.item,
    required this.index,
    required this.onTap,
  });

  final DailyChallengeItem item;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);
    final completed = item.completed;

    // Surfaces opaques du contrat de surface : plus de voiles blancs
    // translucides conçus pour un fond sombre (invisibles sur fond clair).
    final cardColor = completed
        ? (s.isLight ? const Color(0xFFEDF7F0) : s.surfaceMuted)
        : s.surface;
    final borderColor = completed
        ? s.success.withValues(alpha: 0.35)
        : s.border;

    return Semantics(
      button: !completed,
      label: completed
          ? context.l10n.challengeCompletedA11y(item.title)
          : context.l10n.challengeRewardA11y(item.title, item.rewardPoints),
      child: IntelliaPressable(
        onTap: completed ? null : onTap,
        disabledOpacity: 1,
        child:
            Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: IntelliaSpacing.md,
                    vertical: IntelliaSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(IntelliaRadii.small),
                    border: Border.all(color: borderColor),
                    boxShadow: completed
                        ? null
                        : IntelliaShadows.card(Colors.black),
                  ),
                  child: Row(
                    children: [
                      // Completion icon
                      completed
                          ? Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: s.success.withValues(alpha: 0.16),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                color: s.success,
                                size: 20,
                              ),
                            )
                          : Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: s.accentSoft,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.bolt_rounded,
                                color: s.accent,
                                size: 20,
                              ),
                            ),

                      const SizedBox(width: IntelliaSpacing.sm),

                      // Title
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: completed ? s.textDisabled : s.textPrimary,
                            decoration: completed
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: s.textDisabled,
                          ),
                        ),
                      ),

                      const SizedBox(width: IntelliaSpacing.sm),

                      // Pastille de points
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: IntelliaSpacing.xs,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: completed
                              ? s.surfaceMuted
                              : s.numberAccentSoft,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '+${item.rewardPoints} pts',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: completed ? s.textDisabled : s.numberAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .animate(delay: Duration(milliseconds: 80 + index * 60))
                .fadeIn(duration: 400.ms)
                .slideX(begin: 0.04, end: 0),
      ),
    );
  }
}
