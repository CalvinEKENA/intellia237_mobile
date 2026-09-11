import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_role.dart';
import '../../flow/data/flow_feed_repository.dart';
import '../../flow/domain/flow_item.dart';
import '../domain/content_permissions.dart';
import '../domain/content_scope.dart';
import '../domain/editorial_workflow.dart';

/// Publications du fil, du point de vue du Studio.
///
/// L'administration voit tous les états — brouillons compris — là où l'élève
/// ne reçoit que le publié. C'est la même collection, lue avec d'autres
/// droits ; les règles Firestore font la séparation, pas le client.
abstract interface class AdminFlowRepository {
  Future<List<FlowItem>> listForClass(String classLevel);

  /// Crée ou remplace une publication. Renvoie son identifiant.
  Future<String> save(FlowItem item);

  Future<void> delete(String id);
}

class FirestoreAdminFlowRepository implements AdminFlowRepository {
  FirestoreAdminFlowRepository([FirebaseFirestore? firestore])
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _items =>
      _firestore.collection(kFlowItemsCollection);

  @override
  Future<List<FlowItem>> listForClass(String classLevel) async {
    final snapshot = await _items
        .where('classLevels', arrayContains: classLevel)
        .orderBy('updatedAt', descending: true)
        .limit(100)
        .get();

    final items = <FlowItem>[];
    for (final doc in snapshot.docs) {
      final item = FlowItem.fromFirestore(doc.id, doc.data());
      if (item != null) items.add(item);
    }
    return items;
  }

  @override
  Future<String> save(FlowItem item) async {
    final data = <String, Object?>{
      ...item.toFirestore(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (item.id.isEmpty) {
      final created = await _items.add({
        ...data,
        'createdAt': DateTime.now().toIso8601String(),
      });
      return created.id;
    }
    await _items.doc(item.id).set(data, SetOptions(merge: true));
    return item.id;
  }

  @override
  Future<void> delete(String id) => _items.doc(id).delete();
}

final adminFlowRepositoryProvider = Provider<AdminFlowRepository>(
  (ref) => FirestoreAdminFlowRepository(),
);

final adminFlowItemsProvider = FutureProvider.family<List<FlowItem>, String>(
  (ref, classLevel) =>
      ref.watch(adminFlowRepositoryProvider).listForClass(classLevel),
);

/// L'acteur courant, tel que les permissions de contenu le voient.
final contentActorProvider = Provider<ContentActor?>((ref) {
  final auth = ref.watch(authControllerProvider);
  final uid = auth.userId;
  final role = auth.role;
  if (uid == null || role == null) return null;
  return ContentActor(
    uid: uid,
    role: role,
    establishmentId: auth.establishmentId,
    unrestricted: auth.isSuperAdmin,
  );
});

/// Publie ou fait avancer une publication du fil.
///
/// Registre de décisions : la transition est vérifiée ici pour que
/// l'interface ne propose rien d'impossible, mais les règles Firestore
/// restent seules juges — un client modifié n'obtiendrait rien de plus.
class FlowPublicationService {
  const FlowPublicationService(this._repository);

  final AdminFlowRepository _repository;

  Future<FlowItem> transition({
    required FlowItem item,
    required EditorialStatus next,
    required ContentActor actor,
    // Par défaut, le périmètre est celui de la publication elle-même.
    ContentScope? scope,
  }) async {
    final metadata = EditorialWorkflowMetadata(
      status: EditorialStatus.fromString(item.status),
      publishedAt: item.publishedAt,
      scheduledPublishAt: item.scheduledAt,
    );

    final allowed = ContentPermissions.canTransition(
      actor: actor,
      scope: scope ?? item.scope,
      metadata: metadata,
      next: next,
      authorUid: item.createdBy,
    );
    if (!allowed) {
      throw StateError(
        'Transition ${item.status} → ${next.name} non autorisée pour '
        '${actor.role.name}.',
      );
    }

    final now = DateTime.now();
    final updated = item.copyWith(
      status: next.name,
      publishedAt: next == EditorialStatus.published ? now : item.publishedAt,
      updatedAt: now,
    );
    await _repository.save(updated);
    return updated;
  }
}

final flowPublicationServiceProvider = Provider<FlowPublicationService>(
  (ref) => FlowPublicationService(ref.watch(adminFlowRepositoryProvider)),
);

/// Où naît ce que l'acteur courant compose.
///
/// L'administration générale écrit le programme national ; le personnel
/// d'une école écrit pour son école, seul périmètre que les règles lui
/// ouvrent.
final contentAuthoringScopeProvider = Provider<ContentScope>((ref) {
  final ContentActor? actor = ref.watch(contentActorProvider);
  final establishmentId = actor?.establishmentId?.trim() ?? '';
  if (actor == null || actor.unrestricted || establishmentId.isEmpty) {
    return ContentScope.global;
  }
  return ContentScope(
    type: ContentScopeType.establishment,
    establishmentId: establishmentId,
  );
});

/// Rôles autorisés à composer une publication du fil.
bool canComposeFlow(AppRole? role) =>
    role == AppRole.admin || role == AppRole.teacher;
