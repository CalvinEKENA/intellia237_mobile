import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/repositories/auth_repository.dart';
import 'package:intellia237/features/auth/presentation/widgets/auth_success_screen.dart';
import 'package:intellia237/features/student_registration/application/student_registration_controller.dart';
import 'package:intellia237/features/student_registration/data/firebase_student_registration_repository.dart';
import 'package:intellia237/features/student_registration/data/student_registration_repository.dart';
import 'package:intellia237/features/student_registration/domain/academic_rules.dart';
import 'package:intellia237/features/student_registration/domain/student_registration_payload.dart';
import 'package:intellia237/features/student_registration/domain/student_registration_result.dart';
import 'package:intellia237/features/student_registration/presentation/student_registration_flow_screen.dart';

void main() {
  Future<void> pumpSuccess(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    bool reduceMotion = false,
    String asset = 'assets/companions/kira.png',
    String companionName = 'Kira',
    VoidCallback? onContinue,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size, disableAnimations: reduceMotion),
          child: AuthSuccessScreen(
            firstName: 'Amina',
            companionName: companionName,
            companionAsset: asset,
            onContinue: onContinue ?? () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void expectCoreContent() {
    expect(find.text('Bienvenue, Amina !'), findsOneWidget);
    expect(find.textContaining('Ton compte est prêt'), findsOneWidget);
    expect(find.text('Découvrir INTELLIA237'), findsOneWidget);
  }

  testWidgets('1. rendu normal sans exception', (tester) async {
    await pumpSuccess(tester);
    expectCoreContent();
    expect(tester.takeException(), isNull);
  });

  testWidgets('2. largeur 320', (tester) async {
    await pumpSuccess(tester, size: const Size(320, 720));
    expectCoreContent();
    expect(tester.takeException(), isNull);
  });

  testWidgets('3. hauteur 640 (petite hauteur, scroll)', (tester) async {
    await pumpSuccess(tester, size: const Size(360, 640));
    expectCoreContent();
    expect(tester.takeException(), isNull);
  });

  testWidgets('4. 430 x 932', (tester) async {
    await pumpSuccess(tester, size: const Size(430, 932));
    expectCoreContent();
    expect(tester.takeException(), isNull);
  });

  testWidgets('5. reduced-motion : badge visible, aucune exception', (
    tester,
  ) async {
    await pumpSuccess(tester, reduceMotion: true);
    expectCoreContent();
    // Le compagnon reste visible (pas d'opacité figée à 0 sous reduced-motion).
    expect(find.byType(Image), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('6. asset Kira valide rendu', (tester) async {
    await pumpSuccess(tester, asset: 'assets/companions/kira.png');
    final images = tester
        .widgetList<Image>(find.byType(Image))
        .map((i) => i.image)
        .whereType<AssetImage>()
        .map((a) => a.assetName);
    expect(images, contains('assets/companions/kira.png'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('7. asset Léo valide rendu', (tester) async {
    await pumpSuccess(
      tester,
      asset: 'assets/companions/leo.png',
      companionName: 'Léo',
    );
    final images = tester
        .widgetList<Image>(find.byType(Image))
        .map((i) => i.image)
        .whereType<AssetImage>()
        .map((a) => a.assetName);
    expect(images, contains('assets/companions/leo.png'));
    expect(find.text('Bienvenue, Amina !'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('8. asset manquant : fallback premium, écran non vide', (
    tester,
  ) async {
    await pumpSuccess(
      tester,
      asset: 'assets/companions/__inexistant__.png',
      companionName: 'Kira',
    );
    // Le reste de l'écran reste visible et le fallback affiche l'initiale.
    expectCoreContent();
    expect(find.text('K'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('9. bouton CTA visible', (tester) async {
    await pumpSuccess(tester);
    expect(find.text('Découvrir INTELLIA237'), findsOneWidget);
  });

  testWidgets('10. tap sur « Découvrir INTELLIA237 »', (tester) async {
    var tapped = false;
    await pumpSuccess(tester, onContinue: () => tapped = true);
    await tester.tap(find.text('Découvrir INTELLIA237'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tapped, isTrue);
  });

  testWidgets('11 & 12. aucun overflow / aucun flex sous hauteur non bornée', (
    tester,
  ) async {
    // Petites tailles : l'ancienne version (Spacer dans un scroll) jetait
    // « RenderFlex … unbounded ». La nouvelle ne doit rien jeter.
    for (final size in const [
      Size(320, 568),
      Size(360, 640),
      Size(390, 844),
      Size(430, 932),
    ]) {
      await pumpSuccess(tester, size: size);
      expect(
        tester.takeException(),
        isNull,
        reason: 'overflow à ${size.width}x${size.height}',
      );
    }
  });

  testWidgets(
    'parcours : inscription réussie → succès → CTA → auth student (studentHome)',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          studentRegistrationRepositoryProvider.overrideWithValue(
            _FakeRegistrationRepository(),
          ),
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
      );
      addTearDown(container.dispose);

      final rego = container.read(
        studentRegistrationControllerProvider.notifier,
      );
      rego
        ..setFirstName('Amina')
        ..setLastName('Ndi')
        ..setSchoolClass(SchoolClass.sixieme)
        ..setSelectedTutorId('kira')
        ..setEmail('amina@example.com')
        ..setPassword('Password1')
        ..setConfirmPassword('Password1')
        ..setAcceptedTerms(true)
        ..setAcceptedPrivacy(true)
        ..setAcceptedDataPolicy(true);

      final ok = await rego.submit();
      expect(ok, isTrue);
      expect(
        container.read(studentRegistrationControllerProvider).isCompleted,
        isTrue,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: StudentRegistrationFlowScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Écran de réussite avec prénom + compagnon visibles.
      expect(find.text('Bienvenue, Amina !'), findsOneWidget);
      expect(find.textContaining('Kira'), findsWidgets);
      expect(tester.takeException(), isNull);

      // Tap CTA → completeRegistration → auth authenticated/student.
      await tester.tap(find.text('Découvrir INTELLIA237'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final auth = container.read(authControllerProvider);
      expect(auth.status, AuthStatus.authenticated);
      expect(auth.role, AppRole.student);
      // Le router redirige le student vers studentHome.
      expect(AppRole.student.homePath, AppRoutes.studentHome);
      expect(tester.takeException(), isNull);
    },
  );
}

class _FakeRegistrationRepository implements StudentRegistrationRepository {
  @override
  Future<StudentRegistrationResult> registerStudent(
    StudentRegistrationPayload payload,
  ) async => const StudentRegistrationResult(
    uid: 'uid-test',
    email: 'amina@example.com',
    firstName: 'Amina',
    lastName: 'Ndi',
  );
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
