import 'dart:convert';
import 'dart:math' as math;

/// Ordre d'affichage des propositions d'un QCM.
///
/// La bonne réponse est désignée par sa valeur ou par son index d'origine,
/// jamais par sa place à l'écran. Les auteurs écrivent souvent la bonne
/// réponse en premier (le Studio la présélectionne) : sans mélange, « A »
/// devenait la réponse à cocher par réflexe.
///
/// Retourne une permutation de `0..count-1` : `order[position]` est l'index
/// d'origine affiché à cette position. Elle ne dépend que de [questionId] et
/// de [attemptKey] : identique à chaque reconstruction pendant une
/// tentative, différente d'une tentative à l'autre, reproductible en test.
List<int> choiceOrder(
  int count, {
  required String questionId,
  required String attemptKey,
}) {
  final order = List<int>.generate(count, (index) => index);
  if (count < 2) return order;
  final random = math.Random(_fnv1a('$questionId|$attemptKey'));
  // Fisher-Yates : chaque permutation est équiprobable.
  for (var i = count - 1; i > 0; i--) {
    final j = random.nextInt(i + 1);
    final swap = order[i];
    order[i] = order[j];
    order[j] = swap;
  }
  return order;
}

/// Clé d'une nouvelle tentative : distincte à chaque appel, pour que l'ordre
/// change quand l'élève revient sur une question.
String newChoiceAttemptKey() => '$_sessionSeed-${_attempts++}';

final int _sessionSeed = math.Random().nextInt(1 << 30);
int _attempts = 0;

/// Hachage FNV-1a 32 bits : stable d'une exécution à l'autre, contrairement
/// à `String.hashCode`.
int _fnv1a(String text) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(text)) {
    hash ^= byte;
    // × 0x01000193 (premier FNV) décomposé pour rester exact sur le web,
    // où les entiers au-delà de 2^53 perdent leur précision.
    hash = (hash * 0x193 + ((hash << 24) & 0xffffffff)) & 0xffffffff;
  }
  return hash;
}
