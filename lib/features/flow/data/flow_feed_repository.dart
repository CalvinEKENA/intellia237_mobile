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
  ]) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final String? establishmentId;

  @override
  Future<FlowFeedPage> fetchPage({
    required String classLevel,
    String? cursor,
    int limit = kFlowPageSize,
  }) async {
    // L'ordre est déterministe : priorité éditoriale d'abord, puis date de
    // publication, puis identifiant. Sans ce dernier critère, deux
    // publications de même priorité et même date pourraient s'échanger d'une
    // requête à l'autre et réapparaître au fil de la pagination.
    var query = _firestore
        .collection(kFlowItemsCollection)
        .where('status', isEqualTo: 'published')
        .where('classLevels', arrayContains: classLevel)
        .orderBy('priority', descending: true)
        .orderBy('publishedAt', descending: true)
        .orderBy(FieldPath.documentId)
        .limit(limit);

    if (cursor != null) {
      final anchor = await _firestore
          .collection(kFlowItemsCollection)
          .doc(cursor)
          .get();
      // Une ancre disparue — publication archivée entre deux pages — ne doit
      // pas interrompre la lecture : on repart du début plutôt que d'échouer.
      if (anchor.exists) query = query.startAfterDocument(anchor);
    }

    final snapshot = await query.get();
    final now = DateTime.now();
    final items = <FlowItem>[];
    for (final doc in snapshot.docs) {
      final item = FlowItem.fromFirestore(doc.id, doc.data());
      // Un document illisible ou programmé plus tard est ignoré, pas fatal.
      if (item == null || !item.isVisibleAt(now)) continue;
      if (item.scope.isEstablishment &&
          item.scope.establishmentId != establishmentId) {
        continue;
      }
      items.add(item);
    }

    return FlowFeedPage(
      items: items,
      // Le curseur suit le dernier document *lu*, pas le dernier retenu :
      // sinon une page entièrement filtrée bloquerait la pagination.
      nextCursor: snapshot.docs.length < limit ? null : snapshot.docs.last.id,
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
