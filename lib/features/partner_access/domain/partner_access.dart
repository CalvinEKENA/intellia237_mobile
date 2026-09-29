import 'package:flutter/foundation.dart';

import 'partner_digest.dart';

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
///
/// L'ADRESSE N'EST PAS DANS LE DÉPÔT (il est public). L'application ne connaît
/// que son condensat salé ([PartnerDigest]), fourni à la construction :
/// `--dart-define-from-file=config/partner_access.local.json` (fichier local
/// non versionné, voir `docs/ACCES_PARTENAIRE.md`). Sans lui, aucune adresse
/// n'est reconnue et l'écran est celui de tout le monde.
abstract final class PartnerAccess {
  /// L'identifiant du compte canonique, fixé par le serveur.
  static const uid = 'intellia-demo-francis';

  static const _builtDigest = String.fromEnvironment('PARTNER_ACCESS_DIGEST');

  static PartnerDigest? _digest = PartnerDigest.tryParse(_builtDigest);

  static Set<String> _revoked = {...PartnerDigest.revokedDigests};

  /// Un condensat valide est présent dans cette construction.
  static bool get isConfigured => _digest != null;

  /// « PARTENAIRE@EXEMPLE.FR » et « partenaire@exemple.fr » désignent le même
  /// compte : espaces autour et casse ignorés.
  static String normalize(String input) => input.trim().toLowerCase();

  /// Seule la valeur exacte, une fois normalisée, est reconnue : ni un autre
  /// domaine, ni un autre identifiant, ni un préfixe ou un suffixe. Une valeur
  /// révoquée (devenue publique) n'est jamais reconnue, quel que soit le
  /// condensat de la construction.
  static bool recognizes(String input) {
    final digest = _digest;
    if (digest == null) return false;
    final normalized = normalize(input);
    if (PartnerDigest.isRevoked(normalized, revoked: _revoked)) return false;
    return digest.matches(normalized);
  }

  /// Les tests posent le condensat d'une adresse fictive.
  @visibleForTesting
  static void debugUseDigest(String? encoded) =>
      _digest = encoded == null ? null : PartnerDigest.tryParse(encoded);

  /// Les tests révoquent une valeur fictive.
  @visibleForTesting
  static void debugRevoke(String address) =>
      _revoked.add(PartnerDigest.sha256Hex(normalize(address)));

  @visibleForTesting
  static void debugReset() {
    _digest = PartnerDigest.tryParse(_builtDigest);
    _revoked = {...PartnerDigest.revokedDigests};
  }
}
