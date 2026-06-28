import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/student_home/presentation/widgets/student_home_header.dart';

void main() {
  testWidgets(
    'le nom d’utilisateur garde une police blanche mais reçoit un halo lisible',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            // Fond clair : sans halo, le blanc serait illisible.
            backgroundColor: Colors.white,
            body: StudentHomeHeader(firstName: 'Amina'),
          ),
        ),
      );
      // Pas de pumpAndSettle : l'en-tête a des animations en boucle.
      await tester.pump();

      TextSpan? nameSpan;
      for (final richText in tester.widgetList<RichText>(
        find.byType(RichText),
      )) {
        final root = richText.text;
        if (root is TextSpan && root.children != null) {
          for (final child in root.children!) {
            if (child is TextSpan && child.text == 'Amina') {
              nameSpan = child;
            }
          }
        }
      }

      expect(nameSpan, isNotNull, reason: 'le prénom doit être rendu');
      // Police blanche conservée (le bel effet voulu).
      expect(nameSpan!.style!.color, Colors.white);
      // … mais désormais lisible grâce au halo (ombres non vides).
      expect(nameSpan.style!.shadows, isNotNull);
      expect(nameSpan.style!.shadows, isNotEmpty);

      expect(tester.takeException(), isNull);
    },
  );
}
