import 'dart:convert';

/// Preuve d'identité Google obtenue auprès de Google, avant toute décision
/// côté Firebase.
///
/// Registre de décisions (refonte Auth V2) : l'ancienne passerelle appelait
/// `signInWithProvider`, qui crée un utilisateur Firebase pour tout compte
/// Google inconnu. Un parent déjà connu par téléphone (UID A) recevait ainsi
/// un UID B avant même de pouvoir dire « j'ai déjà un compte ». La preuve
/// Google est désormais acquise seule ; ce qu'on en fait se décide ensuite.
///
/// Le jeton est un secret : il ne quitte jamais la mémoire, n'est ni journalisé
/// ni persisté, et [toString] ne le montre pas.
class GoogleProof {
  GoogleProof({required this.idToken, this.email, this.displayName})
    : subject = _subjectOf(idToken);

  final String idToken;
  final String? email;
  final String? displayName;

  /// Identifiant stable du compte Google (`sub`), lu sans vérification
  /// cryptographique : il ne sert qu'à s'assurer qu'une preuve renouvelée
  /// désigne bien le même compte Google. La vérification fait autorité côté
  /// serveur et côté Firebase, jamais ici.
  final String? subject;

  bool sameAccountAs(GoogleProof other) =>
      subject != null && subject == other.subject;

  static String? _subjectOf(String idToken) {
    final parts = idToken.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final sub = (jsonDecode(payload) as Map<String, dynamic>)['sub'];
      return sub is String && sub.isNotEmpty ? sub : null;
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() => 'GoogleProof(<redacted>)';
}

/// Ce que l'acquisition de la preuve Google a donné.
sealed class GoogleCredentialResult {
  const GoogleCredentialResult();
}

class GoogleCredentialAcquired extends GoogleCredentialResult {
  const GoogleCredentialAcquired(this.proof);
  final GoogleProof proof;
}

class GoogleCredentialCancelled extends GoogleCredentialResult {
  const GoogleCredentialCancelled();
}

class GoogleCredentialFailed extends GoogleCredentialResult {
  const GoogleCredentialFailed(this.code);

  /// Code stable (voir [AuthErrorCopy]) ; jamais un message brut.
  final String code;
}

/// Réponse de la sonde serveur : le compte Google est-il déjà la méthode
/// d'accès d'un compte INTELLIA237 ? Aucune identité n'est créée pour le
/// savoir.
enum GoogleIdentityStatus { existing, unknown }

/// Issue du bouton « Continuer avec Google ».
sealed class GoogleAccessOutcome {
  const GoogleAccessOutcome();
}

/// Le compte Google ouvre déjà un compte INTELLIA237 : la session Firebase de
/// ce compte existe, à adopter par le contrôleur d'authentification.
class GoogleAccessSignedIn extends GoogleAccessOutcome {
  const GoogleAccessSignedIn(this.uid, {this.isNewIdentity = false});
  final String uid;

  /// Vrai seulement quand la personne a explicitement choisi de continuer
  /// comme nouvelle identité.
  final bool isNewIdentity;
}

/// Compte Google inconnu : la personne doit dire si elle utilise déjà
/// INTELLIA237. Aucune session Firebase n'est ouverte.
class GoogleAccessNeedsDecision extends GoogleAccessOutcome {
  const GoogleAccessNeedsDecision({this.email});
  final String? email;
}

/// Firebase signale qu'un compte existe déjà avec l'adresse de ce compte
/// Google, sous une autre méthode : il faut d'abord prouver ce compte. Ce
/// n'est pas une déduction de l'application à partir de l'adresse.
class GoogleAccessRecoveryRequired extends GoogleAccessOutcome {
  const GoogleAccessRecoveryRequired({this.email});
  final String? email;
}

class GoogleAccessCancelled extends GoogleAccessOutcome {
  const GoogleAccessCancelled();
}

class GoogleAccessFailed extends GoogleAccessOutcome {
  const GoogleAccessFailed(this.code);
  final String code;
}

/// Issue du rattachement de la preuve Google en attente au compte existant.
sealed class GoogleLinkOutcome {
  const GoogleLinkOutcome();
}

/// Google est désormais une méthode d'accès de l'UID existant, inchangé.
class GoogleLinked extends GoogleLinkOutcome {
  const GoogleLinked(this.uid);
  final String uid;
}

/// Ce compte Google est déjà la méthode d'accès d'un AUTRE compte
/// INTELLIA237 : rien n'est fusionné, copié ni réattribué.
class GoogleLinkedElsewhere extends GoogleLinkOutcome {
  const GoogleLinkedElsewhere();
}

/// Le compte existant a déjà un autre compte Google.
class GoogleLinkProviderTaken extends GoogleLinkOutcome {
  const GoogleLinkProviderTaken();
}

class GoogleLinkFailed extends GoogleLinkOutcome {
  const GoogleLinkFailed(this.code);
  final String code;
}

/// Erreur d'identité normalisée (Firebase, Google, sonde) : un code stable,
/// jamais le message technique.
class IdentityFailure implements Exception {
  const IdentityFailure(this.code, {this.email});
  final String code;
  final String? email;

  @override
  String toString() => 'IdentityFailure($code)';
}
