import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/widgets/intellia_pressable.dart';
import '../../domain/flow_card.dart';
import 'flow_card_scaffold.dart';
import 'flow_concept_animation.dart';

TextStyle _title(BuildContext context) => GoogleFonts.playfairDisplay(
  fontSize: 32,
  fontWeight: FontWeight.w700,
  height: 1.12,
  letterSpacing: -0.4,
  color: IntelliaColors.textPrimary,
);

TextStyle _body() => GoogleFonts.montserrat(
  fontSize: 16,
  height: 1.55,
  fontWeight: FontWeight.w500,
  color: IntelliaColors.textSecondary,
);

// ── Notion ────────────────────────────────────────────────────────────────
class FlowNotionCardView extends StatelessWidget {
  const FlowNotionCardView({required this.card, super.key});
  final FlowNotionCard card;

  @override
  Widget build(BuildContext context) {
    final accent = card.subject.accent;
    return FlowCardScaffold(
      subject: card.subject,
      kicker: card.kicker,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(card.title, style: _title(context))
              .animate()
              .fadeIn(delay: 120.ms, duration: 460.ms)
              .slideY(begin: 0.14, end: 0, delay: 120.ms),
          const SizedBox(height: IntelliaSpacing.md),
          Text(
            card.insight,
            style: _body(),
          ).animate().fadeIn(delay: 240.ms, duration: 460.ms),
          const SizedBox(height: IntelliaSpacing.xl),
          ...card.points.asMap().entries.map((e) {
            return Padding(
                  padding: const EdgeInsets.only(bottom: IntelliaSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: IntelliaSpacing.sm),
                      Expanded(
                        child: Text(
                          e.value,
                          style: GoogleFonts.montserrat(
                            fontSize: 15.5,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            color: IntelliaColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(delay: (360 + e.key * 110).ms, duration: 420.ms)
                .slideX(begin: 0.08, end: 0, delay: (360 + e.key * 110).ms);
          }),
        ],
      ),
    );
  }
}

// ── Question (avec révélation) ──────────────────────────────────────────────
class FlowQuestionCardView extends StatefulWidget {
  const FlowQuestionCardView({required this.card, super.key});
  final FlowQuestionCard card;

  @override
  State<FlowQuestionCardView> createState() => _FlowQuestionCardViewState();
}

class _FlowQuestionCardViewState extends State<FlowQuestionCardView> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final accent = card.subject.accent;
    return FlowCardScaffold(
      subject: card.subject,
      kicker: card.kicker,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.help_outline_rounded, size: 34, color: accent)
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.6, 0.6), end: const Offset(1, 1)),
          const SizedBox(height: IntelliaSpacing.md),
          Text(card.question, style: _title(context))
              .animate()
              .fadeIn(delay: 140.ms, duration: 460.ms)
              .slideY(begin: 0.12, end: 0, delay: 140.ms),
          const SizedBox(height: IntelliaSpacing.lg),
          AnimatedCrossFade(
            duration: IntelliaMotion.slow,
            sizeCurve: Curves.easeOutCubic,
            crossFadeState: _revealed
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: _revealButton(accent),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(IntelliaSpacing.md),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(IntelliaRadii.large),
                border: Border.all(color: accent.withValues(alpha: 0.22)),
              ),
              child: Text(card.answer, style: _body()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _revealButton(Color accent) => IntelliaPressable(
    onTap: () {
      HapticFeedback.selectionClick();
      setState(() => _revealed = true);
    },
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: IntelliaSpacing.lg,
        vertical: IntelliaSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(IntelliaRadii.full),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 16, color: accent),
          const SizedBox(width: 8),
          Text(
            'Découvrir la réponse',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Capsule vidéo (poster + lecture simulée) ────────────────────────────────
class FlowVideoCardView extends StatefulWidget {
  const FlowVideoCardView({required this.card, super.key});
  final FlowVideoCard card;

  @override
  State<FlowVideoCardView> createState() => _FlowVideoCardViewState();
}

class _FlowVideoCardViewState extends State<FlowVideoCardView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.card.estimatedSeconds),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!reduced && !_progress.isAnimating) _progress.forward();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    return FlowCardScaffold(
      subject: card.subject,
      kicker: card.kicker,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(IntelliaRadii.extraLarge),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(gradient: card.subject.gradient),
                  ),
                  Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                            boxShadow: IntelliaShadows.glow(
                              Colors.black,
                              intensity: 0.18,
                            ),
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            size: 40,
                            color: card.subject.accent,
                          ),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .scaleXY(
                        begin: 1,
                        end: 1.06,
                        duration: 1100.ms,
                        curve: Curves.easeInOut,
                      ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Row(
                      children: [
                        Expanded(
                          child: AnimatedBuilder(
                            animation: _progress,
                            builder: (context, _) => ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: _progress.value,
                                minHeight: 4,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.3,
                                ),
                                valueColor: const AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          card.durationLabel,
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: IntelliaSpacing.lg),
          Text(card.title, style: _title(context)),
          const SizedBox(height: IntelliaSpacing.sm),
          Text(card.description, style: _body()),
        ],
      ).animate().fadeIn(duration: 420.ms),
    );
  }
}

// ── Animation conceptuelle ──────────────────────────────────────────────────
class FlowAnimationCardView extends StatelessWidget {
  const FlowAnimationCardView({required this.card, super.key});
  final FlowAnimationCard card;

  @override
  Widget build(BuildContext context) {
    return FlowCardScaffold(
      subject: card.subject,
      kicker: card.kicker,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: IntelliaColors.surfaceSolid.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(IntelliaRadii.extraLarge),
                border: Border.all(
                  color: card.subject.accent.withValues(alpha: 0.12),
                ),
              ),
              child: FlowConceptAnimation(
                kind: card.kind,
                accent: card.subject.accent,
              ),
            ),
          ),
          const SizedBox(height: IntelliaSpacing.lg),
          Text(card.title, style: _title(context)),
          const SizedBox(height: IntelliaSpacing.sm),
          Text(card.caption, style: _body()),
        ],
      ).animate().fadeIn(duration: 420.ms),
    );
  }
}

// ── Anecdote ────────────────────────────────────────────────────────────────
class FlowAnecdoteCardView extends StatelessWidget {
  const FlowAnecdoteCardView({required this.card, super.key});
  final FlowAnecdoteCard card;

  @override
  Widget build(BuildContext context) {
    final accent = card.subject.accent;
    return FlowCardScaffold(
      subject: card.subject,
      kicker: card.kicker,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '“',
            style: GoogleFonts.playfairDisplay(
              fontSize: 72,
              height: 0.8,
              fontWeight: FontWeight.w700,
              color: accent.withValues(alpha: 0.55),
            ),
          ).animate().fadeIn(duration: 420.ms),
          const SizedBox(height: IntelliaSpacing.xs),
          Text(card.title, style: _title(context))
              .animate()
              .fadeIn(delay: 140.ms, duration: 460.ms)
              .slideY(begin: 0.12, end: 0, delay: 140.ms),
          const SizedBox(height: IntelliaSpacing.md),
          Text(
            card.story,
            style: _body().copyWith(fontSize: 17, height: 1.6),
          ).animate().fadeIn(delay: 260.ms, duration: 460.ms),
        ],
      ),
    );
  }
}
