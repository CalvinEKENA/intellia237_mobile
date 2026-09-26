import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/auth/application/phone_auth_controller.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/presentation/forgot_password_screen.dart';
import 'package:intellia237/features/auth/presentation/login_screen.dart';
import 'package:intellia237/features/auth/presentation/widgets/pass_auth_progress.dart';
import 'package:intellia237/features/auth/presentation/phone_auth_screen.dart';
import 'package:intellia237/features/auth/presentation/account_welcome_screen.dart';
import 'package:intellia237/features/auth/presentation/auth_gateway_screen.dart';
import 'package:intellia237/features/parent_registration/presentation/parent_registration_screen.dart';
import 'package:intellia237/features/student_registration/presentation/student_registration_flow_screen.dart';
import 'package:intellia237/features/teacher_registration/presentation/teacher_registration_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../tool/onboarding_preview.dart';
import '../../tool/preview_auth_repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
    'preview opens the real neutral gateway and localizes the shell',
    (tester) async {
      await _pumpPreview(tester);
      expect(find.byType(AuthGatewayScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('gateway-phone-auth')), findsOneWidget);
      expect(find.byKey(const ValueKey('gateway-google-auth')), findsOneWidget);
      for (final role in ['student', 'parent', 'teacher']) {
        expect(find.byKey(ValueKey('pass-role-$role')), findsNothing);
      }
      expect(find.text('APERÇU · aucune donnée envoyée'), findsOneWidget);

      await _tap(tester, 'gateway-phone-auth');
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('phone-auth-language-selector')),
          matching: find.text('EN'),
        ),
      );
      await _settle(tester);
      expect(find.textContaining('PREVIEW · no data is sent'), findsOneWidget);
      expect(Firebase.apps, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  for (final role in [AppRole.student, AppRole.parent]) {
    testWidgets('demo OTP leads to the entry decision, then the real '
        '${role.name} registration', (tester) async {
      final memory = await _pumpPreview(tester);
      await _tap(tester, 'gateway-phone-auth');
      expect(find.byType(PhoneAuthScreen), findsOneWidget);
      expect(
        find.textContaining('Code démo : 123456 · aucun SMS'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('phone-number-field')),
        previewPhone,
      );
      await _tap(tester, 'send-phone-code');
      expect(find.byKey(const ValueKey('phone-otp-field')), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('phone-otp-field')),
        '000000',
      );
      await _tap(tester, 'verify-phone-code');
      final container = ProviderScope.containerOf(
        tester.element(find.byType(PhoneAuthScreen)),
      );
      expect(
        container.read(phoneAuthControllerProvider(false)).errorCode,
        'invalid-verification-code',
      );
      await tester.enterText(
        find.byKey(const ValueKey('phone-otp-field')),
        previewOtp,
      );
      await _tap(tester, 'verify-phone-code');
      await tester.pump(PassSealTiming.completionHold);
      await _settle(tester);
      expect(find.byType(AccountWelcomeScreen), findsOneWidget);

      await _tap(
        tester,
        role == AppRole.student ? 'welcome-student' : 'welcome-parent',
      );
      expect(
        role == AppRole.student
            ? find.byType(StudentRegistrationFlowScreen)
            : find.byType(ParentRegistrationScreen),
        findsOneWidget,
      );
      expect(memory.user, isNull);
      expect(Firebase.apps, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('staff entry renders the actual teacher registration', (
    tester,
  ) async {
    await _pumpPreview(tester);
    await _tap(tester, 'gateway-staff-login');
    await _tap(tester, 'login-create-account');
    expect(find.byType(TeacherRegistrationScreen), findsOneWidget);
    expect(Firebase.apps, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('gateway reaches real email login and reset confirmation', (
    tester,
  ) async {
    await _pumpPreview(tester, initialLocation: AppRoutes.authGateway);
    await _tap(tester, 'gateway-staff-login');
    expect(find.byType(LoginScreen), findsOneWidget);
    final reset = find.text('Mot de passe oublié ?');
    await tester.ensureVisible(reset);
    await tester.tap(reset);
    await _settle(tester);
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('reset-email-field')),
      previewEmail,
    );
    await _tap(tester, 'reset-submit');
    expect(find.byKey(const ValueKey('sent')), findsOneWidget);
    expect(find.byKey(const ValueKey('preview-auth-notice')), findsOneWidget);
    expect(Firebase.apps, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('known demo credentials reach only the local completion view', (
    tester,
  ) async {
    final memory = await _pumpPreview(
      tester,
      initialLocation: AppRoutes.emailLogin,
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-email-field')),
      previewEmail,
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password-field')),
      previewPassword,
    );
    await _tap(tester, 'login-submit');
    // Device QA round 3 : l'espace s'ouvre après le sceau complet.
    await tester.pump(PassSealTiming.completionHold);
    await _settle(tester);
    expect(
      find.byKey(const ValueKey('preview-complete-restart')),
      findsOneWidget,
    );
    expect(memory.user?.uid, startsWith('local-preview-'));
    expect(memory.teacherPending, isTrue);
    expect(Firebase.apps, isEmpty);
    expect(tester.takeException(), isNull);
  });
}

Future<PreviewAuthMemory> _pumpPreview(
  WidgetTester tester, {
  String initialLocation = AppRoutes.authGateway,
}) async {
  final memory = PreviewAuthMemory();
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: memory.overrides,
      child: OnboardingPreviewApp(
        memory: memory,
        initialLocation: initialLocation,
      ),
    ),
  );
  await _settle(tester);
  return memory;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pump(const Duration(milliseconds: 700));
}

Future<void> _tap(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await _settle(tester);
}
