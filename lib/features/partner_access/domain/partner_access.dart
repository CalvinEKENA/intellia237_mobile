/// Accès partenaire : le compte de test « démo pour Francis », ouvert par son
/// adresse exacte, sans mot de passe, sans code et sans lien.
///
/// Décision assumée du propriétaire (29/09/2026) : cette adresse est un compte
/// de test privilégié connu de lui et de son partenaire ; la saisir suffit.
/// Ce n'est donc pas une preuve d'identité. Ce que l'application ne fait
/// JAMAIS : aucun privilège n'est accordé localement. Reconnaître l'adresse
/// ne change que l'écran ; l'accès vient d'une vraie session Firebase émise
/// par le serveur (`functions/src/services/partnerAccess.ts`), sur un compte
/// élève ordinaire, sous les mêmes règles de sécurité que tout le monde.
abstract final class PartnerAccess {
  /// L'adresse canonique : minuscules, sans espaces.
  static const canonicalEmail = 'fran6farmer@yahoo.fr';

  /// L'identifiant du compte canonique, fixé par le serveur.
  static const uid = 'intellia-demo-francis';

  /// « FRAN6FARMER@YAHOO.FR » et « fran6farmer@yahoo.fr » désignent le même
  /// compte : espaces autour et casse ignorés.
  static String normalize(String input) => input.trim().toLowerCase();

  /// Seule l'adresse exacte, une fois normalisée, est reconnue : ni un autre
  /// domaine, ni un autre identifiant, ni un préfixe ou un suffixe.
  static bool recognizes(String input) => normalize(input) == canonicalEmail;
}
