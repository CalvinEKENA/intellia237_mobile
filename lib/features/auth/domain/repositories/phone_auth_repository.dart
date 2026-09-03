class PhoneAuthSession {
  const PhoneAuthSession({
    required this.uid,
    required this.phoneNumber,
    required this.isNewUser,
    required this.linkedToExistingUser,
  });

  final String uid;
  final String? phoneNumber;
  final bool isNewUser;
  final bool linkedToExistingUser;
}

class PhoneCodeDispatch {
  const PhoneCodeDispatch({required this.verificationId, this.resendToken});

  final String verificationId;
  final int? resendToken;
}

class PhoneAuthFailure implements Exception {
  const PhoneAuthFailure(this.code);

  final String code;

  @override
  String toString() => code;
}

abstract interface class PhoneAuthRepository {
  Future<void> startVerification({
    required String phoneNumber,
    required bool linkCurrentUser,
    int? forceResendingToken,
    required void Function(PhoneAuthSession session) onVerified,
    required void Function(PhoneAuthFailure failure) onFailed,
    required void Function(PhoneCodeDispatch dispatch) onCodeSent,
    required void Function(String verificationId) onAutoRetrievalTimeout,
  });

  Future<PhoneAuthSession> confirmCode({
    required String verificationId,
    required String smsCode,
    required bool linkCurrentUser,
  });
}
