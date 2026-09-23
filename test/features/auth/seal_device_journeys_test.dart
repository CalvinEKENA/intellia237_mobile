import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/auth/presentation/widgets/intellia_237_membrane.dart';
import 'package:intellia237/features/auth/presentation/widgets/pass_auth_progress.dart';
import 'package:intellia237/features/role_registration/domain/teacher_catalogs.dart';
import 'package:intellia237/features/teacher_registration/application/teacher_registration_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/intellia_fonts.dart';
import '../../support/seal_device_journey.dart';

/// Device QA round 3 — le sceau « 237 » sur les vrais écrans, comme sur le
/// téléphone du propriétaire : saisie clavier ouvert, SMS tapé ou lu par
/// Android, délais d'un réseau mobile, vraies transitions de pages et vraie
/// redirection du routeur.
///
/// Ces tests ne posent jamais une valeur sur le peintre. Ils pilotent l'écran
/// comme un utilisateur et lisent, image par image, ce que le peintre du
/// sceau reçoit (`Intellia237SealPainter`).
void main() {
  setUpAll(loadIntelliaFonts);
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  const neutral = PassSealStage.neutral;
  const identifier = PassSealStage.identifier;
  const secret = PassSealStage.secret;
  const verified = PassSealStage.verified;
  const fullContract = [neutral, identifier, secret, verified];

  for (final locale in const [Locale('fr'), Locale('en')]) {
    for (final reduced in const [false, true]) {
      final label =
          '${locale.languageCode} · '
          '${reduced ? 'reduced motion' : 'motion'}';

      testWidgets('PHONE + OTP · $label: empty → partial → valid number → '
          'empty → partial → complete OTP → verified → home', (tester) async {
        final journey = await SealJourney.start(
          tester,
          DeviceBackend(),
          locale: locale,
          reduceMotion: reduced,
        );
        await journey.tap('gateway-phone-auth');
        await journey.wait(const Duration(milliseconds: 400));
        expect(journey.location, AppRoutes.phoneAuth);
        expect(journey.seal!.stage, neutral, reason: 'empty number');

        await journey.typeKey('phone-number-field', '69900000');
        expect(journey.seal!.stage, neutral, reason: 'partial number');

        await journey.typeKey(
          'phone-number-field',
          DeviceBackend.studentPhone,
          from: 8,
        );
        expect(journey.seal!.stage, identifier, reason: 'valid number');

        await journey.tap('send-phone-code');
        await journey.waitUntil(_otpShown);
        expect(journey.seal!.stage, identifier, reason: 'empty OTP');

        await journey.wait(const Duration(milliseconds: 800));
        await journey.typeKey('phone-otp-field', '123');
        expect(journey.seal!.stage, identifier, reason: 'partial OTP');

        await journey.typeKey('phone-otp-field', '123456', from: 3);
        expect(journey.seal!.stage, secret, reason: 'complete OTP');

        // Accès neutre, numéro d'un élève : la personne confirme qui elle
        // est ; « 7 » ne s'allume qu'à l'ouverture.
        await journey.confirmStudentPhone();
        await journey.waitUntil(() => journey.seal?.stage == verified);
        expect(journey.location, AppRoutes.phoneAuth);
        expect(
          find.text(
            locale.languageCode == 'fr' ? 'NUMÉRO VÉRIFIÉ' : 'NUMBER VERIFIED',
          ),
          findsOneWidget,
        );

        await journey.waitUntil(
          () => journey.location == AppRoutes.studentHome,
        );
        await journey.wait(const Duration(milliseconds: 1200));

        _expectContract(journey, fullContract);
        _expectEachStageReadable(journey, fullContract);
        _expectCompletionHeld(journey, AppRoutes.phoneAuth, reduced: reduced);
        _expectNoFallBack(journey);
        _expectArrivedComplete(journey, AppRoutes.studentHome);
        if (reduced) _expectStill(journey);
        await _dispose(journey);
      });

      testWidgets('EMAIL · $label: empty → valid e-mail → password → '
          'authenticated → teacher home', (tester) async {
        final journey = await SealJourney.start(
          tester,
          DeviceBackend(),
          locale: locale,
          reduceMotion: reduced,
        );
        await journey.tap('gateway-staff-login');
        await journey.wait(const Duration(milliseconds: 400));
        expect(journey.location, AppRoutes.emailLogin);
        expect(journey.seal!.stage, neutral, reason: 'empty e-mail');

        final email = _inside('login-email-field');
        final password = _inside('login-password-field');
        await journey.type(email, 'serge@', perKey: _fast);
        expect(journey.seal!.stage, neutral, reason: 'partial e-mail');
        await journey.type(
          email,
          DeviceBackend.teacherEmail,
          from: 6,
          perKey: _fast,
        );
        expect(journey.seal!.stage, identifier, reason: 'valid e-mail');

        await journey.type(password, 'motdepa', perKey: _fast);
        expect(journey.seal!.stage, identifier, reason: 'short password');
        await journey.type(
          password,
          DeviceBackend.teacherPassword,
          from: 7,
          perKey: _fast,
        );
        expect(journey.seal!.stage, secret, reason: 'password stage');

        await journey.tap('login-submit');
        await journey.waitUntil(() => journey.seal?.stage == verified);
        expect(journey.location, AppRoutes.emailLogin);
        await journey.waitUntil(
          () => journey.location == AppRoutes.teacherHome,
        );
        await journey.wait(const Duration(milliseconds: 1200));

        _expectContract(journey, fullContract);
        _expectEachStageReadable(journey, fullContract);
        _expectCompletionHeld(journey, AppRoutes.emailLogin, reduced: reduced);
        _expectNoFallBack(journey);
        _expectArrivedComplete(journey, AppRoutes.teacherHome);
        if (reduced) _expectStill(journey);
        await _dispose(journey);
      });
    }
  }

  for (final reduced in const [false, true]) {
    final label = reduced ? 'reduced motion' : 'motion';

    testWidgets('PHONE · SMS read by Android · $label: 3 is shown alone '
        'before 7', (tester) async {
      final backend = DeviceBackend()..sms = SmsBehaviour.autoRetrieved;
      final journey = await SealJourney.start(
        tester,
        backend,
        reduceMotion: reduced,
      );
      await journey.tap('gateway-phone-auth');
      await journey.wait(const Duration(milliseconds: 400));
      await journey.typeKey('phone-number-field', DeviceBackend.studentPhone);
      await journey.tap('send-phone-code');
      await journey.confirmStudentPhone();
      await journey.waitUntil(() => journey.location == AppRoutes.studentHome);
      await journey.wait(const Duration(milliseconds: 1200));

      _expectContract(journey, fullContract);
      // Aucun chiffre tapé : le « 3 » rouge reste seul lisible.
      expect(
        journey.trace.longest(
          (seal) => seal.stage == secret && seal.settled && seal.visible > .95,
        ),
        greaterThanOrEqualTo(
          PassSealTiming.stageHold -
              (reduced ? Duration.zero : Intellia237Motion.colorChange) -
              _frames(2),
        ),
        reason: journey.trace.describe(),
      );
      _expectCompletionHeld(journey, AppRoutes.phoneAuth, reduced: reduced);
      _expectNoFallBack(journey);
      _expectArrivedComplete(journey, AppRoutes.studentHome);
      await _dispose(journey);
    });

    testWidgets('PHONE · instant verification · $label: no step skipped', (
      tester,
    ) async {
      final backend = DeviceBackend()..sms = SmsBehaviour.instant;
      final journey = await SealJourney.start(
        tester,
        backend,
        reduceMotion: reduced,
      );
      await journey.tap('gateway-phone-auth');
      await journey.wait(const Duration(milliseconds: 400));
      await journey.typeKey('phone-number-field', DeviceBackend.studentPhone);
      await journey.tap('send-phone-code');
      await journey.confirmStudentPhone();
      await journey.waitUntil(() => journey.location == AppRoutes.studentHome);
      await journey.wait(const Duration(milliseconds: 800));

      _expectContract(journey, fullContract);
      _expectEachStageReadable(journey, fullContract);
      _expectCompletionHeld(journey, AppRoutes.phoneAuth, reduced: reduced);
      _expectNoFallBack(journey);
      await _dispose(journey);
    });

    testWidgets('PARENT · existing number · $label: identity first, no role '
        'asked, the full progression to the parent space', (tester) async {
      final journey = await SealJourney.start(
        tester,
        DeviceBackend(),
        reduceMotion: reduced,
      );
      await journey.tap('gateway-phone-auth');
      await journey.wait(const Duration(milliseconds: 400));
      expect(journey.location, AppRoutes.phoneAuth);
      expect(journey.seal!.stage, neutral, reason: 'no identity yet');

      await _verifyPhone(journey, DeviceBackend.parentPhone);
      await journey.waitUntil(() => journey.location == AppRoutes.parentHome);
      await journey.wait(const Duration(milliseconds: 1200));

      _expectContract(journey, fullContract);
      _expectEachStageReadable(journey, fullContract);
      _expectCompletionHeld(journey, AppRoutes.phoneAuth, reduced: reduced);
      _expectNoFallBack(journey);
      _expectArrivedComplete(journey, AppRoutes.parentHome);
      await _dispose(journey);
    });

    testWidgets('REGISTRATION · new parent · $label: verified identity → '
        'registration fields → completion, never un-coloured', (tester) async {
      final journey = await SealJourney.start(
        tester,
        DeviceBackend(),
        reduceMotion: reduced,
      );
      await journey.tap('gateway-phone-auth');
      await journey.wait(const Duration(milliseconds: 400));
      await _verifyPhone(journey, DeviceBackend.newPhone);
      // Nouvelle identité : la décision d'entrée vient après le numéro.
      await journey.waitUntil(
        () => journey.location == AppRoutes.accountWelcome,
      );
      await journey.tap('welcome-parent');
      await journey.waitUntil(
        () => journey.location == AppRoutes.parentRegistration,
      );
      await journey.wait(const Duration(milliseconds: 600));
      expect(journey.seal!.stage, verified, reason: 'verified identity');
      expect(journey.seal!.tricolor, isTrue);

      final fields = find.byType(TextFormField);
      await journey.type(fields.at(0), 'Mireille', perKey: _fast);
      await journey.type(fields.at(1), 'Ekane', perKey: _fast);
      expect(journey.seal!.stage, verified, reason: 'registration fields');
      await journey.tap('registration-primary-action');
      await journey.wait(const Duration(milliseconds: 700));
      await journey.tap('registration-primary-action');
      await journey.wait(const Duration(milliseconds: 700));
      await journey.tapText('J’accepte les conditions d’utilisation.');
      await journey.tapText('J’accepte la politique de confidentialité.');
      await journey.tap('registration-primary-action');
      await journey.waitUntil(() => journey.location == AppRoutes.parentHome);
      await journey.wait(const Duration(milliseconds: 1200));

      _expectContract(journey, fullContract);
      _expectCompletionHeld(journey, AppRoutes.phoneAuth, reduced: reduced);
      _expectNoFallBack(journey);
      _expectArrivedComplete(journey, AppRoutes.parentHome);
      await _dispose(journey);
    });

    testWidgets('REGISTRATION · new student · $label: the verified seal '
        'crosses into registration', (tester) async {
      final journey = await SealJourney.start(
        tester,
        DeviceBackend(),
        reduceMotion: reduced,
      );
      await journey.tap('gateway-phone-auth');
      await journey.wait(const Duration(milliseconds: 400));
      await _verifyPhone(journey, DeviceBackend.newPhone);
      await journey.waitUntil(
        () => journey.location == AppRoutes.accountWelcome,
      );
      await journey.tap('welcome-student');
      await journey.waitUntil(
        () => journey.location == AppRoutes.studentRegistration,
      );
      await journey.wait(const Duration(milliseconds: 600));
      final fields = find.byType(TextFormField);
      await journey.type(fields.at(0), 'Amina', perKey: _fast);
      await journey.type(fields.at(1), 'Ndi', perKey: _fast);
      await journey.wait(const Duration(milliseconds: 600));

      _expectContract(journey, fullContract);
      _expectCompletionHeld(journey, AppRoutes.phoneAuth, reduced: reduced);
      _expectNoFallBack(journey);
      _expectArrivedComplete(journey, AppRoutes.studentRegistration);
      await _dispose(journey);
    });

    testWidgets('REGISTRATION · teacher account · $label: credentials, not '
        'form steps, drive the seal', (tester) async {
      final journey = await SealJourney.start(
        tester,
        DeviceBackend(),
        reduceMotion: reduced,
      );
      await journey.tap('gateway-staff-login');
      await journey.wait(const Duration(milliseconds: 400));
      await journey.tap('login-create-account');
      await journey.wait(const Duration(milliseconds: 500));
      expect(journey.location, AppRoutes.teacherRegistration);
      expect(journey.seal!.stage, neutral, reason: 'nothing typed');

      final fields = find.byType(TextFormField);
      await journey.type(fields.at(0), 'Serge', perKey: _fast);
      await journey.type(fields.at(1), 'Mbarga', perKey: _fast);
      expect(journey.seal!.stage, neutral, reason: 'names are not credentials');
      await journey.type(fields.at(2), 'serge.m@ecole.cm', perKey: _fast);
      expect(journey.seal!.stage, identifier, reason: 'valid e-mail');
      await journey.type(fields.at(3), 'motdepasse', perKey: _fast);
      expect(journey.seal!.stage, identifier, reason: 'unconfirmed password');
      await journey.type(fields.at(4), 'motdepasse', perKey: _fast);
      expect(journey.seal!.stage, secret, reason: 'confirmed password');

      await journey.tap('registration-primary-action');
      await journey.wait(const Duration(milliseconds: 800));
      final controller = journey.container.read(
        teacherRegistrationControllerProvider.notifier,
      );
      controller
        ..toggleSubject(TeacherCatalogs.subjects.first)
        ..toggleLevel(TeacherCatalogs.levels.first);
      await journey.wait(const Duration(milliseconds: 300));
      await journey.tap('registration-primary-action');
      await journey.wait(const Duration(milliseconds: 800));
      expect(journey.seal!.stage, secret, reason: 'form steps change nothing');
      controller
        ..setAcceptedTerms(true)
        ..setAcceptedPrivacy(true);
      await journey.wait(const Duration(milliseconds: 300));
      await journey.tap('registration-primary-action');
      await journey.waitUntil(() => journey.location == AppRoutes.teacherHome);
      await journey.wait(const Duration(milliseconds: 1200));

      _expectContract(journey, fullContract);
      _expectCompletionHeld(
        journey,
        AppRoutes.teacherRegistration,
        reduced: reduced,
      );
      _expectNoFallBack(journey);
      _expectArrivedComplete(journey, AppRoutes.teacherHome);
      await _dispose(journey);
    });
  }

  testWidgets('SMALL PHONE · 360×760, text 130 %: every stage and the '
      'completed seal stay fully on screen', (tester) async {
    final journey = await SealJourney.start(
      tester,
      DeviceBackend(),
      device: SealDevice.smallLargeText,
    );
    await journey.tap('gateway-phone-auth');
    await journey.wait(const Duration(milliseconds: 400));
    await _verifyPhone(journey, DeviceBackend.parentPhone);
    await journey.waitUntil(() => journey.location == AppRoutes.parentHome);
    await journey.wait(const Duration(milliseconds: 1200));

    _expectContract(journey, fullContract);
    _expectEachStageReadable(journey, fullContract);
    _expectCompletionHeld(journey, AppRoutes.phoneAuth, reduced: false);
    _expectNoFallBack(journey);
    _expectArrivedComplete(journey, AppRoutes.parentHome);
    await _dispose(journey);
  });

  testWidgets('SMALL PHONE · e-mail sign-in keeps the completed seal on '
      'screen', (tester) async {
    final journey = await SealJourney.start(
      tester,
      DeviceBackend(),
      device: SealDevice.smallLargeText,
    );
    await journey.tap('gateway-staff-login');
    await journey.wait(const Duration(milliseconds: 400));
    await journey.type(
      _inside('login-email-field'),
      DeviceBackend.teacherEmail,
      perKey: _fast,
    );
    await journey.type(
      _inside('login-password-field'),
      DeviceBackend.teacherPassword,
      perKey: _fast,
    );
    await journey.tap('login-submit');
    await journey.waitUntil(() => journey.location == AppRoutes.teacherHome);
    await journey.wait(const Duration(milliseconds: 1200));

    _expectContract(journey, fullContract);
    _expectCompletionHeld(journey, AppRoutes.emailLogin, reduced: false);
    _expectNoFallBack(journey);
    _expectArrivedComplete(journey, AppRoutes.teacherHome);
    await _dispose(journey);
  });

  testWidgets('SMALL PHONE · a digit lit with the keyboard closed never moves '
      'the page under the finger', (tester) async {
    final journey = await SealJourney.start(
      tester,
      DeviceBackend(),
      device: SealDevice.smallLargeText,
    );
    await journey.tap('gateway-phone-auth');
    await journey.wait(const Duration(milliseconds: 400));
    // Quelqu'un a fait défiler jusqu'au bas du formulaire : le Pass est
    // passé au-dessus de l'écran.
    final send = find.byKey(const ValueKey('send-phone-code'));
    final position = Scrollable.of(tester.element(send)).position;
    position.jumpTo(position.maxScrollExtent);
    await journey.wait(const Duration(milliseconds: 100));
    final before = position.pixels;
    expect(journey.seal!.visible, lessThan(.5));

    // Numéro collé ou rempli par le système, clavier fermé.
    tester
        .widget<TextFormField>(find.byKey(const ValueKey('phone-number-field')))
        .controller!
        .text = DeviceBackend
        .studentPhone;
    await journey.wait(const Duration(milliseconds: 600));

    expect(journey.seal!.stage, identifier);
    expect(position.pixels, before);
    await _dispose(journey);
  });

  testWidgets('FAMILY PHONE · student number, "I am the parent": 7 never '
      'lights during the offer and nothing falls back; another number '
      'restarts explicitly', (tester) async {
    final journey = await SealJourney.start(tester, DeviceBackend());
    await journey.tap('gateway-phone-auth');
    await journey.wait(const Duration(milliseconds: 400));
    await _verifyPhone(journey, DeviceBackend.studentPhone);
    // Le numéro est celui de l'élève : la personne dit être son parent.
    await journey.tapWhenShown('phone-student-is-parent');
    await journey.waitUntil(
      () => find
          .byKey(const ValueKey('family-phone-offer'))
          .evaluate()
          .isNotEmpty,
    );
    await journey.wait(const Duration(milliseconds: 1500));

    expect(journey.trace.stages, [neutral, identifier, secret]);
    expect(journey.seal!.stage, secret);

    await journey.tap('family-phone-offer-another-number');
    expect(journey.seal!.stage, neutral, reason: 'explicit restart');
    await _verifyPhone(journey, DeviceBackend.parentPhone);
    await journey.waitUntil(() => journey.location == AppRoutes.parentHome);
    await journey.wait(const Duration(milliseconds: 800));
    expect(journey.trace.stages, [
      neutral,
      identifier,
      secret,
      neutral,
      identifier,
      secret,
      verified,
    ]);
    _expectArrivedComplete(journey, AppRoutes.parentHome);
    await _dispose(journey);
  });

  testWidgets('FR ⇄ EN during the journey rebuilds every screen without '
      'resetting a lit digit', (tester) async {
    final journey = await SealJourney.start(tester, DeviceBackend());
    await journey.tap('gateway-phone-auth');
    await journey.wait(const Duration(milliseconds: 400));
    await journey.typeKey('phone-number-field', DeviceBackend.studentPhone);
    expect(journey.seal!.stage, identifier);

    await journey.tapText('EN');
    await journey.wait(const Duration(milliseconds: 400));
    expect(find.text('Send my code'), findsOneWidget);
    expect(journey.seal!.stage, identifier, reason: 'after FR → EN');

    await journey.tap('send-phone-code');
    await journey.waitUntil(_otpShown);
    await journey.wait(const Duration(milliseconds: 600));
    await journey.typeKey('phone-otp-field', '12345');
    await journey.tapText('FR');
    await journey.wait(const Duration(milliseconds: 400));
    expect(find.text('Vérifier le code'), findsOneWidget);
    expect(journey.seal!.stage, identifier, reason: 'after EN → FR');

    await journey.typeKey('phone-otp-field', '123456', from: 5);
    await journey.confirmStudentPhone();
    await journey.waitUntil(() => journey.location == AppRoutes.studentHome);
    await journey.wait(const Duration(milliseconds: 800));

    _expectContract(journey, fullContract);
    _expectNoFallBack(journey);
    _expectArrivedComplete(journey, AppRoutes.studentHome);
    await _dispose(journey);
  });

  testWidgets('PHONE · change number during the OTP keeps the valid number '
      'green', (tester) async {
    final journey = await SealJourney.start(tester, DeviceBackend());
    await journey.tap('gateway-phone-auth');
    await journey.wait(const Duration(milliseconds: 400));
    await journey.typeKey('phone-number-field', DeviceBackend.studentPhone);
    await journey.tap('send-phone-code');
    await journey.waitUntil(_otpShown);
    await journey.typeKey('phone-otp-field', '12');
    await journey.tapText('Modifier le numéro');
    await journey.wait(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('phone-entry-stage')), findsOneWidget);
    expect(journey.seal!.stage, identifier);
    expect(journey.trace.stages, [neutral, identifier]);
    await _dispose(journey);
  });
}

const _fast = Duration(milliseconds: 70);

Duration _frames(int count) => Duration(microseconds: 16667 * count);

bool _otpShown() =>
    find.byKey(const ValueKey('phone-otp-field')).evaluate().isNotEmpty;

Finder _inside(String key) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.byType(TextField),
);

Future<void> _verifyPhone(SealJourney journey, String number) async {
  await journey.typeKey('phone-number-field', number);
  await journey.tap('send-phone-code');
  await journey.waitUntil(_otpShown);
  await journey.wait(const Duration(milliseconds: 800));
  await journey.typeKey('phone-otp-field', '123456');
}

/// Étapes livrées au peintre, dans l'ordre et sans retour.
void _expectContract(SealJourney journey, List<PassSealStage> expected) {
  expect(journey.trace.stages, expected, reason: journey.trace.describe());
}

/// Chaque étape, une fois son fondu fini, reste lisible — sceau entièrement à
/// l'écran — au moins 300 ms.
void _expectEachStageReadable(SealJourney journey, List<PassSealStage> stages) {
  for (final stage in stages) {
    expect(
      journey.trace.longest(
        (seal) => seal.stage == stage && seal.settled && seal.visible > .95,
      ),
      greaterThanOrEqualTo(const Duration(milliseconds: 300)),
      reason: '$stage\n${journey.trace.describe()}',
    );
  }
}

/// « 2 » vert, « 3 » rouge, « 7 » jaune, exacts et entièrement à l'écran,
/// sur l'écran d'authentification, avant qu'il ne s'en aille.
void _expectCompletionHeld(
  SealJourney journey,
  String route, {
  required bool reduced,
}) {
  final minimum =
      PassSealTiming.completionHold -
      (reduced ? Duration.zero : Intellia237Motion.colorChange) -
      _frames(2);
  expect(
    journey.trace.longest(
      (seal) =>
          seal.stage == PassSealStage.verified &&
          seal.tricolor &&
          seal.visible > .95,
      route: route,
    ),
    greaterThanOrEqualTo(minimum),
    reason: journey.trace.describe(),
  );
}

/// Une fois « 7 » allumé, aucune image — vol du Hero, arrivée, reconstruction
/// — ne livre au peintre une étape inférieure.
void _expectNoFallBack(SealJourney journey) {
  var complete = false;
  for (final frame in journey.trace.frames) {
    for (final seal in frame.seals) {
      if (seal.stage == PassSealStage.verified) {
        complete = true;
      } else if (complete) {
        fail(
          'seal fell back to ${seal.stage} at ${frame.at} on ${frame.route}\n'
          '${journey.trace.describe()}',
        );
      }
    }
  }
  expect(complete, isTrue, reason: journey.trace.describe());
}

void _expectArrivedComplete(SealJourney journey, String route) {
  expect(journey.location, route);
  final seal = journey.seal;
  expect(seal, isNotNull, reason: 'no seal on $route');
  expect(seal!.stage, PassSealStage.verified);
  expect(seal.tricolor, isTrue, reason: SealTrace.digits(seal.digitColors));
  if (AppRoutes.roleHomes.contains(route)) {
    // L'en-tête d'accueil garde un sceau immobile : aucune boucle sans fin
    // sur l'écran où l'on reste.
    _expectStill(journey);
  }
}

void _expectStill(SealJourney journey) {
  for (final motion in journey.motions) {
    expect(motion, Matrix4.identity());
  }
}

Future<void> _dispose(SealJourney journey) async {
  await journey.tester.pumpWidget(const SizedBox.shrink());
  // Le délai de renvoi du SMS se compte en temps réel : il s'arrête avec son
  // contrôleur, pas avec le temps simulé.
  journey.container.dispose();
  await journey.tester.pump(const Duration(seconds: 9));
}
