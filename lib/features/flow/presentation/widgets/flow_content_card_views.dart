import 'flow_typography.dart';
import '../../../learn/presentation/widgets/educational_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../../core/widgets/intellia_pressable.dart';
import '../../domain/flow_card.dart';
import 'flow_card_scaffold.dart';
import 'flow_concept_animation.dart';

TextStyle _title(BuildContext context) => FlowTypography.title(context);
TextStyle _body(BuildContext context) => FlowTypography.body(context);

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
            style: _body(context),
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
              child: Text(card.answer, style: _body(context)),
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
          Icon(Icons.emoji_events_outlined, size: 16, color: accent),
          const SizedBox(width: 8),
          // Sur un écran étroit, le libellé passe à la ligne plutôt que de
          // déborder du bouton.
          Flexible(
            child: Text(
              context.l10n.discoverAnswer,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// The media reference is shared with the lesson and Studio preview.
class FlowVideoCardView extends StatelessWidget {
  const FlowVideoCardView({required this.card, super.key});
  final FlowVideoCard card;
  @override
  Widget build(BuildContext context) => FlowCardScaffold(
    subject: card.subject,
    kicker: card.kicker,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(card.title, style: _title(context)),
        const SizedBox(height: 16),
        if (card.storagePath?.isNotEmpty ?? false)
          EducationalVideoPlayer(
            storagePath: card.storagePath!,
            fileSizeBytes: card.fileSizeBytes,
          )
        else
          Text(context.l10n.parcoursVideoPending),
        const SizedBox(height: 16),
        Text(card.description, style: _body(context)),
      ],
    ),
  );
}

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
          AspectRatio(
            aspectRatio: 1.35,
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
          Text(card.caption, style: _body(context)),
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
            style: _body(context),
          ).animate().fadeIn(delay: 260.ms, duration: 460.ms),
        ],
      ),
    );
  }
}
