import 'package:flutter/material.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

/// Registre de décisions — l'accueil ne présente jamais :
/// - des chiffres (points, série, niveau) sans source réelle ;
/// - une carte « Reprendre » sans leçon réellement ouverte ;
/// - des matières fictives pointant vers des documents inexistants ;
/// - des données de démonstration sans bandeau explicite.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'base vide : expérience éditorialisée honnête, zéro donnée inventée',
    (tester) async {
      await _pumpHome(tester, _EmptyRepository());

      // État « contenu bientôt disponible » avec vraies portes de sortie.
      expect(find.text('Tes cours arrivent'), findsOneWidget);
      expect(find.text('Découvrir mon parcours'), findsOneWidget);
      expect(find.text('Parler à mon compagnon'), findsOneWidget);

      // Rien de factice : ni reprise, ni série, ni progression, ni défis.
      expect(find.text('Reprendre le dernier cours'), findsNothing);
      expect(find.text('Ma progression'), findsNothing);
      expect(find.textContaining('jour de série'), findsNothing);
      expect(find.textContaining('jours de série'), findsNothing);
      expect(find.text('Défis du jour'), findsNothing);
      expect(find.text('Données de démonstration'), findsNothing);

      // Les vraies fonctionnalités restent accessibles.
      expect(find.text('Mon parcours'), findsOneWidget);
      // L'objectif personnel (local) est proposé, jamais pré-rempli.
      expect(find.text('Fixe ton rythme de la semaine'), findsOneWidget);
      await _scrollTo(tester, find.text('Quiz rapide'));
      expect(find.text('Quiz rapide'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('mode démo : bandeau « Données de démonstration » visible', (
    tester,
  ) async {
    await _pumpHome(tester, DemoStudentHomeRepository());

    expect(find.text('Données de démonstration'), findsOneWidget);
    // Le contenu démo s'affiche (série, matières…) mais est étiqueté.
    expect(find.textContaining('de série'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  if (!tester.any(finder)) {
    await tester.scrollUntilVisible(
      finder,
      240,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.pump(const Duration(seconds: 1));
}

class _EmptyRepository implements StudentHomeRepository {
  @override
  Future<StudentHomeSnapshot> fetchHomeSnapshot({required String firstName}) {
    return Future.value(StudentHomeSnapshot(firstName: firstName));
  }
}

Future<void> _pumpHome(
  WidgetTester tester,
  StudentHomeRepository repository,
) async {
  SharedPreferences.setMockInitialValues(const {});
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.staging),
      authRepositoryProvider.overrideWithValue(_AuthRepository()),
      studentHomeRepositoryProvider.overrideWithValue(repository),
      studentAcademicContextProvider.overrideWith(
        (ref) async =>
            const LearnAcademicContext(classLevel: 'Terminale', series: 'D'),
      ),
      learnHubProvider.overrideWith(
        (ref) async => LearnHubSnapshot(
          context: const LearnAcademicContext(
            classLevel: 'Terminale',
            series: 'D',
          ),
          subjects: const [],
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
      GoRoute(
        path: AppRoutes.flow,
        builder: (_, _) => const Scaffold(body: Text('Flow destination')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: TickerMode(enabled: false, child: child!),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
  await tester.pumpAndSettle();
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
