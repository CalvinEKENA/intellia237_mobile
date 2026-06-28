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
import 'package:intellia237/features/student_home/presentation/widgets/quick_access_panel.dart';
import 'package:intellia237/features/student_home/presentation/widgets/student_home_header.dart';
import 'package:intellia237/features/tour_guide/data/firestore_tour_guide_repository.dart';
import 'package:intellia237/features/tour_guide/data/tour_guide_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('real taps switch all five StudentHomeScreen tabs', (
    tester,
  ) async {
    await _pumpHome(tester, size: const Size(390, 844));

    final headerRect = tester.getRect(find.byType(StudentHomeHeader));
    await tester.tapAt(Offset(headerRect.right - 26, headerRect.center.dy));
    await tester.pumpAndSettle();
    expect(find.text('Mon profil'), findsOneWidget);
    await _tapNav(tester, 'Accueil');

    expect(find.text('Reprendre le dernier cours'), findsOneWidget);
    expect(find.bySemanticsLabel('TourGuide'), findsNothing);

    final learnTarget = tester.getCenter(find.text('Apprendre').last);
    final hitPath = tester
        .hitTestOnBinding(learnTarget)
        .path
        .map((entry) => entry.target.runtimeType.toString())
        .toList();
    debugPrint('[INTELLIA][HIT-TEST] $hitPath');
    final listenerIndex = hitPath.indexOf('RenderPointerListener');
    final scaffoldIndex = hitPath.indexOf('RenderCustomMultiChildLayoutBox');
    expect(listenerIndex, greaterThanOrEqualTo(0));
    expect(scaffoldIndex, greaterThan(listenerIndex));

    await _tapNav(tester, 'Apprendre');
    expect(find.text('Parcours personnalisé'), findsOneWidget);
    await _tapNav(tester, 'Quiz');
    expect(find.text('Prêt à relever un défi ?'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Reprendre le dernier cours'), findsOneWidget);
    await _tapNav(tester, 'Compagnon');
    expect(find.text('Explique ce concept'), findsOneWidget);
    await _tapNav(tester, 'Profil');
    expect(find.text('Mon profil'), findsOneWidget);
    await _tapNav(tester, 'Accueil');
    expect(find.text('Reprendre le dernier cours'), findsOneWidget);

    expect(find.text('TAPS 6'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in const [Size(360, 800), Size(390, 844), Size(430, 932)]) {
    testWidgets(
      'navbar stays tappable at ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await _pumpHome(tester, size: size, textScale: 1.3, bottomPadding: 34);

        await _tapNav(tester, 'Apprendre');
        expect(find.text('Parcours personnalisé'), findsOneWidget);
        await _tapNav(tester, 'Profil');
        expect(find.text('Mon profil'), findsOneWidget);
        expect(find.bySemanticsLabel('TourGuide'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('student homepage cards expose real destinations', (
    tester,
  ) async {
    await _pumpHome(tester, size: const Size(390, 844));

    await tester.ensureVisible(find.text('Flow'));
    await tester.tap(find.text('Flow'));
    await tester.pumpAndSettle();
    expect(find.text('Flow destination'), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    await _resetHomeScroll(tester);

    await _scrollHomeTo(tester, find.text('Mathématiques'));
    await tester.tap(find.text('Mathématiques'));
    await tester.pumpAndSettle();
    expect(find.text('Matière math'), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    await _resetHomeScroll(tester);

    await _scrollHomeTo(tester, find.text('Continuer'));
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(find.text('Parcours personnalisé'), findsOneWidget);
    await _tapNav(tester, 'Accueil');

    await _scrollHomeTo(tester, find.text('Quiz rapide'));
    await tester.tap(find.text('Quiz rapide'));
    await tester.pumpAndSettle();
    expect(find.text('Prêt à relever un défi ?'), findsOneWidget);
    await _tapNav(tester, 'Accueil');

    await _scrollHomeTo(tester, find.text('Quiz rapide'));
    final quickCompanion = find.descendant(
      of: find.byType(QuickAccessPanel),
      matching: find.text('Compagnon'),
    );
    await tester.tap(quickCompanion);
    await tester.pumpAndSettle();
    expect(find.text('Explique ce concept'), findsOneWidget);
    await _tapNav(tester, 'Accueil');

    await _scrollHomeTo(tester, find.text('Équations du premier degré'));
    await tester.tap(find.text('Équations du premier degré'));
    await tester.pumpAndSettle();
    expect(find.text('Parcours personnalisé'), findsOneWidget);
    await _tapNav(tester, 'Accueil');

    await _scrollHomeTo(tester, find.text('Terminer un quiz'));
    await tester.tap(find.text('Terminer un quiz'));
    await tester.pumpAndSettle();
    expect(find.text('Prêt à relever un défi ?'), findsOneWidget);
    await _tapNav(tester, 'Accueil');

    await _scrollHomeTo(tester, find.text('Ma progression'));
    await tester.tap(find.text('Ma progression'));
    await tester.pumpAndSettle();
    expect(find.text('Mon profil'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required Size size,
  double textScale = 1,
  double bottomPadding = 0,
}) async {
  SharedPreferences.setMockInitialValues(const {});
  tester.view.physicalSize = size;
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
      tourGuideRepositoryProvider.overrideWithValue(_UnseenTourRepository()),
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
      GoRoute(
        path: AppRoutes.learnSubjectRoute,
        builder: (_, state) => Scaffold(
          body: Text('Matière ${state.pathParameters['subjectId']}'),
        ),
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
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            padding: EdgeInsets.only(bottom: bottomPadding),
            disableAnimations: true,
          ),
          child: TickerMode(enabled: false, child: child!),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
  await tester.pumpAndSettle();
}

Future<void> _tapNav(WidgetTester tester, String label) async {
  await tester.tapAt(tester.getCenter(find.text(label).last));
  await tester.pump();
  await tester.pumpAndSettle();
}

Future<void> _resetHomeScroll(WidgetTester tester) async {
  final state = tester.state<ScrollableState>(find.byType(Scrollable).first);
  state.position.jumpTo(0);
  await tester.pump();
}

Future<void> _scrollHomeTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    240,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
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

class _HomeRepository implements StudentHomeRepository {
  @override
  Future<StudentHomeSnapshot> fetchHomeSnapshot({required String firstName}) {
    return Future.value(
      StudentHomeSnapshot(
        firstName: firstName,
        streakDays: 7,
        motivationText: 'Continue comme ça.',
        lastCourseTitle: 'Fonctions affines',
        lastCourseChapter: 'Chapitre 3',
        lastCourseProgress: 0.64,
        subjects: const [
          SubjectOverview(
            id: 'math',
            title: 'Mathématiques',
            progress: 0.71,
            colorHex: 0xFF1451E1,
          ),
        ],
        recommendations: const [
          RecommendationItem(
            title: 'Équations du premier degré',
            subtitle: 'Renforcer les acquis',
            estimatedMinutes: 18,
          ),
        ],
        challenges: const [
          DailyChallengeItem(
            title: 'Terminer un quiz',
            rewardXp: 35,
            completed: false,
          ),
        ],
        globalProgress: 0.58,
        level: 12,
        currentXp: 1840,
      ),
    );
  }
}

class _UnseenTourRepository implements TourGuideRepository {
  @override
  Future<bool> hasSeenTour(String uid) async => false;

  @override
  Future<void> markTourSeen(String uid) async {}
}
