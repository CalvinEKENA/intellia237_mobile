import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/student_registration/application/student_registration_controller.dart';
import 'package:intellia237/features/student_registration/domain/academic_rules.dart';
import 'package:intellia237/features/student_registration/presentation/student_registration_flow_screen.dart';

void main() {
  for (final size in const [
    Size(320, 640),
    Size(360, 800),
    Size(390, 844),
    Size(430, 932),
  ]) {
    testWidgets(
      'student class step fits ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final container = ProviderContainer();
        addTearDown(container.dispose);
        final controller = container.read(
          studentRegistrationControllerProvider.notifier,
        );
        controller
          ..setFirstName('Amina')
          ..setLastName('Ndi')
          ..goToNextStep();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  disableAnimations: true,
                  textScaler: TextScaler.linear(1.3),
                ),
                child: StudentRegistrationFlowScreen(),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.textContaining('établissement'), findsNothing);
        expect(find.text('6ème'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 1));
      },
    );
  }

  testWidgets('security step remains scrollable above a mobile keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(
      studentRegistrationControllerProvider.notifier,
    );
    controller
      ..setFirstName('Amina')
      ..setLastName('Ndi')
      ..setSchoolClass(SchoolClass.sixieme)
      ..setSelectedTutorId('kira')
      ..goToNextStep();
    controller
      ..goToNextStep()
      ..goToNextStep();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              disableAnimations: true,
              viewInsets: EdgeInsets.only(bottom: 280),
              textScaler: TextScaler.linear(1.3),
            ),
            child: StudentRegistrationFlowScreen(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Créer mon compte'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets(
    'companion step reveals Kira then Léo one at a time, official assets only',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(
        studentRegistrationControllerProvider.notifier,
      );
      controller
        ..setFirstName('Amina')
        ..setLastName('Ndi')
        ..setSchoolClass(SchoolClass.terminale)
        ..setSchoolSeries(SchoolSeries.d)
        ..goToNextStep()
        ..goToNextStep();

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
      await tester.pump();

      Set<String> companionAssets() => tester
          .widgetList<Image>(find.byType(Image))
          .map((image) => image.image)
          .whereType<AssetImage>()
          .map((asset) => asset.assetName)
          .where((path) => path.startsWith('assets/companions/'))
          .toSet();

      bool onlyOfficial() => companionAssets().every(
        (p) =>
            p == 'assets/companions/kira.png' ||
            p == 'assets/companions/leo.png',
      );

      // Kira est présentée SEULE au départ — Léo n'apparaît pas encore.
      expect(companionAssets(), contains('assets/companions/kira.png'));
      expect(companionAssets(), isNot(contains('assets/companions/leo.png')));
      expect(onlyOfficial(), isTrue);

      // La flèche « Découvrir Léo » révèle ensuite Léo, seul.
      await tester.ensureVisible(find.text('Découvrir Léo'));
      await tester.pump();
      await tester.tap(find.text('Découvrir Léo'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(companionAssets(), contains('assets/companions/leo.png'));
      expect(onlyOfficial(), isTrue);

      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );
}
