import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/onboarding/domain/onboarding_slides.dart';
import 'package:intellia237/features/onboarding/presentation/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('onboarding contains four five-second scenes', () {
    expect(OnboardingSlides.slides, hasLength(4));
    expect(onboardingSlideDuration, const Duration(seconds: 5));
  });

  testWidgets('onboarding preserves the first Web scene and skip action', (
    tester,
  ) async {
    final router = await _pumpOnboarding(tester);
    addTearDown(router.dispose);

    expect(find.text('Quelques minutes par jour'), findsOneWidget);
    expect(find.text('Passer'), findsOneWidget);
    expect(find.text('Commencer'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('skip')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Connexion prête'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('onboarding pauses and resumes its five-second progression', (
    tester,
  ) async {
    final router = await _pumpOnboarding(tester);
    addTearDown(router.dispose);

    await tester.pump(const Duration(seconds: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Quelques minutes par jour'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3200));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Chaque matière devient plus claire'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Commencer appears only on the last scene and completes', (
    tester,
  ) async {
    final router = await _pumpOnboarding(tester);
    addTearDown(router.dispose);

    for (var index = 0; index < 3; index++) {
      await tester.tap(find.byKey(const ValueKey('onboarding-next')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
    }

    expect(find.text('Commencer'), findsOneWidget);
    expect(find.text('Passer'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('onboarding-start')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Connexion prête'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<GoRouter> _pumpOnboarding(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final router = GoRouter(
    initialLocation: AppRoutes.onboarding,
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const Scaffold(body: Text('Connexion prête')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
  return router;
}
