import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/repositories/auth_repository.dart';
import 'package:intellia237/features/bootstrap/presentation/bootstrap_screen.dart';
import 'package:intellia237/features/bootstrap/presentation/widgets/intellia_typewriter.dart';

void main() {
  test('le nom s’écrit lettre à lettre, puis le pays après une pause', () {
    expect(SplashMotion.lettersAt(Duration.zero), 1);
    expect(SplashMotion.lettersAt(SplashMotion.letter * 3), 4);
    expect(
      SplashMotion.lettersAt(SplashMotion.letter * 40),
      SplashMotion.name.length,
    );

    // Rien du pays tant que la pause n’est pas passée : c’est elle qui sépare
    // le nom du drapeau.
    final lastLetter = SplashMotion.letter * SplashMotion.name.length;
    expect(SplashMotion.digitsAt(lastLetter), 0);
    expect(
      SplashMotion.digitsAt(lastLetter + SplashMotion.breath ~/ 2),
      0,
      reason: 'la pause doit rester silencieuse',
    );
    expect(SplashMotion.digitsAt(SplashMotion.numberStart), 1);
    expect(
      SplashMotion.digitsAt(SplashMotion.typed),
      SplashMotion.number.length,
    );

    // Le curseur accompagne la frappe et disparaît avec elle.
    expect(SplashMotion.caretAt(Duration.zero), isTrue);
    expect(SplashMotion.caretAt(SplashMotion.typed), isFalse);
    expect(SplashMotion.caretAt(SplashMotion.total), isFalse);

    // La sortie ne commence qu’après le temps de lecture.
    expect(SplashMotion.exitAt(SplashMotion.typed), 0);
    expect(SplashMotion.exitAt(SplashMotion.total), 1);
  });

  testWidgets('le pays porte les trois couleurs du drapeau', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IntelliaTypewriter(elapsed: Duration.zero, reduceMotion: true),
        ),
      ),
    );

    final spans = <InlineSpan>[];
    _wordmark(tester).textSpan!.visitChildren((span) {
      spans.add(span);
      return true;
    });
    final coloured = [
      for (final span in spans)
        if (span is TextSpan && span.text != null)
          (span.text!, span.style?.color),
    ];

    expect(coloured.first.$1, SplashMotion.name);
    expect(coloured.first.$2, isNull, reason: 'le nom garde l’encre du titre');
    expect(coloured.sublist(1), [
      ('2', SplashPalette.green),
      ('3', SplashPalette.red),
      ('7', SplashPalette.yellow),
    ]);
  });

  testWidgets('le splash tient le papier de l’onboarding, sans logo', (
    tester,
  ) async {
    await pumpSplash(tester);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, kSplashBackground);
    expect(scaffold.backgroundColor, const Color(0xFFF4EFE5));
    expect(scaffold.backgroundColor, isNot(const Color(0xFFFFFFFF)));

    // Plus aucune image : le nom est écrit, pas dessiné.
    expect(find.byType(Image), findsNothing);
    expect(find.text('by TECH MOTION'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('en mouvement réduit, le nom est là d’emblée', (tester) async {
    await pumpSplash(tester);

    expect(_wordmark(tester).textSpan!.toPlainText(), 'INTELLIA237');
  });

  testWidgets('la frappe se déroule avant que la route ne change', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: const MaterialApp(home: BootstrapScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    String written() => _wordmark(tester).textSpan!.toPlainText();

    expect(written().length, lessThan('INTELLIA237'.length));
    expect(written(), startsWith('I'));

    await tester.pump(SplashMotion.letter * SplashMotion.name.length);
    expect(written(), SplashMotion.name);

    await tester.pump(SplashMotion.breath + SplashMotion.digit * 3);
    expect(written(), 'INTELLIA237');

    await tester.pump(SplashMotion.hold + SplashMotion.exit);
    expect(tester.takeException(), isNull);
  });
}

/// Le gabarit invisible porte lui aussi un Text : seul le mot visible est
/// identifié.
Text _wordmark(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('splash-wordmark')));

Future<void> pumpSplash(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      ],
      child: const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: BootstrapScreen(),
        ),
      ),
    ),
  );
  await tester.pump();
}

class _FakeAuthRepository implements AuthRepository {
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
