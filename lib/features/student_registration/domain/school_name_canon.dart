/// Forme canonique des noms d'établissements, pour reconnaître le même
/// établissement sous ses variantes d'écriture, et seulement celles-là.
///
/// Pur Dart (sans Flutter) : partagée par l'outil d'import du catalogue et
/// par la recherche de l'application.
abstract final class SchoolNameCanon {
  static const _accents = <String, String>{
    'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a', 'å': 'a', //
    'ç': 'c',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'î': 'i', 'ï': 'i', 'í': 'i', 'ì': 'i',
    'ñ': 'n',
    'ô': 'o', 'ö': 'o', 'ó': 'o', 'ò': 'o', 'õ': 'o',
    'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u',
    'ý': 'y', 'ÿ': 'y',
    'œ': 'oe', 'æ': 'ae',
  };

  /// Mots de liaison sans valeur d'identité.
  static const _stopWords = {
    'd', 'l', 'de', 'du', 'des', 'la', 'le', 'les', 'et', 'of', 'the', //
  };

  static const _roman = {
    '1': 'i', '2': 'ii', '3': 'iii', '4': 'iv', '5': 'v', //
    '6': 'vi', '7': 'vii', '8': 'viii', '9': 'ix', '10': 'x',
  };

  static const _synonyms = {'st': 'saint', 'ste': 'sainte'};

  /// Minuscules, sans accents, apostrophes et tirets devenus des espaces.
  static String fold(String input) {
    final buffer = StringBuffer();
    for (final rune in input.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_accents[char] ?? char);
    }
    return buffer
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  /// [fold], avec pour chaque caractère plié sa position dans [input] : de
  /// quoi surligner dans le nom affiché ce qui correspond dans le nom plié.
  static ({String folded, List<int> offsets}) foldWithOffsets(String input) {
    final buffer = StringBuffer();
    final offsets = <int>[];
    var pendingSpace = false;
    for (var i = 0; i < input.length; i++) {
      final lower = input[i].toLowerCase();
      for (final unit in (_accents[lower] ?? lower).codeUnits) {
        final alphanumeric =
            (unit >= 0x61 && unit <= 0x7a) || (unit >= 0x30 && unit <= 0x39);
        if (!alphanumeric) {
          pendingSpace = offsets.isNotEmpty;
          continue;
        }
        if (pendingSpace) {
          buffer.write(' ');
          offsets.add(i);
          pendingSpace = false;
        }
        buffer.writeCharCode(unit);
        offsets.add(i);
      }
    }
    return (folded: buffer.toString(), offsets: offsets);
  }

  /// Mots d'un nom plié, chiffres romains unifiés (« 2 » et « II »).
  static List<String> tokens(String input) => [
    for (final word in fold(input).split(' '))
      if (word.isNotEmpty) _synonyms[word] ?? _roman[word] ?? word,
  ];

  /// Nom canonique : sans sigle entre parenthèses, sans mots de liaison, et
  /// sans le nom de la ville répété en fin de nom (« … de Yaoundé »).
  static String canonical(String name, {String? city}) {
    var words = [
      for (final word in tokens(name.replaceAll(RegExp(r'\([^)]*\)'), ' ')))
        if (!_stopWords.contains(word)) word,
    ];
    if (city != null && city.trim().isNotEmpty) {
      final cityWords = tokens(city);
      if (words.length > cityWords.length &&
          _endsWith(words, cityWords) &&
          words.length - cityWords.length >= 2) {
        words = words.sublist(0, words.length - cityWords.length);
      }
    }
    return words.join(' ');
  }

  /// Identité d'un établissement : nom canonique et ville. Même nom dans
  /// deux villes : deux établissements.
  static String identityKey(String name, String? city) =>
      '${canonical(name, city: city)}|${fold(city ?? '')}';

  /// Sigles écrits entre parenthèses (« COMAL II »), gardés comme alias.
  static List<String> parentheticals(String name) => [
    for (final match in RegExp(r'\(([^)]+)\)').allMatches(name))
      if (match.group(1)!.trim().isNotEmpty) match.group(1)!.trim(),
  ];

  static bool _endsWith(List<String> words, List<String> suffix) {
    for (var i = 1; i <= suffix.length; i++) {
      if (words[words.length - i] != suffix[suffix.length - i]) return false;
    }
    return true;
  }
}
