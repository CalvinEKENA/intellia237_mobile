import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/app/theme/design_tokens.dart';
import 'package:intellia237/core/localization/app_locale_controller.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/phone_auth_controller.dart';
import 'package:intellia237/features/auth/data/repositories/firebase_phone_auth_repository.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/repositories/auth_repository.dart';
import 'package:intellia237/features/auth/domain/repositories/phone_auth_repository.dart';
import 'package:intellia237/features/auth/presentation/login_screen.dart';
import 'package:intellia237/features/auth/presentation/phone_auth_screen.dart';
import 'package:intellia237/features/auth/presentation/widgets/intellia_237_membrane.dart';
import 'package:intellia237/features/auth/presentation/widgets/living_pass.dart';
import 'package:intellia237/features/auth/presentation/widgets/pass_auth_progress.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device QA round 2 : le « 237 » du Pass suit l'authentification, un chiffre
/// par étape et sur son tiers exact, à l'écran téléphone, au code SMS et à la
/// connexion par e-mail.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  group('PassAuthProgress — phone', () {
    double phone(
      PhoneAuthStage stage, {
      String number = '',
      String code = '',
    }) => PassAuthProgress.phone(
      stage: stage,
      phoneInput: number,
      codeInput: code,
    );

    test('the number fills 2 digit by digit, up to exactly one third', () {
      expect(phone(PhoneAuthStage.phoneEntry), PassAuthProgress.start);
      expect(
        phone(PhoneAuthStage.phoneEntry, number: '699'),
        closeTo(1 / 9, 1e-9),
      );
      expect(phone(PhoneAuthStage.phoneEntry, number: '699123456'), 1 / 3);
      expect(
        phone(PhoneAuthStage.phoneEntry, number: '6 99 12 34 56'),
        PassAuthProgress.identifier,
      );
    });

    test('a typed +237 prefix does not count as local digits', () {
      expect(
        phone(PhoneAuthStage.phoneEntry, number: '+237 699'),
        closeTo(1 / 9, 1e-9),
      );
      expect(
        phone(PhoneAuthStage.phoneEntry, number: '+237 699 12 34 56'),
        PassAuthProgress.identifier,
      );
      expect(
        phone(PhoneAuthStage.phoneEntry, number: '00237699123456'),
        PassAuthProgress.identifier,
      );
    });

    test('the SMS code fills 3 from one third to exactly two thirds', () {
      expect(phone(PhoneAuthStage.codeEntry), PassAuthProgress.identifier);
      expect(phone(PhoneAuthStage.codeEntry, code: '123'), closeTo(0.5, 1e-9));
      expect(phone(PhoneAuthStage.codeEntry, code: '123456'), 2 / 3);
    });

    test('success is exactly complete', () {
      expect(phone(PhoneAuthStage.success), PassAuthProgress.verified);
    });

    test('each completed step gives its digit its exact color', () {
      final afterNumber = Intellia237Palette.digitColors(
        phone(PhoneAuthStage.phoneEntry, number: '699123456'),
      );
      final afterCode = Intellia237Palette.digitColors(
        phone(PhoneAuthStage.codeEntry, code: '123456'),
      );
      final afterSuccess = Intellia237Palette.digitColors(
        phone(PhoneAuthStage.success),
      );
      expect(afterNumber[0], IntelliaColors.cmVert);
      expect(afterNumber[1], Intellia237Palette.base);
      expect(afterCode[1], IntelliaColors.cmRouge);
      expect(afterCode[2], Intellia237Palette.base);
      expect(afterSuccess, [
        IntelliaColors.cmVert,
        IntelliaColors.cmRouge,
        IntelliaColors.cmJaune,
      ]);
    });
  });

  group('PassAuthProgress — e-mail', () {
    test('address then password, never past the secret on this screen', () {
      expect(
        PassAuthProgress.emailSignIn(email: '', password: ''),
        PassAuthProgress.start,
      );
      expect(
        PassAuthProgress.emailSignIn(email: 'amina@', password: ''),
        closeTo(1 / 6, 1e-9),
      );
      expect(
        PassAuthProgress.emailSignIn(email: 'amina@ecole.cm', password: ''),
        PassAuthProgress.identifier,
      );
      expect(
        PassAuthProgress.emailSignIn(email: 'amina@ecole.cm', password: 'abcd'),
        closeTo(0.5, 1e-9),
      );
      expect(
        PassAuthProgress.emailSignIn(
          email: 'amina@ecole.cm',
          password: 'abcdefghijkl',
        ),
        PassAuthProgress.secret,
      );
    });

    test('a password without a valid address does not colour 3', () {
      expect(
        PassAuthProgress.emailSignIn(email: 'amina', password: 'abcdefgh'),
        lessThan(PassAuthProgress.identifier),
      );
    });

    test('password reset stops at the secret once the link is sent', () {
      expect(
        PassAuthProgress.passwordReset(email: '', linkSent: false),
        PassAuthProgress.start,
      );
      expect(
        PassAuthProgress.passwordReset(email: 'a@b.cm', linkSent: false),
        PassAuthProgress.identifier,
      );
      expect(
        PassAuthProgress.passwordReset(email: 'a@b.cm', linkSent: true),
        PassAuthProgress.secret,
      );
    });
  });

  group('phone and OTP screen drive the seal', () {
    for (final (language, verifiedPhase) in const [
      ('fr', 'NUMÉRO VÉRIFIÉ'),
      ('en', 'NUMBER VERIFIED'),
    ]) {
      for (final reduceMotion in const [false, true]) {
        testWidgets(
          '$language reduceMotion=$reduceMotion: 0 → ⅓ → ½ → ⅔ → 1, 7 yellow',
          (tester) async {
            await _pumpPhone(
              tester,
              language: language,
              reduceMotion: reduceMotion,
            );

            double seal() =>
                tester.widget<Intellia237Membrane>(_membrane).progress;
            expect(seal(), PassAuthProgress.start);

            await tester.enterText(_phoneField, '699123456');
            await tester.pump();
            expect(seal(), PassAuthProgress.identifier);
            expect(
              Intellia237Palette.digitColors(seal())[0],
              IntelliaColors.cmVert,
            );

            await tester.ensureVisible(_sendCode);
            await tester.tap(_sendCode);
            await tester.pump(const Duration(milliseconds: 250));
            expect(seal(), PassAuthProgress.identifier);

            // Le champ natif du code reçoit la saisie chiffre par chiffre.
            await tester.enterText(_otpField, '123');
            await tester.pump();
            expect(seal(), closeTo(0.5, 1e-9));

            await tester.enterText(_otpField, '123456');
            await tester.pump();
            await tester.pump();
            expect(seal(), PassAuthProgress.verified);
            final membrane = tester.widget<Intellia237Membrane>(_membrane);
            expect(membrane.verified, isTrue);
            expect(Intellia237Palette.digitColors(membrane.progress), [
              IntelliaColors.cmVert,
              IntelliaColors.cmRouge,
              IntelliaColors.cmJaune,
            ]);
            expect(
              tester.widget<LivingPass>(find.byType(LivingPass)).phase,
              verifiedPhase,
            );

            await tester.pump(const Duration(seconds: 1));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
          },
        );
      }
    }
  });

  group('e-mail sign-in screen drives the seal', () {
    for (final language in const ['fr', 'en']) {
      testWidgets('$language: address colours 2, password colours 3', (
        tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(
            child: _app(language: language, home: const LoginScreen()),
          ),
        );
        await tester.pump();
        double seal() => tester.widget<Intellia237Membrane>(_membrane).progress;
        expect(seal(), PassAuthProgress.start);

        await tester.enterText(
          find.descendant(
            of: find.byKey(const ValueKey('login-email-field')),
            matching: find.byType(TextField),
          ),
          'amina@ecole.cm',
        );
        await tester.pump();
        expect(seal(), PassAuthProgress.identifier);

        await tester.enterText(
          find.descendant(
            of: find.byKey(const ValueKey('login-password-field')),
            matching: find.byType(TextField),
          ),
          'motdepasse',
        );
        await tester.pump();
        expect(seal(), PassAuthProgress.secret);
        expect(Intellia237Palette.digitColors(seal()), [
          IntelliaColors.cmVert,
          IntelliaColors.cmRouge,
          Intellia237Palette.base,
        ]);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  });
}

final _membrane = find.byType(Intellia237Membrane);
final _phoneField = find.byKey(const ValueKey('phone-number-field'));
final _sendCode = find.byKey(const ValueKey('send-phone-code'));
final _otpField = find.byKey(const ValueKey('phone-otp-field'));

Widget _app({
  required String language,
  required Widget home,
  bool reduceMotion = true,
}) => MaterialApp(
  locale: Locale(language),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: child!,
  ),
  home: home,
);

Future<void> _pumpPhone(
  WidgetTester tester, {
  required String language,
  required bool reduceMotion,
}) async {
  SharedPreferences.setMockInitialValues({'app_language_code': language});
  final router = GoRouter(
    initialLocation: AppRoutes.phoneAuth,
    routes: [
      GoRoute(
        path: AppRoutes.phoneAuth,
        builder: (_, _) => const PhoneAuthScreen(),
      ),
      for (final path in [
        AppRoutes.studentHome,
        AppRoutes.studentRegistration,
        AppRoutes.authProfileRecovery,
      ])
        GoRoute(
          path: path,
          builder: (_, _) => Scaffold(body: Text(path)),
        ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appLocaleProvider.overrideWith(() => _FixedLocale(Locale(language))),
        phoneAuthRepositoryProvider.overrideWithValue(_CodeRepository()),
        authRepositoryProvider.overrideWithValue(_StudentRepository()),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pump();
}

class _FixedLocale extends AppLocaleController {
  _FixedLocale(this.locale);

  final Locale locale;

  @override
  Locale build() => locale;
}

class _CodeRepository implements PhoneAuthRepository {
  @override
  Future<void> startVerification({
    required String phoneNumber,
    required bool linkCurrentUser,
    int? forceResendingToken,
    required void Function(PhoneAuthSession) onVerified,
    required void Function(PhoneAuthFailure) onFailed,
    required void Function(PhoneCodeDispatch) onCodeSent,
    required void Function(String) onAutoRetrievalTimeout,
  }) async => onCodeSent(const PhoneCodeDispatch(verificationId: 'v1'));

  @override
  Future<PhoneAuthSession> confirmCode({
    required String verificationId,
    required String smsCode,
    required bool linkCurrentUser,
  }) async => const PhoneAuthSession(
    uid: 'student-uid',
    phoneNumber: '+237699123456',
    isNewUser: false,
    linkedToExistingUser: false,
  );
}

class _StudentRepository implements AuthRepository {
  @override
  Future<AuthUserData?> getCurrentUser() async => const AuthUserData(
    uid: 'student-uid',
    email: '',
    role: AppRole.student,
    firstName: 'Amina',
    lastName: 'Ndi',
    profileCompleted: true,
  );

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthUserData> signInWithEmail({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<AuthUserData> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required AppRole role,
  }) => throw UnimplementedError();
}
