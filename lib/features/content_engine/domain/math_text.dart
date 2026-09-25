import 'dart:math' as math;

/// Lecture des écritures mathématiques saisies par l'élève ou écrites dans
/// un pack. Fonctions pures, sans dépendance : même texte, même lecture.

/// Signes moins typographiques ramenés à « - », espaces supprimés.
String plainMath(String text) =>
    text.replaceAll(RegExp(r'[−–—]'), '-').replaceAll(RegExp(r'[\s  ]'), '');

/// « 7 », « −2/5 », « 0,25 », « 0.25 », « +3 » → réel ; `null` si illisible.
double? parseRealNumber(String text) {
  final plain = plainMath(text);
  final match = RegExp(
    r'^([+-]?)(\d+(?:[.,]\d+)?)(?:/(\d+(?:[.,]\d+)?))?$',
  ).firstMatch(plain);
  if (match == null) return null;
  final numerator = double.parse(match.group(2)!.replaceAll(',', '.'));
  final denominatorText = match.group(3);
  final denominator = denominatorText == null
      ? 1.0
      : double.parse(denominatorText.replaceAll(',', '.'));
  if (denominator == 0) return null;
  final value = numerator / denominator;
  return match.group(1) == '-' ? -value : value;
}

/// Un nombre complexe lu sous forme algébrique : « 3−4i », « −i », « 2i »,
/// « 2/5+i/5 », « 0,4+0,2i », « z=1+2i ». `null` si illisible.
({double re, double im})? parseComplex(String text) {
  var plain = plainMath(text).toLowerCase().replaceAll(RegExp(r'[*×·]'), '');
  // Nom éventuel devant le signe égal : « z = … », « z₁ = … ».
  plain = plain.replaceFirst(RegExp(r'^[a-zδ][0-9₀-₉]*='), '');
  if (plain.isEmpty) return null;
  final terms = RegExp(
    r'[+-]?[^+-]+',
  ).allMatches(plain).map((m) => m.group(0)!).toList();
  if (terms.join() != plain) return null;
  var re = 0.0;
  var im = 0.0;
  for (final term in terms) {
    final count = 'i'.allMatches(term).length;
    if (count > 1) return null;
    if (count == 0) {
      final value = parseRealNumber(term);
      if (value == null) return null;
      re += value;
      continue;
    }
    var coefficient = term.replaceFirst('i', '');
    final sign = coefficient.startsWith('-')
        ? '-'
        : coefficient.startsWith('+')
        ? '+'
        : '';
    coefficient = coefficient.substring(sign.length);
    // « i », « i/5 » : le coefficient implicite vaut 1.
    if (coefficient.isEmpty || coefficient.startsWith('/')) {
      coefficient = '1$coefficient';
    }
    final value = parseRealNumber('$sign$coefficient');
    if (value == null) return null;
    im += value;
  }
  return (re: re, im: im);
}

/// Plusieurs réponses séparées par « ; », un retour à la ligne, « et » ou
/// « ou » (à défaut, par des virgules).
List<String> splitAnswers(String text) {
  var parts = text
      .split(RegExp(r';|\n|\s+et\s+|\s+ou\s+', caseSensitive: false))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.length == 1 && parts.first.contains(',')) {
    parts = parts.first
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }
  return parts;
}

/// Liste de complexes (« 1+2i ; 1−2i », « 1±2i », « ±i ») ; `null` si un
/// élément est illisible.
List<({double re, double im})>? parseComplexList(String text) {
  final items = splitAnswers(text);
  if (items.isEmpty) return null;
  final values = <({double re, double im})>[];
  for (final item in items) {
    final variants = item.contains('±')
        ? [item.replaceFirst('±', '+'), item.replaceFirst('±', '-')]
        : [item];
    for (final variant in variants) {
      final value = parseComplex(variant);
      if (value == null) return null;
      values.add(value);
    }
  }
  return values;
}

/// Valeur d'une écriture avec radical : « 5√2 », « √50 », « sqrt(5) »,
/// « 2/3√3 », ou un simple nombre. `null` si illisible.
double? evaluateRadical(String text) {
  final plain = plainMath(text)
      .toLowerCase()
      .replaceAll('sqrt', '√')
      .replaceAll('racine', '√')
      .replaceAll(RegExp(r'[*×·]'), '');
  final match = RegExp(
    r'^([+-]?)(\d+(?:[.,]\d+)?(?:/\d+(?:[.,]\d+)?)?)?(?:√\(?(\d+(?:[.,]\d+)?)\)?)?$',
  ).firstMatch(plain);
  if (match == null) return null;
  final coefficientText = match.group(2);
  final radicandText = match.group(3);
  if (coefficientText == null && radicandText == null) return null;
  final coefficient = coefficientText == null
      ? 1.0
      : parseRealNumber(coefficientText);
  if (coefficient == null) return null;
  final radicand = radicandText == null
      ? 1.0
      : double.parse(radicandText.replaceAll(',', '.'));
  final value = coefficient * (radicandText == null ? 1 : math.sqrt(radicand));
  return match.group(1) == '-' ? -value : value;
}

/// Un intervalle : « [0;4] », « ]0,5;1] », « [0.5,1] », « [1;+∞[ ».
({double lower, double upper, bool lowerClosed, bool upperClosed})?
parseInterval(String text) {
  final plain = plainMath(text);
  if (plain.length < 5) return null;
  final open = plain[0];
  final close = plain[plain.length - 1];
  if (!'[]('.contains(open) || !'[])'.contains(close)) return null;
  final inner = plain.substring(1, plain.length - 1);
  final List<String> bounds;
  if (inner.contains(';')) {
    bounds = inner.split(';');
  } else if (','.allMatches(inner).length == 1) {
    bounds = inner.split(',');
  } else {
    return null;
  }
  if (bounds.length != 2) return null;
  double? bound(String value) => switch (value) {
    '+∞' || '∞' || '+inf' || 'inf' => double.infinity,
    '-∞' || '-inf' => double.negativeInfinity,
    _ => parseRealNumber(value),
  };
  final lower = bound(bounds[0]);
  final upper = bound(bounds[1]);
  if (lower == null || upper == null || lower > upper) return null;
  return (
    lower: lower,
    upper: upper,
    lowerClosed: open == '[',
    upperClosed: close == ']',
  );
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

/// Forme comparable d'une expression courte : sans espaces ni signe de
/// multiplication, exposants et racines unifiés, en minuscules.
String normalizeExpression(String text) {
  var plain = plainMath(text)
      .toLowerCase()
      .replaceAll('⁻¹', '^-1')
      .replaceAll('⁻', '^-')
      .replaceAll('sqrt', '√')
      .replaceAll('<=', '≤')
      .replaceAll('>=', '≥')
      .replaceAll(RegExp(r'[*×·]'), '');
  _superscripts.forEach(
    (sup, digit) => plain = plain.replaceAll(sup, '^$digit'),
  );
  return plain;
}

/// Égalité de deux réels à [tolerance] près (relative au-delà de 1).
bool nearlyEqual(double a, double b, {double tolerance = 1e-9}) {
  if (a.isInfinite || b.isInfinite) return a == b;
  return (a - b).abs() <= tolerance * math.max(1, b.abs());
}
