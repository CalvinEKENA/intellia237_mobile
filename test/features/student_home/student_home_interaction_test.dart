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
import 'package:intellia237/features/learn/domain/learn_subject.dart';
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

  testWidgets('only the active student tab is painted and interactive', (
    tester,
  ) async {
    await _pumpHome(tester, size: const Size(390, 844));

    expect(find.byType(IndexedStack), findsOneWidget);
    for (var activeIndex = 0; activeIndex < _tabCases.length; activeIndex++) {
      if (activeIndex > 0) {
        await _tapNav(tester, _tabCases[activeIndex].navLabel);
      }

      for (var index = 0; index < _tabCases.length; index++) {
        final tab = _tabCases[index];
        final active = index == activeIndex;
        final visibleRoot = find.byKey(ValueKey(tab.rootKey));
        final mountedRoot = find.byKey(
          ValueKey(tab.rootKey),
          skipOffstage: false,
        );

        expect(visibleRoot, active ? findsOneWidget : findsNothing);
        expect(mountedRoot, findsOneWidget);
        expect(
          tester
              .widget<TickerMode>(
                find.byKey(
                  ValueKey('student-tab-ticker-$index'),
                  skipOffstage: false,
                ),
              )
              .enabled,
          active,
        );
        expect(
          tester
              .widget<ExcludeSemantics>(
                find.byKey(
                  ValueKey('student-tab-semantics-$index'),
                  skipOffstage: false,
                ),
              )
              .excluding,
          !active,
        );
        final focusScope = tester.widget<FocusScope>(
          find.byKey(ValueKey('student-tab-focus-$index'), skipOffstage: false),
        );
        expect(focusScope.canRequestFocus, active);
        expect(focusScope.skipTraversal, !active);
        expect(focusScope.descendantsAreFocusable, active);
        expect(
          tester
              .widget<IgnorePointer>(
                find.byKey(
                  ValueKey('student-tab-pointer-$index'),
                  skipOffstage: false,
                ),
              )
              .ignoring,
          !active,
        );
      }

      expect(find.text(_tabCases[activeIndex].contentMarker), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('tab switches stay exclusive at the former animation midpoint', (
    tester,
  ) async {
    await _pumpHome(tester, size: const Size(390, 844));

    for (var nextIndex = 1; nextIndex < _tabCases.length; nextIndex++) {
      final previousIndex = nextIndex - 1;
      await tester.tapAt(
        tester.getCenter(find.text(_tabCases[nextIndex].navLabel).last),
      );
      await tester.pump(const Duration(milliseconds: 120));

      expect(
        find.byKey(ValueKey(_tabCases[previousIndex].rootKey)),
        findsNothing,
      );
      expect(
        find.byKey(ValueKey(_tabCases[nextIndex].rootKey)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }

    await tester.tapAt(tester.getCenter(find.text('Accueil').last));
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byKey(const ValueKey('student-tab-profile')), findsNothing);
    expect(find.byKey(const ValueKey('student-tab-home')), findsOneWidget);
  });

  for (final interval in const [20, 50, 100]) {
    testWidgets('rapid tab taps at ${interval}ms settle on the last request', (
      tester,
    ) async {
      await _pumpHome(tester, size: const Size(390, 844));

      for (final tab in _tabCases.skip(1)) {
        await tester.tapAt(tester.getCenter(find.text(tab.navLabel).last));
        await tester.pump(Duration(milliseconds: interval));
      }
      await tester.tapAt(tester.getCenter(find.text('Accueil').last));
      await tester.pump(Duration(milliseconds: interval));
      await tester.tapAt(tester.getCenter(find.text('Accueil').last));
      await tester.pump(Duration(milliseconds: interval));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('student-tab-home')), findsOneWidget);
      for (final tab in _tabCases.skip(1)) {
        expect(find.byKey(ValueKey(tab.rootKey)), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('hidden student tabs are absent from the active hit-test path', (
    tester,
  ) async {
    await _pumpHome(tester, size: const Size(390, 844));
    await _tapNav(tester, 'Quiz');

    final activeFinder = find.byKey(const ValueKey('student-tab-quiz'));
    final activeRenderObject = tester.renderObject(activeFinder);
    final path = tester
        .hitTestOnBinding(tester.getCenter(activeFinder))
        .path
        .map((entry) => entry.target)
        .toList();

    expect(path, contains(activeRenderObject));
    for (final tab in _tabCases.where(
      (tab) => tab.rootKey != 'student-tab-quiz',
    )) {
      final hiddenRenderObject = tester.renderObject(
        find.byKey(ValueKey(tab.rootKey), skipOffstage: false),
      );
      expect(path, isNot(contains(hiddenRenderObject)));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('learn and companion state survives tab changes', (tester) async {
    await _pumpHome(tester, size: const Size(390, 844));
    await _tapNav(tester, 'Apprendre');

    final learnRoot = find.byKey(const ValueKey('student-tab-learn'));
    final learnSearch = find.descendant(
      of: learnRoot,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Rechercher une matière…',
      ),
    );
    await tester.enterText(learnSearch, 'Matière');
    await tester.pump();
    final learnEditable = find.descendant(
      of: learnSearch,
      matching: find.byType(EditableText),
    );
    expect(
      tester.widget<EditableText>(learnEditable).focusNode.hasFocus,
      isTrue,
    );

    final learnScrollView = find.descendant(
      of: learnRoot,
      matching: find.byType(CustomScrollView),
    );
    await tester.drag(learnScrollView, const Offset(0, -320));
    await tester.pump();
    final learnScrollable = find
        .descendant(of: learnRoot, matching: find.byType(Scrollable))
        .first;
    final scrollBefore = tester
        .state<ScrollableState>(learnScrollable)
        .position
        .pixels;
    expect(scrollBefore, greaterThan(0));

    await _tapNav(tester, 'Compagnon');
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(
                const ValueKey('student-tab-learn'),
                skipOffstage: false,
              ),
              matching: find.byType(EditableText, skipOffstage: false),
            ),
          )
          .focusNode
          .hasFocus,
      isFalse,
    );
    final companionInput = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Écris ta question…',
    );
    await tester.enterText(companionInput, 'Brouillon conservé');
    await tester.pump();
    final companionEditable = find.descendant(
      of: companionInput,
      matching: find.byType(EditableText),
    );
    expect(
      tester.widget<EditableText>(companionEditable).focusNode.hasFocus,
      isTrue,
    );
    await _tapNav(tester, 'Profil');
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(
                const ValueKey('student-tab-companion'),
                skipOffstage: false,
              ),
              matching: find.byType(EditableText, skipOffstage: false),
            ),
          )
          .focusNode
          .hasFocus,
      isFalse,
    );
    await _tapNav(tester, 'Compagnon');
    expect(
      tester.widget<TextField>(companionInput).controller?.text,
      'Brouillon conservé',
    );

    await _tapNav(tester, 'Apprendre');
    expect(tester.widget<TextField>(learnSearch).controller?.text, 'Matière');
    final scrollAfter = tester
        .state<ScrollableState>(learnScrollable)
        .position
        .pixels;
    expect(scrollAfter, closeTo(scrollBefore, 1));
    expect(tester.takeException(), isNull);
  });

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
        (ref) async => LearnHubSnapshot(
          context: const LearnAcademicContext(
            classLevel: 'Terminale',
            series: 'D',
          ),
          subjects: [
            for (var index = 0; index < 16; index++)
              LearnSubject(
                id: 'subject-$index',
                title: 'Matière $index',
                description: 'Description $index',
                colorHex: 0xFF1451E1,
                iconKey: 'math',
                chapters: const [],
              ),
          ],
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

class _TabCase {
  const _TabCase(this.navLabel, this.rootKey, this.contentMarker);

  final String navLabel;
  final String rootKey;
  final String contentMarker;
}

const _tabCases = [
  _TabCase('Accueil', 'student-tab-home', 'Reprendre le dernier cours'),
  _TabCase('Apprendre', 'student-tab-learn', 'Parcours personnalisé'),
  _TabCase('Quiz', 'student-tab-quiz', 'Prêt à relever un défi ?'),
  _TabCase('Compagnon', 'student-tab-companion', 'Explique ce concept'),
  _TabCase('Profil', 'student-tab-profile', 'Mon profil'),
];
