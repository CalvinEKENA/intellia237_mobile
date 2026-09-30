import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/interactive_learning/domain/interactive_block.dart';

/// Contrat partagé avec le serveur : la fixture est produite à l'identique par
/// extractInteractiveBlock (functions/src/__tests__/interactiveBlocks.test.ts).
/// Un champ ajouté côté serveur ne doit jamais faire rejeter un bloc valide.
void main() {
  final fixtures =
      jsonDecode(
            File(
              'test/fixtures/interactive_learning/server_blocks.json',
            ).readAsStringSync(),
          )
          as List<Object?>;

  for (final fixture in fixtures.cast<Map<String, Object?>>()) {
    test('the app accepts what the server emits: ${fixture['name']}', () {
      final block = InteractiveLearningBlock.tryParse(fixture['block']);
      expect(block, isA<OrderingBlock>());
      final ordering = block! as OrderingBlock;
      final server = fixture['block']! as Map<String, Object?>;
      expect(ordering.type.wire, server['type']);
      expect(ordering.layout.name, server['layout']);
      expect(ordering.solution, server['solution']);
      // Aller-retour : l'historique local relit ce qu'il a écrit.
      expect(
        InteractiveLearningBlock.tryParse(
          jsonDecode(jsonEncode(ordering.toJson())),
        ),
        isA<OrderingBlock>(),
      );
    });
  }
}
