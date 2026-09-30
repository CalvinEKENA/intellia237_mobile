import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../domain/mastery.dart';
import '../../domain/question.dart';
import '../content_style.dart';

/// Même expérience hors ligne dans la leçon et dans Mon Parcours.
/// Le texte saisi n'est jamais envoyé ni comparé à la réponse modèle.
class OpenResponsePanel extends StatefulWidget {
  const OpenResponsePanel({
    required this.question,
    required this.onEvaluate,
    this.onNext,
    this.onHintShown,
    super.key,
  });

  final Question question;
  final Future<void> Function(SelfEvaluation) onEvaluate;
  final VoidCallback? onNext;
  final VoidCallback? onHintShown;

  @override
  State<OpenResponsePanel> createState() => _OpenResponsePanelState();
}

class _OpenResponsePanelState extends State<OpenResponsePanel> {
  final _answer = TextEditingController();
  bool _revealed = false;
  bool _saving = false;
  bool _saveFailed = false;
  int _hints = 0;
  SelfEvaluation? _evaluation;

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  Future<void> _evaluate(SelfEvaluation value) async {
    if (!_revealed || _saving || _evaluation != null) return;
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    try {
      await widget.onEvaluate(value);
      if (mounted) setState(() => _evaluation = value);
    } catch (_) {
      if (mounted) setState(() => _saveFailed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final question = widget.question;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.ceSelfEvaluation, style: ContentText.eyebrow()),
        const SizedBox(height: IntelliaSpacing.sm),
        Text(
          question.prompt,
          style: ContentText.body(size: 18, weight: FontWeight.w700),
        ),
        const SizedBox(height: IntelliaSpacing.sm),
        Text(l10n.ceOpenResponseHelp, style: ContentText.body(size: 14)),
        if (question.visibleFlags.isNotEmpty) ...[
          const SizedBox(height: IntelliaSpacing.sm),
          Text(l10n.ceSourceCaution, style: ContentText.label()),
          for (final flag in question.visibleFlags)
            Text(flag.issue, style: ContentText.body(size: 14)),
        ],
        const SizedBox(height: IntelliaSpacing.md),
        TextField(
          key: const ValueKey('open-response-input'),
          controller: _answer,
          readOnly: _revealed,
          minLines: 3,
          maxLines: 8,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          textCapitalization: TextCapitalization.sentences,
          scrollPadding: const EdgeInsets.all(32),
          decoration: InputDecoration(
            labelText: l10n.ceYourResponse,
            alignLabelWithHint: true,
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: IntelliaSpacing.md),
        if (!_revealed) ...[
          if (_hints < question.hints.length)
            TextButton.icon(
              key: const ValueKey('open-response-hint'),
              onPressed: () {
                setState(() => _hints++);
                widget.onHintShown?.call();
              },
              icon: const Icon(Icons.lightbulb_outline_rounded),
              label: Text(l10n.ceHint),
            ),
          for (final hint in question.hints.take(_hints))
            Padding(
              padding: const EdgeInsets.only(bottom: IntelliaSpacing.sm),
              child: Text(hint, style: ContentText.body()),
            ),
          FilledButton(
            key: const ValueKey('open-response-reveal'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _answer.text.trim().isEmpty
                ? null
                : () {
                    FocusScope.of(context).unfocus();
                    setState(() => _revealed = true);
                  },
            child: Text(l10n.ceRevealModel),
          ),
        ] else ...[
          Semantics(
            liveRegion: true,
            child: Text(l10n.ceModelAnswer, style: ContentText.label(size: 16)),
          ),
          const SizedBox(height: IntelliaSpacing.sm),
          SelectableText(
            question.modelAnswer!,
            key: const ValueKey('open-response-model'),
            style: ContentText.body(),
          ),
          if (question.explanation case final explanation?) ...[
            const SizedBox(height: IntelliaSpacing.md),
            Text(explanation, style: ContentText.body()),
          ],
          if (question.expectedPoints.isNotEmpty) ...[
            const SizedBox(height: IntelliaSpacing.md),
            Text(l10n.ceExpectedPoints, style: ContentText.label()),
            for (final point in question.expectedPoints)
              Text('• $point', style: ContentText.body()),
          ],
          const SizedBox(height: IntelliaSpacing.md),
          Text(l10n.ceSelfEvaluationHelp, style: ContentText.body(size: 14)),
          const SizedBox(height: IntelliaSpacing.sm),
          for (final value in SelfEvaluation.values)
            Padding(
              padding: const EdgeInsets.only(bottom: IntelliaSpacing.sm),
              child: Semantics(
                selected: _evaluation == value,
                child: OutlinedButton.icon(
                  key: ValueKey('self-evaluation-${value.key}'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: _saving || _evaluation != null
                      ? null
                      : () => _evaluate(value),
                  icon: Icon(
                    _evaluation == value
                        ? Icons.check_circle_outline
                        : Icons.radio_button_unchecked,
                  ),
                  label: Text(switch (value) {
                    SelfEvaluation.needsReview => l10n.ceNeedsReview,
                    SelfEvaluation.partialConfidence =>
                      l10n.cePartialConfidence,
                    SelfEvaluation.selfMastered => l10n.ceSelfMastered,
                  }),
                ),
              ),
            ),
          if (_saveFailed)
            Text(l10n.ceSelfSaveError, style: ContentText.body()),
          if (_evaluation != null) ...[
            Text(
              l10n.ceSelfEvaluationSaved,
              key: const ValueKey('self-evaluation-saved'),
              style: ContentText.body(size: 14),
            ),
            if (widget.onNext != null)
              FilledButton(
                key: const ValueKey('open-response-next'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: widget.onNext,
                child: Text(l10n.ceNextQuestion),
              ),
          ],
        ],
      ],
    );
  }
}
