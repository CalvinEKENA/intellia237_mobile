import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_config.dart';
import '../../auth/domain/firebase_error_mapper.dart';
import '../domain/student_registration_payload.dart';
import '../domain/student_registration_result.dart';
import 'student_registration_repository.dart';

final studentRegistrationRepositoryProvider =
    Provider<StudentRegistrationRepository>((ref) {
      final config = ref.watch(appConfigProvider);
      String? projectId;
      String? appId;
      try {
        final options = Firebase.app().options;
        projectId = options.projectId;
        appId = options.appId;
      } catch (_) {
        // Firebase non initialisé (ex. tests) — diagnostics simplement omis.
      }
      return FirebaseStudentRegistrationRepository(
        isStaging: config.isStaging,
        projectId: projectId,
        appId: appId,
      );
    });

class FirebaseStudentRegistrationRepository
    implements StudentRegistrationRepository {
  FirebaseStudentRegistrationRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    this.isStaging = false,
    this.projectId,
    this.appId,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// En staging, l'erreur affichée inclut un identifiant diagnostic copiable
  /// et un log non sensible est émis. En production : message utilisateur seul.
  final bool isStaging;
  final String? projectId;
  final String? appId;

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
        _logStaging('create-user', 'missing-user', null);
        throw StudentRegistrationException(
          message: _decorate(
            'Impossible de créer le compte utilisateur.',
            'missing-user',
            null,
          ),
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
      _logStaging('create-user', error.code, error.message);
      final code = FirebaseErrorMapper.normalizeCode(error.code, error.message);
      throw StudentRegistrationException(
        message: _decorate(
          FirebaseErrorMapper.authMessage(
            code: error.code,
            technicalMessage: error.message,
          ),
          error.code,
          error.message,
        ),
        code: code,
      );
    } on FirebaseException catch (error, stackTrace) {
      _debugLog('create-profile', error.code, error.message, stackTrace);
      _logStaging('create-profile', error.code, error.message);
      await _rollbackAuthUser(user, createdHere: createdHere);
      throw StudentRegistrationException(
        message: _decorate(
          FirebaseErrorMapper.serviceMessage(
            code: error.code,
            technicalMessage: error.message,
          ),
          error.code,
          error.message,
        ),
        code: FirebaseErrorMapper.normalizeCode(error.code, error.message),
      );
    } on StudentRegistrationException {
      await _rollbackAuthUser(user, createdHere: createdHere);
      rethrow;
    } catch (error, stackTrace) {
      _debugLog('registration', 'unknown-error', error.toString(), stackTrace);
      _logStaging('registration', 'unknown-error', error.toString());
      await _rollbackAuthUser(user, createdHere: createdHere);
      throw StudentRegistrationException(
        message: _decorate(
          FirebaseErrorMapper.serviceMessage(code: 'unknown-error'),
          'unknown-error',
          null,
        ),
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

  /// En staging, ajoute l'identifiant diagnostic copiable au message.
  String _decorate(String message, String? code, String? technical) {
    if (!isStaging) return message;
    return '$message\n[${FirebaseErrorMapper.diagnosticId(code, technical)}]';
  }

  /// Log de diagnostic staging — uniquement des champs NON sensibles.
  /// Jamais de mot de passe, clé API, token, ni contenu privé du profil.
  void _logStaging(String step, String? code, String? technical) {
    if (!isStaging) return;
    final appIdShort = appId == null
        ? 'n/a'
        : (appId!.length <= 14 ? appId! : '${appId!.substring(0, 14)}…');
    debugPrint(
      '[INTELLIA237][staging][registration] env=staging '
      'projectId=${projectId ?? 'n/a'} appId=$appIdShort step=$step '
      'code=${FirebaseErrorMapper.normalizeCode(code, technical)} '
      'diagnostic=${FirebaseErrorMapper.diagnosticId(code, technical)}',
    );
  }
}
