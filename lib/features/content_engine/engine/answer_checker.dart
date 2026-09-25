import 'package:flutter/foundation.dart';

import '../data/content_pack_parser.dart' show isPrime;
import '../domain/question.dart';

/// Ce que l'élève a répondu, sous une forme que le correcteur comprend.
sealed class StudentResponse {
  const StudentResponse();
}

/// Une saisie libre (nombre, écriture binaire, liste…).
final class TextResponse extends StudentResponse {
  const TextResponse(this.text);
  final String text;
}

/// Une saisie par champ nommé (ex. `q`, `r`).
final class FieldsResponse extends StudentResponse {
  const FieldsResponse(this.fields);
  final Map<String, String> fields;
}

/// Un choix parmi les propositions.
final class ChoiceResponse extends StudentResponse {
  const ChoiceResponse(this.choice);
  final AnswerAtom choice;
}

/// Plusieurs choix parmi les propositions.
final class MultiChoiceResponse extends StudentResponse {
  const MultiChoiceResponse(this.choices);
  final Set<AnswerAtom> choices;
}

/// Vrai/faux, ou oui/non.
final class BooleanResponse extends StudentResponse {
  const BooleanResponse(this.value);
  final bool value;
}

/// Un ensemble d'entiers choisis (solutions, restes).
final class IntegerSetResponse extends StudentResponse {
  const IntegerSetResponse(this.values);
  final Set<int> values;
}

/// Pourquoi une réponse n'est pas juste, sans jamais donner la solution.
enum GradeDiagnosis {
  /// La saisie n'a pas pu être lue (ex. lettres dans un nombre).
  unreadable,

  /// Certains champs sont justes, d'autres non.
  someFieldsWrong,

  /// Il manque des solutions.
  missingSolutions,

  /// Des valeurs en trop.
  extraSolutions,

  /// Le produit est juste mais un facteur n'est pas premier.
  factorNotPrime,

  /// Les facteurs sont justes, pas les exposants.
  wrongExponents,

  /// Le produit ne redonne pas le nombre de départ.
  wrongProduct,

  /// Réponse simplement différente.
  different,
}

/// Résultat d'une correction.
@immutable
class GradeResult {
  const GradeResult({
    required this.correct,
    this.diagnosis,
    this.fieldResults = const {},
    this.missingCount = 0,
    this.extraCount = 0,
  });

  final bool correct;
  final GradeDiagnosis? diagnosis;

  /// Pour les réponses à champs : champ → juste ?
  final Map<String, bool> fieldResults;
  final int missingCount;
  final int extraCount;
}

/// Correcteur déterministe : même question, même réponse, même verdict.
class AnswerChecker {
  const AnswerChecker();

  GradeResult grade(Question question, StudentResponse response) {
    if (!question.autoScorable) {
      throw ArgumentError.value(
        question.id,
        'question',
        'Question non corrigeable automatiquement.',
      );
    }
    return _grade(question.answer, response);
  }

  GradeResult _grade(Answer answer, StudentResponse response) {
    return switch ((answer, response)) {
      (ScalarAnswer(:final value), TextResponse(:final text)) => _scalar(
        value,
        text,
      ),
      (FieldsAnswer(:final fields), FieldsResponse(fields: final given)) =>
        _fields(fields, given),
      (ChoiceAnswer(:final choice), ChoiceResponse(choice: final given)) =>
        _bool(choice == given),
      (
        MultiChoiceAnswer(:final choices),
        MultiChoiceResponse(choices: final given),
      ) =>
        _set(choices, given),
      (BooleanAnswer(:final value), BooleanResponse(value: final given)) =>
        _bool(value == given),
      (VerdictAnswer(:final yes), BooleanResponse(value: final given)) => _bool(
        yes == given,
      ),
      (
        IntegerSetAnswer(:final values),
        IntegerSetResponse(values: final given),
      ) =>
        _set(values, given),
      (IntegerSetAnswer(:final values), TextResponse(:final text)) =>
        _parsedSet(values, text),
      (
        CongruenceSetAnswer(:final residues, :final modulus),
        IntegerSetResponse(values: final given),
      ) =>
        _set(residues, {for (final value in given) value % modulus}),
      (MultisetAnswer(:final values), TextResponse(:final text)) => _multiset(
        values,
        text,
      ),
      (FactorizationAnswer(), TextResponse(:final text)) => _factorization(
        answer as FactorizationAnswer,
        text,
      ),
      _ => const GradeResult(
        correct: false,
        diagnosis: GradeDiagnosis.unreadable,
      ),
    };
  }

  GradeResult _bool(bool correct) => GradeResult(
    correct: correct,
    diagnosis: correct ? null : GradeDiagnosis.different,
  );

  GradeResult _scalar(AnswerAtom expected, String text) {
    if (expected.integer case final value?) {
      final given = parseInteger(text);
      if (given == null) {
        return const GradeResult(
          correct: false,
          diagnosis: GradeDiagnosis.unreadable,
        );
      }
      return _bool(given == value);
    }
    final given = normalizeText(text);
    if (given.isEmpty) {
      return const GradeResult(
        correct: false,
        diagnosis: GradeDiagnosis.unreadable,
      );
    }
    return _bool(given == normalizeText(expected.text!));
  }

  GradeResult _fields(Map<String, Answer> expected, Map<String, String> given) {
    final results = <String, bool>{};
    var unreadable = false;
    for (final entry in expected.entries) {
      final text = given[entry.key] ?? '';
      final result = _grade(entry.value, TextResponse(text));
      results[entry.key] = result.correct;
      if (result.diagnosis == GradeDiagnosis.unreadable) unreadable = true;
    }
    final correct = results.values.every((ok) => ok);
    return GradeResult(
      correct: correct,
      fieldResults: results,
      diagnosis: correct
          ? null
          : results.values.any((ok) => ok)
          ? GradeDiagnosis.someFieldsWrong
          : unreadable
          ? GradeDiagnosis.unreadable
          : GradeDiagnosis.different,
    );
  }

  GradeResult _set<T>(Set<T> expected, Set<T> given) {
    final missing = expected.difference(given).length;
    final extra = given.difference(expected).length;
    final correct = missing == 0 && extra == 0;
    return GradeResult(
      correct: correct,
      missingCount: missing,
      extraCount: extra,
      diagnosis: correct
          ? null
          : missing > 0
          ? GradeDiagnosis.missingSolutions
          : GradeDiagnosis.extraSolutions,
    );
  }

  GradeResult _parsedSet(Set<int> expected, String text) {
    final values = parseIntegerList(text);
    if (values == null) {
      return const GradeResult(
        correct: false,
        diagnosis: GradeDiagnosis.unreadable,
      );
    }
    return _set(expected, values.toSet());
  }

  GradeResult _multiset(List<int> expected, String text) {
    final values = parseIntegerList(text);
    if (values == null) {
      return const GradeResult(
        correct: false,
        diagnosis: GradeDiagnosis.unreadable,
      );
    }
    final a = [...expected]..sort();
    final b = [...values]..sort();
    return _bool(listEquals(a, b));
  }

  GradeResult _factorization(FactorizationAnswer expected, String text) {
    final given = parseFactorization(text);
    if (given == null) {
      return const GradeResult(
        correct: false,
        diagnosis: GradeDiagnosis.unreadable,
      );
    }
    if (mapEquals(given, expected.exponents)) {
      return const GradeResult(correct: true);
    }
    final product = FactorizationAnswer(given).product;
    final GradeDiagnosis diagnosis;
    if (product != expected.product) {
      diagnosis = GradeDiagnosis.wrongProduct;
    } else if (given.keys.any((factor) => !isPrime(factor))) {
      diagnosis = GradeDiagnosis.factorNotPrime;
    } else {
      diagnosis = GradeDiagnosis.wrongExponents;
    }
    return GradeResult(correct: false, diagnosis: diagnosis);
  }
}

// ── Lecture des saisies ─────────────────────────────────────────────────

/// Signes moins et espaces typographiques ramenés à leur forme simple.
String _plain(String text) =>
    text.replaceAll(RegExp(r'[−–—]'), '-').replaceAll(RegExp(r'[\s  ]'), '');

/// « −54 », « + 12 », « 1 000 » → entier ; `null` si illisible.
int? parseInteger(String text) {
  final plain = _plain(text).replaceFirst(RegExp(r'^\+'), '');
  if (!RegExp(r'^-?\d+$').hasMatch(plain)) return null;
  return int.tryParse(plain);
}

/// Texte comparable : sans espaces, sans indice de base (« 1101₂ »),
/// en minuscules.
String normalizeText(String text) =>
    _plain(text).replaceAll(RegExp(r'[₀-₉]+$'), '').toLowerCase();

/// « 17, 17 ; 23 » ou « 512+256+128 » → liste d'entiers ; `null` si un
/// morceau est illisible.
List<int>? parseIntegerList(String text) {
  final normalized = text.replaceAll(RegExp(r'[−–—]'), '-');
  final parts = normalized
      .split(RegExp(r'[,;+×x*/\s]+|(?<=\d)\s*-\s*(?=\d)'))
      .where((part) => part.trim().isNotEmpty)
      .toList();
  if (parts.isEmpty) return null;
  final values = <int>[];
  for (final part in parts) {
    final value = parseInteger(part);
    if (value == null) return null;
    values.add(value);
  }
  return values;
}

const _superscripts = {
  '⁰': '0',
  '¹': '1',
  '²': '2',
  '³': '3',
  '⁴': '4',
  '⁵': '5',
  '⁶': '6',
  '⁷': '7',
  '⁸': '8',
  '⁹': '9',
};

/// « 2²×3×5 », « 2^2*3*5 », « 2x2x3x5 », « 2.2.3.5 » → {2: 2, 3: 1, 5: 1}.
Map<int, int>? parseFactorization(String text) {
  var plain = _plain(text);
  _superscripts.forEach(
    (sup, digit) => plain = plain.replaceAll(sup, '^$digit'),
  );
  // Exposants en exposant typographique consécutifs : « 2^1^2 » → « 2^12 ».
  plain = plain.replaceAllMapped(
    RegExp(r'\^(\d)((?:\^\d)+)'),
    (m) => '^${m.group(1)}${m.group(2)!.replaceAll('^', '')}',
  );
  final parts = plain.split(RegExp(r'[×x*·.]'));
  final exponents = <int, int>{};
  for (final part in parts) {
    if (part.isEmpty) return null;
    final match = RegExp(r'^(\d+)(?:\^(\d+))?$').firstMatch(part);
    if (match == null) return null;
    final base = int.parse(match.group(1)!);
    final exponent = int.parse(match.group(2) ?? '1');
    if (base < 2 || exponent < 1) return null;
    exponents[base] = (exponents[base] ?? 0) + exponent;
  }
  return exponents;
}
