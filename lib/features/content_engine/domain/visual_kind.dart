import 'curriculum.dart';

/// Primitives visuelles génériques du moteur.
///
/// Aucune n'appartient à un chapitre : un « regroupement » sert la division
/// euclidienne comme les fractions ; une « horloge modulaire » sert les
/// congruences comme les phénomènes périodiques. Un pack peut nommer la
/// primitive (`visual_kind`) ; sinon le moteur la reconnaît dans la
/// description libre `visual_model`.
enum VisualKind {
  /// Des objets rangés dans des boîtes de même taille ; un reste dehors.
  grouping('grouping'),

  /// Des interrupteurs pondérés (valeur de position dans une base).
  placeValue('place_value'),

  /// Une bande des restes autorisés de 0 à |b|−1.
  remainderBand('remainder_band'),

  /// Une horloge à n positions.
  modularClock('modular_clock'),

  /// Un nombre cassé en briques premières.
  factorBricks('factor_bricks'),

  /// Un rectangle pavé de carreaux carrés ; deux rythmes qui se synchronisent.
  tiling('tiling'),

  /// Aucune primitive reconnue : le texte seul est affiché.
  none('none');

  const VisualKind(this.key);

  final String key;

  static VisualKind? fromKey(String? key) {
    for (final kind in values) {
      if (kind.key == key) return kind;
    }
    return null;
  }

  /// Reconnaît la primitive décrite par un texte libre du pack.
  ///
  /// L'ordre compte : les descriptions les plus spécifiques d'abord.
  static VisualKind infer(String? description) {
    if (description == null || description.trim().isEmpty) return none;
    final text = normalizeKey(description);
    bool has(List<String> words) => words.any(text.contains);
    if (has(['interrupteur', 'switch'])) return placeValue;
    if (has(['horloge', 'clock', 'cadran', 'roue'])) return modularClock;
    if (has(['bande', 'band', 'zone-des-restes', 'restes-autorises'])) {
      return remainderBand;
    }
    if (has(['brique', 'brick', 'facteurs-premiers'])) return factorBricks;
    if (has(['carrelage', 'carreau', 'tile', 'pavage', 'rythme'])) {
      return tiling;
    }
    if (has(['boite', 'carton', 'box', 'paquet', 'remplissent'])) {
      return grouping;
    }
    return none;
  }
}
