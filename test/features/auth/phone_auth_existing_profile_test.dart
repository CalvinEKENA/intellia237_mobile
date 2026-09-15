import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'package:intellia237/features/auth/presentation/widgets/pass_auth_progress.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un compte existant quitte l'OTP pour **son** espace — seulement si c'est
/// l'espace choisi à l'entrée.
///
/// Registre de décisions (QA appareil, round 2) : ce test décrivait l'ancien
/// contrat, « le rôle réel l'emporte toujours sur l'entrée choisie ». C'est
/// précisément ce qui menait un parent, entré avec le numéro d'un élève, dans
/// l'espace de cet élève. Sous une intention, un compte d'un autre rôle
/// n'ouvre plus rien : il reste sur l'écran, avec un conflit expliqué. L'accès
/// neutre (sans intention) garde le comportement historique.
void main() {
  // Même rôle que l'entrée : l'espace s'ouvre, ou son inscription reprend.
  for (final role in [AppRole.student, AppRole.parent]) {
    for (final completed in [false, true]) {
      testWidgets(
        '${role.name} entrance, ${role.name} account complete=$completed opens its space',
        (tester) async {
          final destination = completed
              ? role.homePath
              : role == AppRole.student
              ? AppRoutes.studentRegistration
              : AppRoutes.parentRegistration;
          final harness = await _pump(
            tester,
            intent: role,
            accountRole: role,
            completed: completed,
          );
          await harness.verifyPhone(tester);

          expect(harness.location, destination);
          expect(find.text(destination), findsOneWidget);
          expect(harness.repository.signOutCalls, 0);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  // Rôle différent de l'entrée : aucun espace, conflit expliqué, rôle intact.
  for (final (intent, accountRole, completed, title) in const [
    (
      AppRole.parent,
      AppRole.student,
      true,
      'Ce numéro est déjà associé à un compte élève.',
    ),
    (
      AppRole.parent,
      AppRole.student,
      false,
      'Ce numéro est déjà associé à un compte élève.',
    ),
    (
      AppRole.student,
      AppRole.parent,
      true,
      'Ce numéro est déjà associé à un compte parent.',
    ),
    (
      AppRole.parent,
      AppRole.teacher,
      true,
      'Ce numéro est déjà associé à un compte de l’établissement.',
    ),
    (
      AppRole.student,
      AppRole.teacher,
      true,
      'Ce numéro est déjà associé à un compte de l’établissement.',
    ),
  ]) {
    testWidgets(
      '${intent.name} entrance, ${accountRole.name} account complete=$completed stays with a conflict',
      (tester) async {
        final harness = await _pump(
          tester,
          intent: intent,
          accountRole: accountRole,
          completed: completed,
        );
        await harness.verifyPhone(tester);

        expect(harness.location, AppRoutes.phoneAuth);
        expect(
          find.byKey(const ValueKey('phone-role-conflict')),
          findsOneWidget,
        );
        expect(find.text(title), findsOneWidget);
        expect(
          find.text(
            intent == AppRole.parent
                ? 'Pour créer ou ouvrir un espace parent, utilisez les identifiants du parent.'
                : 'Pour ouvrir l’espace élève, utilisez les identifiants de l’élève.',
          ),
          findsOneWidget,
        );
        final container = ProviderScope.containerOf(
          tester.element(find.byType(PhoneAuthScreen)),
        );
        final auth = container.read(authControllerProvider);
        expect(auth.isAuthenticated, isFalse);
        expect(auth.role, isNull);
        expect(harness.repository.signOutCalls, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  // Accès neutre : le compte décide, comme avant.
  for (final role in AppRole.values.where((role) => role != AppRole.admin)) {
    testWidgets('neutral phone access, ${role.name} account opens its space', (
      tester,
    ) async {
      final harness = await _pump(
        tester,
        intent: null,
        accountRole: role,
        completed: true,
      );
      await harness.verifyPhone(tester);

      expect(harness.location, role.homePath);
      expect(harness.repository.signOutCalls, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

class _Harness {
  _Harness(this.router, this.repository);

  final GoRouter router;
  final _RestoredRepository repository;

  String get location => router.routeInformationProvider.value.uri.path;

  Future<void> verifyPhone(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const ValueKey('phone-number-field')),
      '699123456',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('send-phone-code')));
    await tester.tap(find.byKey(const ValueKey('send-phone-code')));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.enterText(
      find.byKey(const ValueKey('phone-otp-field')),
      '123456',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    // Device QA round 3 : l'espace s'ouvre après le sceau complet.
    await tester.pump(PassSealTiming.completionHold);
    await tester.pumpAndSettle();
  }
}

Future<_Harness> _pump(
  WidgetTester tester, {
  required AppRole? intent,
  required AppRole accountRole,
  required bool completed,
}) async {
  SharedPreferences.setMockInitialValues({});
  final router = GoRouter(
    initialLocation: intent == null
        ? AppRoutes.login
        : AppRoutes.phoneRegistration(intent),
    routes: [
      GoRoute(
        path: AppRoutes.phoneAuth,
        builder: (_, state) =>
            PhoneAuthScreen(authIntent: AppRoutes.entryIntentFrom(state.uri)),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const PhoneAuthScreen(),
      ),
      for (final path in [
        AppRoutes.authGateway,
        AppRoutes.register,
        AppRoutes.studentHome,
        AppRoutes.parentHome,
        AppRoutes.teacherHome,
        AppRoutes.adminHome,
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
  final repository = _RestoredRepository(accountRole, completed);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        phoneAuthRepositoryProvider.overrideWithValue(
          _VerifiedPhoneRepository(),
        ),
        authRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pump();
  return _Harness(router, repository);
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
  int signOutCalls = 0;

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
  Future<void> signOut() async => signOutCalls++;
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
