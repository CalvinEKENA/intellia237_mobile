import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intellia237/features/parent_registration/application/parent_registration_controller.dart';
import 'package:intellia237/features/parent_registration/presentation/parent_registration_screen.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('child identifier keeps the panel width on compact phones', (
    tester,
  ) async {
    for (final width in const [320.0, 360.0, 375.0, 390.0, 412.0, 480.0]) {
      for (final scale in const [1.0, 1.5, 2.0]) {
        tester.view.physicalSize = Size(width, 780);
        tester.view.devicePixelRatio = 1;
        final container = ProviderContainer();
        container
            .read(parentRegistrationControllerProvider.notifier)
            .nextStep();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 780),
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: true,
                ),
                child: const ParentRegistrationScreen(),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 700));

        final field = find.byKey(
          const ValueKey('parent-child-identifier-field'),
        );
        final action = find.byKey(const ValueKey('parent-add-child-action'));
        expect(field, findsOneWidget);
        expect(action, findsOneWidget);
        expect(
          tester.getSize(field).width,
          greaterThan(width - 100),
          reason: 'field width at $width px / text scale $scale',
        );
        final fieldRect = tester.getRect(field);
        final actionRect = tester.getRect(action);
        expect(fieldRect.left, greaterThanOrEqualTo(0));
        expect(fieldRect.right, lessThanOrEqualTo(width));
        expect(actionRect.left, greaterThanOrEqualTo(0));
        expect(actionRect.right, lessThanOrEqualTo(width));
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        container.dispose();
      }
    }
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.clearAllTestValues();
  });
}
