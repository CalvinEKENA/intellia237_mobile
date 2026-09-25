import 'package:flutter/foundation.dart';

import 'validation.dart';

/// Une valeur atomique du pack : un entier ou un texte.
@immutable
class AnswerAtom {
  const AnswerAtom.integer(int this.integer) : text = null;
  const AnswerAtom.text(String this.text) : integer = null;

  final int? integer;
  final String? text;

  bool get isInteger => integer != null;

  /// `null` si la valeur JSON n'est ni un entier ni un texte.
  static AnswerAtom? fromJson(Object? raw) {
    if (raw is int) return AnswerAtom.integer(raw);
    if (raw is num && raw == raw.roundToDouble()) {
      return AnswerAtom.integer(raw.toInt());
    }
    if (raw is String) return AnswerAtom.text(raw);
    return null;
  }

  /// Forme affichable, telle que dans le pack.
  String get display => integer?.toString() ?? text!;

  @override
  bool operator ==(Object other) =>
      other is AnswerAtom && other.integer == integer && other.text == text;

  @override
  int get hashCode => Object.hash(integer, text);

  @override
  String toString() => display;
}

/// La réponse attendue, sous une forme que le moteur sait corriger seul.
sealed class Answer {
  const Answer();
}

/// Une seule valeur (entier, ou texte comme une écriture binaire).
final class ScalarAnswer extends Answer {
  const ScalarAnswer(this.value);
  final AnswerAtom value;
}

/// Plusieurs champs nommés (ex. `q` et `r`, `gcd` et `lcm`).
final class FieldsAnswer extends Answer {
  const FieldsAnswer(this.fields);

  /// Dans l'ordre du pack.
  final Map<String, Answer> fields;
}

/// Un choix parmi des propositions (QCM).
final class ChoiceAnswer extends Answer {
  const ChoiceAnswer(this.choice);
  final AnswerAtom choice;
}

/// Plusieurs choix parmi des propositions.
final class MultiChoiceAnswer extends Answer {
  const MultiChoiceAnswer(this.choices);
  final Set<AnswerAtom> choices;
}

/// Vrai ou faux.
final class BooleanAnswer extends Answer {
  const BooleanAnswer(this.value);
  final bool value;
}

/// Oui ou non, à justifier (raisonnement, procédure).
final class VerdictAnswer extends Answer {
  const VerdictAnswer({required this.yes});
  final bool yes;
}

/// Un ensemble d'entiers : toutes les solutions, sans ordre ni doublon.
final class IntegerSetAnswer extends Answer {
  const IntegerSetAnswer(this.values);
  final Set<int> values;
}

/// Des classes de congruence : `n≡2 (mod 5)`, `n≡3 (mod 5)`.
final class CongruenceSetAnswer extends Answer {
  const CongruenceSetAnswer({
    required this.modulus,
    required this.residues,
    this.variable = 'n',
  });
  final int modulus;
  final Set<int> residues;
  final String variable;
}

/// Des entiers sans ordre mais avec répétitions (ex. 17, 17, 23).
final class MultisetAnswer extends Answer {
  const MultisetAnswer(this.values);
  final List<int> values;
}

/// Une décomposition en facteurs premiers : premier → exposant.
final class FactorizationAnswer extends Answer {
  const FactorizationAnswer(this.exponents);
  final Map<int, int> exponents;

  int get product => exponents.entries.fold(1, (acc, entry) {
    var value = acc;
    for (var i = 0; i < entry.value; i++) {
      value *= entry.key;
    }
    return value;
  });
}

/// Un nombre non entier (ex. 0,25), comparé avec une [tolerance] : nulle en
/// pratique pour une valeur exacte, une demi-unité du dernier chiffre pour
/// une valeur approchée (« à 10⁻² près »).
final class DecimalAnswer extends Answer {
  const DecimalAnswer(this.value, {this.tolerance = 1e-9});
  final double value;
  final double tolerance;
}

/// Un nombre complexe x+iy (parties réelles, éventuellement fractionnaires).
final class ComplexAnswer extends Answer {
  const ComplexAnswer(this.re, this.im, {this.acceptedTexts = const []});
  final double re;
  final double im;

  /// Écritures équivalentes fournies par le pack (ex. « (2+i)/5 »).
  final List<String> acceptedTexts;

  String get display => formatComplex(re, im);
}

/// Toutes les solutions complexes, sans ordre ni doublon.
final class ComplexSetAnswer extends Answer {
  const ComplexSetAnswer(this.values);
  final List<ComplexAnswer> values;
}

/// Une valeur exacte avec radical (ex. 5√2), comparée par sa valeur.
final class RadicalAnswer extends Answer {
  const RadicalAnswer({required this.exact, required this.value});

  /// Écriture exacte du pack.
  final String exact;
  final double value;
}

/// Un intervalle de réels, bornes et crochets compris.
final class IntervalAnswer extends Answer {
  const IntervalAnswer({
    required this.lower,
    required this.upper,
    required this.lowerClosed,
    required this.upperClosed,
    required this.display,
  });
  final double lower;
  final double upper;
  final bool lowerClosed;
  final bool upperClosed;
  final String display;
}

/// Une expression ou une équation courte (ex. « y=x+1 »), comparée après
/// normalisation typographique.
final class ExpressionAnswer extends Answer {
  const ExpressionAnswer(this.text);
  final String text;
}

/// Plusieurs expressions, sans ordre (ex. les deux asymptotes).
final class ExpressionSetAnswer extends Answer {
  const ExpressionSetAnswer(this.texts);
  final List<String> texts;
}

/// Réponse que le moteur ne sait pas corriger seul : elle n'est jamais
/// proposée en exercice noté.
final class UnscorableAnswer extends Answer {
  const UnscorableAnswer(this.reason);
  final String reason;
}

/// Types de questions connus. `unknown` protège contre les types futurs.
enum QuestionType {
  numeric('numeric'),
  mcq('mcq'),
  trueFalse('true_false'),
  reasoning('reasoning'),
  multiStep('multi_step'),
  solutionSet('solution_set'),
  multiSelect('multi_select'),
  factorization('factorization'),
  procedure('procedure'),
  complexParts('complex_parts'),
  complexNumber('complex_number'),
  solutionSetComplex('solution_set_complex'),
  numericRadical('numeric_radical'),
  numericApprox('numeric_approx'),
  interval('interval'),
  expression('expression'),
  multiAnswer('multi_answer'),
  unknown('unknown');

  const QuestionType(this.key);
  final String key;

  static QuestionType fromKey(String? key) {
    for (final type in values) {
      if (type.key == key) return type;
    }
    return unknown;
  }
}

/// Une question du pack.
@immutable
class Question {
  const Question({
    required this.id,
    required this.lessonNumber,
    required this.difficulty,
    required this.type,
    required this.rawType,
    required this.prompt,
    required this.answer,
    this.explanation,
    this.sourceAnchor,
    this.tags = const [],
    this.choices = const [],
    this.hints = const [],
    this.flags = const [],
    this.disabledReason,
    this.conceptId,
    this.choiceFeedback = const {},
  });

  final String id;

  /// Numéro de leçon ; `0` désigne une activité d'intégration du chapitre.
  final int lessonNumber;
  final int difficulty;
  final QuestionType type;

  /// Type tel qu'écrit dans le pack (utile quand il est inconnu).
  final String rawType;
  final String prompt;
  final Answer answer;
  final String? explanation;
  final String? sourceAnchor;
  final List<String> tags;
  final List<AnswerAtom> choices;

  /// Indices propres à la question, s'ils existent dans le pack.
  final List<String> hints;

  /// Anomalies de source rattachées à cette question.
  final List<ValidationFlag> flags;

  /// Raison pour laquelle la question est retirée des exercices notés.
  final String? disabledReason;

  /// Notion visée, quand le pack la déclare (sinon : celle de la leçon).
  final String? conceptId;

  /// Retour propre à chaque proposition d'un QCM (lié à la valeur, jamais à
  /// la place à l'écran).
  final Map<AnswerAtom, String> choiceFeedback;

  bool get isIntegration => lessonNumber == 0;

  /// Étiquettes par lesquelles un pack marque lui-même une question fragile.
  static const sensitiveTags = {'quality_sensitive', 'critical_thinking'};

  /// Anomalies à montrer à l'élève : celles qui visent cette question par
  /// son identifiant, ou toutes si le pack la marque comme fragile. Une
  /// anomalie qui ne nomme qu'une page reste attachée (le moteur la
  /// respecte) sans s'afficher sur des questions qu'elle ne concerne pas.
  List<ValidationFlag> get visibleFlags {
    if (tags.any(sensitiveTags.contains)) return flags;
    return [
      for (final flag in flags)
        if (flag.questionIds.contains(id)) flag,
    ];
  }

  /// Vrai si le moteur peut la corriger seul, de façon sûre.
  bool get autoScorable =>
      disabledReason == null && answer is! UnscorableAnswer;

  Question withFlags(List<ValidationFlag> flags) => Question(
    id: id,
    lessonNumber: lessonNumber,
    difficulty: difficulty,
    type: type,
    rawType: rawType,
    prompt: prompt,
    answer: answer,
    explanation: explanation,
    sourceAnchor: sourceAnchor,
    tags: tags,
    choices: choices,
    hints: hints,
    flags: flags,
    disabledReason: disabledReason,
    conceptId: conceptId,
    choiceFeedback: choiceFeedback,
  );
}

/// « 3−4i », « 2/5+1/5i », « −i », « 16 » : écriture algébrique lisible.
String formatComplex(double re, double im) {
  String number(double value) {
    final rational = _rational(value.abs());
    return rational ?? _decimal(value.abs());
  }

  final parts = <String>[];
  if (re != 0 || im == 0) parts.add('${re < 0 ? '−' : ''}${number(re)}');
  if (im != 0) {
    final magnitude = im.abs() == 1 ? '' : number(im);
    final sign = im < 0 ? '−' : (parts.isEmpty ? '' : '+');
    parts.add('$sign${magnitude}i');
  }
  return parts.join();
}

String _decimal(double value) {
  final text = value.toStringAsFixed(6);
  return text.replaceFirst(RegExp(r'\.?0+$'), '');
}

/// Fraction simple (dénominateur ≤ 12) si la valeur en est une.
String? _rational(double value) {
  for (var d = 1; d <= 12; d++) {
    final n = (value * d).round();
    if ((n / d - value).abs() < 1e-9) return d == 1 ? '$n' : '$n/$d';
  }
  return null;
}
