import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../student_registration/data/mock_establishments.dart';
import '../../student_registration/domain/school_establishment.dart';
import '../domain/admin_registration_payload.dart';
import '../domain/parent_registration_payload.dart';
import '../domain/registration_result.dart';
import '../domain/teacher_registration_payload.dart';
import 'role_registration_repository.dart';

final roleRegistrationRepositoryProvider = Provider<RoleRegistrationRepository>(
  (ref) => FirebaseRoleRegistrationRepository(),
);

class FirebaseRoleRegistrationRepository implements RoleRegistrationRepository {
  FirebaseRoleRegistrationRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const _usersCollection = 'users';
  static const _parentProfilesCollection = 'parent_profiles';
  static const _teacherProfilesCollection = 'teacher_profiles';
  static const _adminProfilesCollection = 'admin_profiles';

  @override
  Future<List<SchoolEstablishment>> searchEstablishments(String query) async {
    // Recherche 100% locale — Yaounde et Douala uniquement.
    return EstablishmentCatalog.search(query);
  }

  @override
  Future<RoleRegistrationResult> registerParent(
    ParentRegistrationPayload payload,
  ) {
    return _register(
      email: payload.email,
      password: payload.password,
      userBuilder: (uid, now) => payload.toUserDocument(uid: uid, now: now),
      profileCollection: _parentProfilesCollection,
      profileBuilder: (uid, now) =>
          payload.toParentProfileDocument(uid: uid, now: now),
      firstName: payload.firstName,
      lastName: payload.lastName,
    );
  }

  @override
  Future<RoleRegistrationResult> registerTeacher(
    TeacherRegistrationPayload payload,
  ) {
    return _register(
      email: payload.email,
      password: payload.password,
      userBuilder: (uid, now) => payload.toUserDocument(uid: uid, now: now),
      profileCollection: _teacherProfilesCollection,
      profileBuilder: (uid, now) =>
          payload.toTeacherProfileDocument(uid: uid, now: now),
      firstName: payload.firstName,
      lastName: payload.lastName,
    );
  }

  @override
  Future<RoleRegistrationResult> registerAdmin(
    AdminRegistrationPayload payload,
  ) {
    return _register(
      email: payload.email,
      password: payload.password,
      userBuilder: (uid, now) => payload.toUserDocument(uid: uid, now: now),
      profileCollection: _adminProfilesCollection,
      profileBuilder: (uid, now) =>
          payload.toAdminProfileDocument(uid: uid, now: now),
      firstName: payload.firstName,
      lastName: payload.lastName,
    );
  }

  Future<RoleRegistrationResult> _register({
    required String email,
    required String password,
    required Map<String, dynamic> Function(String uid, DateTime now)
    userBuilder,
    required String profileCollection,
    required Map<String, dynamic> Function(String uid, DateTime now)
    profileBuilder,
    required String firstName,
    required String lastName,
  }) async {
    UserCredential? credential;

    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const RoleRegistrationException(
          message: 'Impossible de creer le compte utilisateur.',
          code: 'missing-user',
        );
      }

      final now = DateTime.now();
      final uid = user.uid;
      final displayName = '${firstName.trim()} ${lastName.trim()}'.trim();
      final batch = _firestore.batch();

      final userRef = _firestore.collection(_usersCollection).doc(uid);
      batch.set(userRef, userBuilder(uid, now), SetOptions(merge: true));

      final profileRef = _firestore.collection(profileCollection).doc(uid);
      batch.set(profileRef, profileBuilder(uid, now), SetOptions(merge: true));

      await batch.commit();
      await user.updateDisplayName(displayName);

      return RoleRegistrationResult(
        uid: uid,
        email: email.trim(),
        firstName: firstName.trim(),
        lastName: lastName.trim(),
      );
    } on FirebaseAuthException catch (error) {
      throw RoleRegistrationException(
        message: _mapAuthError(error),
        code: error.code,
      );
    } on FirebaseException catch (error) {
      await _rollbackAuthUser(credential);
      throw RoleRegistrationException(
        message: 'Impossible d\'enregistrer le compte pour le moment.',
        code: error.code,
      );
    } on RoleRegistrationException {
      await _rollbackAuthUser(credential);
      rethrow;
    } catch (_) {
      await _rollbackAuthUser(credential);
      throw const RoleRegistrationException(
        message: 'Une erreur inattendue est survenue.',
        code: 'unknown-error',
      );
    }
  }

  Future<void> _rollbackAuthUser(UserCredential? credential) async {
    final user = credential?.user;
    if (user == null) {
      return;
    }

    try {
      await user.delete();
    } catch (_) {
      // Evite de masquer l'erreur principale.
    }
  }

  String _mapAuthError(FirebaseAuthException error) {
    return switch (error.code) {
      'email-already-in-use' => 'Cet email est deja utilise.',
      'invalid-email' => 'Adresse email invalide.',
      'weak-password' => 'Mot de passe trop faible (8 caracteres minimum).',
      'network-request-failed' => 'Aucune connexion internet disponible.',
      _ => error.message ?? 'Erreur lors de la creation du compte.',
    };
  }
}
