import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/ai_companion/presentation/ai_companion_screen.dart';
import 'package:intellia237/features/learn/application/learn_providers.dart';
import 'package:intellia237/features/learn/domain/learn_academic_context.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sur téléphone réel, ouvrir le clavier dans Compagnon produisait
/// « BOTTOM OVERFLOWED BY 1.7 PIXELS ».
///
/// L'onglet réserve une hauteur fixe pour la barre de navigation. Quand le
/// clavier réduit la zone utile, cette réserve reste due alors que la barre
/// est justement masquée : la colonne demande alors plus de place qu'il n'en
/// reste. Le composeur doit rester joignable, et les suggestions céder.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpCompanion(
    WidgetTester tester, {
    required Size size,
    double keyboard = 0,
    double textScale = 1.0,
  }) async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentAcademicContextProvider.overrideWith(
            (ref) async => const LearnAcademicContext(
              classLevel: '6eme',
              catalogClassLevel: '6eme',
              academicLevelId: 'fr_general_6e',
              tutorId: 'kira',
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(textScale),
              disableAnimations: true,
              viewInsets: EdgeInsets.only(bottom: keyboard),
            ),
            child: const Scaffold(body: AICompanionScreen(embedded: true)),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Tailles observées sur les appareils visés, en unités logiques.
  const sizes = <String, Size>{
    '320x568': Size(320, 568),
    '360x640': Size(360, 640),
    '390x844': Size(390, 844),
    '412x915': Size(412, 915),
    '360x740': Size(360, 740),
  };

  group('clavier fermé', () {
    for (final entry in sizes.entries) {
      testWidgets('aucun débordement à ${entry.key}', (tester) async {
        await pumpCompanion(tester, size: entry.value);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('clavier ouvert', () {
    for (final entry in sizes.entries) {
      testWidgets('aucun débordement à ${entry.key}', (tester) async {
        // Un clavier Android occupe couramment 40 % de la hauteur.
        await pumpCompanion(
          tester,
          size: entry.value,
          keyboard: entry.value.height * 0.42,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('le composeur reste au-dessus du clavier', (tester) async {
      const size = Size(360, 640);
      const keyboard = 280.0;
      await pumpCompanion(tester, size: size, keyboard: keyboard);

      expect(tester.takeException(), isNull);
      final field = find.byType(TextField);
      expect(field, findsOneWidget);
      final rect = tester.getRect(field);
      expect(
        rect.bottom,
        lessThanOrEqualTo(size.height - keyboard),
        reason: 'le champ de saisie doit rester visible au-dessus du clavier',
      );
    });
  });

  group('échelle de texte', () {
    for (final scale in const [1.0, 1.3, 2.0]) {
      testWidgets('aucun débordement à textScale $scale, clavier ouvert', (
        tester,
      ) async {
        await pumpCompanion(
          tester,
          size: const Size(360, 740),
          keyboard: 300,
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
