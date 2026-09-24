import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intellia237/features/parent/presentation/widgets/parent_guide.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guide de l'espace parent (retour propriétaire, 24/09/2026).
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  Future<BuildContext> host(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late BuildContext captured;
    await tester.pumpWidget(
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
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Builder(
          builder: (context) {
            captured = context;
            return const Scaffold();
          },
        ),
      ),
    );
    return captured;
  }

  testWidgets('six steps name the real places to tap, then close', (
    tester,
  ) async {
    final context = await host(tester);
    ParentGuide.show(context);
    await tester.pumpAndSettle();

    expect(find.text('ÉTAPE 1 SUR 6'), findsOneWidget);
    expect(find.text('Bienvenue dans votre espace parent'), findsOneWidget);
    for (final title in const [
      'Ajouter un enfant',
      'Il a déjà un compte : le code parent',
      'Pas encore de compte : le code d’accès',
      'Votre enfant utilise ce téléphone',
      'Retrouver ce guide',
    ]) {
      await tester.tap(find.byKey(ParentGuide.nextKey));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('ÉTAPE 6 SUR 6'), findsOneWidget);
    expect(find.byKey(ParentGuide.skipKey), findsNothing);
    expect(find.text('C’est compris'), findsOneWidget);

    await tester.tap(find.byKey(ParentGuide.nextKey));
    await tester.pumpAndSettle();
    expect(find.byKey(ParentGuide.sheetKey), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens by itself only the first time on this device', (
    tester,
  ) async {
    final context = await host(tester);
    final first = ParentGuide.maybeShowOnce(context, 'parent-a');
    await tester.pumpAndSettle();
    expect(find.byKey(ParentGuide.sheetKey), findsOneWidget);
    await tester.tap(find.byKey(ParentGuide.skipKey));
    await tester.pumpAndSettle();
    await first;

    ParentGuide.maybeShowOnce(context, 'parent-a');
    await tester.pumpAndSettle();
    expect(find.byKey(ParentGuide.sheetKey), findsNothing);

    // Un autre parent sur le même téléphone le voit à son tour.
    ParentGuide.maybeShowOnce(context, 'parent-b');
    await tester.pumpAndSettle();
    expect(find.byKey(ParentGuide.sheetKey), findsOneWidget);
  });

  testWidgets('small phone, large text: every step fits without error', (
    tester,
  ) async {
    final context = await host(
      tester,
      size: const Size(320, 568),
      textScale: 1.5,
    );
    ParentGuide.show(context);
    await tester.pumpAndSettle();
    for (var i = 0; i < 5; i++) {
      expect(tester.takeException(), isNull, reason: 'step ${i + 1}');
      await tester.tap(find.byKey(ParentGuide.nextKey));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
}
