import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/repositories/auth_repository.dart';
import 'package:intellia237/features/bootstrap/presentation/bootstrap_screen.dart';

void main() {
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

  Set<String> imageAssets(WidgetTester tester) => tester
      .widgetList<Image>(find.byType(Image))
      .map((image) => image.image)
      .whereType<AssetImage>()
      .map((asset) => asset.assetName)
      .toSet();

  testWidgets(
    'le splash démarre sur le fond non blanc (aucune frame blanche)',
    (tester) async {
      await pumpSplash(tester);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, kSplashBackground);
      expect(scaffold.backgroundColor, isNot(const Color(0xFFFFFFFF)));
    },
  );

  testWidgets(
    'le splash affiche le logo officiel, la tagline et la signature',
    (tester) async {
      await pumpSplash(tester);

      expect(imageAssets(tester), contains('assets/icons/icone_final.png'));
      expect(
        find.text('Apprends avec quelqu’un qui te comprend.'),
        findsOneWidget,
      );
      expect(find.text('by TECH MOTION'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('le splash n’utilise que le logo officiel', (tester) async {
    await pumpSplash(tester);

    // Parmi les logos sous assets/icons/, seul le logo officiel est utilisé —
    // aucun logo hérité (assets/icons/logo.png, etc.).
    final iconAssets = imageAssets(
      tester,
    ).where((a) => a.startsWith('assets/icons/')).toSet();
    expect(iconAssets, everyElement('assets/icons/icone_final.png'));
    expect(iconAssets, isNot(contains('assets/icons/logo.png')));
  });
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
