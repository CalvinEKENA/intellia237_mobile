import 'package:flutter/widgets.dart';

/// Description d'une expérience interactive, telle qu'elle est stockée.
///
/// Registre de décisions : un bloc interactif ne transporte **jamais de
/// code** — seulement une clé et une configuration de données. C'est ce qui
/// rend l'exécution distante impossible par construction : le catalogue des
/// composants est compilé dans l'application, et une clé inconnue ne peut
/// rien déclencher.
@immutable
class InteractiveComponentSpec {
  const InteractiveComponentSpec({
    required this.componentKey,
    this.config = const <String, Object?>{},
    this.summary,
  });

  /// Identifiant du composant, versionné : `pythagoras_visual_v1`.
  ///
  /// La version fait partie de la clé. Faire évoluer un composant de façon
  /// incompatible consiste à publier `_v2` et à laisser `_v1` servir les
  /// contenus déjà publiés, plutôt qu'à modifier un composant sous les pieds
  /// des leçons existantes.
  final String componentKey;

  final Map<String, Object?> config;

  /// Ce que l'activité apporte, en une phrase.
  ///
  /// Sert de repli lisible quand le composant n'est pas disponible — une
  /// version plus ancienne de l'application, par exemple.
  final String? summary;

  @override
  bool operator ==(Object other) =>
      other is InteractiveComponentSpec &&
      other.componentKey == componentKey &&
      other.summary == summary &&
      _sameConfig(other.config, config);

  @override
  int get hashCode => Object.hash(componentKey, summary, config.length);

  static bool _sameConfig(Map<String, Object?> a, Map<String, Object?> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }
}

/// Verdict d'une validation de configuration.
@immutable
class InteractiveConfigResult {
  const InteractiveConfigResult.valid() : reason = null;
  const InteractiveConfigResult.invalid(this.reason);

  final String? reason;

  bool get isValid => reason == null;
}

/// Un composant interactif natif, enregistré à la compilation.
abstract interface class InteractiveComponent {
  /// Clé versionnée sous laquelle ce composant est publié.
  String get componentKey;

  /// Vérifie la configuration avant toute construction.
  ///
  /// Une configuration invalide ne doit jamais atteindre le rendu : mieux
  /// vaut un repli explicite qu'un composant qui s'effondre au milieu d'une
  /// leçon.
  InteractiveConfigResult validate(Map<String, Object?> config);

  Widget build(BuildContext context, Map<String, Object?> config);
}

/// Catalogue des expériences interactives disponibles.
///
/// Rien n'y entre à l'exécution : les composants sont enregistrés au
/// démarrage, à partir de code compilé. Une clé absente — contenu plus récent
/// que l'application installée — n'est pas une erreur, c'est un repli.
class InteractiveComponentRegistry {
  InteractiveComponentRegistry([
    Iterable<InteractiveComponent> components = const <InteractiveComponent>[],
  ]) {
    for (final component in components) {
      register(component);
    }
  }

  final _components = <String, InteractiveComponent>{};

  void register(InteractiveComponent component) {
    assert(
      !_components.containsKey(component.componentKey),
      'Composant déjà enregistré : ${component.componentKey}. '
      'Une évolution incompatible doit publier une nouvelle version de clé.',
    );
    _components[component.componentKey] = component;
  }

  bool contains(String componentKey) => _components.containsKey(componentKey);

  Iterable<String> get keys => _components.keys;

  InteractiveComponent? resolve(String componentKey) =>
      _components[componentKey];

  /// Décrit pourquoi une expérience ne peut pas être rendue, ou null si elle
  /// le peut.
  String? rejectionReason(InteractiveComponentSpec spec) {
    final component = _components[spec.componentKey];
    if (component == null) {
      return 'Cette activité demande une version plus récente '
          "de l'application.";
    }
    final verdict = component.validate(spec.config);
    return verdict.isValid ? null : verdict.reason;
  }
}
