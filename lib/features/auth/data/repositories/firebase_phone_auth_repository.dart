import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/phone_auth_repository.dart';

final phoneAuthRepositoryProvider = Provider<PhoneAuthRepository>(
  (ref) => FirebasePhoneAuthRepository(),
);

class FirebasePhoneAuthRepository implements PhoneAuthRepository {
  FirebasePhoneAuthRepository({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

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
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        forceResendingToken: forceResendingToken,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          try {
            onVerified(
              await _completeCredential(
                credential,
                linkCurrentUser: linkCurrentUser,
              ),
            );
          } on FirebaseAuthException catch (error) {
            onFailed(PhoneAuthFailure(_normalizeCode(error.code)));
          }
        },
        verificationFailed: (error) {
          onFailed(PhoneAuthFailure(_normalizeCode(error.code)));
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
      throw PhoneAuthFailure(_normalizeCode(error.code));
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
      throw PhoneAuthFailure(_normalizeCode(error.code));
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

  static String _normalizeCode(String code) =>
      code.toLowerCase().replaceAll('_', '-');
}
