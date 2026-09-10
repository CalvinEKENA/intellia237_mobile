import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/data/repositories/firebase_phone_auth_repository.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/repositories/auth_repository.dart';
import 'package:intellia237/features/auth/domain/repositories/phone_auth_repository.dart';
import 'package:intellia237/features/auth/presentation/phone_auth_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final role in [AppRole.student, AppRole.parent, AppRole.teacher]) {
    for (final completed in role == AppRole.teacher ? [true] : [false, true]) {
      testWidgets(
        'existing ${role.name}, complete=$completed leaves OTP for its actual space',
        (tester) async {
          SharedPreferences.setMockInitialValues({});
          final destination = completed
              ? role.homePath
              : role == AppRole.student
              ? AppRoutes.studentRegistration
              : AppRoutes.parentRegistration;
          final router = GoRouter(
            initialLocation: AppRoutes.phoneAuth,
            routes: [
              GoRoute(
                path: AppRoutes.phoneAuth,
                builder: (_, _) => PhoneAuthScreen(
                  registrationRole: role == AppRole.parent
                      ? AppRole.student
                      : AppRole.parent,
                ),
              ),
              for (final path in [
                AppRoutes.studentHome,
                AppRoutes.parentHome,
                AppRoutes.teacherHome,
                AppRoutes.studentRegistration,
                AppRoutes.parentRegistration,
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
                phoneAuthRepositoryProvider.overrideWithValue(
                  _VerifiedPhoneRepository(),
                ),
                authRepositoryProvider.overrideWithValue(
                  _RestoredRepository(role, completed),
                ),
              ],
              child: MaterialApp.router(
                routerConfig: router,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(disableAnimations: true),
                  child: child!,
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.enterText(
            find.byKey(const ValueKey('phone-number-field')),
            '699123456',
          );
          await tester.ensureVisible(
            find.byKey(const ValueKey('send-phone-code')),
          );
          await tester.tap(find.byKey(const ValueKey('send-phone-code')));
          await tester.pump(const Duration(milliseconds: 250));
          await tester.enterText(
            find.byKey(const ValueKey('phone-otp-field')),
            '123456',
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          await tester.pumpAndSettle();
          expect(router.routeInformationProvider.value.uri.path, destination);
          expect(find.text(destination), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
}

class _VerifiedPhoneRepository implements PhoneAuthRepository {
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
    uid: 'real-account',
    phoneNumber: '+237699123456',
    isNewUser: false,
    linkedToExistingUser: false,
  );
}

class _RestoredRepository implements AuthRepository {
  _RestoredRepository(this.role, this.completed);
  final AppRole role;
  final bool completed;
  @override
  Future<AuthUserData?> getCurrentUser() async => AuthUserData(
    uid: 'real-account',
    email: 'existing@example.com',
    role: role,
    firstName: 'Amina',
    lastName: 'Ndi',
    profileCompleted: completed,
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
