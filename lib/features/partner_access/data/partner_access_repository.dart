import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/partner_access.dart';

/// L'échange a échoué ; [code] est un code Firebase (jamais montré tel quel).
class PartnerAccessException implements Exception {
  const PartnerAccessException(this.code);

  final String code;

  @override
  String toString() => 'PartnerAccessException($code)';
}

/// Ouvre la session du compte partenaire canonique. Le serveur émet le jeton ;
/// l'application ne fabrique rien.
abstract interface class PartnerAccessRepository {
  /// Échange l'adresse contre une session Firebase réelle (jeton personnalisé
  /// émis par la callable `signInWithPartnerAccess`).
  Future<void> signIn(String email);
}

class FirebasePartnerAccessRepository implements PartnerAccessRepository {
  FirebasePartnerAccessRepository({
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  }) : _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1'),
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  @override
  Future<void> signIn(String email) async {
    try {
      final result = await _functions
          .httpsCallable('signInWithPartnerAccess')
          .call<Map<Object?, Object?>>({
            'email': PartnerAccess.normalize(email),
          });
      final token = result.data['token'];
      if (token is! String || token.isEmpty) {
        throw const PartnerAccessException('internal');
      }
      await _auth.signInWithCustomToken(token);
    } on FirebaseFunctionsException catch (error) {
      throw PartnerAccessException(error.code);
    } on FirebaseAuthException catch (error) {
      throw PartnerAccessException(error.code);
    }
  }
}

final partnerAccessRepositoryProvider = Provider<PartnerAccessRepository>(
  (ref) => FirebasePartnerAccessRepository(),
);
