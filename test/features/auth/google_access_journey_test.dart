import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/google_access.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_google_access.dart';
import '../../support/intellia_fonts.dart';
import '../../support/seal_device_journey.dart';

/// « Continuer avec Google » sur les VRAIS écrans, la vraie table de routes
/// et la vraie redirection ; Google, la sonde serveur et Firebase Auth sont
/// simulés sur un même backend (refonte Auth V2, P0-1 à P0-3 de la revue de
/// 7ea5cf0).
void main() {
  setUpAll(loadIntelliaFonts);
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  Future<SealJourney> start(
    WidgetTester tester,
    DeviceBackend backend, {
    String initialLocation = AppRoutes.authGateway,
  }) => SealJourney.start(
    tester,
    backend,
    initialLocation: initialLocation,
    traceSeal: false,
  );

  Future<void> tapGoogle(SealJourney journey) async {
    await journey.tap('gateway-google-auth');
    await journey.wait(const Duration(milliseconds: 600));
  }

  Future<void> answerYes(SealJourney journey) async {
    await journey.waitUntil(
      () => journey.location == AppRoutes.googleAccountQuestion,
    );
    await journey.tap('google-question-yes');
    await journey.waitUntil(() => journey.location == AppRoutes.accountLinking);
  }

  Future<void> recoverByPhone(SealJourney journey, String number) async {
    await journey.typeKey('recovery-phone-field', number);
    await journey.tap('recovery-send-code');
    await journey.waitUntil(() => _shown('recovery-otp-field'));
    await journey.typeKey('recovery-otp-field', '123456');
    await journey.tap('recovery-verify-code');
  }

  group('P0-1 · a known Google account signs in', () {
    testWidgets('existing parent: straight to the parent space, same UID', (
      tester,
    ) async {
      final backend = DeviceBackend();
      backend.identity.googleOwners['sub-claire'] = 'parent-uid';
      backend.identity.googleOf['parent-uid'] = 'sub-claire';
      final journey = await start(tester, backend);
      journey.google.choose(fakeGoogleProof('sub-claire'));

      await tapGoogle(journey);
      await journey.waitUntil(() => journey.location == AppRoutes.parentHome);

      expect(journey.auth.userId, 'parent-uid');
      expect(journey.auth.role, AppRole.parent);
      expect(backend.identity.createdByGoogle, isEmpty);
      await _dispose(journey);
    });
  });

  group('P0-2 · no identity before the decision', () {
    testWidgets('unknown Google account: question first, nothing created', (
      tester,
    ) async {
      final backend = DeviceBackend();
      final journey = await start(tester, backend);
      journey.google.choose(fakeGoogleProof('sub-new', email: 'new@ex.cm'));

      await tapGoogle(journey);
      await journey.waitUntil(
        () => journey.location == AppRoutes.googleAccountQuestion,
      );

      expect(find.text('Vous utilisez déjà INTELLIA237 ?'), findsOneWidget);
      expect(find.text('Compte Google choisi : new@ex.cm'), findsOneWidget);
      expect(backend.identity.createdByGoogle, isEmpty);
      expect(backend.currentUid, isNull);
      expect(backend.identity.calls, ['google.acquire', 'server.probe']);
      expect(journey.auth.hasFirebaseSession, isFalse);
      await _dispose(journey);
    });

    testWidgets('"Non, continuer": one identity, by choice, into Discovery — '
        'and Discovery again after a restart', (tester) async {
      final backend = DeviceBackend();
      final journey = await start(tester, backend);
      journey.google.choose(fakeGoogleProof('sub-new'));
      await tapGoogle(journey);
      await journey.waitUntil(
        () => journey.location == AppRoutes.googleAccountQuestion,
      );

      await journey.tap('google-question-no');
      await journey.waitUntil(
        () => journey.location == AppRoutes.googleDiscovery,
      );
      expect(backend.identity.createdByGoogle, hasLength(1));
      final uid = backend.identity.createdByGoogle.single;
      expect(journey.auth.status, AuthStatus.discovery);
      expect(journey.auth.userId, uid);

      // Aucune route privée n'est atteignable.
      for (final private in [
        AppRoutes.studentHome,
        AppRoutes.parentHome,
        AppRoutes.aiCompanion,
        AppRoutes.settings,
      ]) {
        journey.router.go(private);
        await journey.wait(const Duration(milliseconds: 300));
        expect(journey.location, AppRoutes.googleDiscovery, reason: private);
      }
      await _dispose(journey);

      // Redémarrage : même identité Firebase, toujours sans profil.
      final restarted = await start(
        tester,
        backend,
        initialLocation: AppRoutes.bootstrap,
      );
      await restarted.waitUntil(
        () => restarted.location == AppRoutes.googleDiscovery,
      );
      expect(restarted.auth.status, AuthStatus.discovery);
      expect(restarted.auth.userId, uid);
      expect(backend.identity.createdByGoogle, [uid]);
      await _dispose(restarted);
    });

    testWidgets('leaving Discovery signs out and forgets the Google account', (
      tester,
    ) async {
      final backend = DeviceBackend();
      final journey = await start(tester, backend);
      journey.google.choose(fakeGoogleProof('sub-new'));
      await tapGoogle(journey);
      await journey.tapWhenShown('google-question-no');
      await journey.waitUntil(
        () => journey.location == AppRoutes.googleDiscovery,
      );

      await journey.tap('discovery-exit-button');
      await journey.waitUntil(() => journey.location == AppRoutes.authGateway);
      expect(backend.currentUid, isNull);
      expect(journey.google.signOuts, greaterThanOrEqualTo(1));
      await _dispose(journey);
    });

    testWidgets('an address already used by an account: recovery by e-mail, '
        'never a second account', (tester) async {
      final backend = DeviceBackend();
      backend.identity.emailsInUse.add(DeviceBackend.teacherEmail);
      final journey = await start(tester, backend);
      journey.google.choose(
        fakeGoogleProof('sub-serge', email: DeviceBackend.teacherEmail),
      );
      await tapGoogle(journey);
      await journey.tapWhenShown('google-question-no');
      await journey.waitUntil(
        () => journey.location == AppRoutes.accountLinking,
      );
      expect(_shown('recovery-email-in-use'), isTrue);
      expect(backend.identity.createdByGoogle, isEmpty);

      await journey.typeKey(
        'recovery-password-field',
        DeviceBackend.teacherPassword,
      );
      await journey.tap('recovery-email-submit');
      await journey.waitUntil(() => journey.location == AppRoutes.teacherHome);
      expect(journey.auth.userId, 'teacher-uid');
      expect(backend.identity.googleOwners['sub-serge'], 'teacher-uid');
      await _dispose(journey);
    });
  });

  group('P0-3 · "Oui, retrouver mon compte": Google joins the existing UID', () {
    testWidgets('existing phone account + Google: UID preserved', (
      tester,
    ) async {
      final backend = DeviceBackend();
      final journey = await start(tester, backend);
      journey.google.choose(fakeGoogleProof('sub-claire'));
      await tapGoogle(journey);
      await answerYes(journey);

      await recoverByPhone(journey, DeviceBackend.parentPhone);
      await journey.waitUntil(() => journey.location == AppRoutes.parentHome);

      expect(journey.auth.userId, 'parent-uid');
      expect(backend.identity.googleOwners['sub-claire'], 'parent-uid');
      expect(backend.identity.createdByGoogle, isEmpty);
      expect(backend.identity.deleted, isEmpty);
      await _dispose(journey);
    });

    testWidgets('existing e-mail account + Google: a real sign-in, never a '
        'password created on another identity', (tester) async {
      final backend = DeviceBackend();
      final journey = await start(tester, backend);
      journey.google.choose(fakeGoogleProof('sub-serge'));
      await tapGoogle(journey);
      await answerYes(journey);

      await journey.tap('recovery-mode-email');
      await journey.typeKey('recovery-email-field', DeviceBackend.teacherEmail);
      await journey.typeKey(
        'recovery-password-field',
        DeviceBackend.teacherPassword,
      );
      await journey.tap('recovery-email-submit');
      await journey.waitUntil(() => journey.location == AppRoutes.teacherHome);

      expect(journey.auth.userId, 'teacher-uid');
      expect(backend.identity.googleOwners['sub-serge'], 'teacher-uid');
      expect(
        backend.identity.calls,
        containsAllInOrder([
          'google.acquire',
          'server.probe',
          'firebase.signInWithEmail',
          'firebase.linkGoogle',
        ]),
      );
      expect(
        backend.identity.calls,
        isNot(contains('firebase.signInWithGoogle')),
      );
      await _dispose(journey);
    });

    testWidgets(
      'Google already linked elsewhere: stop, human message, no merge',
      (tester) async {
        final backend = DeviceBackend();
        final journey = await start(tester, backend);
        journey.google.choose(fakeGoogleProof('sub-taken'));
        await tapGoogle(journey);
        await answerYes(journey);
        // Entre-temps, ce compte Google a été rattaché à un autre compte.
        backend.identity.googleOwners['sub-taken'] = 'someone-else';

        await recoverByPhone(journey, DeviceBackend.parentPhone);
        await journey.waitUntil(() => _shown('recovery-stop-linkedElsewhere'));

        expect(
          find.text(
            'Ce compte Google est déjà associé à un autre compte INTELLIA237.',
          ),
          findsOneWidget,
        );
        expect(backend.identity.googleOwners['sub-taken'], 'someone-else');
        expect(backend.identity.googleOf['parent-uid'], isNull);
        expect(journey.auth.isAuthenticated, isFalse);

        await journey.tap('recovery-open-without-google');
        await journey.waitUntil(() => journey.location == AppRoutes.parentHome);
        expect(journey.auth.userId, 'parent-uid');
        await _dispose(journey);
      },
    );

    testWidgets('cancelling after proving the account closes that session', (
      tester,
    ) async {
      final backend = DeviceBackend();
      final journey = await start(tester, backend);
      journey.google.choose(fakeGoogleProof('sub-taken'));
      await tapGoogle(journey);
      await answerYes(journey);
      backend.identity.googleOwners['sub-taken'] = 'someone-else';
      await recoverByPhone(journey, DeviceBackend.parentPhone);
      await journey.waitUntil(() => _shown('recovery-stop-linkedElsewhere'));

      await journey.tap('recovery-stop-cancel');
      await journey.waitUntil(() => journey.location == AppRoutes.authGateway);
      expect(backend.currentUid, isNull);
      expect(journey.auth.hasFirebaseSession, isFalse);
      await _dispose(journey);
    });

    testWidgets('a number with no account: the fresh identity is deleted', (
      tester,
    ) async {
      final backend = DeviceBackend();
      final journey = await start(tester, backend);
      journey.google.choose(fakeGoogleProof('sub-g'));
      await tapGoogle(journey);
      await answerYes(journey);

      await recoverByPhone(journey, DeviceBackend.newPhone);
      await journey.waitUntil(() => _shown('recovery-message'));

      expect(
        find.textContaining('Aucun compte INTELLIA237 n’utilise ce numéro'),
        findsOneWidget,
      );
      expect(backend.identity.deleted, hasLength(1));
      expect(backend.currentUid, isNull);
      expect(backend.identity.googleOwners['sub-g'], isNull);
      await _dispose(journey);
    });

    testWidgets('bad number, bad code, bad password: human messages only', (
      tester,
    ) async {
      final backend = DeviceBackend()..rejectedCodes.add('000000');
      final journey = await start(tester, backend);
      journey.google.choose(fakeGoogleProof('sub-g'));
      await tapGoogle(journey);
      await answerYes(journey);

      await journey.typeKey('recovery-phone-field', '12345');
      await journey.tap('recovery-send-code');
      await journey.waitUntil(() => _shown('recovery-error'));
      expect(
        find.textContaining('pas un numéro mobile camerounais valide'),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey('recovery-phone-field')),
        '',
      );
      await journey.typeKey('recovery-phone-field', DeviceBackend.parentPhone);
      await journey.tap('recovery-send-code');
      await journey.waitUntil(() => _shown('recovery-otp-field'));
      await journey.typeKey('recovery-otp-field', '000000');
      await journey.tap('recovery-verify-code');
      await journey.waitUntil(
        () =>
            find.textContaining('Ce code est incorrect').evaluate().isNotEmpty,
      );
      expect(journey.auth.isAuthenticated, isFalse);

      await journey.tap('recovery-change-number');
      await journey.tap('recovery-mode-email');
      await journey.typeKey('recovery-email-field', DeviceBackend.teacherEmail);
      await journey.typeKey('recovery-password-field', 'mauvais');
      await journey.tap('recovery-email-submit');
      await journey.waitUntil(
        () => find
            .text('Adresse e-mail ou mot de passe incorrect.')
            .evaluate()
            .isNotEmpty,
      );
      expect(backend.identity.googleOf, isEmpty);
      expect(find.textContaining('Exception'), findsNothing);
      await _dispose(journey);
    });

    testWidgets('network failure while linking: explained, retry possible', (
      tester,
    ) async {
      final backend = DeviceBackend();
      final journey = await start(tester, backend);
      journey.google.choose(fakeGoogleProof('sub-g'));
      await tapGoogle(journey);
      await answerYes(journey);
      backend.identity.linkFailures.add('network-request-failed');

      await recoverByPhone(journey, DeviceBackend.parentPhone);
      await journey.waitUntil(() => _shown('recovery-stop-failed'));
      expect(
        find.text(
          'Connexion Internet instable. Vérifiez votre réseau, puis réessayez.',
        ),
        findsOneWidget,
      );
      expect(backend.identity.googleOf['parent-uid'], isNull);
      await _dispose(journey);
    });
  });

  group('gateway outcomes', () {
    testWidgets('a cancelled Google picker shows nothing and stays put', (
      tester,
    ) async {
      final backend = DeviceBackend();
      final journey = await start(tester, backend);
      journey.google.script.add(const GoogleCredentialCancelled());
      await tapGoogle(journey);
      expect(journey.location, AppRoutes.authGateway);
      expect(_shown('gateway-google-error'), isFalse);
      await _dispose(journey);
    });

    testWidgets('an unavailable server or a missing configuration is explained', (
      tester,
    ) async {
      final backend = DeviceBackend();
      backend.probe.unavailable = true;
      final journey = await start(tester, backend);
      journey.google.choose(fakeGoogleProof('sub-g'));
      await tapGoogle(journey);
      expect(_shown('gateway-google-error'), isTrue);
      expect(
        find.text(
          'Connexion Internet instable. Vérifiez votre réseau, puis réessayez.',
        ),
        findsOneWidget,
      );

      journey.google.script
        ..clear()
        ..add(const GoogleCredentialFailed('google-not-configured'));
      await tapGoogle(journey);
      expect(
        find.textContaining('La connexion Google n’est pas encore disponible'),
        findsOneWidget,
      );
      expect(backend.identity.createdByGoogle, isEmpty);
      await _dispose(journey);
    });
  });

  testWidgets('session lost elsewhere: the app returns to the gateway', (
    tester,
  ) async {
    final backend = DeviceBackend();
    final journey = await SealJourney.start(
      tester,
      backend,
      signedInPhone: DeviceBackend.parentPhone,
      initialLocation: AppRoutes.parentHome,
      traceSeal: false,
    );
    await journey.waitUntil(() => journey.location == AppRoutes.parentHome);

    // Jeton révoqué, compte supprimé ou déconnexion depuis un autre écran.
    backend.currentUid = null;
    await journey.waitUntil(() => journey.location == AppRoutes.authGateway);
    expect(journey.auth.status, AuthStatus.unauthenticated);
    await _dispose(journey);
  });
}

bool _shown(String key) => find.byKey(ValueKey(key)).evaluate().isNotEmpty;

Future<void> _dispose(SealJourney journey) async {
  await journey.tester.pumpWidget(const SizedBox.shrink());
  journey.container.dispose();
  await journey.tester.pump(const Duration(seconds: 9));
}
