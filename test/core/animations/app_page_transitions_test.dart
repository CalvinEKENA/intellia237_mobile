import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/theme/design_tokens.dart';
import 'package:intellia237/core/animations/app_page_transitions.dart';
import 'package:intellia237/core/widgets/intellia_loading_surface.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

void main() {
  testWidgets(
    'successful navigation paints branded home transition on its first frame',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: buildAppTransitionFrame(
            animation: const AlwaysStoppedAnimation<double>(0),
            transitionBackground: const IntelliaLoadingSurface(),
            child: const Scaffold(body: Text('Student home')),
          ),
        ),
      );

      final surface = tester.widget<ColoredBox>(
        find.byKey(const Key('intellia-loading-surface')),
      );
      expect(surface.color, IntelliaColors.backgroundPrimary);
      expect(
        find.byKey(const Key('intellia-loading-identity')),
        findsOneWidget,
      );
      expect(find.text('Préparation de ton espace…'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: buildAppTransitionFrame(
            animation: const AlwaysStoppedAnimation<double>(1),
            transitionBackground: const IntelliaLoadingSurface(),
            child: const Scaffold(body: Text('Student home')),
          ),
        ),
      );
      expect(find.text('Student home'), findsOneWidget);
      expect(find.byKey(const Key('intellia-loading-surface')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('branded loading copy is localized in English', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: IntelliaLoadingSurface(),
      ),
    );

    expect(find.text('Preparing your space…'), findsOneWidget);
    expect(find.byKey(const Key('intellia-loading-identity')), findsOneWidget);
  });
}
