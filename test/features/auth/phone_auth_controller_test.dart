import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/application/phone_auth_controller.dart';
import 'package:intellia237/features/auth/domain/repositories/phone_auth_repository.dart';

void main() {
  test('leaving and reopening OTP does not resend during cooldown', () async {
    final gate = PhoneRequestGate();
    final repository = _FakePhoneAuthRepository();
    final first = PhoneAuthController(
      repository: repository,
      linkCurrentUser: false,
      requestGate: gate,
    );
    await first.sendCode('699123456');
    repository.failed!(const PhoneAuthFailure('too-many-requests'));
    first.close();
    final reopened = PhoneAuthController(
      repository: repository,
      linkCurrentUser: false,
      requestGate: gate,
    );
    addTearDown(reopened.close);
    await reopened.sendCode('699123456');
    expect(repository.startCalls, 1);
    expect(reopened.state.cooldownSeconds, greaterThan(0));
  });

  test(
    'callbacks from the previous number cannot replace the current code',
    () async {
      final repository = _FakePhoneAuthRepository();
      final controller = PhoneAuthController(
        repository: repository,
        linkCurrentUser: false,
      );
      addTearDown(controller.close);
      await controller.sendCode('699123456');
      repository.codeSent!(const PhoneCodeDispatch(verificationId: 'old'));
      final staleCodeSent = repository.codeSent!;
      controller.changePhoneNumber();
      await controller.sendCode('699123457');
      repository.codeSent!(const PhoneCodeDispatch(verificationId: 'new'));
      staleCodeSent(const PhoneCodeDispatch(verificationId: 'old-late'));
      expect(controller.state.verificationId, 'new');
      await controller.confirmCode('123456');
      repository.failed!(const PhoneAuthFailure('too-many-requests'));
      repository.codeSent!(const PhoneCodeDispatch(verificationId: 'late'));
      expect(controller.state.stage, PhoneAuthStage.success);
      expect(controller.state.errorCode, isNull);
    },
  );
  test(
    'dispatches E.164 number and exposes every verification callback',
    () async {
      final repository = _FakePhoneAuthRepository();
      final controller = PhoneAuthController(
        repository: repository,
        linkCurrentUser: false,
      );
      addTearDown(controller.close);

      await controller.sendCode('699 12 34 56');
      expect(repository.lastPhoneNumber, '+237699123456');
      expect(repository.lastLinkCurrentUser, isFalse);

      repository.codeSent!(
        const PhoneCodeDispatch(
          verificationId: 'verification-1',
          resendToken: 12,
        ),
      );
      expect(controller.state.stage, PhoneAuthStage.codeEntry);
      expect(
        controller.state.cooldownSeconds,
        PhoneAuthController.resendCooldown,
      );

      repository.timeout!('verification-1');
      expect(controller.state.autoRetrievalTimedOut, isTrue);

      repository.failed!(const PhoneAuthFailure('network-request-failed'));
      expect(controller.state.errorCode, 'network-request-failed');
    },
  );

  test('confirms pasted code and supports safe link mode', () async {
    final repository = _FakePhoneAuthRepository();
    final controller = PhoneAuthController(
      repository: repository,
      linkCurrentUser: true,
    );
    addTearDown(controller.close);

    await controller.sendCode('+237699123456');
    repository.codeSent!(const PhoneCodeDispatch(verificationId: 'id'));
    await controller.confirmCode('12 34-56');

    expect(repository.lastLinkCurrentUser, isTrue);
    expect(repository.lastCode, '123456');
    expect(controller.state.stage, PhoneAuthStage.success);
    expect(controller.state.session?.uid, 'existing-uid');
    expect(controller.state.session?.linkedToExistingUser, isTrue);
  });

  test('keeps phone entry active for invalid Cameroon number', () async {
    final repository = _FakePhoneAuthRepository();
    final controller = PhoneAuthController(
      repository: repository,
      linkCurrentUser: false,
    );
    addTearDown(controller.close);

    await controller.sendCode('222 12 34 56');

    expect(repository.startCalls, 0);
    expect(controller.state.stage, PhoneAuthStage.phoneEntry);
    expect(controller.state.errorCode, 'invalid-phone-number');
  });
}

class _FakePhoneAuthRepository implements PhoneAuthRepository {
  int startCalls = 0;
  String? lastPhoneNumber;
  String? lastCode;
  bool? lastLinkCurrentUser;
  void Function(PhoneAuthSession)? verified;
  void Function(PhoneAuthFailure)? failed;
  void Function(PhoneCodeDispatch)? codeSent;
  void Function(String)? timeout;

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
    startCalls++;
    lastPhoneNumber = phoneNumber;
    lastLinkCurrentUser = linkCurrentUser;
    verified = onVerified;
    failed = onFailed;
    codeSent = onCodeSent;
    timeout = onAutoRetrievalTimeout;
  }

  @override
  Future<PhoneAuthSession> confirmCode({
    required String verificationId,
    required String smsCode,
    required bool linkCurrentUser,
  }) async {
    lastCode = smsCode;
    lastLinkCurrentUser = linkCurrentUser;
    return PhoneAuthSession(
      uid: linkCurrentUser ? 'existing-uid' : 'new-uid',
      phoneNumber: '+237699123456',
      isNewUser: !linkCurrentUser,
      linkedToExistingUser: linkCurrentUser,
    );
  }
}
