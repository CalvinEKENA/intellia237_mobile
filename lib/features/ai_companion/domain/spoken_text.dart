import 'rich_text_document.dart';

/// Un fragment à prononcer dans une langue donnée.
class SpokenSegment {
  const SpokenSegment({required this.text, required this.languageCode});

  final String text;

  /// Code de langue à deux lettres : « fr » ou « en ».
  final String languageCode;

  @override
  bool operator ==(Object other) =>
      other is SpokenSegment &&
      other.text == text &&
      other.languageCode == languageCode;

  @override
  int get hashCode => Object.hash(text, languageCode);

  @override
  String toString() => 'SpokenSegment($languageCode: "$text")';
}

/// Transforme un texte **affiché** en texte **prononcé**.
///
/// Registre de décisions : ce sont deux représentations distinctes. Le moteur
/// lisait jusqu'ici la chaîne d'affichage telle quelle, si bien qu'il énonçait
/// les emojis, butait sur le balisage résiduel, et prononçait « x² » caractère
/// par caractère.
///
/// ## Sur la langue
///
/// Ni la réponse du compagnon ni la callable `askTutor` ne portent
/// aujourd'hui d'information de langue. La seule donnée structurée fiable est
/// donc la langue de l'application, qui sert de base. Un basculement vers
/// l'anglais n'a lieu que sur un faisceau d'indices net — c'est une
/// heuristique assumée, et un champ `language` renvoyé par le backend
/// resterait préférable.
abstract final class SpokenText {
  /// Découpe une réponse en fragments prêts à être prononcés.
  static List<SpokenSegment> from(
    String display, {
    required String baseLanguage,
  }) {
    final base = baseLanguage.toLowerCase().startsWith('en') ? 'en' : 'fr';
    // Le balisage n'a rien à dire à voix haute : on part du texte des blocs.
    final plain = RichTextDocument.parse(
      display,
    ).map((block) => block.plainText).join('. ');

    final segments = <SpokenSegment>[];
    for (final sentence in _sentences(plain)) {
      final language = _languageOf(sentence, base: base);
      final spoken = _speakable(sentence, language);
      if (spoken.isEmpty) continue;
      if (segments.isNotEmpty && segments.last.languageCode == language) {
        segments[segments.length - 1] = SpokenSegment(
          text: '${segments.last.text} $spoken',
          languageCode: language,
        );
      } else {
        segments.add(SpokenSegment(text: spoken, languageCode: language));
      }
    }
    return segments;
  }

  /// Texte prononcé d'un seul tenant, dans la langue de base.
  static String plain(String display, {required String baseLanguage}) =>
      from(display, baseLanguage: baseLanguage).map((s) => s.text).join(' ');

  // ── Découpage ──────────────────────────────────────────────────────────

  static List<String> _sentences(String value) => value
      .split(RegExp(r'(?<=[.!?…])\s+|\n+'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);

  // ── Langue ─────────────────────────────────────────────────────────────

  /// Mots outils très fréquents, choisis pour ne pas exister dans l'autre
  /// langue avec le même sens.
  static const _englishMarkers = {
    'the',
    'is',
    'are',
    'was',
    'were',
    'you',
    'your',
    'my',
    'this',
    'that',
    'with',
    'have',
    'has',
    'does',
    'do',
    'what',
    'when',
    'where',
    'which',
    'they',
    'there',
    'here',
    'and',
    'but',
    'because',
    'about',
    'would',
    'should',
    'could',
    'i',
    'am',
    'we',
    'he',
    'she',
    'it',
    'not',
  };

  static const _frenchMarkers = {
    'le',
    'la',
    'les',
    'un',
    'une',
    'des',
    'est',
    'sont',
    'tu',
    'ton',
    'ta',
    'tes',
    'je',
    'nous',
    'vous',
    'ce',
    'cette',
    'avec',
    'pour',
    'dans',
    'que',
    'qui',
    'quoi',
    'donc',
    'mais',
    'parce',
    'sur',
    'plus',
    'moins',
    'quand',
    'comment',
    'pourquoi',
    'il',
    'elle',
    'on',
    'et',
    'ou',
    'ne',
  };

  static String _languageOf(String sentence, {required String base}) {
    final lower = sentence.toLowerCase();
    // Les diacritiques françaises sont un signal fort et bon marché.
    if (RegExp(r'[àâäçéèêëîïôöùûüœ]').hasMatch(lower)) return 'fr';

    final words = lower
        .split(RegExp(r"[^a-z']+"))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
    if (words.length < 2) return base;

    var english = 0;
    var french = 0;
    for (final word in words) {
      if (_englishMarkers.contains(word)) english++;
      if (_frenchMarkers.contains(word)) french++;
    }

    // On ne quitte la langue de base que sur un écart net : une bascule à
    // tort déforme davantage la lecture qu'un accent approximatif.
    if (base == 'fr' && english >= 2 && english > french) return 'en';
    if (base == 'en' && french >= 2 && french > english) return 'fr';
    return base;
  }

  // ── Nettoyage et mise en mots ──────────────────────────────────────────

  static String _speakable(String sentence, String language) {
    var value = _stripDecorations(sentence);
    value = _mathToWords(value, language);
    // Une ponctuation orpheline laissée par un pictogramme retiré.
    value = value.replaceAll(RegExp(r'\s*([,;:])\s*(?=[,;:.])'), '');
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Retire les décorations visuelles qui n'apportent rien à l'oral.
  ///
  /// Les symboles réellement porteurs de sens — exposants, comparateurs,
  /// opérateurs, lettres grecques — sont préservés : ils sont mis en mots
  /// juste après.
  static String _stripDecorations(String value) {
    final kept = StringBuffer();
    for (final rune in value.runes) {
      if (_isMeaningful(rune)) {
        kept.writeCharCode(rune);
      } else if (_isDecorative(rune)) {
        kept.write(' ');
      } else {
        kept.writeCharCode(rune);
      }
    }
    return kept.toString();
  }

  static const _meaningfulSymbols = {
    0x00B2, // ²
    0x00B3, // ³
    0x00D7, // ×
    0x00F7, // ÷
    0x0394, // Δ
    0x03C0, // π
    0x2013, 0x2014, // – —
    0x2019, // ’
    0x2212, // −
    0x221A, // √
    0x221E, // ∞
    0x2260, 0x2264, 0x2265, // ≠ ≤ ≥
  };

  static bool _isMeaningful(int rune) => _meaningfulSymbols.contains(rune);

  static bool _isDecorative(int rune) {
    // Emojis, pictogrammes, drapeaux, modificateurs de teinte, dingbats,
    // flèches décoratives et sélecteurs de variante.
    if (rune >= 0x1F000 && rune <= 0x1FAFF) return true;
    if (rune >= 0x2600 && rune <= 0x27BF) return true;
    if (rune >= 0x2B00 && rune <= 0x2BFF) return true;
    if (rune >= 0xFE00 && rune <= 0xFE0F) return true;
    if (rune == 0x200D) return true; // liaison d'emoji
    if (rune >= 0x2190 && rune <= 0x21FF) return true; // flèches
    // Puces décoratives.
    if (rune == 0x2022 || rune == 0x25CF || rune == 0x25AA) return true;
    return false;
  }

  static const _frenchMath = <int, String>{
    0x00B2: ' au carré ',
    0x00B3: ' au cube ',
    0x2264: ' inférieur ou égal à ',
    0x2265: ' supérieur ou égal à ',
    0x2260: ' différent de ',
    0x00D7: ' fois ',
    0x00F7: ' divisé par ',
    0x2212: ' moins ',
    0x221A: ' racine carrée de ',
    0x0394: ' delta ',
    0x03C0: ' pi ',
    0x221E: ' infini ',
  };

  static const _englishMath = <int, String>{
    0x00B2: ' squared ',
    0x00B3: ' cubed ',
    0x2264: ' less than or equal to ',
    0x2265: ' greater than or equal to ',
    0x2260: ' not equal to ',
    0x00D7: ' times ',
    0x00F7: ' divided by ',
    0x2212: ' minus ',
    0x221A: ' square root of ',
    0x0394: ' delta ',
    0x03C0: ' pi ',
    0x221E: ' infinity ',
  };

  static String _mathToWords(String value, String language) {
    final table = language == 'en' ? _englishMath : _frenchMath;
    var spoken = value;
    table.forEach((rune, words) {
      spoken = spoken.replaceAll(String.fromCharCode(rune), words);
    });
    // « = » se lit rarement bien en lecture continue.
    spoken = spoken.replaceAll('=', language == 'en' ? ' equals ' : ' égale ');
    return spoken;
  }
}
