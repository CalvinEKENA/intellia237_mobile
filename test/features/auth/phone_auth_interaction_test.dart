import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/data/repositories/firebase_phone_auth_repository.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/repositories/auth_repository.dart';
import 'package:intellia237/features/auth/domain/repositories/phone_auth_repository.dart';
import 'package:intellia237/features/auth/presentation/phone_auth_screen.dart';
import 'package:intellia237/features/auth/presentation/widgets/auth_controls.dart';
import 'package:intellia237/features/auth/presentation/widgets/intellia_237_membrane.dart';
import 'package:intellia237/features/auth/presentation/widgets/living_pass.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'OTP auto completion, keyboard and button make one request; errors can retry',
    (tester) async {
      final repository = _PendingVerificationRepository();
      await tester.pumpWidget(_screen(repository));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('phone-number-field')),
        '699123456',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('send-phone-code')));
      await tester.tap(find.byKey(const ValueKey('send-phone-code')));
      await tester.pump(const Duration(milliseconds: 250));
      final native = tester.widget<TextField>(find.byType(TextField));
      final button = tester.widget<AuthPrimaryButton>(
        find.byKey(const ValueKey('verify-phone-code')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('phone-otp-field')),
        '123456',
      );
      native.onSubmitted!('123456');
      button.onTap!();
      expect(repository.confirmCalls, 1);
      expect(
        tester.widget<LivingPass>(find.byType(LivingPass)).verified,
        isFalse,
      );

      repository.pending.completeError(
        const PhoneAuthFailure('invalid-verification-code'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(AuthErrorBanner), findsOneWidget);
      expect(
        tester.widget<LivingPass>(find.byType(LivingPass)).verified,
        isFalse,
      );
      final retry = tester.widget<AuthPrimaryButton>(
        find.byKey(const ValueKey('verify-phone-code')),
      );
      retry.onTap!();
      expect(repository.confirmCalls, 2);
      repository.pending.complete(
        const PhoneAuthSession(
          uid: 'verified-user',
          phoneNumber: '+237699123456',
          isNewUser: true,
          linkedToExistingUser: false,
        ),
      );
      await tester.pump();
      // Device QA round 3 : le numéro validé allume « 3 ». « 7 » attend
      // l'ouverture d'un espace, que ce test ne résout pas.
      expect(
        tester.widget<LivingPass>(find.byType(LivingPass)).seal,
        PassSealStage.secret,
      );
      expect(
        tester.widget<LivingPass>(find.byType(LivingPass)).phase,
        'NUMBER VERIFIED',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      // Délai de lecture du profil (8 s) laissé en suspens par ce test.
      await tester.pump(const Duration(seconds: 9));
    },
  );

  testWidgets(
    'phone and OTP remain usable at 320px with keyboard and 1.6x text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _PendingVerificationRepository();
      await tester.pumpWidget(_screen(repository, compact: true));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('phone-number-field')),
        '699123456',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('send-phone-code')));
      await tester.tap(find.byKey(const ValueKey('send-phone-code')));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.ensureVisible(find.byKey(const ValueKey('phone-otp-field')));
      await tester.enterText(
        find.byKey(const ValueKey('phone-otp-field')),
        '123',
      );
      expect(find.byType(TextFormField), findsOneWidget);
      expect(repository.confirmCalls, 0);
      // Le Pass cède la place dès que la hauteur manque : sans cela le
      // formulaire serait repoussé hors de portée.
      expect(
        tester.widget<LivingPass>(find.byType(LivingPass)).compact ||
            tester.getSize(find.byType(LivingPass)).height < 220,
        isTrue,
        reason: 'le Pass doit se réduire quand le clavier occupe l’écran',
      );

      // Sur un appareil, toucher ailleurs congédie d'abord la poignée de
      // sélection laissée par la saisie ; en test il faut le faire à la main,
      // sinon elle intercepte le toucher depuis l'Overlay.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.ensureVisible(find.text('Change phone number'));
      await tester.pump();
      await tester.tap(find.text('Change phone number'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(const ValueKey('phone-number-field')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}

Widget _screen(
  _PendingVerificationRepository repository, {
  bool compact = false,
}) => ProviderScope(
  // La lecture du profil ne répond jamais : l'écran reste sur la réussite
  // du numéro, sans espace à ouvrir.
  overrides: [
    phoneAuthRepositoryProvider.overrideWithValue(repository),
    authRepositoryProvider.overrideWithValue(_UnresolvedProfile()),
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
        size: compact ? const Size(320, 760) : const Size(800, 600),
        viewInsets: compact
            ? const EdgeInsets.only(bottom: 290)
            : EdgeInsets.zero,
        textScaler: TextScaler.linear(compact ? 1.6 : 1),
        disableAnimations: true,
      ),
      child: const PhoneAuthScreen(),
    ),
  ),
);

class _UnresolvedProfile implements AuthRepository, AuthSessionResolver {
  @override
  Future<AuthSessionResolution> resolveCurrentSession() =>
      Completer<AuthSessionResolution>().future;

  @override
  Future<AuthUserData?> getCurrentUser() async => null;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

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

class _PendingVerificationRepository implements PhoneAuthRepository {
  int confirmCalls = 0;
  late Completer<PhoneAuthSession> pending;

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
  }) {
    confirmCalls++;
    pending = Completer<PhoneAuthSession>();
    return pending.future;
  }
}
