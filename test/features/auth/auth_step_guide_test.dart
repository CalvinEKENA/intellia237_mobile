import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/presentation/widgets/auth_step_guide.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

/// Le fil de l'inscription (QA appareil, 23/09/2026) : à chaque étape, le
/// parent lit pourquoi il la fait et ce qui vient ensuite.
void main() {
  const labels = ['Identité parent', 'Liaison enfants', 'Validation finale'];
  const hints = ['Conseil identité.', 'Conseil liaison.', 'Conseil final.'];

  Future<void> pump(WidgetTester tester, int step, {bool reduced = false}) =>
      tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: child!,
          ),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: AuthStepGuide(
                currentStep: step,
                labels: labels,
                hints: hints,
              ),
            ),
          ),
        ),
      );

  testWidgets('says why this step matters and what comes next', (tester) async {
    await pump(tester, 0);
    await tester.pumpAndSettle();
    expect(find.text('Conseil identité.'), findsOneWidget);
    expect(find.text('Ensuite : Liaison enfants'), findsOneWidget);

    await pump(tester, 1);
    await tester.pumpAndSettle();
    expect(find.text('Conseil liaison.'), findsOneWidget);
    expect(find.text('Ensuite : Validation finale'), findsOneWidget);
    expect(find.text('Conseil identité.'), findsNothing);

    await pump(tester, 2);
    await tester.pumpAndSettle();
    expect(find.text('Conseil final.'), findsOneWidget);
    expect(find.text('Dernière étape'), findsOneWidget);
  });

  testWidgets('the ink stroke is drawn up to the current step', (tester) async {
    await pump(tester, 0);
    await tester.pumpAndSettle();
    final track = tester.getSize(find.byKey(AuthStepGuide.guideKey)).width;
    final first = tester
        .getSize(find.byKey(const ValueKey('registration-guide-ink')))
        .width;

    await pump(tester, 1);
    await tester.pump(const Duration(milliseconds: 60));
    final moving = tester
        .getSize(find.byKey(const ValueKey('registration-guide-ink')))
        .width;
    await tester.pumpAndSettle();
    final second = tester
        .getSize(find.byKey(const ValueKey('registration-guide-ink')))
        .width;

    expect(first, lessThan(track));
    expect(moving, greaterThan(first));
    expect(moving, lessThan(second));
    expect(second, closeTo(first * 2, 1));
  });

  testWidgets('reduced motion: the new hint is in place at once', (
    tester,
  ) async {
    await pump(tester, 0, reduced: true);
    await pump(tester, 1, reduced: true);
    await tester.pump();
    expect(find.text('Conseil liaison.'), findsOneWidget);
    expect(find.text('Conseil identité.'), findsNothing);
  });

  testWidgets('one announcement for screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, 1);
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Conseil liaison. Ensuite : Validation finale'),
      findsOneWidget,
    );
    semantics.dispose();
  });
}
