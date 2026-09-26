import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/application/google_access_coordinator.dart';
import 'package:intellia237/features/auth/data/services/firebase_identity_port.dart';
import 'package:intellia237/features/auth/domain/google_access.dart';

import '../../support/fake_google_access.dart';

/// Orchestration Google, prouvée par l'ordre des appels (refonte Auth V2,
/// P0-2 et P0-3 de la revue de 7ea5cf0).
void main() {
  late FakeIdentityBackend backend;
  late FakeGoogleCredentialSource source;
  late FakeGoogleIdentityProbe probe;
  late GoogleAccessCoordinator coordinator;

  setUp(() {
    backend = FakeIdentityBackend();
    source = FakeGoogleCredentialSource(backend);
    probe = FakeGoogleIdentityProbe(backend);
    coordinator = GoogleAccessCoordinator(
      source: source,
      probe: probe,
      identity: FakeFirebaseIdentity(backend),
    );
  });

  group('begin', () {
    test(
      'a known Google account signs in only after the server said so',
      () async {
        backend.googleOwners['sub-a'] = 'uid-A';
        source.choose(fakeGoogleProof('sub-a'));

        final outcome = await coordinator.begin();

        expect(outcome, isA<GoogleAccessSignedIn>());
        expect((outcome as GoogleAccessSignedIn).uid, 'uid-A');
        expect(outcome.isNewIdentity, isFalse);
        expect(backend.calls, [
          'google.acquire',
          'server.probe',
          'firebase.signInWithGoogle',
        ]);
        expect(backend.createdByGoogle, isEmpty);
      },
    );

    test(
      'an unknown Google account creates NOTHING before the decision',
      () async {
        source.choose(fakeGoogleProof('sub-new', email: 'new@example.cm'));

        final outcome = await coordinator.begin();

        expect(outcome, isA<GoogleAccessNeedsDecision>());
        expect((outcome as GoogleAccessNeedsDecision).email, 'new@example.cm');
        // Acquisition ≠ connexion Firebase : aucune identité, aucune session.
        expect(backend.calls, ['google.acquire', 'server.probe']);
        expect(backend.createdByGoogle, isEmpty);
        expect(backend.currentUid, isNull);
        expect(coordinator.hasPendingProof, isTrue);
      },
    );

    test('a cancelled picker does nothing else', () async {
      source.script.add(const GoogleCredentialCancelled());
      expect(await coordinator.begin(), isA<GoogleAccessCancelled>());
      expect(backend.calls, ['google.acquire']);
    });

    test('a picker failure keeps its code, never a raw message', () async {
      source.script.add(const GoogleCredentialFailed('google-not-configured'));
      final outcome = await coordinator.begin();
      expect((outcome as GoogleAccessFailed).code, 'google-not-configured');
      expect(backend.calls, ['google.acquire']);
    });

    test('a probe outage never falls back to a Firebase sign-in', () async {
      probe.unavailable = true;
      source.choose(fakeGoogleProof('sub-a'));
      final outcome = await coordinator.begin();
      expect((outcome as GoogleAccessFailed).code, 'network-request-failed');
      expect(backend.calls, ['google.acquire', 'server.probe']);
      expect(backend.createdByGoogle, isEmpty);
    });

    test(
      'a race (known, then gone) deletes the fresh identity at once',
      () async {
        backend.googleOwners['sub-race'] = 'uid-gone';
        source.choose(fakeGoogleProof('sub-race'));
        // Le compte disparaît entre la sonde et la connexion.
        final identity = _RacingIdentity(backend);
        coordinator = GoogleAccessCoordinator(
          source: source,
          probe: probe,
          identity: identity,
        );

        final outcome = await coordinator.begin();

        expect(outcome, isA<GoogleAccessNeedsDecision>());
        expect(backend.deleted, hasLength(1));
        expect(backend.currentUid, isNull);
        expect(
          backend.calls,
          containsAllInOrder([
            'firebase.signInWithGoogle',
            'firebase.deleteCurrentUser',
            'firebase.signOut',
          ]),
        );
      },
    );
  });

  group('continueAsNewIdentity ("Non, continuer")', () {
    test('creates the identity only now, by explicit choice', () async {
      source.choose(fakeGoogleProof('sub-new'));
      await coordinator.begin();
      expect(backend.createdByGoogle, isEmpty);

      final outcome = await coordinator.continueAsNewIdentity();

      expect(outcome, isA<GoogleAccessSignedIn>());
      expect((outcome as GoogleAccessSignedIn).isNewIdentity, isTrue);
      expect(backend.createdByGoogle, [outcome.uid]);
      expect(coordinator.hasPendingProof, isFalse);
    });

    test(
      'an address already used by an account asks for recovery, creates nothing',
      () async {
        backend.emailsInUse.add('parent@example.cm');
        source.choose(fakeGoogleProof('sub-p', email: 'parent@example.cm'));
        await coordinator.begin();

        final outcome = await coordinator.continueAsNewIdentity();

        expect(outcome, isA<GoogleAccessRecoveryRequired>());
        expect(
          (outcome as GoogleAccessRecoveryRequired).email,
          'parent@example.cm',
        );
        expect(backend.createdByGoogle, isEmpty);
        expect(coordinator.hasPendingProof, isTrue);
      },
    );

    test('without a pending proof, nothing is created', () async {
      final outcome = await coordinator.continueAsNewIdentity();
      expect((outcome as GoogleAccessFailed).code, 'google-session-expired');
      expect(backend.calls, isEmpty);
    });
  });

  group('linkPendingTo ("Oui, retrouver mon compte")', () {
    Future<void> pending(String sub) async {
      source.choose(fakeGoogleProof(sub));
      await coordinator.begin();
    }

    test(
      'links Google to the proven existing UID, which never changes',
      () async {
        await pending('sub-g');
        backend.currentUid = 'uid-A'; // connexion réelle au compte existant
        backend.calls.clear();

        final outcome = await coordinator.linkPendingTo('uid-A');

        expect(outcome, isA<GoogleLinked>());
        expect((outcome as GoogleLinked).uid, 'uid-A');
        expect(backend.googleOwners['sub-g'], 'uid-A');
        expect(backend.currentUid, 'uid-A');
        expect(backend.calls, ['firebase.linkGoogle']);
        expect(backend.createdByGoogle, isEmpty);
        expect(coordinator.hasPendingProof, isFalse);
      },
    );

    test('refuses to link onto any session but the proven one', () async {
      await pending('sub-g');
      backend.currentUid = 'uid-B';
      backend.calls.clear();

      final outcome = await coordinator.linkPendingTo('uid-A');

      expect((outcome as GoogleLinkFailed).code, 'identity-mismatch');
      expect(backend.calls, isEmpty);
    });

    test(
      'Google already held by another account: stop, no merge, no copy',
      () async {
        await pending('sub-g');
        backend.googleOwners['sub-g'] = 'uid-B';
        backend.currentUid = 'uid-A';
        backend.calls.clear();

        final outcome = await coordinator.linkPendingTo('uid-A');

        expect(outcome, isA<GoogleLinkedElsewhere>());
        expect(backend.googleOwners['sub-g'], 'uid-B');
        expect(backend.googleOf['uid-A'], isNull);
        expect(backend.calls, ['firebase.linkGoogle', 'google.signOut']);
      },
    );

    test('the existing account already has another Google account', () async {
      await pending('sub-g');
      backend.currentUid = 'uid-A';
      backend.googleOf['uid-A'] = 'sub-other';
      backend.googleOwners['sub-other'] = 'uid-A';

      expect(
        await coordinator.linkPendingTo('uid-A'),
        isA<GoogleLinkProviderTaken>(),
      );
      expect(backend.googleOwners['sub-g'], isNull);
    });

    test(
      'an expired proof is renewed once, for the same Google account only',
      () async {
        await pending('sub-g');
        backend.currentUid = 'uid-A';
        backend.linkFailures.add('invalid-credential');
        backend.calls.clear();

        final outcome = await coordinator.linkPendingTo('uid-A');

        expect(outcome, isA<GoogleLinked>());
        expect(backend.calls, [
          'firebase.linkGoogle',
          'google.acquire',
          'firebase.linkGoogle',
        ]);
      },
    );

    test('a renewed proof for ANOTHER Google account is refused', () async {
      await pending('sub-g');
      backend.currentUid = 'uid-A';
      backend.linkFailures.add('invalid-credential');
      source.choose(fakeGoogleProof('sub-someone-else'));

      final outcome = await coordinator.linkPendingTo('uid-A');

      expect((outcome as GoogleLinkFailed).code, 'google-session-expired');
      expect(backend.googleOf['uid-A'], isNull);
    });
  });

  test('abandon forgets the proof and the chosen Google account', () async {
    source.choose(fakeGoogleProof('sub-g'));
    await coordinator.begin();
    await coordinator.abandon();
    expect(coordinator.hasPendingProof, isFalse);
    expect(source.signOuts, 1);
  });

  test('the proof never prints its token', () {
    final proof = fakeGoogleProof('sub-g');
    expect(proof.toString(), isNot(contains(proof.idToken)));
    expect(proof.subject, 'sub-g');
  });
}

/// Le compte connu disparaît entre la sonde et la connexion : Firebase crée
/// alors une identité neuve.
class _RacingIdentity extends FakeFirebaseIdentity {
  _RacingIdentity(super.backend);

  @override
  Future<FederatedSignIn> signInWithGoogle(GoogleProof proof) {
    backend.googleOwners.remove(proof.subject);
    return super.signInWithGoogle(proof);
  }
}
