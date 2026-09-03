import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/theme/app_theme.dart';

void main() {
  testWidgets('themed inline buttons cannot starve adjacent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(1.5),
          ),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Texte principal lisible',
                      key: ValueKey('inline-text'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: () {}, child: const Text('Action')),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('inline-text'))).width,
      greaterThan(100),
    );
    expect(tester.takeException(), isNull);
  });
}
