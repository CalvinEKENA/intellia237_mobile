import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/flow/presentation/widgets/flow_entry_card.dart';

void main() {
  testWidgets('la carte d’entrée Flow s’affiche et déclenche le tap', (
    WidgetTester tester,
  ) async {
    var tapped = false;
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            textScaler: TextScaler.linear(1.5),
            disableAnimations: true,
          ),
          child: Scaffold(
            body: Center(child: FlowEntryCard(onTap: () => tapped = true)),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Flow'), findsOneWidget);
    expect(find.text('NOUVEAU'), findsOneWidget);

    await tester.tap(find.text('Flow'));
    // Laisse expirer le timer anti-rebond (350 ms) d'IntelliaPressable.
    await tester.pump(const Duration(milliseconds: 400));

    expect(tapped, isTrue);
  });
}
