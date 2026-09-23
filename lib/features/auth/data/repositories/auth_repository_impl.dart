import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../domain/app_role.dart';
import '../../domain/firebase_error_mapper.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository, AuthSessionResolver {
  AuthRepositoryImpl({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const _usersCollection = 'users';

  @override
  Future<AuthUserData> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        throw const AuthError(
          message: 'Utilisateur introuvable après connexion.',
          code: 'missing-user',
        );
      }

      return await _fetchUserData(uid);
    } on FirebaseAuthException catch (error) {
      _debugLog('signInWithEmail', error.code, error.message, error.stackTrace);
      throw _mapFirebaseAuthError(error);
    }
  }

  @override
  Future<AuthUserData> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required AppRole role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        throw const AuthError(
          message: 'Impossible de créer le compte utilisateur.',
          code: 'missing-user',
        );
      }

      final now = DateTime.now().toUtc();
      await _firestore.collection(_usersCollection).doc(uid).set({
        'uid': uid,
        'email': email.trim(),
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'role': role.name,
        'avatarId': 'nova',
        'profileCompleted': false,
        'tourGuideSeen': false,
        'createdAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));
      await _sendVerificationBestEffort(credential.user);

      return AuthUserData(
        uid: uid,
        email: email.trim(),
        role: role,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        profileCompleted: false,
      );
    } on FirebaseAuthException catch (error) {
      _debugLog('register', error.code, error.message, error.stackTrace);
      throw _mapFirebaseAuthError(error);
    } on FirebaseException catch (error, stackTrace) {
      _debugLog('register-profile', error.code, error.message, stackTrace);
      throw AuthError(
        message: FirebaseErrorMapper.serviceMessage(
          code: error.code,
          technicalMessage: error.message,
        ),
        code: FirebaseErrorMapper.normalizeCode(error.code, error.message),
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      _debugLog(
        'sendPasswordResetEmail',
        error.code,
        error.message,
        error.stackTrace,
      );
      throw _mapFirebaseAuthError(error);
    }
  }

  @override
  Future<AuthUserData?> getCurrentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return null;
    }
    return _fetchUserData(currentUser.uid);
  }

  @override
  Future<AuthSessionResolution> resolveCurrentSession() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const AuthSessionResolution(
        kind: AuthSessionResolutionKind.unauthenticated,
      );
    }

    final uid = currentUser.uid;
    final email = currentUser.email ?? '';
    final providers = [
      for (final info in currentUser.providerData) info.providerId,
    ];
    try {
      final user = await _fetchUserData(uid);
      final kind = user.legacyProfile
          ? AuthSessionResolutionKind.legacyProfileRecovery
          : user.profileCompleted
          ? AuthSessionResolutionKind.authenticated
          : AuthSessionResolutionKind.needsOnboarding;
      return AuthSessionResolution(
        kind: kind,
        firebaseUid: uid,
        firebaseEmail: email,
        user: user,
        signInProviders: providers,
      );
    } on AuthError catch (error) {
      if (error.code == 'user-disabled') {
        await _auth.signOut();
        return const AuthSessionResolution(
          kind: AuthSessionResolutionKind.unauthenticated,
          errorCode: 'user-disabled',
        );
      }
      if (error.code == 'user-profile-not-found') {
        return AuthSessionResolution(
          kind: AuthSessionResolutionKind.needsOnboarding,
          firebaseUid: uid,
          firebaseEmail: email,
          errorCode: error.code,
          signInProviders: providers,
        );
      }
      if (error.code == 'user-role-invalid') {
        developer.log(
          'Unknown stored account role; Firebase session retained for recovery.',
          name: 'intellia237.auth',
          error: error.code,
        );
        return AuthSessionResolution(
          kind: AuthSessionResolutionKind.legacyProfileRecovery,
          firebaseUid: uid,
          firebaseEmail: email,
          errorCode: error.code,
        );
      }
      rethrow;
    } on FirebaseException catch (error, stackTrace) {
      _debugLog(
        'resolve-profile',
        error.code,
        'Firestore profile resolution failed.',
        stackTrace,
      );
      return AuthSessionResolution(
        kind: AuthSessionResolutionKind.retryableProfileFailure,
        firebaseUid: uid,
        firebaseEmail: email,
        errorCode: FirebaseErrorMapper.normalizeCode(error.code, error.message),
      );
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  Future<AuthUserData> _fetchUserData(String uid) async {
    final snapshot = await _firestore
        .collection(_usersCollection)
        .doc(uid)
        .get();
    final data = snapshot.data();

    if (data == null) {
      throw const AuthError(
        message: 'Profil utilisateur introuvable.',
        code: 'user-profile-not-found',
      );
    }

    final roleString = (data['role'] as String? ?? '').trim();
    if (const ['suspended', 'deleted'].contains(data['accountStatus'])) {
      throw const AuthError(
        message: 'Ce compte est désactivé. Contacte l’assistance Intellia 237.',
        code: 'user-disabled',
      );
    }

    final parsedRole = parseStoredAppRole(roleString);
    final role = parsedRole.role;
    if (role == null) {
      throw const AuthError(
        message: 'Le rôle de ce compte est manquant ou invalide.',
        code: 'user-role-invalid',
      );
    }
    final parsedRoles = parseStoredAppRoles(data['roles'], roleString);
    var profileCompleted = data['profileCompleted'] as bool? ?? false;
    if (role == AppRole.student) {
      final studentProfile = await _firestore
          .collection('student_profiles')
          .doc(uid)
          .get();
      final classLevel =
          (studentProfile.data()?['classLevel'] as String?)?.trim() ?? '';
      profileCompleted =
          profileCompleted && studentProfile.exists && classLevel.isNotEmpty;
    }

    return AuthUserData(
      uid: uid,
      email: (data['email'] as String? ?? '').trim(),
      role: role,
      roles: parsedRoles,
      firstName: (data['firstName'] as String? ?? '').trim(),
      lastName: (data['lastName'] as String? ?? '').trim(),
      profileCompleted: profileCompleted,
      legacyProfile: parsedRole.isLegacy,
      isSuperAdmin: parsedRole.isSuperAdmin,
      establishmentId: switch ((data['establishmentId'] as String?)?.trim()) {
        final String id when id.isNotEmpty => id,
        _ => null,
      },
      accountStatus: data['accountStatus'] as String?,
    );
  }

  AuthError _mapFirebaseAuthError(FirebaseAuthException error) {
    final code = FirebaseErrorMapper.normalizeCode(error.code, error.message);
    return AuthError(
      message: FirebaseErrorMapper.authMessage(
        code: error.code,
        technicalMessage: error.message,
      ),
      code: code,
    );
  }

  void _debugLog(
    String operation,
    String? code,
    String? message,
    StackTrace? stackTrace,
  ) {
    if (!kDebugMode) return;
    debugPrint('Firebase Auth $operation failed: code=$code message=$message');
    if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
  }

  Future<void> _sendVerificationBestEffort(User? user) async {
    if (user == null || user.emailVerified) return;
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException {
      // Le compte est déjà créé : un problème d’envoi ne doit pas annuler
      // l’inscription. Paramètres permet de renvoyer le message plus tard.
    }
  }
}

class AuthError implements Exception {
  const AuthError({required this.message, this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}
