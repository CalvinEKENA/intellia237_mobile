import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/onboarding/presentation/onboarding_screen.dart';

void main() {
  testWidgets(
    'onboarding ouvre sur la 1re scène Web et masque « Commencer »',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            // disableAnimations : fige les boucles des visuels (pas de timers
            // en attente) pour un test déterministe.
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: OnboardingScreen(),
            ),
          ),
        ),
      );

      // Laisse jouer les entrées en cascade sans atteindre l'auto-défilement.
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('Quelques minutes par jour'), findsOneWidget);
      expect(find.text('Passer'), findsOneWidget);
      expect(find.text('Commencer'), findsNothing);

      expect(tester.takeException(), isNull);
    },
  );
}
