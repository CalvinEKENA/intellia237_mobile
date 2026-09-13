import 'package:cloud_functions/cloud_functions.dart';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/flow_item.dart';
import '../../auth/application/auth_controller.dart';

/// Collection des publications du fil pédagogique.
const kFlowItemsCollection = 'flow_items';

/// Nombre de publications lues par requête.
///
/// Le fil se parcourt carte par carte : charger tout `flow_items` en mémoire
/// serait coûteux sans rien apporter, et deviendrait ruineux à mesure que le
/// catalogue grandit.
const kFlowPageSize = 10;

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

/// Consume the cursor, including pages containing only filtered-out entries.
/// Previously the UI silently stopped after its first ten documents.
Future<List<FlowItem>> fetchFlowCatalog(
  FlowFeedRepository repository,
  String classLevel,
) async {
  final items = <String, FlowItem>{};
  final seenCursors = <String>{};
  String? cursor;
  do {
    final page = await repository.fetchPage(
      classLevel: classLevel,
      cursor: cursor,
      limit: 100,
    );
    for (final item in page.items) {
      items[item.id] = item;
    }
    cursor = page.nextCursor;
  } while (cursor != null && seenCursors.add(cursor));
  return items.values.toList(growable: false);
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
      for (final item in items)
        <String, Object?>{'id': item.id, ...item.toFirestore()},
    ]);
    await _prefs.setString(_key(classLevel), payload);
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

final flowFeedRepositoryProvider = Provider<FlowFeedRepository>(
  (ref) => FirestoreFlowFeedRepository(
    null,
    ref.watch(authControllerProvider).establishmentId,
  ),
);
