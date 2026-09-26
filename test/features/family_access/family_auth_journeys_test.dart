import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/parent/application/pending_child_link.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/intellia_fonts.dart';
import '../../support/seal_device_journey.dart';

/// Parcours famille sur les VRAIS écrans, la vraie table de routes et la vraie
/// redirection de production (harnais « appareil ») ; seuls les services
/// distants sont simulés, comme le serveur les implémente.
///
/// Le premier test est la régression exigée par le propriétaire : un seul
/// téléphone dans la famille, d'abord utilisé pour l'accès de l'élève.
void main() {
  setUpAll(loadIntelliaFonts);
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  testWidgets('OWNER · OLD behaves as student; NEW offers the migration, opens '
      'the parent space with the child linked, keeps the student profile, and '
      'the student access code works', (tester) async {
    final backend = DeviceBackend();
    final journey = await SealJourney.start(
      tester,
      backend,
      realParentHome: true,
      traceSeal: false,
    );
    final studentBefore = backend.accounts['student-uid'];

    // OLD — le numéro de la famille ouvre l'espace élève : l'élève confirme
    // que c'est bien lui (accès neutre, aucun rôle demandé avant).
    await journey.tap('gateway-phone-auth');
    await journey.wait(const Duration(milliseconds: 400));
    await _verifyPhone(journey, DeviceBackend.studentPhone);
    await journey.confirmStudentPhone();
    await journey.waitUntil(() => journey.location == AppRoutes.studentHome);
    expect(journey.auth.role, AppRole.student);
    expect(journey.auth.userId, 'student-uid');
    await _signOut(journey);
    // La famille repasse par l'entrée parent une minute plus tard : un même
    // numéro ne peut pas redemander de SMS plus tôt.
    backend.requestGate.advance(const Duration(seconds: 61));

    // NEW — même numéro, vérifié d'abord ; la personne dit ensuite être le
    // parent de l'élève. Aucun code enfant n'est demandé avant l'identité.
    await journey.tap('gateway-phone-auth');
    await journey.wait(const Duration(milliseconds: 400));
    await _verifyPhone(journey, DeviceBackend.studentPhone);
    await journey.tapWhenShown('phone-student-is-parent');
    await journey.waitUntil(() => _shown('family-phone-offer'));
    expect(
      find.text(
        'Ce numéro est actuellement utilisé pour l’accès d’un élève. '
        'Souhaitez-vous l’utiliser comme numéro du parent ? L’élève '
        'conservera son profil et utilisera désormais son code d’accès '
        'INTELLIA.',
      ),
      findsOneWidget,
    );
    // Jamais en silence : rien n'est ouvert ni transféré avant la réponse.
    expect(journey.location, AppRoutes.phoneAuth);
    expect(journey.auth.isAuthenticated, isFalse);
    expect(
      backend.uidsByPhone['+237${DeviceBackend.studentPhone}'],
      'student-uid',
    );

    await journey.tap('family-phone-offer-confirm');
    await journey.waitUntil(() => _shown('family-phone-migrated'));
    final code = tester
        .widget<SelectableText>(
          find.byKey(const ValueKey('student-access-code-value')),
        )
        .data!;
    expect(code, matches(RegExp(r'^[A-Z2-9]{4}-[A-Z2-9]{4}-[A-Z2-9]{4}$')));
    expect(find.text('Code d’accès INTELLIA de Awa'), findsOneWidget);
    // Le numéro appartient désormais à une identité parent distincte.
    expect(
      backend.uidsByPhone['+237${DeviceBackend.studentPhone}'],
      'parent-of-student-uid',
    );
    expect(journey.auth.isAuthenticated, isFalse, reason: 'code shown first');

    await journey.tap('student-access-code-continue');
    await journey.waitUntil(
      () => journey.location == AppRoutes.parentRegistration,
    );
    await _registerParent(journey);
    await journey.waitUntil(() => journey.location == AppRoutes.parentHome);
    await journey.wait(const Duration(milliseconds: 1200));

    // L'espace parent s'ouvre sous l'identité du parent, enfant lié.
    expect(journey.auth.role, AppRole.parent);
    expect(journey.auth.userId, 'parent-of-student-uid');
    expect(backend.parentLinks['parent-of-student-uid'], {'student-uid'});
    expect(find.text('Awa'), findsWidgets);
    // Le profil de l'élève est intact : même UID, même compte.
    expect(backend.accounts['student-uid'], same(studentBefore));
    expect(journey.container.read(pendingChildLinkProvider).code, isNull);

    // Le code d'accès ouvre le MÊME élève, sans SMS.
    await _signOut(journey);
    await _signInWithCode(journey, code);
    expect(journey.auth.role, AppRole.student);
    expect(journey.auth.userId, 'student-uid');

    // Et le numéro de la famille ouvre désormais l'espace parent.
    await _signOut(journey);
    backend.requestGate.advance(const Duration(seconds: 61));
    await journey.tap('gateway-phone-auth');
    await journey.wait(const Duration(milliseconds: 400));
    await _verifyPhone(journey, DeviceBackend.studentPhone);
    await journey.waitUntil(() => journey.location == AppRoutes.parentHome);
    expect(journey.auth.userId, 'parent-of-student-uid');
    await _dispose(journey);
  });

  testWidgets('F · failure halfway: the phone left the student but the parent '
      'identity could not be created; the student code is shown at once, the '
      'number is verified again and the parent space opens with the child', (
    tester,
  ) async {
    final backend = DeviceBackend()..failMigrationAfterDetach = true;
    final journey = await SealJourney.start(
      tester,
      backend,
      realParentHome: true,
      traceSeal: false,
    );
    await journey.tap('gateway-phone-auth');
    await journey.wait(const Duration(milliseconds: 400));
    await _verifyPhone(journey, DeviceBackend.studentPhone);
    await journey.tapWhenShown('phone-student-is-parent');
    await journey.waitUntil(() => _shown('family-phone-offer'));
    await journey.tap('family-phone-offer-confirm');
    await journey.waitUntil(() => _shown('family-phone-verify-to-finish'));

    // L'élève n'est jamais sans accès : son code est montré tout de suite.
    final code = tester
        .widget<SelectableText>(
          find.byKey(const ValueKey('student-access-code-value')),
        )
        .data!;
    expect(backend.accessCodes.values, contains('student-uid'));
    expect(journey.auth.isAuthenticated, isFalse);

    await journey.tap('student-access-code-continue');
    await journey.waitUntil(() => _shown('phone-number-field'));
    // Nouvelle vérification du numéro, une minute plus tard.
    backend.requestGate.advance(const Duration(seconds: 61));
    backend.failMigrationAfterDetach = false;
    await _verifyPhone(journey, DeviceBackend.studentPhone);
    await journey.waitUntil(
      () => journey.location == AppRoutes.parentRegistration,
    );
    final parentUid = journey.auth.userId!;
    expect(parentUid, isNot('student-uid'));
    expect(backend.parentLinks[parentUid], {'student-uid'});
    await _registerParent(journey);
    await journey.waitUntil(() => journey.location == AppRoutes.parentHome);

    // Et le code montré pendant la panne ouvre toujours l'élève.
    await _signOut(journey);
    await _signInWithCode(journey, code);
    expect(journey.auth.userId, 'student-uid');
    await _dispose(journey);
  });

  testWidgets(
    'A · new parent, one child: phone, OTP, "Je suis parent", '
    'parent account, parent home, "Rattacher mon enfant", child code, child '
    'visible, child profile — never a child code before the parent identity',
    (tester) async {
      final backend = DeviceBackend();
      final journey = await SealJourney.start(
        tester,
        backend,
        realParentHome: true,
        traceSeal: false,
      );
      await journey.tap('gateway-phone-auth');
      await journey.wait(const Duration(milliseconds: 400));
      expect(find.byKey(const ValueKey('parent-add-child-code')), findsNothing);
      await _verifyPhone(journey, DeviceBackend.newPhone);
      await journey.waitUntil(
        () => journey.location == AppRoutes.accountWelcome,
      );
      await journey.tap('welcome-parent');
      await journey.waitUntil(
        () => journey.location == AppRoutes.parentRegistration,
      );
      await _registerParent(journey);
      await journey.waitUntil(() => journey.location == AppRoutes.parentHome);
      await journey.wait(const Duration(milliseconds: 1200));

      final parentUid = journey.auth.userId!;
      expect(journey.auth.role, AppRole.parent);
      expect(backend.parentLinks[parentUid] ?? const <String>{}, isEmpty);

      // Identité parent établie : « Rattacher mon enfant » avec son code.
      await journey.tapText('Enfants');
      await journey.wait(const Duration(milliseconds: 600));
      await journey.tap('parent-add-child');
      await journey.wait(const Duration(milliseconds: 400));
      await journey.typeKey('parent-add-child-code', 'K7MP2QXA');
      await journey.tap('parent-add-child-submit');
      await journey.waitUntil(
        () =>
            (backend.parentLinks[parentUid]?.contains('student-uid') ??
                false) &&
            !_shown('parent-add-child-submit'),
      );
      await journey.wait(const Duration(milliseconds: 600));
      expect(backend.parentLinks[parentUid], {'student-uid'});
      await _scrollToInChildren(journey, 'parent-child-card-student-uid');
      expect(
        find.byKey(const ValueKey('parent-child-card-student-uid')),
        findsOneWidget,
      );
      await journey.tap('parent-child-profile-student-uid');
      await journey.waitUntil(
        () => journey.location == AppRoutes.parentChildProfile('student-uid'),
      );
      await journey.wait(const Duration(milliseconds: 500));
      expect(find.text('MODE PARENT — PROFIL DE AWA'), findsOneWidget);
      expect(journey.auth.userId, parentUid);
      await _dispose(journey);
    },
  );

  testWidgets('B · same parent adds child B then child C from the parent '
      'home: each appears at once, no sign-out, no new OTP', (tester) async {
    final backend = DeviceBackend()
      ..createStudentWithoutPhone('noah-uid', 'Noah')
      ..createStudentWithoutPhone('chloe-uid', 'Chloé')
      ..parentLinks['parent-uid'] = {'student-uid'};
    backend.linkCodes.addAll({'P3RT9WXY': 'noah-uid', 'H4NR8TBZ': 'chloe-uid'});
    final journey = await SealJourney.start(
      tester,
      backend,
      realParentHome: true,
      traceSeal: false,
      signedInPhone: DeviceBackend.parentPhone,
      initialLocation: AppRoutes.parentHome,
    );
    await journey.waitUntil(() => journey.location == AppRoutes.parentHome);
    await journey.tapText('Enfants');
    await journey.wait(const Duration(milliseconds: 600));

    for (final (code, uid) in const [
      ('P3RT9WXY', 'noah-uid'),
      ('H4NR8TBZ', 'chloe-uid'),
    ]) {
      await _scrollChildrenToTop(journey);
      await journey.tap('parent-add-child');
      await journey.wait(const Duration(milliseconds: 400));
      await journey.typeKey('parent-add-child-code', code);
      await journey.tap('parent-add-child-submit');
      await journey.waitUntil(
        () =>
            (backend.parentLinks['parent-uid']?.contains(uid) ?? false) &&
            !_shown('parent-add-child-submit'),
      );
      await journey.wait(const Duration(milliseconds: 600));
      // Le nouvel enfant apparaît aussitôt, sans rafraîchissement manuel.
      await _scrollToInChildren(journey, 'parent-child-card-$uid');
      expect(find.byKey(ValueKey('parent-child-card-$uid')), findsOneWidget);
    }
    await _scrollChildrenToTop(journey);
    for (final uid in ['student-uid', 'noah-uid', 'chloe-uid']) {
      await _scrollToInChildren(journey, 'parent-child-card-$uid');
      expect(find.byKey(ValueKey('parent-child-card-$uid')), findsOneWidget);
    }
    expect(journey.auth.userId, 'parent-uid');
    expect(journey.location, AppRoutes.parentHome);
    await _dispose(journey);
  });

  testWidgets('C · existing parent: phone, OTP, parent home with existing '
      'children', (tester) async {
    final backend = DeviceBackend()
      ..createStudentWithoutPhone('noah-uid', 'Noah')
      ..parentLinks['parent-uid'] = {'student-uid', 'noah-uid'};
    final journey = await SealJourney.start(
      tester,
      backend,
      realParentHome: true,
      traceSeal: false,
    );
    await journey.tap('gateway-phone-auth');
    await journey.wait(const Duration(milliseconds: 400));
    await _verifyPhone(journey, DeviceBackend.parentPhone);
    await journey.waitUntil(() => journey.location == AppRoutes.parentHome);
    await journey.wait(const Duration(milliseconds: 1200));
    await journey.tapText('Enfants');
    await journey.wait(const Duration(milliseconds: 600));
    for (final uid in ['student-uid', 'noah-uid']) {
      await _scrollToInChildren(journey, 'parent-child-card-$uid');
      expect(find.byKey(ValueKey('parent-child-card-$uid')), findsOneWidget);
    }
    await _dispose(journey);
  });

  testWidgets('B/G · a parent with two children in two schools: one card per '
      'child under its school; profiles open child by child in parent mode', (
    tester,
  ) async {
    final backend = DeviceBackend()
      ..createStudentWithoutPhone('noah-uid', 'Noah')
      ..schoolOf.addAll({'student-uid': 'Lycée A', 'noah-uid': 'Collège B'})
      ..parentLinks['parent-uid'] = {'student-uid', 'noah-uid'};
    backend.issueAccessCode('noah-uid');
    final journey = await SealJourney.start(
      tester,
      backend,
      realParentHome: true,
      traceSeal: false,
      signedInPhone: DeviceBackend.parentPhone,
      initialLocation: AppRoutes.parentHome,
    );
    await journey.waitUntil(() => journey.location == AppRoutes.parentHome);
    await journey.tapText('Enfants');
    await journey.wait(const Duration(milliseconds: 600));

    // Rangés par école : « Collège B » (Noah) puis « Lycée A » (Awa).
    for (final key in [
      'parent-children-school-Collège B',
      'parent-child-card-noah-uid',
      'parent-child-access-noah-uid',
    ]) {
      await _scrollToInChildren(journey, key);
      expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
    }
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('parent-child-access-noah-uid')),
          )
          .data,
      'Se connecte avec son code d’accès INTELLIA',
    );
    for (final key in [
      'parent-children-school-Lycée A',
      'parent-child-card-student-uid',
      'parent-child-access-student-uid',
    ]) {
      await _scrollToInChildren(journey, key);
      expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
    }
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('parent-child-access-student-uid')),
          )
          .data,
      'Connecté avec son propre accès INTELLIA',
    );
    // Aucune « école du parent » : chaque enfant garde la sienne.
    expect(find.textContaining('votre établissement'), findsNothing);

    await _scrollToInChildren(journey, 'parent-child-profile-student-uid');
    await journey.tap('parent-child-profile-student-uid');
    await journey.waitUntil(
      () => journey.location == AppRoutes.parentChildProfile('student-uid'),
    );
    await journey.wait(const Duration(milliseconds: 500));
    expect(find.text('MODE PARENT — PROFIL DE AWA'), findsOneWidget);
    expect(journey.auth.userId, 'parent-uid', reason: 'no impersonation');

    journey.router.pop();
    await journey.wait(const Duration(milliseconds: 600));
    await _scrollChildrenToTop(journey);
    await _scrollToInChildren(journey, 'parent-child-profile-noah-uid');
    await journey.tap('parent-child-profile-noah-uid');
    await journey.waitUntil(
      () => journey.router.state.pathParameters['studentId'] == 'noah-uid',
    );
    await journey.wait(const Duration(milliseconds: 500));
    expect(find.text('MODE PARENT — PROFIL DE NOAH'), findsOneWidget);
    expect(find.text('MODE PARENT — PROFIL DE AWA'), findsNothing);
    expect(journey.auth.userId, 'parent-uid');
    await _dispose(journey);
  });

  testWidgets('D · a student without a phone enters with an access code', (
    tester,
  ) async {
    final backend = DeviceBackend()
      ..createStudentWithoutPhone('noah-uid', 'Noah');
    final code = backend.issueAccessCode('noah-uid');
    final journey = await SealJourney.start(tester, backend, traceSeal: false);

    await _signInWithCode(journey, 'ZZZZ-ZZZZ-ZZZZ', expectSuccess: false);
    expect(
      find.byKey(const ValueKey('student-access-code-error')),
      findsOneWidget,
    );
    expect(journey.auth.isAuthenticated, isFalse);
    await tester.enterText(
      find.byKey(const ValueKey('student-access-code-field')),
      '',
    );
    await journey.typeKey('student-access-code-field', code);
    await journey.tap('student-access-code-submit');
    await journey.waitUntil(() => journey.location == AppRoutes.studentHome);
    expect(journey.auth.userId, 'noah-uid');
    expect(journey.auth.role, AppRole.student);
    await _dispose(journey);
  });

  testWidgets('E/I · rotation: the parent generates, then replaces the code; '
      'the old code stops, the new one opens the child; signing out one space '
      'never closes the other access', (tester) async {
    final backend = DeviceBackend()
      ..createStudentWithoutPhone('noah-uid', 'Noah')
      ..parentLinks['parent-uid'] = {'noah-uid'};
    final journey = await SealJourney.start(
      tester,
      backend,
      realParentHome: true,
      traceSeal: false,
      signedInPhone: DeviceBackend.parentPhone,
      initialLocation: AppRoutes.parentHome,
    );
    await journey.waitUntil(() => journey.location == AppRoutes.parentHome);
    await journey.tapText('Enfants');
    await journey.wait(const Duration(milliseconds: 600));

    Future<String> generate({required bool replacing}) async {
      await _scrollToInChildren(journey, 'parent-child-access-code-noah-uid');
      await journey.tap('parent-child-access-code-noah-uid');
      await journey.wait(const Duration(milliseconds: 600));
      await journey.tap('parent-student-access-code-generate');
      if (replacing) {
        await journey.wait(const Duration(milliseconds: 400));
        await journey.tap('student-access-code-replace-confirm');
      }
      await journey.waitUntil(
        () => _shown('parent-student-access-code-issued'),
      );
      final code = tester
          .widget<SelectableText>(
            find.byKey(const ValueKey('student-access-code-value')),
          )
          .data!;
      await journey.tap('student-access-code-continue');
      await journey.wait(const Duration(milliseconds: 600));
      return code;
    }

    final first = await generate(replacing: false);
    final second = await generate(replacing: true);
    expect(second, isNot(first));
    expect(
      backend.accessCodes.values.where((uid) => uid == 'noah-uid'),
      hasLength(1),
    );

    // Déconnexion du parent : l'accès de l'enfant n'en dépend pas.
    await _signOut(journey);
    await _signInWithCode(journey, first, expectSuccess: false);
    expect(journey.auth.isAuthenticated, isFalse);
    journey.router.go(AppRoutes.authGateway);
    await journey.wait(const Duration(milliseconds: 600));
    await _signInWithCode(journey, second);
    expect(journey.auth.userId, 'noah-uid');

    // Déconnexion de l'enfant : le parent retrouve son espace et le lien.
    await _signOut(journey);
    await journey.tap('gateway-phone-auth');
    await journey.wait(const Duration(milliseconds: 400));
    await _verifyPhone(journey, DeviceBackend.parentPhone);
    await journey.waitUntil(() => journey.location == AppRoutes.parentHome);
    expect(backend.parentLinks['parent-uid'], {'noah-uid'});
    await _dispose(journey);
  });

  testWidgets('NEW FAMILY · the child has no phone and no account: the parent '
      'opens the access, the card waits for the first sign-in, the child '
      'enters with the code and completes their own school profile', (
    tester,
  ) async {
    final backend = DeviceBackend();
    final journey = await SealJourney.start(
      tester,
      backend,
      realParentHome: true,
      traceSeal: false,
      signedInPhone: DeviceBackend.parentPhone,
      initialLocation: AppRoutes.parentHome,
    );
    await journey.waitUntil(() => journey.location == AppRoutes.parentHome);
    await journey.tapText('Enfants');
    await journey.wait(const Duration(milliseconds: 600));

    await journey.tap('parent-add-child');
    await journey.wait(const Duration(milliseconds: 400));
    await journey.tap('parent-add-child-no-account');
    await journey.wait(const Duration(milliseconds: 400));
    await journey.typeKey('parent-add-child-first-name', 'Noah');
    await journey.tap('parent-add-child-create-access');
    await journey.waitUntil(() => _shown('parent-add-child-created'));
    final code = tester
        .widget<SelectableText>(
          find.byKey(const ValueKey('student-access-code-value')),
        )
        .data!;
    final childUid = backend.parentLinks['parent-uid']!.single;
    // Aucun téléphone n'est attaché à l'enfant, nulle part.
    expect(backend.uidsByPhone.containsValue(childUid), isFalse);
    await journey.tap('student-access-code-continue');
    await journey.wait(const Duration(milliseconds: 800));
    await _scrollToInChildren(journey, 'parent-child-pending-$childUid');
    expect(find.text('En attente de sa première connexion'), findsOneWidget);

    // Première connexion de l'enfant, sans SMS : son inscription scolaire.
    await _signOut(journey);
    await _signInWithCode(journey, code, expectRegistration: true);
    expect(journey.auth.userId, childUid);
    expect(journey.location, AppRoutes.studentRegistration);
    await _dispose(journey);
  });

  testWidgets('H · parent A cannot open a student linked only to parent B', (
    tester,
  ) async {
    final backend = DeviceBackend()
      ..createStudentWithoutPhone('noah-uid', 'Noah')
      ..parentLinks['someone-else'] = {'noah-uid'}
      ..parentLinks['parent-uid'] = {'student-uid'};
    final journey = await SealJourney.start(
      tester,
      backend,
      realParentHome: true,
      traceSeal: false,
      signedInPhone: DeviceBackend.parentPhone,
      initialLocation: AppRoutes.parentHome,
    );
    await journey.waitUntil(() => journey.location == AppRoutes.parentHome);

    journey.router.push(AppRoutes.parentChildProfile('noah-uid'));
    await journey.wait(const Duration(milliseconds: 800));
    expect(
      find.byKey(const ValueKey('child-profile-not-found')),
      findsOneWidget,
    );
    expect(find.textContaining('NOAH'), findsNothing);
    expect(find.text('Noah'), findsNothing);
    expect(journey.auth.userId, 'parent-uid');

    // L'accès de l'élève d'un autre parent ne peut pas être réémis.
    backend.networkDelays = false;
    await expectLater(
      DeviceFamilyAccess(backend).issueStudentAccessCode('noah-uid'),
      throwsA(anything),
    );
    await _dispose(journey);
  });
}

bool _shown(String key) => find.byKey(ValueKey(key)).evaluate().isNotEmpty;

Future<void> _scrollChildrenToTop(SealJourney journey) async {
  await journey.tester.drag(
    find.byKey(const ValueKey('parent-children-list')),
    const Offset(0, 6000),
  );
  await journey.wait(const Duration(milliseconds: 400));
}

/// La liste des enfants est construite à la demande : on défile comme un
/// doigt jusqu'à l'élément voulu.
Future<void> _scrollToInChildren(SealJourney journey, String key) async {
  await journey.tester.scrollUntilVisible(
    find.byKey(ValueKey(key)),
    250,
    scrollable: find
        .descendant(
          of: find.byKey(const ValueKey('parent-children-list')),
          matching: find.byType(Scrollable),
        )
        .first,
    maxScrolls: 60,
  );
  await journey.wait(const Duration(milliseconds: 200));
}

bool _otpShown() => _shown('phone-otp-field');

Future<void> _verifyPhone(SealJourney journey, String number) async {
  await journey.typeKey('phone-number-field', number);
  await journey.tap('send-phone-code');
  await journey.waitUntil(_otpShown);
  await journey.wait(const Duration(milliseconds: 800));
  await journey.typeKey('phone-otp-field', '123456');
}

Future<void> _signOut(SealJourney journey) async {
  await journey.container.read(authControllerProvider.notifier).signOut();
  await journey.waitUntil(() => journey.location == AppRoutes.authGateway);
  await journey.wait(const Duration(milliseconds: 400));
}

Future<void> _signInWithCode(
  SealJourney journey,
  String code, {
  bool expectSuccess = true,
  bool expectRegistration = false,
}) async {
  if (journey.location == AppRoutes.authGateway) {
    await journey.tap('gateway-student-access-code');
    await journey.waitUntil(
      () => journey.location == AppRoutes.studentAccessCode,
    );
    await journey.wait(const Duration(milliseconds: 400));
  }
  await journey.type(
    find.byKey(const ValueKey('student-access-code-field')),
    code,
    perKey: const Duration(milliseconds: 60),
  );
  await journey.tap('student-access-code-submit');
  if (expectRegistration) {
    await journey.waitUntil(
      () => journey.location == AppRoutes.studentRegistration,
    );
  } else if (expectSuccess) {
    await journey.waitUntil(() => journey.location == AppRoutes.studentHome);
  } else {
    await journey.waitUntil(() => _shown('student-access-code-error'));
  }
}

Future<void> _registerParent(SealJourney journey) async {
  final tester = journey.tester;
  final fields = find.byType(TextFormField);
  await journey.type(
    fields.at(0),
    'Calvin',
    perKey: const Duration(milliseconds: 60),
  );
  await journey.type(
    fields.at(1),
    'Ekena',
    perKey: const Duration(milliseconds: 60),
  );
  await journey.tap('registration-primary-action');
  await journey.wait(const Duration(milliseconds: 700));
  await journey.tap('registration-primary-action');
  await journey.wait(const Duration(milliseconds: 700));
  await journey.tapText('J’accepte les conditions d’utilisation.');
  await journey.tapText('J’accepte la politique de confidentialité.');
  await journey.tap('registration-primary-action');
  expect(tester.takeException(), isNull);
}

Future<void> _dispose(SealJourney journey) async {
  await journey.tester.pumpWidget(const SizedBox.shrink());
  journey.container.dispose();
  await journey.tester.pump(const Duration(seconds: 9));
}
