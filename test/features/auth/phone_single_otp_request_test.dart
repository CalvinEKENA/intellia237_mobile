import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/application/phone_auth_controller.dart';
import 'package:intellia237/features/auth/domain/repositories/phone_auth_repository.dart';

/// Firebase a répondu « trop de tentatives » lors du test appareil. Le champ
/// téléphone valide sur `onFieldSubmitted` **et** sur le bouton, et la saisie
/// du sixième chiffre du code valide déjà automatiquement en plus du
/// « terminé » du clavier : un seul geste de l'élève pouvait donc consommer
/// deux demandes OTP.
void main() {
  test('un envoi en cours ne peut pas être relancé par le clavier', () async {
    final repository = _PendingPhoneAuthRepository();
    final controller = PhoneAuthController(
      repository: repository,
      linkCurrentUser: false,
    );
    addTearDown(controller.close);

    // Bouton puis « envoyer » du clavier, sans attendre la réponse.
    final first = controller.sendCode('699 12 34 56');
    final second = controller.sendCode('699 12 34 56');
    await Future.wait([first, second]);

    expect(
      repository.startCalls,
      1,
      reason:
          'un seul geste utilisateur doit produire un seul verifyPhoneNumber',
    );
  });

  test('le renvoi reste bloqué pendant le compte à rebours', () async {
    final repository = _PendingPhoneAuthRepository();
    final controller = PhoneAuthController(
      repository: repository,
      linkCurrentUser: false,
    );
    addTearDown(controller.close);

    await controller.sendCode('699 12 34 56');
    repository.codeSent!(
      const PhoneCodeDispatch(verificationId: 'v1', resendToken: 1),
    );
    expect(controller.state.cooldownSeconds, greaterThan(0));

    await controller.resendCode();

    expect(repository.startCalls, 1);
  });

  test('le code n’est pas confirmé deux fois pour une seule saisie', () async {
    final repository = _PendingPhoneAuthRepository();
    final controller = PhoneAuthController(
      repository: repository,
      linkCurrentUser: false,
    );
    addTearDown(controller.close);

    await controller.sendCode('699 12 34 56');
    repository.codeSent!(
      const PhoneCodeDispatch(verificationId: 'v1', resendToken: 1),
    );

    // Sixième chiffre saisi puis « terminé » du clavier.
    final first = controller.confirmCode('123456');
    final second = controller.confirmCode('123456');
    await Future.wait([first, second]);

    expect(repository.confirmCalls, 1);
  });
}

/// Dépôt qui ne résout jamais l'envoi tout seul : il reproduit la fenêtre
/// pendant laquelle Firebase n'a pas encore rappelé.
class _PendingPhoneAuthRepository implements PhoneAuthRepository {
  int startCalls = 0;
  int confirmCalls = 0;
  void Function(PhoneCodeDispatch)? codeSent;

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
    codeSent = onCodeSent;
  }

  @override
  Future<PhoneAuthSession> confirmCode({
    required String verificationId,
    required String smsCode,
    required bool linkCurrentUser,
  }) async {
    confirmCalls++;
    return const PhoneAuthSession(
      uid: 'uid-1',
      phoneNumber: '+237699123456',
      isNewUser: true,
      linkedToExistingUser: false,
    );
  }
}
