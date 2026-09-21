import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/widgets/tab_presentation.dart';
import '../domain/interactive_block.dart';
import '../domain/ordering_session.dart';

/// Identité du compagnon qui propose l'activité.
class ExerciseCompanion {
  const ExerciseCompanion({
    required this.id,
    required this.name,
    required this.avatarAsset,
  });

  final String id;
  final String name;
  final String avatarAsset;

  bool get isLeo => id == 'leo';
}

/// Activité d'ordre : phrase à reconstruire (en ligne) ou étapes à remettre
/// dans l'ordre (empilée). Tout fonctionne hors ligne.
class OrderingExerciseView extends StatefulWidget {
  const OrderingExerciseView({
    required this.block,
    required this.companion,
    this.onOutcome,
    this.onContinue,
    this.random,
    super.key,
  });

  final OrderingBlock block;
  final ExerciseCompanion companion;
  final ValueChanged<ActivityOutcome>? onOutcome;
  final VoidCallback? onContinue;

  /// Source du mélange initial, injectable pour les tests.
  final Random? random;

  @override
  State<OrderingExerciseView> createState() => _OrderingExerciseViewState();
}

enum _Feedback { none, correct, almost, hint, solution }

class _OrderingExerciseViewState extends State<OrderingExerciseView> {
  late OrderingSession _session;
  _Feedback _feedback = _Feedback.none;
  String? _hintText;
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    _session = OrderingSession(widget.block, random: widget.random);
  }

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  void _update(VoidCallback change) {
    setState(() {
      change();
      if (_feedback != _Feedback.solution && _feedback != _Feedback.correct) {
        _feedback = _Feedback.none;
      }
    });
  }

  void _place(String id, {int? index}) {
    HapticFeedback.selectionClick();
    _update(() => _session.place(id, index: index));
  }

  void _remove(String id) {
    HapticFeedback.selectionClick();
    _update(() => _session.remove(id));
  }

  void _move(int from, int to) {
    HapticFeedback.selectionClick();
    _update(() => _session.move(from, to));
  }

  void _check() {
    final result = _session.check();
    setState(() {
      _feedback = result.correct ? _Feedback.correct : _Feedback.almost;
      _hintText = null;
    });
    if (result.correct) {
      HapticFeedback.lightImpact();
      _report();
    }
  }

  void _hint() {
    final hint = _session.nextHint();
    if (hint == null) return;
    setState(() {
      _feedback = _Feedback.hint;
      _hintText = hint.text ?? context.l10n.ilbPositionHint(hint.position ?? 1);
    });
  }

  void _reveal() {
    setState(() {
      _session.revealSolution();
      _feedback = _Feedback.solution;
    });
    _report();
  }

  void _restart() {
    setState(() {
      _session.reset();
      _feedback = _Feedback.none;
      _hintText = null;
    });
  }

  void _report() {
    if (_reported) return;
    _reported = true;
    widget.onOutcome?.call(_session.toOutcome());
  }

  String _companionLine(BuildContext context) {
    final l10n = context.l10n;
    final inline = _session.isInline;
    if (widget.companion.isLeo) {
      return inline ? l10n.ilbLeoWords : l10n.ilbLeoSteps;
    }
    return inline ? l10n.ilbKiraWords : l10n.ilbKiraSteps;
  }

  String _instruction(BuildContext context) {
    final given = widget.block.instruction;
    if (given != null) return given;
    final l10n = context.l10n;
    return switch (widget.block.type) {
      InteractiveBlockType.wordOrder => l10n.ilbWordOrderInstruction,
      InteractiveBlockType.timelineOrder => l10n.ilbTimelineInstruction,
      InteractiveBlockType.processSequence => l10n.ilbProcessInstruction,
      _ => l10n.ilbStepOrderInstruction,
    };
  }

  String _feedbackText(BuildContext context) {
    final l10n = context.l10n;
    return switch (_feedback) {
      _Feedback.none => '',
      _Feedback.correct => switch (_session.attempts % 3) {
        1 => l10n.ilbCorrect1,
        2 => l10n.ilbCorrect2,
        _ => l10n.ilbCorrect3,
      },
      _Feedback.almost => () {
        final position = _session.lastCheck?.firstWrongPosition;
        final nudge = position == null
            ? l10n.ilbTryAgain
            : l10n.ilbPositionHint(position);
        return '${l10n.ilbAlmost} $nudge';
      }(),
      _Feedback.hint => _hintText ?? '',
      _Feedback.solution => l10n.ilbSolutionShown,
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette =
        TabSurface.maybeOf(context) ??
        TabPalette.forBrightness(Theme.of(context).brightness);
    final l10n = context.l10n;
    final block = widget.block;
    final done = _session.completed;
    final explanation = block.explanation;

    return InteractiveExerciseCard(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExerciseCompanionHeader(
            companion: widget.companion,
            line: _companionLine(context),
            palette: palette,
            trailing: ExerciseProgress(
              attempt: done ? max(_session.attempts, 1) : _session.attempts + 1,
              hintsUsed: _session.hintsShown,
              palette: palette,
            ),
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          Text(
            _instruction(context),
            style: GoogleFonts.manrope(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1.3,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          if (_session.isInline) ...[
            AnswerZone(
              session: _session,
              palette: palette,
              reduceMotion: _reduceMotion,
              highlightPosition: _feedback == _Feedback.almost
                  ? _session.lastCheck?.firstWrongPosition
                  : null,
              solved: done,
              onRemove: _remove,
              onPlace: _place,
            ),
            const SizedBox(height: IntelliaSpacing.sm),
            _WordBank(
              session: _session,
              palette: palette,
              reduceMotion: _reduceMotion,
              onPlace: _place,
            ),
          ] else
            _StackedOrdering(
              session: _session,
              palette: palette,
              reduceMotion: _reduceMotion,
              highlightPosition: _feedback == _Feedback.almost
                  ? _session.lastCheck?.firstWrongPosition
                  : null,
              solved: done,
              onMove: _move,
            ),
          ExerciseFeedback(
            text: _feedbackText(context),
            positive: _feedback == _Feedback.correct,
            palette: palette,
            reduceMotion: _reduceMotion,
          ),
          if (done && explanation != null) ...[
            const SizedBox(height: IntelliaSpacing.xs),
            Text(
              explanation,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                height: 1.45,
                color: palette.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: IntelliaSpacing.sm),
          Wrap(
            spacing: IntelliaSpacing.xs,
            runSpacing: IntelliaSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (!done)
                FilledButton(
                  onPressed: _session.readyToCheck ? _check : null,
                  child: Text(l10n.ilbCheck),
                ),
              if (!done)
                TextButton.icon(
                  onPressed: _hint,
                  icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
                  label: Text(l10n.ilbHint),
                ),
              if (!done)
                TextButton(onPressed: _restart, child: Text(l10n.ilbRestart)),
              if (_session.canRevealSolution)
                TextButton(
                  onPressed: _reveal,
                  child: Text(l10n.ilbShowSolution),
                ),
              if (done && widget.onContinue != null)
                FilledButton.tonal(
                  onPressed: widget.onContinue,
                  child: Text(l10n.ilbContinueWith(widget.companion.name)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Carte commune des activités : même maison que le reste de l'application.
class InteractiveExerciseCard extends StatelessWidget {
  const InteractiveExerciseCard({
    required this.palette,
    required this.child,
    super.key,
  });

  final TabPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(IntelliaSpacing.md),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(IntelliaRadii.large),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isLight ? 0.05 : 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Le compagnon qui propose l'activité, discret : l'exercice reste l'essentiel.
class ExerciseCompanionHeader extends StatelessWidget {
  const ExerciseCompanionHeader({
    required this.companion,
    required this.line,
    required this.palette,
    this.trailing,
    super.key,
  });

  final ExerciseCompanion companion;
  final String line;
  final TabPalette palette;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.accentSoft,
              image: DecorationImage(
                image: AssetImage(companion.avatarAsset),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(width: IntelliaSpacing.xs),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${companion.name} · ',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(text: line),
              ],
            ),
            style: GoogleFonts.montserrat(
              fontSize: 13,
              height: 1.4,
              color: palette.textSecondary,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: IntelliaSpacing.xs),
          // Bornée : à grand facteur de texte, la progression passe à la
          // ligne au lieu de pousser la phrase du compagnon hors de l'écran.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 104),
            child: trailing!,
          ),
        ],
      ],
    );
  }
}

/// Progression discrète : essai en cours et indices utilisés.
class ExerciseProgress extends StatelessWidget {
  const ExerciseProgress({
    required this.attempt,
    required this.hintsUsed,
    required this.palette,
    super.key,
  });

  final int attempt;
  final int hintsUsed;
  final TabPalette palette;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          l10n.ilbAttempt(attempt),
          textAlign: TextAlign.end,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: palette.accent,
          ),
        ),
        Text(
          l10n.ilbHintsUsed(hintsUsed),
          textAlign: TextAlign.end,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            color: palette.textTertiary,
          ),
        ),
      ],
    );
  }
}

/// Retour après vérification : jamais une croix rouge, une indication.
class ExerciseFeedback extends StatelessWidget {
  const ExerciseFeedback({
    required this.text,
    required this.positive,
    required this.palette,
    required this.reduceMotion,
    super.key,
  });

  final String text;
  final bool positive;
  final TabPalette palette;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final child = text.isEmpty
        ? const SizedBox(key: ValueKey('feedback-empty'), height: 0)
        : Padding(
            key: ValueKey(text),
            padding: const EdgeInsets.only(top: IntelliaSpacing.sm),
            child: Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    positive
                        ? Icons.check_circle_rounded
                        : Icons.lightbulb_rounded,
                    size: 20,
                    color: positive ? palette.success : palette.accent,
                  ),
                  const SizedBox(width: IntelliaSpacing.xs),
                  Expanded(
                    child: Text(
                      text,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
    if (reduceMotion) return child;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(sizeFactor: animation, child: child),
      ),
      child: child,
    );
  }
}

/// Zone de construction : les cartes placées, dans l'ordre choisi.
class AnswerZone extends StatelessWidget {
  const AnswerZone({
    required this.session,
    required this.palette,
    required this.reduceMotion,
    required this.solved,
    required this.onRemove,
    required this.onPlace,
    this.highlightPosition,
    super.key,
  });

  final OrderingSession session;
  final TabPalette palette;
  final bool reduceMotion;
  final bool solved;
  final int? highlightPosition;
  final ValueChanged<String> onRemove;
  final void Function(String id, {int? index}) onPlace;

  static const zoneKey = ValueKey('ilb-answer-zone');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final block = session.block;
    return Semantics(
      container: true,
      label: l10n.ilbAnswerZoneA11y,
      child: DragTarget<String>(
        onWillAcceptWithDetails: (_) => !session.completed,
        onAcceptWithDetails: (details) => onPlace(details.data),
        builder: (context, candidates, _) {
          final hovering = candidates.isNotEmpty;
          return AnimatedContainer(
            key: zoneKey,
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 160),
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.all(IntelliaSpacing.xs),
            decoration: BoxDecoration(
              color: solved
                  ? palette.success.withValues(alpha: 0.08)
                  : hovering
                  ? palette.accentSoft
                  : palette.surfaceMuted,
              borderRadius: BorderRadius.circular(IntelliaRadii.medium),
              border: Border.all(
                color: solved
                    ? palette.success.withValues(alpha: 0.6)
                    : hovering
                    ? palette.accent
                    : palette.border,
                width: hovering ? 2 : 1,
              ),
            ),
            child: session.answer.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(IntelliaSpacing.sm),
                    child: Text(
                      l10n.ilbAnswerZoneEmpty,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: palette.textTertiary,
                      ),
                    ),
                  )
                : Wrap(
                    spacing: IntelliaSpacing.xs,
                    runSpacing: IntelliaSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (var i = 0; i < session.answer.length; i++)
                        _Appear(
                          key: ValueKey('answer-${session.answer[i]}'),
                          reduceMotion: reduceMotion,
                          child: DragTarget<String>(
                            onWillAcceptWithDetails: (details) =>
                                !session.completed &&
                                details.data != session.answer[i],
                            onAcceptWithDetails: (details) =>
                                onPlace(details.data, index: i),
                            builder: (context, _, _) => WordTile(
                              id: session.answer[i],
                              text: block.itemById(session.answer[i]).text,
                              placed: true,
                              palette: palette,
                              enabled: !session.completed,
                              emphasis: highlightPosition == i + 1
                                  ? WordTileEmphasis.review
                                  : solved
                                  ? WordTileEmphasis.solved
                                  : WordTileEmphasis.none,
                              semanticLabel: l10n.ilbRemoveWordA11y(
                                block.itemById(session.answer[i]).text,
                                i + 1,
                              ),
                              onTap: () => onRemove(session.answer[i]),
                            ),
                          ),
                        ),
                      if (block.trailing != null)
                        ExcludeSemantics(
                          child: Text(
                            block.trailing!,
                            style: GoogleFonts.manrope(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _WordBank extends StatelessWidget {
  const _WordBank({
    required this.session,
    required this.palette,
    required this.reduceMotion,
    required this.onPlace,
  });

  final OrderingSession session;
  final TabPalette palette;
  final bool reduceMotion;
  final void Function(String id, {int? index}) onPlace;

  static const bankKey = ValueKey('ilb-word-bank');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      container: true,
      label: l10n.ilbWordBankA11y,
      child: SizedBox(
        key: bankKey,
        width: double.infinity,
        child: Wrap(
          spacing: IntelliaSpacing.xs,
          runSpacing: IntelliaSpacing.xs,
          children: [
            for (final id in session.bank)
              _Appear(
                key: ValueKey('bank-$id'),
                reduceMotion: reduceMotion,
                child: LongPressDraggable<String>(
                  data: id,
                  delay: const Duration(milliseconds: 150),
                  feedback: Material(
                    color: Colors.transparent,
                    child: WordTile(
                      id: id,
                      text: session.block.itemById(id).text,
                      placed: false,
                      palette: palette,
                      lifted: true,
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: WordTile(
                      id: id,
                      text: session.block.itemById(id).text,
                      placed: false,
                      palette: palette,
                      enabled: false,
                    ),
                  ),
                  child: WordTile(
                    id: id,
                    text: session.block.itemById(id).text,
                    placed: false,
                    palette: palette,
                    enabled: !session.completed,
                    semanticLabel: l10n.ilbPlaceWordA11y(
                      session.block.itemById(id).text,
                    ),
                    onTap: () => onPlace(id),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum WordTileEmphasis { none, review, solved }

/// Carte manipulable : grande cible tactile, texte très lisible.
class WordTile extends StatelessWidget {
  const WordTile({
    required this.id,
    required this.text,
    required this.placed,
    required this.palette,
    this.onTap,
    this.enabled = true,
    this.lifted = false,
    this.emphasis = WordTileEmphasis.none,
    this.semanticLabel,
    super.key,
  });

  final String id;
  final String text;
  final bool placed;
  final TabPalette palette;
  final VoidCallback? onTap;
  final bool enabled;
  final bool lifted;
  final WordTileEmphasis emphasis;
  final String? semanticLabel;

  static ValueKey<String> keyFor(String id, {required bool placed}) =>
      ValueKey('ilb-tile-${placed ? 'answer' : 'bank'}-$id');

  @override
  Widget build(BuildContext context) {
    final border = switch (emphasis) {
      WordTileEmphasis.review => palette.warning,
      WordTileEmphasis.solved => palette.success.withValues(alpha: 0.7),
      WordTileEmphasis.none => placed ? palette.accent : palette.border,
    };
    final tile = Material(
      key: keyFor(id, placed: placed),
      color: placed ? palette.accentSoft : palette.surface,
      elevation: lifted ? 6 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: border,
          width: emphasis == WordTileEmphasis.review ? 2 : 1.2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
    if (semanticLabel == null) return ExcludeSemantics(child: tile);
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: enabled ? onTap : null,
      child: tile,
    );
  }
}

/// Étapes empilées : glisser une étape sur une autre, ou la monter et la
/// descendre (clavier, lecteur d'écran).
class _StackedOrdering extends StatelessWidget {
  const _StackedOrdering({
    required this.session,
    required this.palette,
    required this.reduceMotion,
    required this.solved,
    required this.onMove,
    this.highlightPosition,
  });

  final OrderingSession session;
  final TabPalette palette;
  final bool reduceMotion;
  final bool solved;
  final int? highlightPosition;
  final void Function(int from, int to) onMove;

  static const listKey = ValueKey('ilb-stacked-list');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      key: listKey,
      children: [
        for (var i = 0; i < session.answer.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: IntelliaSpacing.xs),
            child: _Appear(
              key: ValueKey('step-${session.answer[i]}-$i'),
              reduceMotion: reduceMotion,
              child: DragTarget<int>(
                onWillAcceptWithDetails: (details) =>
                    !session.completed && details.data != i,
                onAcceptWithDetails: (details) => onMove(details.data, i),
                builder: (context, candidates, _) => LongPressDraggable<int>(
                  data: i,
                  delay: const Duration(milliseconds: 150),
                  feedback: const SizedBox.shrink(),
                  child: _StepRow(
                    position: i + 1,
                    text: session.block.itemById(session.answer[i]).text,
                    palette: palette,
                    hovering: candidates.isNotEmpty,
                    emphasis: highlightPosition == i + 1
                        ? WordTileEmphasis.review
                        : solved
                        ? WordTileEmphasis.solved
                        : WordTileEmphasis.none,
                    semanticLabel: l10n.ilbStepA11y(
                      i + 1,
                      session.block.itemById(session.answer[i]).text,
                    ),
                    onUp: session.completed || i == 0
                        ? null
                        : () => onMove(i, i - 1),
                    onDown: session.completed || i == session.answer.length - 1
                        ? null
                        : () => onMove(i, i + 1),
                    upLabel: l10n.ilbMoveUp,
                    downLabel: l10n.ilbMoveDown,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.position,
    required this.text,
    required this.palette,
    required this.hovering,
    required this.emphasis,
    required this.semanticLabel,
    required this.onUp,
    required this.onDown,
    required this.upLabel,
    required this.downLabel,
  });

  final int position;
  final String text;
  final TabPalette palette;
  final bool hovering;
  final WordTileEmphasis emphasis;
  final String semanticLabel;
  final VoidCallback? onUp;
  final VoidCallback? onDown;
  final String upLabel;
  final String downLabel;

  @override
  Widget build(BuildContext context) {
    final border = switch (emphasis) {
      WordTileEmphasis.review => palette.warning,
      WordTileEmphasis.solved => palette.success.withValues(alpha: 0.7),
      WordTileEmphasis.none => hovering ? palette.accent : palette.border,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: IntelliaSpacing.sm,
        vertical: IntelliaSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: hovering ? palette.accentSoft : palette.surface,
        borderRadius: BorderRadius.circular(IntelliaRadii.medium),
        border: Border.all(
          color: border,
          width: emphasis == WordTileEmphasis.review ? 2 : 1.2,
        ),
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.accentSoft,
              ),
              child: Text(
                '$position',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: palette.accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: IntelliaSpacing.sm),
          Expanded(
            child: Semantics(
              label: semanticLabel,
              excludeSemantics: true,
              child: Text(
                text,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: palette.textPrimary,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: upLabel,
            onPressed: onUp,
            icon: const Icon(Icons.keyboard_arrow_up_rounded),
          ),
          IconButton(
            tooltip: downLabel,
            onPressed: onDown,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
        ],
      ),
    );
  }
}

/// Apparition douce d'une carte dans sa nouvelle zone : jamais de saut brutal.
class _Appear extends StatelessWidget {
  const _Appear({required this.child, required this.reduceMotion, super.key});

  final Widget child;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      // La carte reste annoncée par le lecteur d'écran pendant son fondu.
      builder: (context, value, child) => Opacity(
        alwaysIncludeSemantics: true,
        opacity: ((value - 0.9) * 10).clamp(0.0, 1.0),
        child: Transform.scale(scale: value, child: child),
      ),
      child: child,
    );
  }
}
