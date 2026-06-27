import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/firebase_error_mapper.dart';
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
    FirebaseFunctions? functions,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  static const _usersCollection = 'users';
  static const _parentProfilesCollection = 'parent_profiles';
  static const _staffRegistrationCallable = 'submitStaffRegistration';

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
    return _registerPrivilegedStaff(
      email: payload.email,
      password: payload.password,
      firstName: payload.firstName,
      lastName: payload.lastName,
      callableData: payload.toStaffRegistrationData(),
    );
  }

  @override
  Future<RoleRegistrationResult> registerAdmin(
    AdminRegistrationPayload payload,
  ) {
    return _registerPrivilegedStaff(
      email: payload.email,
      password: payload.password,
      firstName: payload.firstName,
      lastName: payload.lastName,
      callableData: payload.toStaffRegistrationData(),
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
    } on FirebaseAuthException catch (error, stackTrace) {
      _debugLog('register-role', error.code, error.message, stackTrace);
      throw RoleRegistrationException(
        message: FirebaseErrorMapper.authMessage(
          code: error.code,
          technicalMessage: error.message,
        ),
        code: FirebaseErrorMapper.normalizeCode(error.code, error.message),
      );
    } on FirebaseException catch (error, stackTrace) {
      _debugLog('register-role-profile', error.code, error.message, stackTrace);
      await _rollbackAuthUser(credential);
      throw RoleRegistrationException(
        message: FirebaseErrorMapper.serviceMessage(
          code: error.code,
          technicalMessage: error.message,
        ),
        code: FirebaseErrorMapper.normalizeCode(error.code, error.message),
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

  Future<RoleRegistrationResult> _registerPrivilegedStaff({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required Map<String, dynamic> callableData,
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

      final displayName = '${firstName.trim()} ${lastName.trim()}'.trim();
      await user.updateDisplayName(displayName);
      await user.getIdToken(true);

      final callable = _functions.httpsCallable(_staffRegistrationCallable);
      final result = await callable.call<Map<String, dynamic>>(callableData);
      final data = result.data;

      return RoleRegistrationResult(
        uid: (data['uid'] as String?) ?? user.uid,
        email: (data['email'] as String?) ?? email.trim(),
        firstName: (data['firstName'] as String?) ?? firstName.trim(),
        lastName: (data['lastName'] as String?) ?? lastName.trim(),
      );
    } on FirebaseAuthException catch (error, stackTrace) {
      _debugLog('register-staff-auth', error.code, error.message, stackTrace);
      throw RoleRegistrationException(
        message: FirebaseErrorMapper.authMessage(
          code: error.code,
          technicalMessage: error.message,
        ),
        code: FirebaseErrorMapper.normalizeCode(error.code, error.message),
      );
    } on FirebaseFunctionsException catch (error, stackTrace) {
      _debugLog(
        'register-staff-callable',
        error.code,
        error.message,
        stackTrace,
      );
      await _rollbackAuthUser(credential);
      throw RoleRegistrationException(
        message: FirebaseErrorMapper.serviceMessage(
          code: error.code,
          technicalMessage: error.message,
        ),
        code: FirebaseErrorMapper.normalizeCode(error.code, error.message),
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

  void _debugLog(
    String operation,
    String? code,
    String? message,
    StackTrace stackTrace,
  ) {
    if (!kDebugMode) return;
    debugPrint(
      'Role registration $operation failed: code=$code message=$message',
    );
    debugPrintStack(stackTrace: stackTrace);
  }
}
