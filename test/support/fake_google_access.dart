import 'dart:async';
import 'dart:convert';

import 'package:intellia237/features/auth/data/services/firebase_identity_port.dart';
import 'package:intellia237/features/auth/data/services/google_credential_source.dart';
import 'package:intellia237/features/auth/domain/google_access.dart';

/// Jeton d'identité Google de test : `sub` et adresse lisibles, signature
/// factice (seuls le serveur et Firebase vérifient une signature).
GoogleProof fakeGoogleProof(String subject, {String? email}) {
  String encode(Map<String, Object?> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final token =
      '${encode({'alg': 'RS256', 'kid': 'test'})}.'
      '${encode({'sub': subject, 'email': email})}.signature';
  return GoogleProof(idToken: token, email: email, displayName: 'Test');
}

/// Identités Firebase simulées : UID, fournisseurs Google rattachés,
/// comptes e-mail, session courante. Chaque appel est journalisé pour prouver
/// l'ordre des opérations.
class FakeIdentityBackend {
  final calls = <String>[];

  /// `sub` Google → UID qui porte ce compte Google.
  final googleOwners = <String, String>{};

  /// UID → `sub` Google rattaché.
  final googleOf = <String, String>{};

  /// Adresse → (UID, mot de passe).
  final emailAccounts = <String, ({String uid, String password})>{};

  /// Adresses que Firebase réserve déjà à un compte (une seule identité par
  /// adresse) : une connexion Google sur l'une d'elles est refusée.
  final emailsInUse = <String>{};

  /// UID créés par une connexion Google.
  final createdByGoogle = <String>[];
  final deleted = <String>[];

  bool networkDown = false;
  bool deleteFails = false;

  /// Codes à lever au prochain appel de rattachement (une fois chacun).
  final linkFailures = <String>[];

  final _uids = StreamController<String?>.broadcast();
  String? _currentUid;
  int _next = 0;

  String? get currentUid => _currentUid;
  set currentUid(String? uid) {
    if (_currentUid == uid) return;
    _currentUid = uid;
    _uids.add(uid);
  }

  Stream<String?> get uidChanges => _uids.stream;

  void _network() {
    if (networkDown) throw const IdentityFailure('network-request-failed');
  }
}

class FakeFirebaseIdentity implements FirebaseIdentityPort {
  FakeFirebaseIdentity(this.backend);
  final FakeIdentityBackend backend;

  @override
  String? get currentUid => backend.currentUid;

  @override
  Stream<String?> uidChanges() => backend.uidChanges;

  @override
  Future<FederatedSignIn> signInWithGoogle(GoogleProof proof) async {
    backend.calls.add('firebase.signInWithGoogle');
    backend._network();
    final sub = proof.subject!;
    final owner = backend.googleOwners[sub];
    if (owner != null) {
      backend.currentUid = owner;
      return FederatedSignIn(uid: owner, isNewUser: false);
    }
    if (proof.email != null && backend.emailsInUse.contains(proof.email)) {
      throw IdentityFailure(
        'account-exists-with-different-credential',
        email: proof.email,
      );
    }
    final uid = 'google-uid-${++backend._next}';
    backend.createdByGoogle.add(uid);
    backend.googleOwners[sub] = uid;
    backend.googleOf[uid] = sub;
    backend.currentUid = uid;
    return FederatedSignIn(uid: uid, isNewUser: true);
  }

  @override
  Future<String> linkGoogleToCurrentUser(GoogleProof proof) async {
    backend.calls.add('firebase.linkGoogle');
    backend._network();
    if (backend.linkFailures.isNotEmpty) {
      throw IdentityFailure(backend.linkFailures.removeAt(0));
    }
    final uid = backend.currentUid;
    if (uid == null) throw const IdentityFailure('no-current-user');
    final sub = proof.subject!;
    final owner = backend.googleOwners[sub];
    if (owner != null && owner != uid) {
      throw const IdentityFailure('credential-already-in-use');
    }
    if (backend.googleOf[uid] != null && backend.googleOf[uid] != sub) {
      throw const IdentityFailure('provider-already-linked');
    }
    backend.googleOwners[sub] = uid;
    backend.googleOf[uid] = sub;
    return uid;
  }

  @override
  Future<String> signInWithEmailPassword(String email, String password) async {
    backend.calls.add('firebase.signInWithEmail');
    backend._network();
    final account = backend.emailAccounts[email.trim()];
    if (account == null || account.password != password) {
      throw const IdentityFailure('invalid-credential');
    }
    backend.currentUid = account.uid;
    return account.uid;
  }

  @override
  Future<void> deleteCurrentUser() async {
    backend.calls.add('firebase.deleteCurrentUser');
    if (backend.deleteFails) {
      throw const IdentityFailure('requires-recent-login');
    }
    final uid = backend.currentUid;
    if (uid == null) return;
    backend.deleted.add(uid);
    final sub = backend.googleOf.remove(uid);
    if (sub != null) backend.googleOwners.remove(sub);
  }

  @override
  Future<void> signOut() async {
    backend.calls.add('firebase.signOut');
    backend.currentUid = null;
  }
}

/// Sélecteur de comptes Google simulé : chaque `acquire` rend le résultat
/// suivant de [script] (le dernier est répété).
class FakeGoogleCredentialSource implements GoogleCredentialSource {
  FakeGoogleCredentialSource(
    this.backend, [
    List<GoogleCredentialResult>? script,
  ]) : script = script ?? [];

  final FakeIdentityBackend backend;
  final List<GoogleCredentialResult> script;
  int signOuts = 0;

  void choose(GoogleProof proof) => script
    ..clear()
    ..add(GoogleCredentialAcquired(proof));

  @override
  Future<GoogleCredentialResult> acquire() async {
    backend.calls.add('google.acquire');
    if (script.isEmpty) return const GoogleCredentialCancelled();
    return script.length == 1 ? script.first : script.removeAt(0);
  }

  @override
  Future<void> signOut() async {
    backend.calls.add('google.signOut');
    signOuts++;
  }
}

/// Sonde serveur simulée : elle lit qui porte un `sub` Google, sans rien
/// créer.
class FakeGoogleIdentityProbe implements GoogleIdentityProbe {
  FakeGoogleIdentityProbe(this.backend);
  final FakeIdentityBackend backend;
  bool unavailable = false;

  @override
  Future<GoogleIdentityStatus> probe(GoogleProof proof) async {
    backend.calls.add('server.probe');
    if (unavailable) throw const IdentityFailure('network-request-failed');
    return backend.googleOwners.containsKey(proof.subject)
        ? GoogleIdentityStatus.existing
        : GoogleIdentityStatus.unknown;
  }
}
