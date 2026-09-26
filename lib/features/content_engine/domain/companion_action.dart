import 'package:flutter/foundation.dart';

import 'curriculum.dart';

/// Actions rapides du Compagnon sans modèle de langage.
enum CompanionAction {
  explainStandard,
  explainSimple,
  explainUltraSimple,
  showMe,
  example,
  hint,
  testMe,
  whyWrong;

  /// Reconnaît une action écrite librement par un pack
  /// (« Donne un indice », « Donne-moi un indice »…).
  static CompanionAction? fromLabel(String label) {
    final key = normalizeKey(label);
    if (key.contains('12-ans') ||
        key.contains('ultra') ||
        key.contains('very-simple')) {
      return explainUltraSimple;
    }
    if (key.contains('plus-simple') ||
        key == 'simple' ||
        key.contains('simpler')) {
      return explainSimple;
    }
    if (key.contains('explique') || key.contains('explain')) {
      return explainStandard;
    }
    if (key.contains('montre') || key.contains('show-me')) return showMe;
    if (key.contains('exemple') || key.contains('example')) return example;
    if (key.contains('indice') || key.contains('hint')) return hint;
    if (key.contains('teste') || key.contains('test-me')) return testMe;
    if (key.contains('pourquoi') ||
        key.contains('faux') ||
        key.contains('wrong')) {
      return whyWrong;
    }
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
    this.labels = const {},
  });

  static const defaults = CompanionConfig(actions: CompanionAction.values);

  /// Actions toujours proposées : « Donne-moi un exemple » s'ajoute à
  /// celles du pack dès que le pack contient de quoi le nourrir.
  List<CompanionAction> get effectiveActions => [
    ...actions,
    if (!actions.contains(CompanionAction.example)) CompanionAction.example,
  ];

  /// Actions proposées, dans l'ordre du pack.
  final List<CompanionAction> actions;

  /// Libellés du pack qu'aucune action ne reconnaît (signalés, non inventés).
  final List<String> unrecognizedLabels;

  /// Nombre de notions proches proposées quand une demande sort du pack.
  final int fallbackSuggestions;

  /// Libellés du pack pour ses actions, dans la langue du contenu (ex.
  /// « Explain this » pour l'anglais) ; à défaut, ceux de l'application.
  final Map<CompanionAction, String> labels;
}
