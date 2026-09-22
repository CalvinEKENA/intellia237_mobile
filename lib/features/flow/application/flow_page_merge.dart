/// Fusion d'une page suivante du Parcours dans les cartes déjà présentes.
///
/// Règles :
/// - une carte déjà présente, ou répétée dans la page, n'est ajoutée qu'une
///   fois (première occurrence) ;
/// - les nouvelles cartes non terminées passent devant les cartes déjà
///   terminées, mais jamais avant la carte que l'élève regarde ;
/// - les nouvelles cartes déjà terminées vont à la fin, dans l'ordre reçu.
///
/// La page est parcourue une seule fois et matérialisée : aucun itérable
/// paresseux à effet de bord n'est consommé deux fois.
List<T> mergeFlowNextPage<T>({
  required List<T> current,
  required Iterable<T> incoming,
  required String Function(T card) idOf,
  required Set<String> completed,
  required int currentIndex,
}) {
  final known = {for (final card in current) idOf(card)};
  final pending = <T>[];
  final done = <T>[];
  for (final card in incoming) {
    final id = idOf(card);
    if (!known.add(id)) continue;
    (completed.contains(id) ? done : pending).add(card);
  }
  final tail = current.indexWhere((card) => completed.contains(idOf(card)));
  final insertAt = tail > currentIndex ? tail : current.length;
  return [
    ...current.take(insertAt),
    ...pending,
    ...current.skip(insertAt),
    ...done,
  ];
}
