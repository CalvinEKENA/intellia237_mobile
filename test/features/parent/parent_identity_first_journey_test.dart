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

  testWidgets('owner reproduction · the student\'s number, typed by the '
      'parent, never opens the student space silently', (tester) async {
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

    // Le numéro est prouvé ; rien n'est ouvert avant la réponse.
    await journey.waitUntil(
      () => find
          .byKey(const ValueKey('phone-student-confirmation'))
          .evaluate()
          .isNotEmpty,
    );
    expect(find.text('Ce numéro ouvre l’espace élève de Awa.'), findsOneWidget);
    expect(journey.location, AppRoutes.phoneAuth);
    expect(journey.auth.isAuthenticated, isFalse);

    await journey.tap('phone-student-is-parent');
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

  testWidgets('a verified-number session awaiting "who are you?" is closed '
      'when the person leaves', (tester) async {
    final backend = DeviceBackend();
    final journey = await SealJourney.start(tester, backend, traceSeal: false);
    await journey.tap('gateway-phone-auth');
    await journey.wait(const Duration(milliseconds: 400));
    await journey.typeKey('phone-number-field', DeviceBackend.studentPhone);
    await journey.tap('send-phone-code');
    await journey.waitUntil(
      () => find.byKey(const ValueKey('phone-otp-field')).evaluate().isNotEmpty,
    );
    await journey.wait(const Duration(milliseconds: 800));
    await journey.typeKey('phone-otp-field', '123456');
    await journey.tapWhenShown('phone-student-other-number');
    await journey.wait(const Duration(milliseconds: 400));

    expect(backend.currentUid, isNull, reason: 'session closed');
    expect(journey.auth.isAuthenticated, isFalse);
    expect(find.byKey(const ValueKey('phone-entry-stage')), findsOneWidget);
    await _dispose(journey);
  });

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
