import 'interactive_block.dart';

/// Quelle interaction pour quelle matière.
///
/// Le compagnon (côté serveur) choisit l'activité avec la même politique :
/// l'ordre des mots pour une langue, les étapes d'une résolution en maths,
/// la chronologie en histoire, les étapes d'un processus en SVT. WORD_ORDER
/// n'est pas universel. Les types marqués « prévus » dans le registre
/// entreront dans ces listes quand leur rendu existera.
abstract final class InteractionPolicy {
  static const _bySubject = <String, List<InteractiveBlockType>>{
    'anglais': [InteractiveBlockType.wordOrder],
    'english': [InteractiveBlockType.wordOrder],
    'francais': [InteractiveBlockType.wordOrder],
    'french': [InteractiveBlockType.wordOrder],
    'espagnol': [InteractiveBlockType.wordOrder],
    'allemand': [InteractiveBlockType.wordOrder],
    'mathematiques': [
      InteractiveBlockType.equationOrder,
      InteractiveBlockType.stepOrder,
    ],
    'maths': [
      InteractiveBlockType.equationOrder,
      InteractiveBlockType.stepOrder,
    ],
    'physique': [
      InteractiveBlockType.stepOrder,
      InteractiveBlockType.equationOrder,
    ],
    'chimie': [
      InteractiveBlockType.equationOrder,
      InteractiveBlockType.sequence,
    ],
    'svt': [InteractiveBlockType.processSequence],
    'biologie': [InteractiveBlockType.processSequence],
    'histoire': [InteractiveBlockType.timelineOrder],
    'history': [InteractiveBlockType.timelineOrder],
    'geographie': [InteractiveBlockType.sequence],
    'philosophie': [InteractiveBlockType.sequence],
    'litterature': [InteractiveBlockType.sequence],
  };

  static String _normalize(String subject) {
    const accents = {
      'à': 'a',
      'â': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'î': 'i',
      'ï': 'i',
      'ô': 'o',
      'ö': 'o',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };
    final lower = subject.trim().toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(accents[char] ?? char);
    }
    return buffer.toString().split(RegExp(r'[\s/_-]+')).first;
  }

  /// Types d'interaction préférés pour une matière, dans l'ordre.
  static List<InteractiveBlockType> preferredTypesFor(String subject) =>
      _bySubject[_normalize(subject)] ?? const [InteractiveBlockType.sequence];
}
