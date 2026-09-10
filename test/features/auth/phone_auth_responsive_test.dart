import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/data/repositories/firebase_phone_auth_repository.dart';
import 'package:intellia237/features/auth/domain/repositories/phone_auth_repository.dart';
import 'package:intellia237/features/auth/presentation/phone_auth_screen.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('phone and OTP stages fit the complete compact-device matrix', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});

    for (final width in const [320.0, 360.0, 390.0, 412.0]) {
      for (final textScale in const [1.0, 1.3, 1.6]) {
        tester.view.physicalSize = Size(width, 920);
        tester.view.devicePixelRatio = 1;
        final repository = _ResponsivePhoneRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              phoneAuthRepositoryProvider.overrideWithValue(repository),
            ],
            child: MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 920),
                  textScaler: TextScaler.linear(textScale),
                  disableAnimations: true,
                ),
                child: const PhoneAuthScreen(),
              ),
            ),
          ),
        );
        await tester.pump();

        await tester.enterText(
          find.byKey(const ValueKey('phone-number-field')),
          '699123456',
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'phone stage at $width / $textScale',
        );

        await tester.ensureVisible(
          find.byKey(const ValueKey('send-phone-code')),
        );
        await tester.tap(find.byKey(const ValueKey('send-phone-code')));
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.byKey(const ValueKey('phone-otp-field')), findsOneWidget);
        expect(find.byType(TextFormField), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: 'OTP stage at $width / $textScale',
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    }
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.clearAllTestValues();
  });
}

class _ResponsivePhoneRepository implements PhoneAuthRepository {
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
    onCodeSent(const PhoneCodeDispatch(verificationId: 'responsive-id'));
  }

  @override
  Future<PhoneAuthSession> confirmCode({
    required String verificationId,
    required String smsCode,
    required bool linkCurrentUser,
  }) async => const PhoneAuthSession(
    uid: 'test-uid',
    phoneNumber: '+237699123456',
    isNewUser: true,
    linkedToExistingUser: false,
  );
}
