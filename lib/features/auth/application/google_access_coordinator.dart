import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/firebase_identity_port.dart';
import '../data/services/google_credential_source.dart';
import '../domain/google_access.dart';

final googleCredentialSourceProvider = Provider<GoogleCredentialSource>(
  (ref) => NativeGoogleCredentialSource(),
);

final googleIdentityProbeProvider = Provider<GoogleIdentityProbe>(
  (ref) => CallableGoogleIdentityProbe(),
);

final firebaseIdentityPortProvider = Provider<FirebaseIdentityPort>(
  (ref) => FirebaseAuthIdentityPort(),
);

/// Coordinateur unique du parcours Google. Il vit tant que l'application vit :
/// la preuve en attente traverse la question « Vous utilisez déjà
/// INTELLIA237 ? » puis l'écran de récupération du compte existant.
final googleAccessCoordinatorProvider = Provider<GoogleAccessCoordinator>(
  (ref) => GoogleAccessCoordinator(
    source: ref.watch(googleCredentialSourceProvider),
    probe: ref.watch(googleIdentityProbeProvider),
    identity: ref.watch(firebaseIdentityPortProvider),
  ),
);

/// Google comme méthode d'accès, sans jamais dupliquer une identité.
///
/// Registre de décisions (refonte Auth V2, P0-2 et P0-3 de la revue de
/// 7ea5cf0) :
/// 1. La preuve Google est acquise sans session Firebase
///    ([GoogleCredentialSource]).
/// 2. Le serveur dit si ce compte Google ouvre déjà un compte INTELLIA237
///    ([GoogleIdentityProbe]) — sans rien créer. Le SDK client ne sait pas
///    tester une preuve fédérée sans connexion : `signInWithCredential` crée
///    l'utilisateur, et `fetchSignInMethodsForEmail` est vide sous la
///    protection contre l'énumération d'adresses (et ne verrait pas un compte
///    ouvert par téléphone). La sonde évite donc tout UID temporaire.
/// 3. Compte connu : connexion directe. Compte inconnu : aucune identité
///    n'existe tant que la personne n'a pas répondu.
/// 4. « Oui, retrouver mon compte » : la personne se connecte réellement à son
///    compte existant (UID A), puis la preuve Google en attente est rattachée
///    à A. L'UID renvoyé doit être A, sinon rien n'est ouvert.
/// 5. Compte Google déjà porté par un autre UID : arrêt. Aucune fusion, aucune
///    copie, aucune réattribution.
///
/// La preuve en attente ne vit qu'en mémoire.
class GoogleAccessCoordinator {
  GoogleAccessCoordinator({
    required GoogleCredentialSource source,
    required GoogleIdentityProbe probe,
    required FirebaseIdentityPort identity,
  }) : _source = source,
       _probe = probe,
       _identity = identity;

  final GoogleCredentialSource _source;
  final GoogleIdentityProbe _probe;
  final FirebaseIdentityPort _identity;

  GoogleProof? _pending;

  bool get hasPendingProof => _pending != null;
  String? get pendingEmail => _pending?.email;

  /// « Continuer avec Google ».
  Future<GoogleAccessOutcome> begin() async {
    _pending = null;
    final acquired = await _source.acquire();
    final GoogleProof proof;
    switch (acquired) {
      case GoogleCredentialCancelled():
        return const GoogleAccessCancelled();
      case GoogleCredentialFailed(:final code):
        return GoogleAccessFailed(code);
      case GoogleCredentialAcquired(proof: final acquiredProof):
        proof = acquiredProof;
    }

    final GoogleIdentityStatus status;
    try {
      status = await _probe.probe(proof);
    } on IdentityFailure catch (error) {
      return GoogleAccessFailed(error.code);
    } catch (_) {
      return const GoogleAccessFailed('google-probe-failed');
    }

    if (status == GoogleIdentityStatus.unknown) {
      _pending = proof;
      return GoogleAccessNeedsDecision(email: proof.email);
    }
    return _signInKnownAccount(proof);
  }

  Future<GoogleAccessOutcome> _signInKnownAccount(GoogleProof proof) async {
    try {
      final result = await _identity.signInWithGoogle(proof);
      if (result.isNewUser) {
        // Le compte a disparu entre la sonde et la connexion : l'identité
        // née à l'instant, sans aucun profil, est supprimée aussitôt et la
        // personne répond à la question comme pour un compte inconnu.
        await _discardFreshIdentity();
        _pending = proof;
        return GoogleAccessNeedsDecision(email: proof.email);
      }
      return GoogleAccessSignedIn(result.uid);
    } on IdentityFailure catch (error) {
      if (error.code == 'account-exists-with-different-credential') {
        _pending = proof;
        return GoogleAccessRecoveryRequired(email: error.email ?? proof.email);
      }
      return GoogleAccessFailed(error.code);
    }
  }

  /// « Non, continuer » : une nouvelle identité, par choix explicite.
  Future<GoogleAccessOutcome> continueAsNewIdentity() async {
    final proof = _pending;
    if (proof == null) {
      return const GoogleAccessFailed('google-session-expired');
    }
    try {
      final result = await _signInFreshProof(proof);
      _pending = null;
      return GoogleAccessSignedIn(result.uid, isNewIdentity: result.isNewUser);
    } on IdentityFailure catch (error) {
      if (error.code == 'account-exists-with-different-credential') {
        // Firebase connaît déjà cette adresse sous une autre méthode : on ne
        // crée rien et on demande de prouver ce compte.
        return GoogleAccessRecoveryRequired(email: error.email ?? proof.email);
      }
      return GoogleAccessFailed(error.code);
    }
  }

  /// Rattache la preuve Google en attente au compte existant, auquel la
  /// personne vient de se connecter réellement sous [expectedUid].
  Future<GoogleLinkOutcome> linkPendingTo(String expectedUid) async {
    final proof = _pending;
    if (proof == null) return const GoogleLinkFailed('google-session-expired');
    if (_identity.currentUid != expectedUid) {
      return const GoogleLinkFailed('identity-mismatch');
    }
    try {
      final linkedUid = await _linkFreshProof(proof);
      if (linkedUid != expectedUid) {
        return const GoogleLinkFailed('identity-mismatch');
      }
      _pending = null;
      return GoogleLinked(linkedUid);
    } on IdentityFailure catch (error) {
      switch (error.code) {
        case 'credential-already-in-use' || 'email-already-in-use':
          _pending = null;
          await _source.signOut();
          return const GoogleLinkedElsewhere();
        case 'provider-already-linked':
          _pending = null;
          await _source.signOut();
          return const GoogleLinkProviderTaken();
        default:
          return GoogleLinkFailed(error.code);
      }
    }
  }

  /// Supprime l'identité que la vérification de récupération vient de créer
  /// (numéro inconnu) : elle n'a jamais eu de profil. Renvoie faux si la
  /// suppression n'a pas pu être faite — l'écran le dit.
  Future<bool> discardFreshIdentity() => _discardFreshIdentity();

  Future<bool> _discardFreshIdentity() async {
    var deleted = true;
    try {
      await _identity.deleteCurrentUser();
    } catch (_) {
      deleted = false;
    }
    try {
      await _identity.signOut();
    } catch (_) {}
    return deleted;
  }

  /// Abandon du parcours : la preuve est oubliée, ainsi que le compte Google
  /// choisi sur l'appareil.
  Future<void> abandon() async {
    _pending = null;
    await _source.signOut();
  }

  /// Une preuve Google vit environ une heure. Si Firebase la refuse comme
  /// expirée, elle est renouvelée une fois, pour le MÊME compte Google.
  Future<FederatedSignIn> _signInFreshProof(GoogleProof proof) =>
      _withRenewal(proof, _identity.signInWithGoogle);

  Future<String> _linkFreshProof(GoogleProof proof) =>
      _withRenewal(proof, _identity.linkGoogleToCurrentUser);

  Future<T> _withRenewal<T>(
    GoogleProof proof,
    Future<T> Function(GoogleProof proof) action,
  ) async {
    try {
      return await action(proof);
    } on IdentityFailure catch (error) {
      if (!_expiredProofCodes.contains(error.code)) rethrow;
      final renewed = await _source.acquire();
      if (renewed is! GoogleCredentialAcquired ||
          !renewed.proof.sameAccountAs(proof)) {
        throw const IdentityFailure('google-session-expired');
      }
      _pending = renewed.proof;
      return action(renewed.proof);
    }
  }

  static const _expiredProofCodes = {
    'invalid-credential',
    'user-token-expired',
  };
}
