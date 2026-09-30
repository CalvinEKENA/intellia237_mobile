/// Forme d'un code de liaison enfant, vérifiable sans réseau.
///
/// Le code est une **invitation de relation**, pas un identifiant de
/// connexion : sa bonne forme ne prouve rien, ne résout aucun élève et
/// n'authentifie personne. Seul le serveur le résout, et seulement pour un
/// compte parent authentifié.
///
/// Reflète le générateur serveur (`functions/src/services/childLinkCallable.ts`) :
/// huit caractères pris dans un alphabet sans caractères ambigus (ni O/0, ni
/// I/1, ni L), normalisés en majuscules, sans espaces ni tirets.
abstract final class ChildLinkCode {
  static const length = 8;

  static final _wellFormed = RegExp(r'^[A-HJKMNP-Z2-9]{8}$');
  static final _separators = RegExp(r'[\s-]+');

  /// Même normalisation que le serveur.
  static String normalize(String raw) =>
      raw.trim().toUpperCase().replaceAll(_separators, '');

  static bool isWellFormed(String raw) => _wellFormed.hasMatch(normalize(raw));
}
