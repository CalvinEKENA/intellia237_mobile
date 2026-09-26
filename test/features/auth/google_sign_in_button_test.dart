import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

import '../../support/intellia_fonts.dart';

/// Bouton « Continuer avec Google » : logo officiel fourni par Google (jamais
/// redessiné), couleurs et dimensions de la marque, accessibilité.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadIntelliaFonts);

  Future<void> pump(
    WidgetTester tester,
    Widget button, {
    Locale locale = const Locale('fr'),
  }) => tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Center(child: SizedBox(width: 360, child: button)),
      ),
    ),
  );

  testWidgets('shows the official Google "G" asset, never a painted copy', (
    tester,
  ) async {
    await pump(tester, GoogleSignInButton(onPressed: () {}));
    final logo = tester.widget<Image>(
      find.byKey(const Key('google-signin-logo')),
    );
    expect((logo.image as AssetImage).assetName, GoogleSignInButton.logoAsset);
    expect(logo.width, 18);
    expect(logo.height, 18);
    // Aucun logo peint : seuls les peintres du Material (encre) subsistent.
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint &&
            '${widget.painter.runtimeType}'.contains('Google'),
      ),
      findsNothing,
    );
    expect(
      File(
        'lib/features/auth/presentation/widgets/google_sign_in_button.dart',
      ).readAsStringSync(),
      isNot(contains('extends CustomPainter')),
    );
  });

  test('the asset files are the ones extracted from Google Play services', () {
    // Variantes 1× à 3×, tailles d'origine (voir
    // docs/branding/GOOGLE_G_LOGO_SOURCE.md).
    const expected = {
      'assets/branding/google/googleg_standard_color_18.png': 18,
      'assets/branding/google/1.5x/googleg_standard_color_18.png': 27,
      'assets/branding/google/2.0x/googleg_standard_color_18.png': 36,
      'assets/branding/google/3.0x/googleg_standard_color_18.png': 54,
    };
    for (final MapEntry(key: path, value: size) in expected.entries) {
      final bytes = File(path).readAsBytesSync();
      final header = ByteData.sublistView(bytes, 16, 24);
      expect(header.getUint32(0), size, reason: path);
      expect(header.getUint32(4), size, reason: path);
    }
    expect(File('docs/branding/GOOGLE_G_LOGO_SOURCE.md').existsSync(), isTrue);
  });

  testWidgets('follows the light-theme brand colours and a 48 dp target', (
    tester,
  ) async {
    await pump(tester, GoogleSignInButton(onPressed: () {}));
    final button = tester.widget<OutlinedButton>(
      find.byKey(const Key('google-signin-button')),
    );
    final style = button.style!;
    expect(
      style.backgroundColor!.resolve(const <WidgetState>{}),
      const Color(0xFFFFFFFF),
    );
    expect(
      style.side!.resolve(const <WidgetState>{})!.color,
      const Color(0xFF747775),
    );
    final label = tester.widget<Text>(find.text('Continuer avec Google'));
    expect(label.style!.color, const Color(0xFF1F1F1F));
    expect(label.style!.fontWeight, FontWeight.w500);
    expect(label.style!.fontSize, 14);
    expect(
      tester.getSize(find.byKey(const Key('google-signin-button'))).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('taps reach the action; loading ignores taps', (tester) async {
    var taps = 0;
    await pump(tester, GoogleSignInButton(onPressed: () => taps++));
    await tester.tap(find.byKey(const Key('google-signin-button')));
    expect(taps, 1);

    await pump(
      tester,
      GoogleSignInButton(isLoading: true, onPressed: () => taps++),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Connexion Google en cours'), findsOneWidget);
    await tester.tap(find.byKey(const Key('google-signin-button')));
    expect(taps, 1);
  });

  testWidgets('announces one TalkBack button, in French and English', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester, GoogleSignInButton(onPressed: () {}));
    expect(
      tester.getSemantics(find.byType(GoogleSignInButton)),
      matchesSemantics(
        label: 'Continuer avec Google',
        isButton: true,
        isEnabled: true,
        hasEnabledState: true,
      ),
    );
    await pump(
      tester,
      GoogleSignInButton(onPressed: () {}),
      locale: const Locale('en'),
    );
    expect(find.text('Continue with Google'), findsOneWidget);
    handle.dispose();
  });
}
