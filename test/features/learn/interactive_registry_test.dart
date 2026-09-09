import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/learn/domain/interactive_component.dart';
import 'package:intellia237/features/learn/presentation/widgets/interactive/interactive_block_view.dart';
import 'package:intellia237/features/learn/presentation/widgets/interactive/pythagoras_visual.dart';

/// Un bloc interactif ne transporte qu'une clé et des données. Le catalogue
/// est compilé dans l'application : une clé inconnue ne peut rien déclencher,
/// et une configuration invalide n'atteint jamais le rendu.
void main() {
  group('registre', () {
    test('le composant de référence est enregistré', () {
      final registry = InteractiveComponentRegistry(const [
        PythagorasVisualComponent(),
      ]);

      expect(registry.contains(PythagorasVisualComponent.key), isTrue);
      expect(registry.keys, contains('pythagoras_visual_v1'));
    });

    test('la clé porte sa version', () {
      // Une évolution incompatible publie `_v2` et laisse `_v1` servir les
      // leçons déjà publiées.
      expect(PythagorasVisualComponent.key, endsWith('_v1'));
    });

    test('une clé inconnue est refusée sans exception', () {
      final registry = InteractiveComponentRegistry(const [
        PythagorasVisualComponent(),
      ]);

      final reason = registry.rejectionReason(
        const InteractiveComponentSpec(componentKey: 'simulateur_inexistant'),
      );

      expect(reason, isNotNull);
      expect(registry.resolve('simulateur_inexistant'), isNull);
    });

    test('un registre vide ne rend rien mais n’échoue pas', () {
      final registry = InteractiveComponentRegistry();

      expect(
        registry.rejectionReason(
          const InteractiveComponentSpec(componentKey: 'x'),
        ),
        isNotNull,
      );
    });
  });

  group('validation de configuration', () {
    const component = PythagorasVisualComponent();

    test('une configuration vide est acceptée', () {
      expect(component.validate(const {}).isValid, isTrue);
    });

    test('des côtés plausibles sont acceptés', () {
      expect(
        component.validate(const {'initialA': 3, 'initialB': 4.5}).isValid,
        isTrue,
      );
    });

    test('un côté hors bornes est refusé', () {
      expect(component.validate(const {'initialA': 0}).isValid, isFalse);
      expect(component.validate(const {'initialB': 999}).isValid, isFalse);
    });

    test('un type inattendu est refusé plutôt que converti', () {
      // Une configuration venue de Firestore n'est pas de confiance.
      final verdict = component.validate(const {'initialA': 'trois'});

      expect(verdict.isValid, isFalse);
      expect(verdict.reason, contains('nombre'));
    });

    test('une étiquette d’unité non textuelle est refusée', () {
      expect(component.validate(const {'unitLabel': 12}).isValid, isFalse);
    });

    test('le registre refuse une configuration invalide', () {
      final registry = InteractiveComponentRegistry(const [
        PythagorasVisualComponent(),
      ]);

      final reason = registry.rejectionReason(
        const InteractiveComponentSpec(
          componentKey: PythagorasVisualComponent.key,
          config: {'initialA': 500},
        ),
      );

      expect(reason, isNotNull);
    });
  });

  group('rendu', () {
    Future<void> pump(
      WidgetTester tester,
      InteractiveComponentSpec spec,
    ) async {
      // Un écran de téléphone : le composant vit dans une leçon, pas sur un
      // bureau.
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: InteractiveBlockView(spec: spec),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('le composant de référence se rend et réagit', (tester) async {
      await pump(
        tester,
        const InteractiveComponentSpec(
          componentKey: PythagorasVisualComponent.key,
          config: {'initialA': 3, 'initialB': 4},
        ),
      );

      expect(find.byKey(const ValueKey('interactive-fallback')), findsNothing);
      // 3² + 4² = 25, et c vaut donc 5.
      expect(find.textContaining('25.0'), findsWidgets);
      expect(find.textContaining('5.00'), findsOneWidget);
    });

    testWidgets('déplacer un côté met à jour l’égalité', (tester) async {
      await pump(
        tester,
        const InteractiveComponentSpec(
          componentKey: PythagorasVisualComponent.key,
          config: {'initialA': 3, 'initialB': 4},
        ),
      );

      final slider = find.byType(Slider).first;
      await tester.drag(slider, const Offset(60, 0));
      await tester.pump();

      // L'égalité se recalcule : la somme n'est plus celle de 3-4-5.
      expect(find.textContaining('= 25.0'), findsNothing);
    });

    testWidgets('une clé inconnue montre le repli, pas une erreur', (
      tester,
    ) async {
      await pump(
        tester,
        const InteractiveComponentSpec(
          componentKey: 'chute_libre_v3',
          summary: 'Comprendre la chute libre en faisant varier la hauteur.',
        ),
      );

      expect(
        find.byKey(const ValueKey('interactive-fallback')),
        findsOneWidget,
      );
      // Le contenu pédagogique passe même quand l'interaction ne passe pas.
      expect(
        find.text('Comprendre la chute libre en faisant varier la hauteur.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('une configuration invalide bascule sur le repli', (
      tester,
    ) async {
      await pump(
        tester,
        const InteractiveComponentSpec(
          componentKey: PythagorasVisualComponent.key,
          config: {'initialA': 'trois'},
          summary: 'Visualiser le théorème de Pythagore.',
        ),
      );

      expect(
        find.byKey(const ValueKey('interactive-fallback')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
