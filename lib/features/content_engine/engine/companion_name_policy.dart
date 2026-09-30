/// Quand le Compagnon peut appeler l'élève par son prénom.
///
/// Règle de conversation : le prénom est une attention, pas une ponctuation.
/// Il n'apparaît qu'à certains moments, et jamais deux fois de suite.
enum CompanionMoment {
  /// Première réponse importante de la séance.
  firstInteraction,

  /// Retour après plusieurs erreurs sur la même notion.
  afterErrors,

  /// Réussite notable (série, notion maîtrisée).
  notableSuccess,

  /// Encouragement ponctuel.
  encouragement,

  /// Réponse ordinaire : jamais de prénom.
  routine,
}

class CompanionNamePolicy {
  CompanionNamePolicy({this.minimumGap = 4});

  /// Nombre minimal de messages entre deux emplois du prénom.
  final int minimumGap;

  int _sinceLastUse = 1 << 20;
  bool _greeted = false;

  /// Prénom exploitable tiré du profil, ou `null` (l'échange reste alors
  /// parfaitement naturel sans prénom).
  static String? usableFirstName(String? raw) {
    if (raw == null) return null;
    final first = raw.trim().split(RegExp(r'\s+')).first;
    if (first.length < 2 || first.length > 24) return null;
    if (RegExp(r'[0-9@_#/\\]').hasMatch(first)) return null;
    return first[0].toUpperCase() + first.substring(1);
  }

  /// Le prénom à employer pour ce message, ou `null`. Chaque appel compte
  /// comme un message.
  String? nameFor(CompanionMoment moment, String? firstName) {
    final name = usableFirstName(firstName);
    var effective = moment;
    if (!_greeted && moment == CompanionMoment.routine) {
      effective = CompanionMoment.firstInteraction;
    }
    final eligible =
        name != null &&
        effective != CompanionMoment.routine &&
        (effective != CompanionMoment.firstInteraction || !_greeted) &&
        _sinceLastUse >= minimumGap;
    _greeted = true;
    if (eligible) {
      _sinceLastUse = 1;
      return name;
    }
    _sinceLastUse++;
    return null;
  }
}
