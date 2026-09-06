import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intellia237/app/config/app_config.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/repositories/auth_repository.dart';
import 'package:intellia237/features/learn/application/learn_providers.dart';
import 'package:intellia237/features/learn/domain/learn_academic_context.dart';
import 'package:intellia237/features/learn/domain/learn_hub_snapshot.dart';
import 'package:intellia237/features/quiz/application/quiz_providers.dart';
import 'package:intellia237/features/student_home/data/student_home_repository.dart';
import 'package:intellia237/features/student_home/domain/student_home_snapshot.dart';
import 'package:intellia237/features/student_home/presentation/student_home_screen.dart';
import 'package:intellia237/features/tour_guide/data/firestore_tour_guide_repository.dart';
import 'package:intellia237/features/tour_guide/data/tour_guide_repository.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Le compteur « TAPS n » est un outil de mise au point de la navigation.
/// Il ne doit jamais atteindre un élève : ni sur une fiche de magasin, ni
/// dans une compilation de production.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => debugShowNavTapCounter = kDebugMode);

  test('le compteur suit le mode debug par défaut', () {
    // En release, `kDebugMode` vaut faux : l'incrustation est donc absente
    // de l'AAB sans qu'aucun réglage ne soit nécessaire.
    expect(debugShowNavTapCounter, kDebugMode);
  });

  testWidgets('aucune incrustation de diagnostic quand le drapeau est levé', (
    tester,
  ) async {
    debugShowNavTapCounter = false;
    await _pumpHome(tester);

    expect(find.byKey(const ValueKey('student-nav-tap-counter')), findsNothing);
    expect(find.textContaining('TAPS'), findsNothing);
  });

  testWidgets('le compteur reste disponible pour le diagnostic', (
    tester,
  ) async {
    debugShowNavTapCounter = true;
    await _pumpHome(tester);

    expect(
      find.byKey(const ValueKey('student-nav-tap-counter')),
      findsOneWidget,
    );
  });
}

Future<void> _pumpHome(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(const {});
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.staging),
      authRepositoryProvider.overrideWithValue(_AuthRepository()),
      studentHomeRepositoryProvider.overrideWithValue(_HomeRepository()),
      studentAcademicContextProvider.overrideWith(
        (ref) async =>
            const LearnAcademicContext(classLevel: 'Terminale', series: 'D'),
      ),
      learnHubProvider.overrideWith(
        (ref) async => const LearnHubSnapshot(
          context: LearnAcademicContext(classLevel: 'Terminale', series: 'D'),
          subjects: [],
        ),
      ),
      quizHubProvider.overrideWith((ref) async => const []),
      tourGuideRepositoryProvider.overrideWithValue(_SeenTourRepository()),
    ],
  );
  addTearDown(container.dispose);
  container
      .read(authControllerProvider.notifier)
      .setAuthenticatedUser(
        role: AppRole.student,
        userId: 'student-test',
        email: 'student@example.com',
        firstName: 'Amina',
      );

  final router = GoRouter(
    initialLocation: AppRoutes.studentHome,
    routes: [
      GoRoute(
        path: AppRoutes.studentHome,
        builder: (_, _) => const StudentHomeScreen(),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: TickerMode(enabled: false, child: child!),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
}

class _HomeRepository implements StudentHomeRepository {
  @override
  Future<StudentHomeSnapshot> fetchHomeSnapshot({required String firstName}) =>
      Future.value(StudentHomeSnapshot(firstName: firstName));
}

class _AuthRepository implements AuthRepository {
  @override
  Future<AuthUserData?> getCurrentUser() async => null;

  @override
  Future<AuthUserData> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required AppRole role,
  }) => throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthUserData> signInWithEmail({
    required String email,
    required String password,
  }) => throw UnimplementedError();
}

class _SeenTourRepository implements TourGuideRepository {
  @override
  Future<bool> hasSeenTour(String uid) async => true;

  @override
  Future<void> markTourSeen(String uid) async {}
}
