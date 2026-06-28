import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../domain/app_role.dart';
import '../../domain/firebase_error_mapper.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
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
          message: 'Utilisateur introuvable apres connexion.',
          code: 'missing-user',
        );
      }

      return _fetchUserData(uid);
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
          message: 'Impossible de creer le compte utilisateur.',
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

    try {
      return await _fetchUserData(currentUser.uid);
    } catch (_) {
      return null;
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

    return AuthUserData(
      uid: uid,
      email: (data['email'] as String? ?? '').trim(),
      role: _parseRole(roleString),
      firstName: (data['firstName'] as String? ?? '').trim(),
      lastName: (data['lastName'] as String? ?? '').trim(),
      profileCompleted: data['profileCompleted'] as bool? ?? false,
    );
  }

  AppRole _parseRole(String role) {
    return AppRole.values.firstWhere(
      (value) => value.name == role,
      orElse: () => AppRole.student,
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
}

class AuthError implements Exception {
  const AuthError({required this.message, this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}
