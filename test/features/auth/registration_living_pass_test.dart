import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/presentation/widgets/auth_controls.dart';
import 'package:intellia237/features/auth/presentation/widgets/living_pass.dart';
import 'package:intellia237/features/parent_registration/application/parent_registration_controller.dart';
import 'package:intellia237/features/parent_registration/presentation/parent_registration_screen.dart';
import 'package:intellia237/features/student_registration/application/student_registration_controller.dart';
import 'package:intellia237/features/student_registration/domain/academic_rules.dart';
import 'package:intellia237/features/student_registration/presentation/student_registration_flow_screen.dart';
import 'package:intellia237/features/teacher_registration/application/teacher_registration_controller.dart';
import 'package:intellia237/features/teacher_registration/application/teacher_registration_state.dart';
import 'package:intellia237/features/teacher_registration/presentation/teacher_registration_screen.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

Future<void> _show(
  WidgetTester tester,
  ProviderContainer container,
  Widget screen, {
  bool keyboard = false,
}) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(320, 640),
            disableAnimations: true,
            textScaler: const TextScaler.linear(1.6),
            viewInsets: EdgeInsets.only(bottom: keyboard ? 280 : 0),
          ),
          child: screen,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'the student PASS follows the saved identity and academic choices',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(
        studentRegistrationControllerProvider.notifier,
      );
      controller
        ..setFirstName('Amina')
        ..setLastName('Ndi');
      await _show(tester, container, const StudentRegistrationFlowScreen());

      final firstNameField = find.descendant(
        of: find.byType(AuthAnimatedField).first,
        matching: find.byType(TextFormField),
      );
      expect(
        tester.widget<TextFormField>(firstNameField).controller!.text,
        'Amina',
      );
      await tester.enterText(firstNameField, 'Fatou');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('living-pass-name')))
            .data,
        'Fatou',
      );

      controller
        ..setSchoolClass(SchoolClass.terminale)
        ..setSchoolSeries(SchoolSeries.d)
        ..setSelectedTutorId('leo')
        ..goToNextStep()
        ..goToNextStep()
        ..goToNextStep();
      await tester.pumpAndSettle();

      final pass = find.byKey(const ValueKey('student-living-pass'));
      expect(
        find.descendant(of: pass, matching: find.textContaining('Terminale')),
        findsOneWidget,
      );
      final companion = tester.widget<Image>(
        find.descendant(of: pass, matching: find.byType(Image)),
      );
      expect(
        (companion.image as AssetImage).assetName,
        'assets/companions/leo.png',
      );
      expect(find.byType(AuthConsentTile), findsNWidgets(3));
      expect(find.text('PASS PRÊT'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'parent can add an identifier above the keyboard without claiming a verified link',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(parentRegistrationControllerProvider.notifier)
        ..setFirstName('Marie')
        ..setLastName('Ndi')
        ..nextStep();
      await _show(
        tester,
        container,
        const ParentRegistrationScreen(),
        keyboard: true,
      );

      final field = find.descendant(
        of: find.byKey(const ValueKey('parent-child-identifier-field')),
        matching: find.byType(TextFormField),
      );
      await tester.ensureVisible(field);
      await tester.enterText(field, 'test-237');
      final add = find.byKey(const ValueKey('parent-add-child-action'));
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pumpAndSettle();

      expect(
        container.read(parentRegistrationControllerProvider).childIdentifiers,
        ['TEST-237'],
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('parent-living-pass')),
          matching: find.textContaining('1 identifiant ajouté'),
        ),
        findsOneWidget,
      );
      final action = find.byKey(const ValueKey('registration-primary-action'));
      await tester.ensureVisible(action);
      expect(tester.getRect(action).bottom, lessThanOrEqualTo(360));
      expect(tester.takeException(), isNull);
    },
  );

  for (var step = 0; step < 3; step++) {
    testWidgets(
      'teacher step $step keeps its action reachable at 320 px with keyboard and large text',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final controller = container.read(
          teacherRegistrationControllerProvider.notifier,
        );
        controller
          ..setFirstName('Jean')
          ..setLastName('Fotso');
        for (var index = 0; index < step; index++) {
          controller.nextStep();
        }
        await _show(
          tester,
          container,
          const TeacherRegistrationScreen(),
          keyboard: true,
        );

        expect(find.byType(LivingPass), findsOneWidget);
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        final action = find.byKey(
          const ValueKey('registration-primary-action'),
        );
        await tester.ensureVisible(action);
        expect(tester.getRect(action).bottom, lessThanOrEqualTo(360));
        if (step == 2) expect(find.byType(AuthConsentTile), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'pending teacher validation shows the saved status without offering resubmission',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          teacherRegistrationControllerProvider.overrideWith(
            _PendingTeacher.new,
          ),
        ],
      );
      addTearDown(container.dispose);
      await _show(tester, container, const TeacherRegistrationScreen());
      expect(find.text('COMPTE CRÉÉ.'), findsOneWidget);
      expect(find.text('VALIDATION EN ATTENTE'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('registration-primary-action')),
        findsNothing,
      );
      expect(find.text('PASS PRÊT'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

class _PendingTeacher extends TeacherRegistrationController {
  @override
  TeacherRegistrationState build() => const TeacherRegistrationState(
    firstName: 'Jean',
    lastName: 'Fotso',
    currentStep: 2,
    awaitsValidation: true,
  );
}
