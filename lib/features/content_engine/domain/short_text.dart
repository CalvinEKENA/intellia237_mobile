/// Réponses textuelles courtes : forme comparable et reconnaissance.
library;

final _apostrophes = RegExp('[’‘ʼ`´]');
final _spaces = RegExp(r'\s+');

/// Ponctuation et guillemets autour de la réponse (« down. », "down").
final _edges = RegExp(r'''^[\s.,;:!?"'«»“”]+|[\s.,;:!?"'«»“”]+$''');

/// Forme comparable d'une réponse courte : sans espaces superflus ni
/// ponctuation autour, en minuscules, apostrophes typographiques unifiées.
/// Les accents et l'orthographe restent tels quels : « down » ≠ « out »,
/// « colour » ≠ « color » sauf si le pack accepte les deux.
String normalizeShortText(String text) => text
    .replaceAll(' ', ' ')
    .replaceAll(_apostrophes, "'")
    .replaceAll(_edges, '')
    .replaceAll(_spaces, ' ')
    .trim()
    .toLowerCase();

/// Vrai si [given] est exactement l'une des formes [accepted].
bool matchesShortText(List<String> accepted, String given) {
  final normalized = normalizeShortText(given);
  if (normalized.isEmpty) return false;
  return accepted.any((answer) => normalizeShortText(answer) == normalized);
}

/// Fonctions et notations mathématiques écrites en lettres.
const _mathWords = {
  'sin', 'cos', 'tan', 'cot', 'ln', 'log', 'exp', 'sqrt', 'lim', 'arcsin', //
  'arccos', 'arctan', 'sh', 'ch', 'th', 'pi', 'inf',
};

/// Vrai si [text] n'est fait que de mots (lettres, apostrophes, traits
/// d'union), sans chiffre, opérateur, parenthèse ni variable d'une lettre :
/// une réponse de langue, pas une expression mathématique.
bool looksLikeWords(String text) {
  final words = text.trim().split(_spaces);
  if (words.isEmpty || words.first.isEmpty) return false;
  final letters = RegExp(r"^[\p{L}][\p{L}'’\-]*$", unicode: true);
  for (final word in words) {
    if (!letters.hasMatch(word)) return false;
    if (word.length < 2) return false;
    if (_mathWords.contains(word.toLowerCase())) return false;
  }
  return true;
}
