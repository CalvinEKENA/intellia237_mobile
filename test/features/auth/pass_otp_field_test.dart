import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/presentation/widgets/pass_otp_field.dart';

void main() {
  testWidgets('one native OTP field accepts paste and completes only once', (
    tester,
  ) async {
    final controller = TextEditingController();
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    var submissions = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 280,
            child: PassOtpField(
              controller: controller,
              focusNode: focus,
              label: 'Code de vérification',
              fieldKey: const ValueKey('phone-otp-field'),
              onSubmit: () => submissions++,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(TextFormField), findsOneWidget);
    for (var index = 0; index < 6; index++) {
      expect(find.byKey(ValueKey('pass-otp-slot-$index')), findsOneWidget);
    }
    final field = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(field.controller, same(controller));
    final native = tester.widget<TextField>(find.byType(TextField));
    expect(native.autofillHints, contains(AutofillHints.oneTimeCode));
    await tester.enterText(find.byType(TextFormField), '12 34-56');
    expect(controller.text, '123456');
    expect(submissions, 1);
    await tester.pump();
    await tester.enterText(find.byType(TextFormField), '123456');
    expect(submissions, 1);
    await tester.enterText(find.byType(TextFormField), '12345');
    await tester.enterText(find.byType(TextFormField), '123456');
    expect(submissions, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('OTP has one accessible text field at large text size', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final controller = TextEditingController();
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: Scaffold(
            body: SizedBox(
              width: 248,
              child: PassOtpField(
                controller: controller,
                focusNode: focus,
                label: 'Verification code',
                onSubmit: () {},
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Verification code'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '135790');
    await tester.pump();
    expect(controller.text, '135790');
    expect(tester.takeException(), isNull);
    handle.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
