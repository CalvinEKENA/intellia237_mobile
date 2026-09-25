import 'package:flutter/foundation.dart';

import 'curriculum.dart';

/// Actions rapides du Compagnon sans modèle de langage.
enum CompanionAction {
  explainStandard,
  explainSimple,
  explainUltraSimple,
  showMe,
  hint,
  testMe,
  whyWrong;

  /// Reconnaît une action écrite librement par un pack
  /// (« Donne un indice », « Donne-moi un indice »…).
  static CompanionAction? fromLabel(String label) {
    final key = normalizeKey(label);
    if (key.contains('12-ans') || key.contains('ultra')) {
      return explainUltraSimple;
    }
    if (key.contains('plus-simple') || key == 'simple') return explainSimple;
    if (key.contains('explique')) return explainStandard;
    if (key.contains('montre')) return showMe;
    if (key.contains('indice') || key.contains('hint')) return hint;
    if (key.contains('teste') || key.contains('test-me')) return testMe;
    if (key.contains('pourquoi') || key.contains('faux')) return whyWrong;
    return null;
  }
}

/// Réglages du Compagnon déclarés par le pack.
@immutable
class CompanionConfig {
  const CompanionConfig({
    required this.actions,
    this.unrecognizedLabels = const [],
    this.fallbackSuggestions = 3,
  });

  static const defaults = CompanionConfig(actions: CompanionAction.values);

  /// Actions proposées, dans l'ordre du pack.
  final List<CompanionAction> actions;

  /// Libellés du pack qu'aucune action ne reconnaît (signalés, non inventés).
  final List<String> unrecognizedLabels;

  /// Nombre de notions proches proposées quand une demande sort du pack.
  final int fallbackSuggestions;
}
