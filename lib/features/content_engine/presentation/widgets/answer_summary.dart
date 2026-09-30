import 'package:flutter/widgets.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../domain/question.dart';
import 'answer_input.dart' show fieldLabel;

/// La réponse du pack, destinée uniquement à une correction déjà validée.
/// Aucun calcul ni nouvelle réponse n'est inventé par la présentation.
String answerSummary(BuildContext context, Answer answer) => switch (answer) {
  ScalarAnswer(:final value) => value.display,
  FieldsAnswer(:final fields) =>
    fields.entries
        .map(
          (e) =>
              '${fieldLabel(context, e.key)} : ${answerSummary(context, e.value)}',
        )
        .join(' ; '),
  ChoiceAnswer(:final choice) => choice.display,
  MultiChoiceAnswer(:final choices) =>
    choices.map((e) => e.display).join(' ; '),
  BooleanAnswer(:final value) =>
    value ? context.l10n.ceTrue : context.l10n.ceFalse,
  VerdictAnswer(:final yes) => yes ? context.l10n.ceYes : context.l10n.ceNo,
  IntegerSetAnswer(:final values) => values.join(' ; '),
  CongruenceSetAnswer(:final residues, :final modulus, :final variable) =>
    residues.map((r) => '$variable ≡ $r (mod $modulus)').join(' ; '),
  MultisetAnswer(:final values) => values.join(' ; '),
  FactorizationAnswer(:final exponents) =>
    exponents.entries
        .map((e) => e.value == 1 ? '${e.key}' : '${e.key}^${e.value}')
        .join(' × '),
  DecimalAnswer(:final value) => '$value',
  ComplexAnswer() => answer.display,
  ComplexSetAnswer(:final values) => values.map((e) => e.display).join(' ; '),
  RadicalAnswer(:final exact) => exact,
  IntervalAnswer(:final display) => display,
  ExpressionAnswer(:final text) => text,
  ExpressionSetAnswer(:final texts) => texts.join(' ; '),
  ShortTextAnswer(:final display) => display,
  UnscorableAnswer() => '',
};
