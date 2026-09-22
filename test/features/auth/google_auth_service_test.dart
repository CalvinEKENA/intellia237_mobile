import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/data/services/google_auth_service.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/auth_linking_state.dart';

class FakeGoogleAuthGateway implements GoogleAuthGateway {
  FakeGoogleAuthGateway({this.mockResult});

  GoogleAuthResult? mockResult;
  bool signOutCalled = false;

  @override
  Future<GoogleAuthResult> signIn() async {
    return mockResult ?? const GoogleAuthCancelled();
  }

  @override
  Future<AccountLinkingState> linkGoogleCredential(
    User currentUser,
    AuthCredential credential,
  ) async {
    return const LinkingSuccessState(
      linkedUid: 'user-linked-123',
      roles: [AppRole.student],
    );
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }
}

void main() {
  group('GoogleAuthService & Result hierarchy tests', () {
    test('GoogleAuthSuccess contains user and role', () {
      const success = GoogleAuthSuccess(
        uid: 'user-google-123',
        roles: [AppRole.student],
        profileCompleted: true,
      );
      expect(success.roles, equals([AppRole.student]));
      expect(success.profileCompleted, isTrue);
      expect(success, isA<GoogleAuthSuccess>());
    });

    test('GoogleAuthNewUser carries user email and displayName', () {
      const newUser = GoogleAuthNewUser(
        email: 'newuser@example.cm',
        displayName: 'Visiteur Test',
      );
      expect(newUser, isA<GoogleAuthNewUser>());
      expect(newUser.email, 'newuser@example.cm');
      expect(newUser.displayName, 'Visiteur Test');
    });

    test(
      'GoogleAuthCollision captures collided email and credential details',
      () {
        const collision = GoogleAuthCollision(
          code: 'account-exists-with-different-credential',
          email: 'test@example.cm',
          message: 'Collision detected with existing account.',
        );
        expect(collision.code, 'account-exists-with-different-credential');
        expect(collision.email, 'test@example.cm');
        expect(collision.message, contains('Collision'));
      },
    );

    test('GoogleAuthFailure captures technical error message', () {
      const failure = GoogleAuthFailure(
        code: 'network-request-failed',
        message: 'Network timeout during Google OAuth.',
      );
      expect(failure.code, 'network-request-failed');
      expect(failure.message, 'Network timeout during Google OAuth.');
    });

    test(
      'FakeGoogleAuthGateway returns mock results and records signOut',
      () async {
        final gateway = FakeGoogleAuthGateway(
          mockResult: const GoogleAuthNewUser(),
        );

        final result = await gateway.signIn();
        expect(result, isA<GoogleAuthNewUser>());

        await gateway.signOut();
        expect(gateway.signOutCalled, isTrue);
      },
    );
  });
}
