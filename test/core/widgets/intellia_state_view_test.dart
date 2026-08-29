import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/theme/design_tokens.dart';
import 'package:intellia237/core/widgets/intellia_async_states.dart';
import 'package:intellia237/core/widgets/intellia_state_view.dart';
import 'package:intellia237/core/widgets/tab_presentation.dart';

void main() {
  group('stateKindForError — panne ≠ vide ≠ autorisation', () {
    test('permission-denied → accès refusé', () {
      expect(
        stateKindForError(
          FirebaseException(plugin: 'firestore', code: 'permission-denied'),
        ),
        IntelliaStateKind.accessDenied,
      );
    });

    test('unavailable / réseau → hors ligne', () {
      expect(
        stateKindForError(
          FirebaseException(plugin: 'firestore', code: 'unavailable'),
        ),
        IntelliaStateKind.offline,
      );
      expect(
        stateKindForError(Exception('SocketException: failed host lookup')),
        IntelliaStateKind.offline,
      );
    });

    test('autre erreur → récupérable', () {
      expect(
        stateKindForError(StateError('boom')),
        IntelliaStateKind.errorRetryable,
      );
    });
  });

  group('IntelliaStateView — variantes de surface', () {
    testWidgets('surface claire : titre sombre, action 48dp, callback', (
      tester,
    ) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: IntelliaColors.backgroundPrimary,
            body: TabSurface(
              palette: const TabPalette(TabPresentationMode.embeddedLight),
              child: IntelliaStateView(
                kind: IntelliaStateKind.errorRetryable,
                title: 'Oups',
                message: 'Réessaie.',
                primaryLabel: 'Réessayer',
                onPrimary: () => retried = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final title = tester.widget<Text>(find.text('Oups'));
      expect(title.style!.color, IntelliaColors.textPrimary);

      final buttonSize = tester.getSize(
        find.ancestor(
          of: find.text('Réessayer'),
          matching: find.byType(Container),
        ),
      );
      expect(buttonSize.height, greaterThanOrEqualTo(48));

      await tester.tap(find.text('Réessayer'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(retried, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('palette sombre imposée : titre blanc', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: Color(0xFF060E22),
            body: IntelliaStateView(
              kind: IntelliaStateKind.comingSoon,
              palette: TabPalette(TabPresentationMode.standaloneDark),
              title: 'Bientôt',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final title = tester.widget<Text>(find.text('Bientôt'));
      expect(title.style!.color, const Color(0xFFFFFFFF));
      expect(tester.takeException(), isNull);
    });

    testWidgets('sans TabSurface : repli sur la luminosité du Theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          home: const Scaffold(
            body: IntelliaStateView(
              kind: IntelliaStateKind.empty,
              title: 'Vide',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final title = tester.widget<Text>(find.text('Vide'));
      expect(title.style!.color!.computeLuminance(), lessThan(0.2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('chargement : indicateur visible et annoncé', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IntelliaStateView(kind: IntelliaStateKind.loading),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
