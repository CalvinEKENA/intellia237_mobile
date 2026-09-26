import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../domain/google_access.dart';

/// Résultat d'une connexion Firebase par une preuve fédérée.
class FederatedSignIn {
  const FederatedSignIn({required this.uid, required this.isNewUser});
  final String uid;
  final bool isNewUser;
}

/// Opérations Firebase Auth dont le parcours Google a besoin, derrière une
/// interface pour que l'ordre des appels soit prouvé par les tests.
///
/// Toute erreur remonte en [IdentityFailure] portant le code Firebase ;
/// aucun message technique n'en sort.
abstract interface class FirebaseIdentityPort {
  String? get currentUid;

  /// Identités successives de l'appareil (`null` : aucune session).
  Stream<String?> uidChanges();

  Future<FederatedSignIn> signInWithGoogle(GoogleProof proof);

  /// Rattache [proof] à la session courante et renvoie son UID.
  Future<String> linkGoogleToCurrentUser(GoogleProof proof);

  /// Connexion réelle au compte e-mail existant.
  Future<String> signInWithEmailPassword(String email, String password);

  /// Supprime l'identité courante. Réservé à une identité créée à l'instant
  /// par ce parcours et restée sans profil.
  Future<void> deleteCurrentUser();

  Future<void> signOut();
}

class FirebaseAuthIdentityPort implements FirebaseIdentityPort {
  FirebaseAuthIdentityPort({FirebaseAuth? auth}) : _authOverride = auth;

  final FirebaseAuth? _authOverride;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  @override
  String? get currentUid => Firebase.apps.isEmpty && _authOverride == null
      ? null
      : _auth.currentUser?.uid;

  @override
  Stream<String?> uidChanges() {
    if (Firebase.apps.isEmpty && _authOverride == null) {
      return const Stream<String?>.empty();
    }
    return _auth.authStateChanges().map((user) => user?.uid);
  }

  @override
  Future<FederatedSignIn> signInWithGoogle(GoogleProof proof) =>
      _guard(() async {
        final result = await _auth.signInWithCredential(
          GoogleAuthProvider.credential(idToken: proof.idToken),
        );
        final user = result.user;
        if (user == null) throw const IdentityFailure('missing-user');
        return FederatedSignIn(
          uid: user.uid,
          isNewUser: result.additionalUserInfo?.isNewUser ?? false,
        );
      });

  @override
  Future<String> linkGoogleToCurrentUser(GoogleProof proof) => _guard(() async {
    final user = _auth.currentUser;
    if (user == null) throw const IdentityFailure('no-current-user');
    final result = await user.linkWithCredential(
      GoogleAuthProvider.credential(idToken: proof.idToken),
    );
    return result.user?.uid ?? user.uid;
  });

  @override
  Future<String> signInWithEmailPassword(String email, String password) =>
      _guard(() async {
        final result = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        final uid = result.user?.uid;
        if (uid == null) throw const IdentityFailure('missing-user');
        return uid;
      });

  @override
  Future<void> deleteCurrentUser() => _guard(() async {
    await _auth.currentUser?.delete();
  });

  @override
  Future<void> signOut() => _guard(() => _auth.signOut());

  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (error) {
      throw IdentityFailure(error.code, email: error.email);
    } on FirebaseException catch (error) {
      throw IdentityFailure(error.code);
    }
  }
}

/// Demande au serveur si un compte Google est déjà la méthode d'accès d'un
/// compte INTELLIA237, sans rien créer.
abstract interface class GoogleIdentityProbe {
  Future<GoogleIdentityStatus> probe(GoogleProof proof);
}

/// Callable `probeGoogleIdentity` : le serveur vérifie la signature et
/// l'audience du jeton Google, puis cherche l'UID qui porte ce compte
/// Google. Il ne répond qu'au détenteur du jeton, sur son propre compte.
class CallableGoogleIdentityProbe implements GoogleIdentityProbe {
  CallableGoogleIdentityProbe({FirebaseFunctions? functions})
    : _functionsOverride = functions;

  final FirebaseFunctions? _functionsOverride;

  @override
  Future<GoogleIdentityStatus> probe(GoogleProof proof) async {
    try {
      final functions =
          _functionsOverride ??
          FirebaseFunctions.instanceFor(region: 'europe-west1');
      final response = await functions
          .httpsCallable('probeGoogleIdentity')
          .call<Map<String, dynamic>>({'idToken': proof.idToken});
      return switch (response.data['status']) {
        'existing' => GoogleIdentityStatus.existing,
        'unknown' => GoogleIdentityStatus.unknown,
        _ => throw const IdentityFailure('google-probe-invalid-response'),
      };
    } on FirebaseFunctionsException catch (error) {
      throw IdentityFailure(switch (error.code) {
        'unavailable' || 'deadline-exceeded' => 'network-request-failed',
        'resource-exhausted' => 'too-many-requests',
        'invalid-argument' || 'unauthenticated' => 'invalid-credential',
        _ => 'google-probe-failed',
      });
    }
  }
}
