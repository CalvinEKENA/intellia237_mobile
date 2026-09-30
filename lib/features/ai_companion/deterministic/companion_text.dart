/// Normalisation des messages de l'élève pour le compagnon déterministe :
/// minuscules, sans accents ni ponctuation, apostrophes et espaces unifiés,
/// variantes d'écriture courantes ramenées à leur forme simple.
library;

const _accents = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a', //
  'ç': 'c',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
  'ñ': 'n',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
  'ý': 'y', 'ÿ': 'y',
  'œ': 'oe', 'æ': 'ae',
};

final _nonWord = RegExp(r'[^a-z0-9]+');

/// Forme comparable de [text]. [replacements] (déjà normalisées) remplacent
/// des suites de mots entières : « stp » disparaît, « jveux » devient
/// « je veux ».
String normalizeCompanionText(
  String text, {
  Map<String, String> replacements = const {},
}) {
  final lower = text.toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_accents[char] ?? char);
  }
  var normalized = buffer.toString().replaceAll(_nonWord, ' ').trim();
  if (replacements.isEmpty || normalized.isEmpty) return normalized;
  // Les remplacements les plus longs d'abord : « s il te plait » avant
  // « te ».
  final keys = replacements.keys.where((k) => k.isNotEmpty).toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  var padded = ' $normalized ';
  for (final key in keys) {
    final value = replacements[key]!;
    padded = padded.replaceAll(' $key ', value.isEmpty ? ' ' : ' $value ');
  }
  return padded.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Vrai si [phrase] apparaît en mots entiers dans [message] (tous deux
/// normalisés).
bool containsPhrase(String message, String phrase) {
  if (phrase.isEmpty || message.isEmpty) return false;
  return ' $message '.contains(' $phrase ');
}

/// Nombre de mots de [text] normalisé.
int wordCount(String text) =>
    text.isEmpty ? 0 : text.split(' ').where((w) => w.isNotEmpty).length;
