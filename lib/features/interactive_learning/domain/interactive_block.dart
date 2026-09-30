import 'dart:convert';

/// Mécaniques d'interaction réutilisables : une primitive sert plusieurs
/// matières (l'ordre des mots en anglais, des étapes en maths, des dates en
/// histoire). La logique métier d'une matière ne vit jamais dans un widget.
enum InteractionPrimitive {
  ordering,
  choice,
  binary,
  gapFill,
  pairing,
  grouping,
  numeric,
  labeling,
  map,
  data,
}

/// Disposition d'une activité d'ordre.
enum OrderingLayout {
  /// Éléments courts qui forment une phrase et reviennent à la ligne.
  inline,

  /// Étapes ou événements, un par ligne.
  stacked,
}

/// Types d'activités connus. Seuls les types [supported] sont rendus ; les
/// autres sont l'architecture annoncée et ne s'affichent jamais tant qu'un
/// rendu n'existe pas. Même registre que le serveur
/// (`functions/src/llm/interactiveBlocks.ts`).
enum InteractiveBlockType {
  wordOrder(
    'word_order',
    InteractionPrimitive.ordering,
    layout: OrderingLayout.inline,
    supported: true,
  ),
  stepOrder(
    'step_order',
    InteractionPrimitive.ordering,
    layout: OrderingLayout.stacked,
    supported: true,
  ),
  equationOrder(
    'equation_order',
    InteractionPrimitive.ordering,
    layout: OrderingLayout.stacked,
    supported: true,
  ),
  timelineOrder(
    'timeline_order',
    InteractionPrimitive.ordering,
    layout: OrderingLayout.stacked,
    supported: true,
  ),
  processSequence(
    'process_sequence',
    InteractionPrimitive.ordering,
    layout: OrderingLayout.stacked,
    supported: true,
  ),
  sequence(
    'sequence',
    InteractionPrimitive.ordering,
    layout: OrderingLayout.stacked,
    supported: true,
  ),
  multipleChoice('multiple_choice', InteractionPrimitive.choice),
  trueFalse('true_false', InteractionPrimitive.binary),
  fillBlank('fill_blank', InteractionPrimitive.gapFill),
  sentenceCorrection('sentence_correction', InteractionPrimitive.gapFill),
  matching('matching', InteractionPrimitive.pairing),
  expressionMatch('expression_match', InteractionPrimitive.pairing),
  formulaMatch('formula_match', InteractionPrimitive.pairing),
  unitMatch('unit_match', InteractionPrimitive.pairing),
  elementMatch('element_match', InteractionPrimitive.pairing),
  labelMatch('label_match', InteractionPrimitive.pairing),
  eventMatch('event_match', InteractionPrimitive.pairing),
  causeEffectMatch('cause_effect_match', InteractionPrimitive.pairing),
  claimMatch('claim_match', InteractionPrimitive.pairing),
  classification('classification', InteractionPrimitive.grouping),
  argumentClassification(
    'argument_classification',
    InteractionPrimitive.grouping,
  ),
  sorting('sorting', InteractionPrimitive.grouping),
  numericInput('numeric_input', InteractionPrimitive.numeric),
  valueInput('value_input', InteractionPrimitive.numeric),
  textEvidence('text_evidence', InteractionPrimitive.choice),
  diagramLabeling('diagram_labeling', InteractionPrimitive.labeling),
  mapInteraction('map_interaction', InteractionPrimitive.map),
  dataInterpretation('data_interpretation', InteractionPrimitive.data);

  const InteractiveBlockType(
    this.wire,
    this.primitive, {
    this.layout,
    this.supported = false,
  });

  /// Nom échangé avec le serveur.
  final String wire;
  final InteractionPrimitive primitive;
  final OrderingLayout? layout;

  /// Rendu disponible dans cette version de l'application.
  final bool supported;

  static InteractiveBlockType? fromWire(Object? value) {
    for (final type in values) {
      if (type.wire == value) return type;
    }
    return null;
  }

  /// Types que ce téléphone sait rendre, déclarés au serveur.
  static List<String> get supportedWireNames => [
    for (final type in values)
      if (type.supported) type.wire,
  ];
}

/// Élément d'une activité : un identifiant opaque, jamais son texte, porte
/// l'identité (deux « I » dans « I think I can » sont deux éléments).
class BlockItem {
  const BlockItem({required this.id, required this.text});

  final String id;
  final String text;

  Map<String, Object?> toJson() => {'id': id, 'text': text};
}

/// Bloc d'apprentissage interactif, indépendant de l'écran qui l'accueille
/// (conversation avec le compagnon, Parcours, leçon, révision, quiz).
sealed class InteractiveLearningBlock {
  const InteractiveLearningBlock({
    required this.id,
    required this.type,
    required this.language,
    required this.hints,
    required this.difficulty,
    this.instruction,
    this.subject,
    this.explanation,
    this.rationale,
  });

  final String id;
  final InteractiveBlockType type;

  /// Langue d'enseignement de l'élève (fr | en).
  final String language;
  final String? instruction;
  final String? subject;

  /// Indices progressifs, du plus léger au plus précis.
  final List<String> hints;
  final String? explanation;
  final int difficulty;

  /// Pourquoi cette activité aide, selon le compagnon.
  final String? rationale;

  Map<String, Object?> toJson();

  /// Lecture stricte : tout écart au contrat donne `null`, et rien n'est
  /// rendu. Aucun HTML, aucune interface libre, aucun type inconnu.
  static InteractiveLearningBlock? tryParse(Object? raw) {
    if (raw is! Map) return null;
    try {
      if (jsonEncode(raw).length > InteractiveBlockLimits.maxJsonChars) {
        return null;
      }
    } catch (_) {
      return null;
    }
    final map = Map<String, Object?>.from(raw);
    if (map['version'] != 1) return null;
    final type = InteractiveBlockType.fromWire(map['type']);
    if (type == null || !type.supported) return null;
    return switch (type.primitive) {
      InteractionPrimitive.ordering => OrderingBlock._parse(map, type),
      _ => null,
    };
  }
}

/// Bornes du contrat, identiques au serveur.
abstract final class InteractiveBlockLimits {
  static const maxJsonChars = 6000;
  static const instructionChars = 160;
  static const inlineItemsMax = 10;
  static const inlineItemChars = 24;
  static const stackedItemsMax = 8;
  static const stackedItemChars = 140;
  static const hints = 3;
  static const hintChars = 160;
  static const explanationChars = 400;
  static const rationaleChars = 160;
}

/// Remettre dans l'ordre : mots, étapes, événements.
final class OrderingBlock extends InteractiveLearningBlock {
  const OrderingBlock({
    required super.id,
    required super.type,
    required super.language,
    required super.hints,
    required super.difficulty,
    required this.items,
    required this.solution,
    super.instruction,
    super.subject,
    super.explanation,
    super.rationale,
    this.trailing,
  });

  final List<BlockItem> items;

  /// Identifiants dans le bon ordre.
  final List<String> solution;

  /// Ponctuation finale d'une phrase, affichée hors des cartes.
  final String? trailing;

  OrderingLayout get layout => type.layout!;

  BlockItem itemById(String id) => items.firstWhere((item) => item.id == id);

  @override
  Map<String, Object?> toJson() => {
    'version': 1,
    'id': id,
    'type': type.wire,
    'language': language,
    'instruction': ?instruction,
    'subject': ?subject,
    'items': [for (final item in items) item.toJson()],
    'solution': solution,
    'trailing': ?trailing,
    'hints': hints,
    'explanation': ?explanation,
    'difficulty': difficulty,
    'rationale': ?rationale,
  };

  static final _idPattern = RegExp(r'^[A-Za-z0-9_-]{1,40}$');

  static OrderingBlock? _parse(
    Map<String, Object?> map,
    InteractiveBlockType type,
  ) {
    final id = map['id'];
    if (id is! String || !_idPattern.hasMatch(id)) return null;
    final inline = type.layout == OrderingLayout.inline;
    final maxItems = inline
        ? InteractiveBlockLimits.inlineItemsMax
        : InteractiveBlockLimits.stackedItemsMax;
    final maxChars = inline
        ? InteractiveBlockLimits.inlineItemChars
        : InteractiveBlockLimits.stackedItemChars;

    final rawItems = map['items'];
    if (rawItems is! List ||
        rawItems.length < 2 ||
        rawItems.length > maxItems) {
      return null;
    }
    final items = <BlockItem>[];
    for (final raw in rawItems) {
      if (raw is! Map) return null;
      final itemId = raw['id'];
      final text = raw['text'];
      if (itemId is! String || !_idPattern.hasMatch(itemId)) return null;
      if (text is! String) return null;
      final trimmed = text.trim();
      if (trimmed.isEmpty || trimmed.length > maxChars) return null;
      items.add(BlockItem(id: itemId, text: trimmed));
    }
    final ids = {for (final item in items) item.id};
    if (ids.length != items.length) return null;
    // Sans deux textes différents, tout ordre serait juste.
    if ({for (final item in items) item.text}.length < 2) return null;

    final rawSolution = map['solution'];
    if (rawSolution is! List || rawSolution.length != items.length) {
      return null;
    }
    final solution = <String>[];
    for (final value in rawSolution) {
      if (value is! String || !ids.contains(value)) return null;
      solution.add(value);
    }
    if (solution.toSet().length != solution.length) return null;

    final trailing = map['trailing'];
    if (trailing != null &&
        (!inline ||
            trailing is! String ||
            !const {'.', '?', '!'}.contains(trailing))) {
      return null;
    }

    final hints = _stringList(
      map['hints'],
      max: InteractiveBlockLimits.hints,
      chars: InteractiveBlockLimits.hintChars,
    );
    if (hints == null) return null;
    final difficulty = map['difficulty'];
    if (difficulty is! int || difficulty < 1 || difficulty > 3) return null;
    final language = map['language'] == 'en' ? 'en' : 'fr';

    final instruction = _optionalText(
      map['instruction'],
      InteractiveBlockLimits.instructionChars,
    );
    final explanation = _optionalText(
      map['explanation'],
      InteractiveBlockLimits.explanationChars,
    );
    final rationale = _optionalText(
      map['rationale'],
      InteractiveBlockLimits.rationaleChars,
    );
    final subject = _optionalText(map['subject'], 60);
    if (instruction == _invalid ||
        explanation == _invalid ||
        rationale == _invalid ||
        subject == _invalid) {
      return null;
    }

    return OrderingBlock(
      id: id,
      type: type,
      language: language,
      hints: hints,
      difficulty: difficulty,
      items: List.unmodifiable(items),
      solution: List.unmodifiable(solution),
      trailing: trailing as String?,
      instruction: instruction,
      explanation: explanation,
      rationale: rationale,
      subject: subject,
    );
  }
}

/// Valeur refusée par le contrat (distincte d'un champ simplement absent).
const _invalid = '#invalid#';

String? _optionalText(Object? value, int max) {
  if (value == null) return null;
  if (value is! String) return _invalid;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  return trimmed.length > max ? _invalid : trimmed;
}

List<String>? _stringList(
  Object? value, {
  required int max,
  required int chars,
}) {
  if (value == null) return const [];
  if (value is! List || value.length > max) return null;
  final result = <String>[];
  for (final entry in value) {
    if (entry is! String) return null;
    final trimmed = entry.trim();
    if (trimmed.isEmpty || trimmed.length > chars) return null;
    result.add(trimmed);
  }
  return List.unmodifiable(result);
}

/// Compte rendu d'une activité, envoyé au compagnon avec le message suivant
/// pour qu'il s'adapte. Activité pédagogique, jamais une note officielle.
class ActivityOutcome {
  const ActivityOutcome({
    required this.blockId,
    required this.type,
    required this.correct,
    required this.attempts,
    required this.hintsUsed,
    required this.solutionRevealed,
    this.duration,
  });

  final String blockId;
  final InteractiveBlockType type;
  final bool correct;
  final int attempts;
  final int hintsUsed;
  final bool solutionRevealed;

  /// Durée sur l'appareil ; jamais envoyée au serveur.
  final Duration? duration;

  Map<String, Object?> toJson() => {
    'blockId': blockId,
    'type': type.wire,
    'correct': correct,
    'attempts': attempts.clamp(0, 20),
    'hintsUsed': hintsUsed.clamp(0, InteractiveBlockLimits.hints),
    'solutionRevealed': solutionRevealed,
  };
}
