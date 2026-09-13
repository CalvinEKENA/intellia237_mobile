import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_role.dart';
import '../../flow/data/flow_feed_repository.dart';
import '../../flow/domain/flow_item.dart';
import '../../flow/domain/flow_item_mapper.dart';
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
    final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('listEditorialFlow')
        .call<Map<String, dynamic>>({'classLevel': classLevel});
    return (response.data['items'] as List)
        .map((raw) {
          final data = Map<String, dynamic>.from(raw as Map);
          return FlowItem.fromFirestore(data['id'] as String, data);
        })
        .whereType<FlowItem>()
        .toList();
  }

  @override
  Future<String> save(FlowItem item) async {
    final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('saveFlowPublication')
        .call<Map<String, dynamic>>({
          'id': item.id,
          'content': item.toFirestore(),
        });
    return result.data['id'] as String;
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

    // Rendre visible une carte que le fil écarterait reviendrait à publier
    // du vide : l'élève ne recevrait rien, et personne ne le saurait.
    if ((next == EditorialStatus.published ||
            next == EditorialStatus.scheduled) &&
        FlowItemMapper.toCard(item) == null) {
      throw StateError(
        'Publication incomplète : l’élève ne la verrait pas. '
        'Complète-la avant de la publier.',
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
