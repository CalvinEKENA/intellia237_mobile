import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/repositories/auth_repository.dart';
import 'package:intellia237/features/bootstrap/presentation/bootstrap_screen.dart';
import 'package:intellia237/core/assets/intellia_assets.dart';

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
      .map(_assetName)
      .whereType<String>()
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

      expect(imageAssets(tester), contains(IntelliaBrandAssets.identityMaster));
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

    final activeAssets = imageAssets(tester);
    expect(activeAssets, contains(IntelliaBrandAssets.identityMaster));
    expect(
      activeAssets.where((asset) => asset.startsWith('assets/icons/')),
      isEmpty,
    );
  });
}

String? _assetName(ImageProvider<Object> provider) {
  if (provider is AssetImage) return provider.assetName;
  if (provider is ResizeImage) return _assetName(provider.imageProvider);
  return null;
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
