import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/firebase_error_mapper.dart';
import '../domain/student_registration_payload.dart';
import '../domain/student_registration_result.dart';
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
  Future<StudentRegistrationResult> registerStudent(
    StudentRegistrationPayload payload,
  ) async {
    User? user;
    var createdHere = false;

    try {
      final normalizedEmail = payload.email.trim().toLowerCase();
      final currentUser = _auth.currentUser;
      if (currentUser != null &&
          currentUser.email?.trim().toLowerCase() == normalizedEmail) {
        user = currentUser;
      } else {
        final credential = await _auth
            .createUserWithEmailAndPassword(
              email: payload.email.trim(),
              password: payload.password,
            )
            .timeout(const Duration(seconds: 20));
        user = credential.user;
        createdHere = true;
      }

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

      await batch.commit().timeout(const Duration(seconds: 20));
      await user.updateDisplayName(displayName);

      return StudentRegistrationResult(
        uid: uid,
        email: payload.email.trim(),
        firstName: payload.firstName.trim(),
        lastName: payload.lastName.trim(),
      );
    } on FirebaseAuthException catch (error, stackTrace) {
      _debugLog('create-user', error.code, error.message, stackTrace);
      final code = FirebaseErrorMapper.normalizeCode(error.code, error.message);
      throw StudentRegistrationException(
        message: FirebaseErrorMapper.authMessage(
          code: error.code,
          technicalMessage: error.message,
        ),
        code: code,
      );
    } on FirebaseException catch (error, stackTrace) {
      _debugLog('create-profile', error.code, error.message, stackTrace);
      await _rollbackAuthUser(user, createdHere: createdHere);
      throw StudentRegistrationException(
        message: FirebaseErrorMapper.serviceMessage(
          code: error.code,
          technicalMessage: error.message,
        ),
        code: FirebaseErrorMapper.normalizeCode(error.code, error.message),
      );
    } on StudentRegistrationException {
      await _rollbackAuthUser(user, createdHere: createdHere);
      rethrow;
    } catch (error, stackTrace) {
      _debugLog('registration', 'unknown-error', error.toString(), stackTrace);
      await _rollbackAuthUser(user, createdHere: createdHere);
      throw StudentRegistrationException(
        message: FirebaseErrorMapper.serviceMessage(code: 'unknown-error'),
        code: 'unknown-error',
      );
    }
  }

  Future<void> _rollbackAuthUser(
    User? user, {
    required bool createdHere,
  }) async {
    if (user == null || !createdHere) return;

    try {
      await user.delete();
    } catch (error, stackTrace) {
      _debugLog(
        'rollback-user',
        'rollback-failed',
        error.toString(),
        stackTrace,
      );
    }
  }

  void _debugLog(
    String operation,
    String? code,
    String? message,
    StackTrace stackTrace,
  ) {
    if (!kDebugMode) return;
    debugPrint(
      'Student registration $operation failed: code=$code message=$message',
    );
    debugPrintStack(stackTrace: stackTrace);
  }
}
