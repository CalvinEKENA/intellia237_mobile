import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intellia237/features/flow/application/flow_controller.dart';
import 'package:intellia237/features/flow/data/flow_points_gateway.dart';
import 'package:intellia237/features/flow/presentation/widgets/flow_hud.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sortie du Parcours (retour appareil, 24/09/2026) : visible et nommée.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  testWidgets('the Parcours says "Quitter" and closes on tap', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var closed = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flowPointsGatewayProvider.overrideWithValue(_QuietGateway()),
          flowCardsProvider.overrideWithValue(const []),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: FlowHud(onClose: () => closed++)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final exit = find.byKey(const ValueKey('flow-exit'));
    expect(exit, findsOneWidget);
    expect(find.text('Quitter'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    expect(tester.getSize(exit).height, greaterThanOrEqualTo(44));

    await tester.tap(exit);
    await tester.pump(const Duration(milliseconds: 300));
    expect(closed, 1);
    expect(tester.takeException(), isNull);
  });
}

class _QuietGateway implements FlowPointsGateway {
  @override
  String newClientEventId() => 'evt_quiet_abcdefgh';

  @override
  Future<FlowPointsResult> submit(FlowActivityCommand command) =>
      throw UnimplementedError();

  @override
  Future<List<FlowPointsResult>> flushPending() async => const [];

  @override
  Future<int> pendingCount() async => 0;
}
