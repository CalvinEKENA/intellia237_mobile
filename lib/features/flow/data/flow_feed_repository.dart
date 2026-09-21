import 'package:cloud_functions/cloud_functions.dart';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/flow_item.dart';
import '../../auth/application/auth_controller.dart';

/// Collection des publications du fil pédagogique.
const kFlowItemsCollection = 'flow_items';

/// Nombre de publications lues par requête, par défaut.
const kFlowPageSize = 10;

/// Première fenêtre du fil : de quoi commencer tout de suite, sans jamais
/// charger tout le catalogue à l'ouverture.
const kFlowFirstPageSize = 12;

/// Pages suivantes, demandées quand l'élève approche de la fin.
const kFlowNextPageSize = 12;

/// L'écran demande la page suivante à ce nombre de cartes de la fin.
const kFlowPrefetchThreshold = 4;

/// Une page peut revenir vide avec un curseur (le serveur borne ce qu'il lit
/// par appel). On en suit au plus ce nombre par demande : jamais de cascade.
const kFlowMaxPagesPerLoad = 2;

/// Au-delà, l'écran cesse de redemander jusqu'à la prochaine ouverture.
const kFlowMaxLoadFailures = 3;

/// Cartes gardées dans le cache hors ligne.
const kFlowCacheLimit = 60;

/// Source des publications du fil.
abstract interface class FlowFeedRepository {
  /// Lit une page de publications visibles pour ce niveau.
  ///
  /// [cursor] est l'identifiant de la dernière publication déjà reçue.
  Future<FlowFeedPage> fetchPage({
    required String classLevel,
    String? cursor,
    int limit,
  });
}

/// Une fenêtre du fil : une page, plus au plus [kFlowMaxPagesPerLoad] - 1
/// pages vides suivies si le serveur a borné sa lecture. Jamais de boucle sur
/// tout le catalogue.
Future<FlowFeedPage> fetchFlowWindow(
  FlowFeedRepository repository,
  String classLevel, {
  String? cursor,
  int limit = kFlowFirstPageSize,
}) async {
  var page = await repository.fetchPage(
    classLevel: classLevel,
    cursor: cursor,
    limit: limit,
  );
  var requests = 1;
  final seenCursors = <String>{?cursor};
  while (page.items.isEmpty &&
      page.nextCursor != null &&
      requests < kFlowMaxPagesPerLoad &&
      seenCursors.add(page.nextCursor!)) {
    page = await repository.fetchPage(
      classLevel: classLevel,
      cursor: page.nextCursor,
      limit: limit,
    );
    requests++;
  }
  return page;
}

class FirestoreFlowFeedRepository implements FlowFeedRepository {
  FirestoreFlowFeedRepository([
    FirebaseFirestore? firestore,
    this.establishmentId,
  ]);

  final String? establishmentId;

  @override
  Future<FlowFeedPage> fetchPage({
    required String classLevel,
    String? cursor,
    int limit = kFlowPageSize,
  }) async {
    final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('readLearningCatalog')
        .call<Map<String, dynamic>>({
          'action': 'flow',
          'classLevel': classLevel,
          'limit': limit,
          'cursor': ?cursor,
        });
    final items = <FlowItem>[];
    for (final doc in response.data['documents'] as List? ?? []) {
      final item = FlowItem.fromFirestore(
        doc['id'] as String,
        Map<String, dynamic>.from(doc['data'] as Map),
      );
      if (item != null && item.isVisibleAt(DateTime.now())) items.add(item);
    }
    return FlowFeedPage(
      items: items,
      nextCursor: response.data['nextCursor'] as String?,
    );
  }
}

/// Dernier fil valide conservé sur l'appareil.
///
/// Registre de décisions : sur une connexion intermittente, un élève doit
/// retrouver ce qu'il avait déjà reçu plutôt qu'un écran vide. Le cache ne
/// remplace pas Firestore, il le relaie quand le réseau manque.
class FlowFeedCache {
  const FlowFeedCache(this._prefs);

  final SharedPreferences _prefs;

  static const _keyPrefix = 'flow_feed_cache_v1_';

  String _key(String classLevel) => '$_keyPrefix$classLevel';

  Future<void> save(String classLevel, List<FlowItem> items) async {
    if (items.isEmpty) return;
    final payload = jsonEncode([
      for (final item in items.take(kFlowCacheLimit))
        <String, Object?>{'id': item.id, ...item.toFirestore()},
    ]);
    await _prefs.setString(_key(classLevel), payload);
  }

  /// Ajoute une page chargée plus tard, sans doublon et dans la limite.
  Future<void> append(String classLevel, List<FlowItem> items) async {
    if (items.isEmpty) return;
    final current = read(classLevel);
    final known = {for (final item in current) item.id};
    await save(classLevel, [
      ...current,
      ...items.where((item) => known.add(item.id)),
    ]);
  }

  List<FlowItem> read(String classLevel) {
    final raw = _prefs.getString(_key(classLevel));
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final items = <FlowItem>[];
      for (final entry in decoded) {
        if (entry is! Map) continue;
        final map = Map<String, Object?>.from(entry);
        final id = map['id'] as String?;
        if (id == null) continue;
        final item = FlowItem.fromFirestore(id, map);
        if (item != null) items.add(item);
      }
      return items;
    } catch (_) {
      // Un cache corrompu ne doit pas empêcher l'application de démarrer.
      return const [];
    }
  }

  Future<void> clear(String classLevel) => _prefs.remove(_key(classLevel));
}

/// Ne dépend que de l'établissement : un simple drapeau de chargement de la
/// session ne doit pas reconstruire le dépôt, donc recomposer le fil.
final flowFeedRepositoryProvider = Provider<FlowFeedRepository>(
  (ref) => FirestoreFlowFeedRepository(
    null,
    ref.watch(authControllerProvider.select((auth) => auth.establishmentId)),
  ),
);
