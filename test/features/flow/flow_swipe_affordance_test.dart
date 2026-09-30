import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/flow/presentation/widgets/flow_swipe_affordance.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

Future<void> _pump(
  WidgetTester tester, {
  required bool prominent,
  required Locale locale,
  bool reduceMotion = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(
          body: Stack(children: [FlowSwipeAffordance(prominent: prominent)]),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// L'invite anime en boucle (bob doux). On dispose l'arbre en fin de test pour
/// ne pas laisser d'animation en suspens (comme la matrice typographique).
Future<void> _settle(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void main() {
  testWidgets('prominent affordance shows localized helper text (FR)', (
    tester,
  ) async {
    await _pump(tester, prominent: true, locale: const Locale('fr'));
    expect(find.text('Balaie vers le haut pour continuer'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _settle(tester);
  });

  testWidgets('prominent affordance shows localized helper text (EN)', (
    tester,
  ) async {
    await _pump(tester, prominent: true, locale: const Locale('en'));
    expect(find.text('Swipe up to continue'), findsOneWidget);
    await _settle(tester);
  });

  testWidgets('minimal affordance drops the text but keeps a directional cue', (
    tester,
  ) async {
    await _pump(tester, prominent: false, locale: const Locale('fr'));
    expect(find.text('Balaie vers le haut pour continuer'), findsNothing);
    expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);
    await _settle(tester);
  });

  testWidgets('reduced motion renders a static cue without exception', (
    tester,
  ) async {
    await _pump(
      tester,
      prominent: true,
      locale: const Locale('en'),
      reduceMotion: true,
    );
    expect(find.text('Swipe up to continue'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    await _settle(tester);
  });
}
