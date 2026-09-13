import 'flow_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../application/flow_controller.dart';
import '../../domain/flow_card.dart';
import 'flow_card_scaffold.dart';

class FlowTrueFalseCardView extends ConsumerStatefulWidget {
  const FlowTrueFalseCardView({
    required this.card,
    required this.onAward,
    super.key,
  });

  final FlowTrueFalseCard card;
  final ValueChanged<FlowAward> onAward;

  @override
  ConsumerState<FlowTrueFalseCardView> createState() =>
      _FlowTrueFalseCardViewState();
}

class _FlowTrueFalseCardViewState extends ConsumerState<FlowTrueFalseCardView> {
  bool? _answer;

  Future<void> _submit(bool answer) async {
    if (_answer != null) return;
    final correct = answer == widget.card.correctValue;
    setState(() => _answer = answer);
    _feedbackHaptic(correct);
    final award = await ref
        .read(flowControllerProvider.notifier)
        .answerExercise(widget.card, answer: answer, localCorrect: correct);
    if (!mounted) return;
    widget.onAward(award);
  }

  @override
  Widget build(BuildContext context) {
    final locked = _answer != null;
    final correct = _answer == widget.card.correctValue;
    return FlowCardScaffold(
      subject: widget.card.subject,
      kicker: widget.card.kicker,
      footer: locked
          ? _ExerciseFeedback(
              correct: correct,
              explanation: widget.card.explanation,
            )
          : null,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ExerciseTitle(widget.card.statement),
            const SizedBox(height: IntelliaSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: _ChoiceButton(
                    label: 'Vrai',
                    icon: Icons.check_rounded,
                    selected: _answer == true,
                    revealedCorrect: locked && widget.card.correctValue,
                    revealedWrong:
                        locked && _answer == true && !widget.card.correctValue,
                    onTap: locked ? null : () => _submit(true),
                  ),
                ),
                const SizedBox(width: IntelliaSpacing.sm),
                Expanded(
                  child: _ChoiceButton(
                    label: 'Faux',
                    icon: Icons.close_rounded,
                    selected: _answer == false,
                    revealedCorrect: locked && !widget.card.correctValue,
                    revealedWrong:
                        locked && _answer == false && widget.card.correctValue,
                    onTap: locked ? null : () => _submit(false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FlowFillBlankCardView extends ConsumerStatefulWidget {
  const FlowFillBlankCardView({
    required this.card,
    required this.onAward,
    super.key,
  });

  final FlowFillBlankCard card;
  final ValueChanged<FlowAward> onAward;

  @override
  ConsumerState<FlowFillBlankCardView> createState() =>
      _FlowFillBlankCardViewState();
}

class _FlowFillBlankCardViewState extends ConsumerState<FlowFillBlankCardView> {
  final _controller = TextEditingController();
  bool? _correct;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_correct != null || _controller.text.trim().isEmpty) return;
    final answer = _controller.text;
    final correct = widget.card.accepts(answer);
    setState(() => _correct = correct);
    FocusManager.instance.primaryFocus?.unfocus();
    _feedbackHaptic(correct);
    final award = await ref
        .read(flowControllerProvider.notifier)
        .answerExercise(widget.card, answer: answer, localCorrect: correct);
    if (!mounted) return;
    widget.onAward(award);
  }

  @override
  Widget build(BuildContext context) {
    final locked = _correct != null;
    return FlowCardScaffold(
      subject: widget.card.subject,
      kicker: widget.card.kicker,
      footer: locked
          ? _ExerciseFeedback(
              correct: _correct!,
              explanation: widget.card.explanation,
              correction: _correct!
                  ? null
                  : context.l10n.expectedAnswer(
                      widget.card.acceptedAnswers.first,
                    ),
            )
          : null,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ExerciseTitle(widget.card.prompt),
            if (widget.card.hint != null) ...[
              const SizedBox(height: IntelliaSpacing.sm),
              Text(
                'Indice : ${widget.card.hint}',
                style: GoogleFonts.montserrat(
                  color: IntelliaColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: IntelliaSpacing.xl),
            TextField(
              controller: _controller,
              enabled: !locked,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: context.l10n.yourAnswerLabel,
                hintText: context.l10n.missingAnswerHint,
                prefixIcon: const Icon(Icons.edit_rounded),
                suffixIcon: locked
                    ? Icon(
                        _correct!
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: _correct!
                            ? IntelliaColors.success
                            : IntelliaColors.error,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: IntelliaSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: locked ? null : _submit,
                icon: const Icon(Icons.check_rounded),
                label: Text(context.l10n.submitMyAnswer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FlowOrderingCardView extends ConsumerStatefulWidget {
  const FlowOrderingCardView({
    required this.card,
    required this.onAward,
    super.key,
  });

  final FlowOrderingCard card;
  final ValueChanged<FlowAward> onAward;

  @override
  ConsumerState<FlowOrderingCardView> createState() =>
      _FlowOrderingCardViewState();
}

class _FlowOrderingCardViewState extends ConsumerState<FlowOrderingCardView> {
  late final List<String> _items;
  bool? _correct;

  @override
  void initState() {
    super.initState();
    _items = widget.card.items.reversed.toList(growable: true);
  }

  Future<void> _submit() async {
    if (_correct != null) return;
    final correct = widget.card.accepts(_items);
    setState(() => _correct = correct);
    _feedbackHaptic(correct);
    final award = await ref
        .read(flowControllerProvider.notifier)
        .answerExercise(
          widget.card,
          answer: List<String>.of(_items),
          localCorrect: correct,
        );
    if (!mounted) return;
    widget.onAward(award);
  }

  @override
  Widget build(BuildContext context) {
    final locked = _correct != null;
    return FlowCardScaffold(
      subject: widget.card.subject,
      kicker: widget.card.kicker,
      footer: locked
          ? _ExerciseFeedback(
              correct: _correct!,
              explanation: widget.card.explanation,
              correction: _correct!
                  ? null
                  : 'Ordre attendu : ${widget.card.items.join(' → ')}',
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ExerciseTitle(widget.card.instruction),
          const SizedBox(height: IntelliaSpacing.md),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: !locked,
            itemCount: _items.length,
            onReorderItem: (oldIndex, newIndex) {
              if (locked) return;
              HapticFeedback.selectionClick();
              setState(() {
                final item = _items.removeAt(oldIndex);
                _items.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) => Card(
              key: ValueKey(_items[index]),
              margin: const EdgeInsets.only(bottom: IntelliaSpacing.sm),
              child: ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(_items[index]),
                trailing: locked ? null : const Icon(Icons.drag_handle_rounded),
              ),
            ),
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: locked ? null : _submit,
              icon: const Icon(Icons.rule_rounded),
              label: Text(context.l10n.checkOrder),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseTitle extends StatelessWidget {
  const _ExerciseTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: FlowTypography.title(context),
  ).animate().fadeIn(duration: 420.ms).slideY(begin: 0.1, end: 0);
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.revealedCorrect,
    required this.revealedWrong,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool revealedCorrect;
  final bool revealedWrong;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = revealedCorrect
        ? IntelliaColors.success
        : revealedWrong
        ? IntelliaColors.error
        : IntelliaColors.brandIndigo;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(IntelliaRadii.large),
        child: AnimatedContainer(
          duration: IntelliaMotion.fast,
          constraints: const BoxConstraints(minHeight: 88),
          decoration: BoxDecoration(
            color: color.withValues(alpha: selected ? 0.15 : 0.07),
            borderRadius: BorderRadius.circular(IntelliaRadii.large),
            border: Border.all(color: color.withValues(alpha: 0.45)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.montserrat(
                  color: IntelliaColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseFeedback extends StatelessWidget {
  const _ExerciseFeedback({
    required this.correct,
    required this.explanation,
    this.correction,
  });

  final bool correct;
  final String explanation;
  final String? correction;

  @override
  Widget build(BuildContext context) {
    final color = correct ? IntelliaColors.success : IntelliaColors.error;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(IntelliaSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(IntelliaRadii.large),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              correct ? Icons.check_circle_rounded : Icons.tips_and_updates,
              color: color,
            ),
            const SizedBox(width: IntelliaSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    correct ? 'Exact !' : 'Pas encore.',
                    style: GoogleFonts.montserrat(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (correction != null) Text(correction!),
                  Text(explanation),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.12, end: 0),
    );
  }
}

void _feedbackHaptic(bool correct) {
  if (correct) {
    HapticFeedback.mediumImpact();
  } else {
    HapticFeedback.heavyImpact();
  }
}
