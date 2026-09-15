import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/firebase_error_mapper.dart';
import '../domain/registration_diagnostic.dart';
import '../domain/student_registration_payload.dart';
import '../domain/student_registration_result.dart';
import 'student_registration_gateways.dart';
import 'student_registration_repository.dart';
import 'registration_establishments_provider.dart';

final studentRegistrationRepositoryProvider =
    Provider<StudentRegistrationRepository>((ref) {
      String? projectId;
      String? appId;
      try {
        final options = Firebase.app().options;
        projectId = options.projectId;
        appId = options.appId;
      } catch (_) {
        // Firebase is not initialized in some unit tests. Diagnostics simply
        // omit the build identity in that case.
      }
      return FirebaseStudentRegistrationRepository(
        projectId: projectId,
        appId: appId,
        isRegisteredEstablishment: (id) async => (await ref.read(
          registrationEstablishmentsProvider.future,
        )).any((school) => school.id == id),
      );
    });

class FirebaseStudentRegistrationRepository
    implements StudentRegistrationRepository {
  FirebaseStudentRegistrationRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    RegistrationAuthGateway? authGateway,
    RegistrationDocumentStore? documentStore,
    this.isRegisteredEstablishment,
    this.projectId,
    this.appId,
  }) : _authGateway =
           authGateway ??
           FirebaseRegistrationAuthGateway(auth ?? FirebaseAuth.instance),
       _documentStore =
           documentStore ??
           FirebaseRegistrationDocumentStore(
             firestore ?? FirebaseFirestore.instance,
           );

  final Future<bool> Function(String)? isRegisteredEstablishment;
  final RegistrationAuthGateway _authGateway;
  final RegistrationDocumentStore _documentStore;
  final String? projectId;
  final String? appId;

  @override
  Future<StudentRegistrationResult> registerStudent(
    StudentRegistrationPayload payload,
  ) async {
    var operation = RegistrationOperation.authCreate;

    try {
      final user = await _resolveAuthUser(payload);
      if (user == null) {
        throw const _RegistrationFailure(
          operation: RegistrationOperation.authCreate,
          code: 'missing-user',
        );
      }

      final school = payload.establishment;
      if (school != null &&
          isRegisteredEstablishment != null &&
          (school.candidateId == null ||
              !await isRegisteredEstablishment!(school.candidateId!))) {
        throw const StudentRegistrationException(
          message: 'Sélectionnez un établissement dans la liste actualisée.',
          code: 'invalid-establishment',
        );
      }
      final now = DateTime.now();
      final uid = user.uid;
      final userCreateData = payload.toUserDocument(uid: uid, now: now);
      final userUpdateData = payload.toUserUpdateDocument(now: now);
      final verifiedPhone = user.phoneNumber?.trim();
      if (verifiedPhone != null && verifiedPhone.isNotEmpty) {
        userCreateData['phoneNumber'] = verifiedPhone;
        userUpdateData['phoneNumber'] = verifiedPhone;
      }

      operation = await _documentStore.upsertUser(
        uid: uid,
        createData: userCreateData,
        updateData: userUpdateData,
      );
      operation = await _documentStore.upsertProfile(
        uid: uid,
        createData: payload.toStudentProfileDocument(uid: uid, now: now),
        updateData: payload.toStudentProfileUpdateDocument(now: now),
      );

      final displayName =
          '${payload.firstName.trim()} ${payload.lastName.trim()}'.trim();
      await _updateAuthMetadataBestEffort(user, displayName);

      return StudentRegistrationResult(
        uid: uid,
        email: user.email?.trim() ?? payload.email.trim(),
        firstName: payload.firstName.trim(),
        lastName: payload.lastName.trim(),
      );
    } on RegistrationAuthFailure catch (error, stackTrace) {
      _throwRegistrationFailure(
        operation: RegistrationOperation.authCreate,
        code: error.code,
        technicalMessage: error.technicalMessage,
        stackTrace: stackTrace,
        isAuth: true,
      );
    } on RegistrationWriteFailure catch (error, stackTrace) {
      _throwRegistrationFailure(
        operation: error.operation,
        code: error.code,
        technicalMessage: error.technicalMessage,
        stackTrace: stackTrace,
      );
    } on _RegistrationFailure catch (error, stackTrace) {
      _throwRegistrationFailure(
        operation: error.operation,
        code: error.code,
        technicalMessage: null,
        stackTrace: stackTrace,
        isAuth: error.operation == RegistrationOperation.authCreate,
      );
    } on StudentRegistrationException {
      rethrow;
    } catch (error, stackTrace) {
      _throwRegistrationFailure(
        operation: operation,
        code: 'unknown-error',
        technicalMessage: error.runtimeType.toString(),
        stackTrace: stackTrace,
      );
    }
  }

  Future<RegistrationAuthUser?> _resolveAuthUser(
    StudentRegistrationPayload payload,
  ) async {
    final normalizedEmail = payload.email.trim().toLowerCase();
    final currentUser = _authGateway.currentUser;
    if (currentUser != null) {
      final verifiedPhone = currentUser.phoneNumber?.trim() ?? '';
      final currentEmail = currentUser.email?.trim().toLowerCase() ?? '';
      if (verifiedPhone.isNotEmpty ||
          (normalizedEmail.isNotEmpty && currentEmail == normalizedEmail) ||
          // Élève sans téléphone entré avec son code d'accès : il complète le
          // profil de SA propre identité, sans créer de compte e-mail.
          (normalizedEmail.isEmpty && currentUser.openedByServerToken)) {
        return currentUser;
      }
    }

    if (normalizedEmail.isEmpty || payload.password.isEmpty) {
      throw const RegistrationAuthFailure(code: 'phone-verification-required');
    }

    try {
      return await _authGateway.createUser(
        email: payload.email.trim(),
        password: payload.password,
      );
    } on RegistrationAuthFailure catch (error) {
      final normalized = FirebaseErrorMapper.normalizeCode(
        error.code,
        error.technicalMessage,
      );
      if (normalized != 'email-already-in-use') rethrow;

      // A previous submit may have created Firebase Auth before a Firestore
      // write failed. Re-authenticate and resume the idempotent writes.
      return _authGateway.signIn(
        email: payload.email.trim(),
        password: payload.password,
      );
    }
  }

  Future<void> _updateAuthMetadataBestEffort(
    RegistrationAuthUser user,
    String displayName,
  ) async {
    try {
      await user.updateDisplayName(displayName);
      if ((user.email?.isNotEmpty ?? false) && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on Object catch (error, stackTrace) {
      _debugLog(
        operation: RegistrationOperation.authCreate,
        normalizedErrorCode: 'metadata-best-effort',
        diagnosticId: 'AUTH-META-106',
        stackTrace: stackTrace,
        technicalType: error.runtimeType.toString(),
      );
    }
  }

  Never _throwRegistrationFailure({
    required RegistrationOperation operation,
    required String? code,
    required String? technicalMessage,
    required StackTrace stackTrace,
    bool isAuth = false,
  }) {
    final normalized = FirebaseErrorMapper.normalizeCode(
      code,
      technicalMessage,
    );
    final classifiedOperation = _classifyOperation(
      operation,
      normalized,
      technicalMessage,
    );
    final diagnosticId = FirebaseErrorMapper.diagnosticId(
      normalized,
      technicalMessage,
    );
    _debugLog(
      operation: classifiedOperation,
      normalizedErrorCode: normalized,
      diagnosticId: diagnosticId,
      stackTrace: stackTrace,
    );

    final baseMessage = isAuth
        ? FirebaseErrorMapper.authMessage(
            code: normalized,
            technicalMessage: technicalMessage,
          )
        : FirebaseErrorMapper.serviceMessage(
            code: normalized,
            technicalMessage: technicalMessage,
          );
    throw StudentRegistrationException(
      message: '$baseMessage\n[$diagnosticId]',
      code: normalized,
      registrationOperation: classifiedOperation.code,
      diagnosticId: diagnosticId,
    );
  }

  RegistrationOperation _classifyOperation(
    RegistrationOperation operation,
    String normalizedCode,
    String? technicalMessage,
  ) {
    final source = '$normalizedCode ${technicalMessage ?? ''}'.toLowerCase();
    if (source.contains('app-check') || source.contains('app check')) {
      return RegistrationOperation.appCheck;
    }
    if ({
      'network-request-failed',
      'network-error',
      'unavailable',
      'deadline-exceeded',
      'timeout',
    }.contains(normalizedCode)) {
      return RegistrationOperation.network;
    }
    if (normalizedCode == 'unknown-error') {
      return RegistrationOperation.unknown;
    }
    return operation;
  }

  void _debugLog({
    required RegistrationOperation operation,
    required String normalizedErrorCode,
    required String diagnosticId,
    required StackTrace stackTrace,
    String? technicalType,
  }) {
    final appIdShort = appId == null
        ? 'n/a'
        : (appId!.length <= 14 ? appId! : '${appId!.substring(0, 14)}…');
    debugPrint(
      '[INTELLIA237][registration] '
      'registrationOperation=${operation.code} '
      'normalizedErrorCode=$normalizedErrorCode '
      'diagnosticId=$diagnosticId '
      'projectId=${projectId ?? 'n/a'} appId=$appIdShort '
      'technicalType=${technicalType ?? 'n/a'}',
    );
    if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
  }
}

class _RegistrationFailure implements Exception {
  const _RegistrationFailure({required this.operation, required this.code});

  final RegistrationOperation operation;
  final String code;
}
