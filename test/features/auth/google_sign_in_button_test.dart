import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/presentation/widgets/google_sign_in_button.dart';
import '../../support/intellia_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadIntelliaFonts);

  testWidgets(
    'GoogleSignInButton renders standard Google branding and dimensions',
    (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: GoogleSignInButton(onPressed: () => tapped = true),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GoogleSignInButton), findsOneWidget);
      expect(find.text('Continuer avec Google'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      // Height constraint must satisfy >= 48dp
      final buttonBox = tester.renderObject<RenderBox>(
        find.byKey(const Key('google-signin-button')),
      );
      expect(buttonBox.size.height, greaterThanOrEqualTo(48.0));

      // Tap action
      await tester.tap(find.byKey(const Key('google-signin-button')));
      await tester.pump();
      expect(tapped, isTrue);
    },
  );

  testWidgets(
    'GoogleSignInButton shows spinner when isLoading is true and ignores taps',
    (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GoogleSignInButton(
                isLoading: true,
                onPressed: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Continuer avec Google'), findsNothing);

      await tester.tap(find.byKey(const Key('google-signin-button')));
      await tester.pump();
      expect(tapped, isFalse);
    },
  );

  testWidgets('GoogleSignInButton has proper TalkBack semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: GoogleSignInButton(onPressed: () {})),
        ),
      ),
    );

    final semantics = tester.getSemantics(find.byType(GoogleSignInButton));
    expect(semantics.label, contains('Continuer avec Google'));
  });
}
