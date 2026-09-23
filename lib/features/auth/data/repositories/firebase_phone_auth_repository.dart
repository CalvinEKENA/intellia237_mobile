import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/firebase_error_mapper.dart';
import '../../domain/repositories/phone_auth_repository.dart';

final phoneAuthRepositoryProvider = Provider<PhoneAuthRepository>(
  (ref) => FirebasePhoneAuthRepository(),
);

class FirebasePhoneAuthRepository
    implements PhoneAuthRepository, CancelablePhoneAuthRepository {
  FirebasePhoneAuthRepository({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  int _attempt = 0;

  @override
  void cancelPendingVerification() => _attempt++;

  @override
  Future<void> startVerification({
    required String phoneNumber,
    required bool linkCurrentUser,
    int? forceResendingToken,
    required void Function(PhoneAuthSession session) onVerified,
    required void Function(PhoneAuthFailure failure) onFailed,
    required void Function(PhoneCodeDispatch dispatch) onCodeSent,
    required void Function(String verificationId) onAutoRetrievalTimeout,
  }) async {
    final attempt = ++_attempt;
    if (kIsWeb) {
      await _startWebVerification(
        phoneNumber: phoneNumber,
        attempt: attempt,
        onCodeSent: onCodeSent,
      );
      return;
    }
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        forceResendingToken: forceResendingToken,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          if (attempt != _attempt) return;
          try {
            onVerified(
              await _completeCredential(
                credential,
                linkCurrentUser: linkCurrentUser,
              ),
            );
          } on FirebaseAuthException catch (error) {
            onFailed(
              PhoneAuthFailure(_normalizeCode(error.code, error.message)),
            );
          }
        },
        verificationFailed: (error) {
          onFailed(PhoneAuthFailure(_normalizeCode(error.code, error.message)));
        },
        codeSent: (verificationId, resendToken) {
          onCodeSent(
            PhoneCodeDispatch(
              verificationId: verificationId,
              resendToken: resendToken,
            ),
          );
        },
        codeAutoRetrievalTimeout: onAutoRetrievalTimeout,
      );
    } on FirebaseAuthException catch (error) {
      throw PhoneAuthFailure(_normalizeCode(error.code, error.message));
    }
  }

  /// Web (application web, 23/09/2026) : `verifyPhoneNumber` n'existe que
  /// sur téléphone. Le navigateur envoie le SMS par `signInWithPhoneNumber`,
  /// après une vérification anti-robot invisible gérée par Firebase ; seul
  /// l'identifiant de vérification est gardé. La suite est la même que sur
  /// téléphone : [confirmCode] construit l'identifiant avec le code reçu,
  /// puis connecte ou rattache le compte (le navigateur sait faire les deux).
  Future<void> _startWebVerification({
    required String phoneNumber,
    required int attempt,
    required void Function(PhoneCodeDispatch dispatch) onCodeSent,
  }) async {
    try {
      // Sans conteneur, Firebase pose une vérification invisible, puis la
      // retire : l'élève ne voit une épreuve que si le trafic est suspect.
      final confirmation = await _auth.signInWithPhoneNumber(phoneNumber);
      if (attempt != _attempt) return;
      onCodeSent(
        PhoneCodeDispatch(verificationId: confirmation.verificationId),
      );
    } on FirebaseAuthException catch (error) {
      throw PhoneAuthFailure(_normalizeCode(error.code, error.message));
    }
  }

  @override
  Future<PhoneAuthSession> confirmCode({
    required String verificationId,
    required String smsCode,
    required bool linkCurrentUser,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return await _completeCredential(
        credential,
        linkCurrentUser: linkCurrentUser,
      );
    } on FirebaseAuthException catch (error) {
      throw PhoneAuthFailure(_normalizeCode(error.code, error.message));
    }
  }

  Future<PhoneAuthSession> _completeCredential(
    PhoneAuthCredential credential, {
    required bool linkCurrentUser,
  }) async {
    late final UserCredential result;
    if (linkCurrentUser) {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw FirebaseAuthException(code: 'requires-recent-login');
      }
      // Linking is intentionally used instead of signing in with the phone
      // credential: an existing email account must keep its UID and profile.
      result = await currentUser.linkWithCredential(credential);
    } else {
      result = await _auth.signInWithCredential(credential);
    }

    final user = result.user;
    if (user == null) throw FirebaseAuthException(code: 'user-not-found');
    return PhoneAuthSession(
      uid: user.uid,
      phoneNumber: user.phoneNumber,
      isNewUser: result.additionalUserInfo?.isNewUser ?? false,
      linkedToExistingUser: linkCurrentUser,
    );
  }

  /// Le code seul ne suffit pas : le motif réel d'un refus Android est
  /// souvent porté par le message technique.
  static String _normalizeCode(String code, [String? technicalMessage]) {
    final normalized = FirebaseErrorMapper.normalizeCode(
      code,
      technicalMessage,
    );
    final reference = FirebaseErrorMapper.diagnosticId(normalized);
    // Never send the SDK message: it may contain a phone number or credential.
    // Collection still respects the user's existing Crashlytics preference.
    if (!kIsWeb && !kDebugMode) {
      unawaited(_recordDiagnostic(reference));
    }
    return normalized;
  }

  static Future<void> _recordDiagnostic(String reference) async {
    try {
      await FirebaseCrashlytics.instance.recordError(
        'PhoneAuthFailure:$reference',
        StackTrace.current,
        reason: 'Phone verification failed',
      );
    } catch (_) {
      // Telemetry must never interrupt authentication.
    }
  }
}
