import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/intellia_fonts.dart';
import '../../support/seal_device_journey.dart';

/// Parent : l'identité d'abord, le code de l'enfant ensuite.
///
/// Registre de décisions (refonte Auth V2) : l'entrée parent demandait le
/// code de l'enfant AVANT toute identité, puis un rôle choisi sur des cartes.
/// Elle est retirée. Ces parcours rejouent, sur les vrais écrans et la vraie
/// redirection, la reproduction du propriétaire (round 2) et les adresses
/// historiques qui peuvent subsister dans un lien.
void main() {
  setUpAll(loadIntelliaFonts);
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  testWidgets('owner reproduction · the student opens directly; the parent '
      'proves identity again before the migration offer', (tester) async {
    final backend = DeviceBackend();
    final journey = await SealJourney.start(tester, backend, traceSeal: false);

    // Aucun champ de code enfant, aucune carte de rôle avant l'identité.
    expect(find.byKey(const ValueKey('parent-entry-code-field')), findsNothing);
    expect(find.byKey(const ValueKey('pass-role-parent')), findsNothing);

    await journey.tap('gateway-phone-auth');
    await journey.wait(const Duration(milliseconds: 400));
    await journey.typeKey('phone-number-field', DeviceBackend.studentPhone);
    await journey.tap('send-phone-code');
    await journey.waitUntil(
      () => find.byKey(const ValueKey('phone-otp-field')).evaluate().isNotEmpty,
    );
    await journey.wait(const Duration(milliseconds: 800));
    await journey.typeKey('phone-otp-field', '123456');

    // Auth V3 : le numéro élève ouvre directement son espace.
    await journey.waitUntil(() => journey.location == AppRoutes.studentHome);
    expect(journey.auth.userId, 'student-uid');
    expect(
      find.byKey(const ValueKey('phone-student-confirmation')),
      findsNothing,
    );
    // Le parent repart d'une preuve distincte ; aucun accès parental local.
    // Le délai de renvoi du SMS reste respecté.
    backend.requestGate.advance(const Duration(seconds: 61));
    journey.router.go(AppRoutes.parentAccess);
    await journey.wait(const Duration(milliseconds: 400));
    await journey.tap('parent-proof-phone');
    await journey.wait(const Duration(milliseconds: 400));
    expect(journey.auth.isAuthenticated, isFalse);
    await journey.typeKey('phone-number-field', DeviceBackend.studentPhone);
    await journey.tap('send-phone-code');
    await journey.waitUntil(
      () => find.byKey(const ValueKey('phone-otp-field')).evaluate().isNotEmpty,
    );
    await journey.wait(const Duration(milliseconds: 800));
    await journey.typeKey('phone-otp-field', '123456');
    await journey.waitUntil(
      () => find
          .byKey(const ValueKey('family-phone-offer'))
          .evaluate()
          .isNotEmpty,
    );
    expect(journey.location, AppRoutes.phoneAuth);
    expect(journey.auth.isAuthenticated, isFalse);
    expect(journey.auth.role, isNot(AppRole.student));
    await _dispose(journey);
  });

  testWidgets(
    'a verified family identity awaiting a child choice is closed when the person leaves',
    (tester) async {
      final backend = DeviceBackend()
        ..parentLinks['parent-uid'] = {'student-uid', 'noah-uid'};
      final journey = await SealJourney.start(
        tester,
        backend,
        traceSeal: false,
      );
      await journey.tap('gateway-phone-auth');
      await journey.wait(const Duration(milliseconds: 400));
      await journey.typeKey('phone-number-field', DeviceBackend.parentPhone);
      await journey.tap('send-phone-code');
      await journey.waitUntil(
        () =>
            find.byKey(const ValueKey('phone-otp-field')).evaluate().isNotEmpty,
      );
      await journey.wait(const Duration(milliseconds: 800));
      await journey.typeKey('phone-otp-field', '123456');
      await journey.waitUntil(
        () => journey.location == AppRoutes.familySelection,
      );
      expect(journey.auth.familyEntryPending, isTrue);
      await journey.tapText('Utiliser un autre compte');
      await journey.waitUntil(() => journey.location == AppRoutes.authGateway);
      expect(backend.currentUid, isNull, reason: 'session closed');
      expect(journey.auth.isAuthenticated, isFalse);
      expect(journey.auth.familyEntryPending, isFalse);
      await _dispose(journey);
    },
  );

  for (final legacy in const [AppRoutes.parentEntry, AppRoutes.register]) {
    testWidgets('legacy $legacy link leads to the neutral gateway', (
      tester,
    ) async {
      final journey = await SealJourney.start(
        tester,
        DeviceBackend(),
        initialLocation: legacy,
        traceSeal: false,
      );
      await journey.wait(const Duration(milliseconds: 400));
      expect(journey.location, AppRoutes.authGateway);
      expect(find.byKey(const ValueKey('gateway-phone-auth')), findsOneWidget);
      await _dispose(journey);
    });
  }
}

Future<void> _dispose(SealJourney journey) async {
  await journey.tester.pumpWidget(const SizedBox.shrink());
  journey.container.dispose();
  await journey.tester.pump(const Duration(seconds: 9));
}
