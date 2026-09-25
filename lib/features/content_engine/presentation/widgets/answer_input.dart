import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../domain/question.dart';
import '../../engine/answer_checker.dart';
import '../content_style.dart';

/// Libellé d'un champ de réponse. Vocabulaire commun aux packs ; une clé
/// inconnue est montrée telle quelle.
String fieldLabel(BuildContext context, String key) {
  final l10n = context.l10n;
  final normalized = key.toLowerCase();
  if (normalized == 'q') return l10n.ceFieldQuotient;
  if (normalized == 'r') return l10n.ceFieldRemainder;
  if (normalized == 'b') return l10n.ceFieldDivisor;
  if (normalized == 'gcd') return l10n.ceGcd;
  if (normalized == 'lcm') return l10n.ceLcm;
  if (normalized == 'binary') return l10n.ceFieldBinary;
  if (normalized == 'decimal') return l10n.ceFieldDecimal;
  if (normalized == 'decomposition') return l10n.ceFieldDecomposition;
  if (normalized.startsWith('litre') || normalized.startsWith('liter')) {
    return l10n.ceFieldLitres;
  }
  if (normalized.startsWith('bucket')) return l10n.ceFieldBuckets;
  return key;
}

/// Saisie adaptée à la forme de la réponse attendue.
///
/// [onChanged] reçoit `null` tant que la réponse est incomplète.
class AnswerInput extends StatefulWidget {
  const AnswerInput({
    required this.question,
    required this.onChanged,
    this.enabled = true,
    this.grade,
    super.key,
  });

  final Question question;
  final ValueChanged<StudentResponse?> onChanged;
  final bool enabled;
  final GradeResult? grade;

  @override
  State<AnswerInput> createState() => _AnswerInputState();
}

class _AnswerInputState extends State<AnswerInput> {
  final _controllers = <String, TextEditingController>{};
  AnswerAtom? _choice;
  final _choices = <AnswerAtom>{};
  bool? _bool;
  final _set = <int>{};

  TextEditingController _controller(String key) =>
      _controllers.putIfAbsent(key, () {
        final controller = TextEditingController();
        controller.addListener(_emit);
        return controller;
      });

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _emit() => widget.onChanged(_response());

  StudentResponse? _response() {
    final answer = widget.question.answer;
    String text(String key) => _controller(key).text.trim();
    return switch (answer) {
      ScalarAnswer() || MultisetAnswer() || FactorizationAnswer() =>
        text('value').isEmpty ? null : TextResponse(text('value')),
      FieldsAnswer(:final fields) =>
        fields.keys.any((key) => text(key).isEmpty)
            ? null
            : FieldsResponse({for (final key in fields.keys) key: text(key)}),
      ChoiceAnswer() => _choice == null ? null : ChoiceResponse(_choice!),
      MultiChoiceAnswer() =>
        _choices.isEmpty ? null : MultiChoiceResponse({..._choices}),
      BooleanAnswer() ||
      VerdictAnswer() => _bool == null ? null : BooleanResponse(_bool!),
      IntegerSetAnswer() || CongruenceSetAnswer() =>
        _set.isEmpty ? null : IntegerSetResponse({..._set}),
      UnscorableAnswer() => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final answer = widget.question.answer;
    return switch (answer) {
      ScalarAnswer(:final value) => _field(
        'value',
        label: context.l10n.ceYourAnswer,
        numeric: value.isInteger || RegExp(r'^[01]+$').hasMatch(value.display),
      ),
      MultisetAnswer() => _field(
        'value',
        label: context.l10n.ceYourAnswer,
        hint: context.l10n.ceListHint,
      ),
      FactorizationAnswer() => _factorization(),
      FieldsAnswer(:final fields) => Column(
        children: [
          for (final entry in fields.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: IntelliaSpacing.sm),
              child: _field(
                entry.key,
                label: fieldLabel(context, entry.key),
                numeric:
                    entry.value is ScalarAnswer &&
                    (entry.value as ScalarAnswer).value.isInteger,
                hint: entry.value is MultisetAnswer
                    ? context.l10n.ceListHint
                    : null,
                status: widget.grade?.fieldResults[entry.key],
              ),
            ),
        ],
      ),
      ChoiceAnswer() => _choiceChips(multi: false),
      MultiChoiceAnswer() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.ceSelectAll,
            style: ContentText.body(color: ContentPalette.inkSoft, size: 13),
          ),
          const SizedBox(height: 6),
          _choiceChips(multi: true),
        ],
      ),
      BooleanAnswer() => _binary(context.l10n.ceTrue, context.l10n.ceFalse),
      VerdictAnswer() => _binary(context.l10n.ceYes, context.l10n.ceNo),
      IntegerSetAnswer() => _integerSet(),
      CongruenceSetAnswer(:final modulus) => _residues(modulus),
      UnscorableAnswer() => const SizedBox.shrink(),
    };
  }

  Widget _field(
    String key, {
    required String label,
    bool numeric = false,
    String? hint,
    bool? status,
  }) {
    final color = status == null
        ? ContentPalette.accent
        : status
        ? ContentPalette.success
        : ContentPalette.error;
    final field = TextField(
      key: ValueKey('answer-field-$key'),
      controller: _controller(key),
      enabled: widget.enabled,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(signed: true)
          : TextInputType.text,
      inputFormatters: [LengthLimitingTextInputFormatter(60)],
      style: ContentText.math(size: 20),
      decoration: InputDecoration(
        hintText: hint,
        hintMaxLines: 3,
        filled: true,
        fillColor: Colors.white,
        suffixIcon: status == null
            ? null
            : Icon(
                status ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: color,
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(IntelliaRadii.medium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(IntelliaRadii.medium),
          borderSide: BorderSide(
            color: status == null ? ContentPalette.line : color,
            width: status == null ? 1 : 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(IntelliaRadii.medium),
          borderSide: BorderSide(color: color, width: 2),
        ),
      ),
    );
    // Libellé au-dessus du champ : il passe à la ligne au lieu d'être
    // coupé, et reste annoncé avec le champ par les lecteurs d'écran.
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: ContentText.label(size: 13.5)),
          const SizedBox(height: 4),
          field,
        ],
      ),
    );
  }

  Widget _factorization() {
    final controller = _controller('value');
    void insert(String symbol) {
      final selection = controller.selection;
      final text = controller.text;
      final start = selection.isValid ? selection.start : text.length;
      final end = selection.isValid ? selection.end : text.length;
      controller.value = TextEditingValue(
        text: text.replaceRange(start, end, symbol),
        selection: TextSelection.collapsed(offset: start + symbol.length),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(
          'value',
          label: context.l10n.ceYourAnswer,
          hint: context.l10n.ceFactorizationHint,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          children: [
            for (final symbol in const ['×', '²', '³', '^'])
              ActionChip(
                label: Text(symbol, style: ContentText.math(size: 16)),
                onPressed: widget.enabled ? () => insert(symbol) : null,
              ),
          ],
        ),
      ],
    );
  }

  Widget _choiceChips({required bool multi}) => Wrap(
    spacing: IntelliaSpacing.xs,
    runSpacing: IntelliaSpacing.xs,
    children: [
      for (final choice in widget.question.choices)
        ChoiceChip(
          key: ValueKey('answer-choice-${choice.display}'),
          label: Text(choice.display, style: ContentText.math(size: 17)),
          selected: multi ? _choices.contains(choice) : _choice == choice,
          showCheckmark: multi,
          selectedColor: ContentPalette.accent.withValues(alpha: 0.18),
          onSelected: widget.enabled
              ? (selected) {
                  setState(() {
                    if (multi) {
                      selected ? _choices.add(choice) : _choices.remove(choice);
                    } else {
                      _choice = choice;
                    }
                  });
                  _emit();
                }
              : null,
        ),
    ],
  );

  Widget _binary(String yes, String no) => Row(
    children: [
      for (final (value, label) in [(true, yes), (false, no)]) ...[
        Expanded(
          child: _BigToggle(
            key: ValueKey('answer-bool-$value'),
            label: label,
            selected: _bool == value,
            onTap: widget.enabled
                ? () {
                    setState(() => _bool = value);
                    _emit();
                  }
                : null,
          ),
        ),
        if (value) const SizedBox(width: IntelliaSpacing.sm),
      ],
    ],
  );

  Widget _integerSet() {
    final controller = _controller('pending');
    void add() {
      final values = parseIntegerList(controller.text);
      if (values == null) return;
      setState(() => _set.addAll(values));
      controller.clear();
      _emit();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.ceSetPrompt,
          style: ContentText.body(color: ContentPalette.inkSoft, size: 13),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('answer-set-input'),
                controller: controller,
                enabled: widget.enabled,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
                onSubmitted: (_) => add(),
                style: ContentText.math(size: 18),
                decoration: InputDecoration(
                  hintText: context.l10n.ceListHint,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(IntelliaRadii.medium),
                  ),
                ),
              ),
            ),
            const SizedBox(width: IntelliaSpacing.xs),
            FilledButton(
              key: const ValueKey('answer-set-add'),
              onPressed: widget.enabled ? add : null,
              child: Text(context.l10n.ceAddValue),
            ),
          ],
        ),
        const SizedBox(height: IntelliaSpacing.xs),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final value in (_set.toList()..sort()))
              InputChip(
                label: Text('$value', style: ContentText.math(size: 16)),
                onDeleted: widget.enabled
                    ? () {
                        setState(() => _set.remove(value));
                        _emit();
                      }
                    : null,
              ),
          ],
        ),
      ],
    );
  }

  Widget _residues(int modulus) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        context.l10n.ceResiduesPrompt(modulus),
        style: ContentText.body(color: ContentPalette.inkSoft, size: 13),
      ),
      const SizedBox(height: 6),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (var r = 0; r < modulus; r++)
            FilterChip(
              key: ValueKey('answer-residue-$r'),
              label: Text('$r', style: ContentText.math(size: 17)),
              selected: _set.contains(r),
              onSelected: widget.enabled
                  ? (selected) {
                      setState(() => selected ? _set.add(r) : _set.remove(r));
                      _emit();
                    }
                  : null,
            ),
        ],
      ),
    ],
  );
}

class _BigToggle extends StatelessWidget {
  const _BigToggle({
    required this.label,
    required this.selected,
    this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? ContentPalette.accent : Colors.white,
    borderRadius: BorderRadius.circular(IntelliaRadii.medium),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(IntelliaRadii.medium),
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(IntelliaRadii.medium),
          border: Border.all(
            color: selected ? ContentPalette.accent : ContentPalette.line,
          ),
        ),
        child: Text(
          label,
          style: ContentText.label(
            size: 16,
            color: selected ? Colors.white : ContentPalette.ink,
          ),
        ),
      ),
    ),
  );
}
