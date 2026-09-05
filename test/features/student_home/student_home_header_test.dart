import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/theme/design_tokens.dart';
import 'package:intellia237/core/widgets/tab_presentation.dart';
import 'package:intellia237/features/student_home/presentation/widgets/student_home_header.dart';

Future<void> _pumpHeader(
  WidgetTester tester, {
  required TabPresentationMode mode,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        backgroundColor: mode == TabPresentationMode.embeddedLight
            ? IntelliaColors.backgroundPrimary
            : const Color(0xFF060E22),
        body: TabSurface(
          palette: TabPalette(mode),
          child: const StudentHomeHeader(firstName: 'Amina'),
        ),
      ),
    ),
  );
  // Aucune boucle d'animation permanente : pumpAndSettle doit converger.
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'sur surface claire : prénom sombre, sans ombre-halo de substitution',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpHeader(tester, mode: TabPresentationMode.embeddedLight);

      final name = tester.widget<Text>(find.text('Amina'));

      // Contrat de surface : texte sombre sur fond clair.
      expect(name.style!.color, IntelliaColors.textPrimary);
      expect(name.style!.color!.computeLuminance(), lessThan(0.2));

      // Le halo (ombres) n'est plus un substitut de contraste.
      expect(
        name.style!.shadows ?? const <Shadow>[],
        isEmpty,
        reason: 'plus d\'ombre de texte comme béquille de lisibilité',
      );

      // Le sous-titre or profond reste lisible sur clair.
      final subtitle = tester.widget<Text>(
        find.text('Mon espace d’apprentissage'),
      );
      expect(
        subtitle.style!.color,
        const TabPalette(TabPresentationMode.embeddedLight).numberAccent,
      );

      // L'avatar est un vrai bouton accessible.
      final avatarSemantics = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Ouvrir mon profil',
      );
      expect(avatarSemantics, findsOneWidget);
      final node = tester.getSemantics(avatarSemantics);
      expect(node.getSemanticsData().label, contains('Ouvrir mon profil'));
      semantics.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('sur surface sombre : prénom blanc (variante du contrat)', (
    tester,
  ) async {
    await _pumpHeader(tester, mode: TabPresentationMode.standaloneDark);

    final name = tester.widget<Text>(find.text('Amina'));
    expect(name.style!.color, const Color(0xFFFFFFFF));
    expect(tester.takeException(), isNull);
  });
}
