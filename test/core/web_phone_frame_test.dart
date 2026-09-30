import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/core/widgets/web_phone_frame.dart';

/// Application web responsive (23/09/2026) : plein écran sur téléphone et
/// tablette, colonne centrée en pleine hauteur sur ordinateur.
void main() {
  Future<Size> screenSeenBy(WidgetTester tester, Size window) async {
    tester.view.physicalSize = window;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late Size seen;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            WebPhoneFrame(enabled: true, child: child!),
        home: Builder(
          builder: (context) {
            seen = MediaQuery.sizeOf(context);
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    );
    return seen;
  }

  for (final window in const [
    Size(360, 740),
    Size(412, 915),
    Size(768, 1024),
  ]) {
    testWidgets('${window.width.toInt()} px: the app fills the window', (
      tester,
    ) async {
      expect(await screenSeenBy(tester, window), window);
      expect(find.byKey(WebPhoneFrame.frameKey), findsNothing);
    });
  }

  testWidgets('desktop: a centred full-height column', (tester) async {
    const window = Size(1280, 800);
    final seen = await screenSeenBy(tester, window);
    expect(seen, const Size(WebPhoneFrame.columnWidth, 800));
    final frame = tester.getRect(find.byKey(WebPhoneFrame.frameKey));
    expect(frame.height, 800);
    expect(frame.center.dx, closeTo(window.width / 2, 0.5));
  });

  testWidgets('on Android nothing changes', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: WebPhoneFrame(enabled: false, child: Scaffold())),
    );
    expect(find.byKey(WebPhoneFrame.frameKey), findsNothing);
  });
}
