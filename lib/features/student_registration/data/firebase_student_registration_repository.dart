import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/school_establishment.dart';
import '../domain/student_registration_payload.dart';
import '../domain/student_registration_result.dart';
import 'mock_establishments.dart';
import 'student_registration_repository.dart';

final studentRegistrationRepositoryProvider =
    Provider<StudentRegistrationRepository>(
      (ref) => FirebaseStudentRegistrationRepository(),
    );

class FirebaseStudentRegistrationRepository
    implements StudentRegistrationRepository {
  FirebaseStudentRegistrationRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const _usersCollection = 'users';
  static const _profilesCollection = 'student_profiles';

  @override
  Future<List<SchoolEstablishment>> searchEstablishments(String query) async {
    // Recherche 100% locale — Yaounde et Douala uniquement.
    return EstablishmentCatalog.search(query);
  }

  @override
  Future<StudentRegistrationResult> registerStudent(
    StudentRegistrationPayload payload,
  ) async {
    UserCredential? credential;

    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: payload.email.trim(),
        password: payload.password,
      );

      final user = credential.user;
      if (user == null) {
        throw const StudentRegistrationException(
          message: 'Impossible de creer le compte utilisateur.',
          code: 'missing-user',
        );
      }

      final now = DateTime.now();
      final uid = user.uid;
      final displayName =
          '${payload.firstName.trim()} ${payload.lastName.trim()}'.trim();

      final batch = _firestore.batch();

      final userRef = _firestore.collection(_usersCollection).doc(uid);
      batch.set(
        userRef,
        payload.toUserDocument(uid: uid, now: now),
        SetOptions(merge: true),
      );

      final profileRef = _firestore.collection(_profilesCollection).doc(uid);
      batch.set(
        profileRef,
        payload.toStudentProfileDocument(uid: uid, now: now),
        SetOptions(merge: true),
      );

      await batch.commit();
      await user.updateDisplayName(displayName);

      return StudentRegistrationResult(
        uid: uid,
        email: payload.email.trim(),
        firstName: payload.firstName.trim(),
        lastName: payload.lastName.trim(),
      );
    } on FirebaseAuthException catch (error) {
      throw StudentRegistrationException(
        message: _mapAuthError(error),
        code: error.code,
      );
    } on FirebaseException catch (error) {
      await _rollbackAuthUser(credential);
      throw StudentRegistrationException(
        message: 'Impossible d\'enregistrer le compte pour le moment.',
        code: error.code,
      );
    } on StudentRegistrationException {
      await _rollbackAuthUser(credential);
      rethrow;
    } catch (_) {
      await _rollbackAuthUser(credential);
      throw const StudentRegistrationException(
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
