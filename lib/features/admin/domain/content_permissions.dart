import '../../auth/domain/app_role.dart';
import 'content_scope.dart';
import 'editorial_workflow.dart';

/// Qui peut faire quoi sur un contenu pédagogique.
///
/// Registre de décisions : le modèle actuel ne porte qu'**un seul rôle par
/// compte** (`users/{uid}.role`, comparé à une valeur unique dans les règles
/// Firestore). Les rôles `contentEditor` / `contentReviewer` /
/// `contentPublisher` demandés à terme n'existent donc pas encore, et rien ici
/// ne fait semblant du contraire : l'enseignant tient le rôle d'auteur,
/// l'administration celui de relecteur et de publieur.
///
/// Cette classe est le pendant Dart des règles Firestore. Elle ne les remplace
/// pas — le client n'est pas une autorité — mais elle permet à l'interface de
/// n'offrir que des gestes qui aboutiront, et de le tester.
class ContentActor {
  const ContentActor({
    required this.uid,
    required this.role,
    this.establishmentId,
    this.unrestricted = false,
  });

  final String uid;
  final AppRole role;
  final String? establishmentId;

  /// L'administration générale n'est rattachée à aucun établissement : elle
  /// publie pour tous, sur tous les niveaux. Un administrateur d'établissement
  /// reste, lui, borné au sien.
  final bool unrestricted;

  bool get isAdministration => role == AppRole.admin;
  bool get isTeacher => role == AppRole.teacher;

  /// Le personnel pédagogique : les seuls à pouvoir rédiger.
  bool get isStaff => isAdministration || isTeacher;

  /// Relire, approuver, programmer, publier et archiver relèvent de
  /// l'administration.
  bool get isReviewer => isAdministration;

  /// Vrai quand cet acteur peut écrire dans ce périmètre.
  ///
  /// Le programme national n'appartient à personne en particulier : seule
  /// l'administration générale y touche. Un contenu d'établissement n'est
  /// modifiable
  /// que par le personnel de cet établissement — c'est ce qui empêche un
  /// enseignant d'écraser le travail d'un autre établissement.
  bool canWriteInScope(ContentScope scope) {
    if (!isStaff) return false;
    if (unrestricted) return isAdministration;
    // Le programme national est celui de toutes les écoles : aucun
    // établissement ne le rédige pour les autres.
    if (scope.isGlobal) return false;
    final establishment = establishmentId;
    if (establishment == null || establishment.isEmpty) return false;
    return establishment == scope.establishmentId;
  }

  /// Vrai quand cet acteur peut consulter ce périmètre.
  bool canReadScope(ContentScope scope) {
    if (scope.isGlobal || unrestricted) return true;
    return establishmentId != null && establishmentId == scope.establishmentId;
  }
}

abstract final class ContentPermissions {
  /// Décide si [actor] peut faire passer un contenu à [next].
  ///
  /// Trois conditions se cumulent : le périmètre, la qualité de l'acteur, et
  /// la légalité de la transition elle-même — un contenu publié ne redevient
  /// jamais un brouillon en place, quel que soit le rôle.
  static bool canTransition({
    required ContentActor actor,
    required ContentScope scope,
    required EditorialWorkflowMetadata metadata,
    required EditorialStatus next,
    String? authorUid,
  }) {
    if (!actor.canWriteInScope(scope)) return false;
    return metadata.canTransitionTo(
      next,
      isReviewerOrAdmin: actor.isReviewer,
      isAuthor: authorUid == null || authorUid == actor.uid,
    );
  }

  /// Transitions réellement proposables à cet acteur, dans l'ordre du
  /// parcours éditorial. L'interface s'en sert pour n'afficher que des gestes
  /// qui aboutiront.
  static List<EditorialStatus> availableTransitions({
    required ContentActor actor,
    required ContentScope scope,
    required EditorialWorkflowMetadata metadata,
    String? authorUid,
  }) {
    const ordered = [
      EditorialStatus.draft,
      EditorialStatus.inReview,
      EditorialStatus.approved,
      EditorialStatus.rejected,
      EditorialStatus.scheduled,
      EditorialStatus.published,
      EditorialStatus.archived,
    ];
    return [
      for (final status in ordered)
        if (status != metadata.status &&
            canTransition(
              actor: actor,
              scope: scope,
              metadata: metadata,
              next: status,
              authorUid: authorUid,
            ))
          status,
    ];
  }

  /// Un contenu déjà publié ne se modifie pas : il se révise.
  ///
  /// L'appelant obtient ici la marche à suivre plutôt qu'un simple refus.
  static bool requiresRevisionToEdit(EditorialWorkflowMetadata metadata) =>
      metadata.isPublished;
}
