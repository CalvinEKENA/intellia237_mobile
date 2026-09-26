import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/application/google_access_coordinator.dart';
import 'package:intellia237/features/auth/data/repositories/firebase_phone_auth_repository.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/repositories/phone_auth_repository.dart';
import 'package:intellia237/features/auth/presentation/account_linking_screen.dart';
import 'package:intellia237/features/auth/presentation/account_welcome_screen.dart';
import 'package:intellia237/features/auth/presentation/auth_gateway_screen.dart';
import 'package:intellia237/features/auth/presentation/google_account_question_screen.dart';
import 'package:intellia237/features/auth/presentation/phone_auth_screen.dart';
import 'package:intellia237/features/auth/presentation/role_selector_screen.dart';
import 'package:intellia237/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_google_access.dart';
import '../../support/intellia_fonts.dart';
import '../../support/seal_device_journey.dart';

/// Matrice exigée par la refonte Auth V2 : 320 × 568, 360 de large, texte
/// système à 130 % et 200 %, en français et en anglais. Aucun débordement,
/// et chaque action reste atteignable par défilement.
const _matrix = <({Size size, double scale})>[
  (size: Size(320, 568), scale: 1.0),
  (size: Size(320, 568), scale: 2.0),
  (size: Size(360, 760), scale: 1.3),
  (size: Size(360, 760), scale: 2.0),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadIntelliaFonts);
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    required Size size,
    required double scale,
    Locale locale = const Locale('fr'),
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: screen,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> expectReachable(
    WidgetTester tester,
    List<String> keys,
    String reason,
  ) async {
    expect(tester.takeException(), isNull, reason: reason);
    for (final key in keys) {
      final finder = find.byKey(ValueKey(key));
      expect(finder, findsOneWidget, reason: '$key · $reason');
      await tester.ensureVisible(finder);
      await tester.pump();
      expect(finder.hitTestable(), findsOneWidget, reason: '$key · $reason');
    }
    expect(tester.takeException(), isNull, reason: reason);
  }

  Future<GoogleAccessCoordinator> pendingCoordinator() async {
    final backend = FakeIdentityBackend();
    final source = FakeGoogleCredentialSource(backend)
      ..choose(fakeGoogleProof('sub-r', email: 'awa.parent@example.cm'));
    final coordinator = GoogleAccessCoordinator(
      source: source,
      probe: FakeGoogleIdentityProbe(backend),
      identity: FakeFirebaseIdentity(backend),
    );
    await coordinator.begin();
    return coordinator;
  }

  for (final locale in const [Locale('fr'), Locale('en')]) {
    for (final (:size, :scale) in _matrix) {
      final label =
          '${locale.languageCode} ${size.width.toInt()}×'
          '${size.height.toInt()} @$scale';

      testWidgets('gateway · $label', (tester) async {
        await pump(
          tester,
          const AuthGatewayScreen(),
          size: size,
          scale: scale,
          locale: locale,
        );
        await expectReachable(tester, const [
          'gateway-phone-auth',
          'gateway-google-auth',
          'gateway-student-access-code',
          'gateway-staff-login',
        ], label);
      });

      testWidgets('Google button · $label', (tester) async {
        await pump(
          tester,
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: GoogleSignInButton(onPressed: () {})),
            ),
          ),
          size: size,
          scale: scale,
          locale: locale,
        );
        await expectReachable(tester, const ['google-signin-button'], label);
        expect(
          tester.getSize(find.byKey(const Key('google-signin-button'))).height,
          greaterThanOrEqualTo(48),
        );
      });

      testWidgets('phone input and OTP · $label', (tester) async {
        await pump(
          tester,
          const PhoneAuthScreen(),
          size: size,
          scale: scale,
          locale: locale,
          overrides: [
            phoneAuthRepositoryProvider.overrideWithValue(_CodeSender()),
          ],
        );
        await expectReachable(tester, const [
          'phone-number-field',
          'send-phone-code',
        ], 'phone · $label');
        await tester.enterText(
          find.byKey(const ValueKey('phone-number-field')),
          '699123456',
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('send-phone-code')),
        );
        await tester.tap(find.byKey(const ValueKey('send-phone-code')));
        await tester.pump(const Duration(milliseconds: 300));
        await expectReachable(tester, const [
          'phone-otp-field',
        ], 'OTP · $label');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 61));
      });

      testWidgets('Google question · $label', (tester) async {
        final coordinator = await pendingCoordinator();
        await pump(
          tester,
          const GoogleAccountQuestionScreen(),
          size: size,
          scale: scale,
          locale: locale,
          overrides: [
            googleAccessCoordinatorProvider.overrideWithValue(coordinator),
          ],
        );
        await expectReachable(tester, const [
          'google-question-yes',
          'google-question-no',
          'google-question-other-account',
        ], label);
      });

      testWidgets('account recovery · $label', (tester) async {
        final coordinator = await pendingCoordinator();
        await pump(
          tester,
          const AccountLinkingScreen(),
          size: size,
          scale: scale,
          locale: locale,
          overrides: [
            googleAccessCoordinatorProvider.overrideWithValue(coordinator),
            phoneAuthRepositoryProvider.overrideWithValue(_CodeSender()),
          ],
        );
        await expectReachable(tester, const [
          'recovery-mode-phone',
          'recovery-mode-email',
          'recovery-phone-field',
          'recovery-send-code',
          'recovery-cancel',
        ], 'recovery phone · $label');

        await tester.enterText(
          find.byKey(const ValueKey('recovery-phone-field')),
          '677000002',
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('recovery-send-code')),
        );
        await tester.tap(find.byKey(const ValueKey('recovery-send-code')));
        await tester.pump(const Duration(milliseconds: 300));
        await expectReachable(tester, const [
          'recovery-otp-field',
          'recovery-verify-code',
          'recovery-change-number',
        ], 'recovery OTP · $label');

        await tester.tap(find.byKey(const ValueKey('recovery-change-number')));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.ensureVisible(
          find.byKey(const ValueKey('recovery-mode-email')),
        );
        await tester.tap(find.byKey(const ValueKey('recovery-mode-email')));
        await tester.pump(const Duration(milliseconds: 300));
        await expectReachable(tester, const [
          'recovery-email-field',
          'recovery-password-field',
          'recovery-email-submit',
        ], 'recovery e-mail · $label');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 61));
      });

      testWidgets('entry decision · $label', (tester) async {
        await pump(
          tester,
          const AccountWelcomeScreen(),
          size: size,
          scale: scale,
          locale: locale,
        );
        await expectReachable(tester, const [
          'welcome-parent',
          'welcome-student',
          'welcome-discover',
          'welcome-sign-out',
        ], label);
      });

      testWidgets('space chooser · $label', (tester) async {
        await pump(
          tester,
          const RoleSelectorScreen(),
          size: size,
          scale: scale,
          locale: locale,
          overrides: [
            authControllerProvider.overrideWith(
              () => _FixedAuth(
                const AuthState.authenticated(
                  role: AppRole.teacher,
                  availableRoles: [
                    AppRole.teacher,
                    AppRole.parent,
                    AppRole.admin,
                  ],
                  userId: 'multi',
                  spaceChoicePending: true,
                ),
              ),
            ),
          ],
        );
        await expectReachable(tester, const [
          'role-select-teacher',
          'role-select-parent',
          'role-select-admin',
          'role-select-sign-out',
        ], label);
      });
    }
  }

  testWidgets('family phone confirmation · 320×568, text 200 %: both answers '
      'stay reachable', (tester) async {
    final journey = await SealJourney.start(
      tester,
      DeviceBackend(),
      device: const SealDevice(
        physicalSize: Size(640, 1136),
        pixelRatio: 2,
        keyboardHeight: 260,
        textScale: 2,
      ),
      traceSeal: false,
    );
    await journey.tap('gateway-phone-auth');
    await journey.wait(const Duration(milliseconds: 400));
    await journey.typeKey('phone-number-field', DeviceBackend.studentPhone);
    await journey.tap('send-phone-code');
    await journey.waitUntil(
      () => find.byKey(const ValueKey('phone-otp-field')).evaluate().isNotEmpty,
    );
    await journey.wait(const Duration(milliseconds: 800));
    await journey.typeKey('phone-otp-field', '123456');
    await journey.waitUntil(
      () => find
          .byKey(const ValueKey('phone-student-confirm'))
          .evaluate()
          .isNotEmpty,
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await journey.wait(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    for (final key in const [
      'phone-student-confirm',
      'phone-student-is-parent',
      'phone-student-other-number',
    ]) {
      await journey.reveal(find.byKey(ValueKey(key)));
      expect(find.byKey(ValueKey(key)).hitTestable(), findsOneWidget);
    }
    await journey.tap('phone-student-confirm');
    await journey.waitUntil(() => journey.location == AppRoutes.studentHome);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    journey.container.dispose();
    await tester.pump(const Duration(seconds: 9));
  });
}

/// Firebase envoie le SMS aussitôt ; la validation n'est jamais atteinte.
class _CodeSender implements PhoneAuthRepository {
  @override
  Future<void> startVerification({
    required String phoneNumber,
    required bool linkCurrentUser,
    int? forceResendingToken,
    required void Function(PhoneAuthSession) onVerified,
    required void Function(PhoneAuthFailure) onFailed,
    required void Function(PhoneCodeDispatch) onCodeSent,
    required void Function(String) onAutoRetrievalTimeout,
  }) async => onCodeSent(PhoneCodeDispatch(verificationId: phoneNumber));

  @override
  Future<PhoneAuthSession> confirmCode({
    required String verificationId,
    required String smsCode,
    required bool linkCurrentUser,
  }) => throw const PhoneAuthFailure('invalid-verification-code');
}

class _FixedAuth extends AuthController {
  _FixedAuth(this.initial);
  final AuthState initial;

  @override
  AuthState build() => initial;
}
