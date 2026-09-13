import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/admin/domain/content_permissions.dart';
import 'package:intellia237/features/admin/domain/content_scope.dart';
import 'package:intellia237/features/admin/domain/editorial_workflow.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';

/// Le cloisonnement et la barrière éditoriale sont les deux garanties du
/// Studio : un établissement ne touche pas au travail d'un autre, et rien ne
/// devient visible aux élèves sans publication explicite.
void main() {
  const leclerc = ContentScope(
    type: ContentScopeType.establishment,
    establishmentId: 'lycee-leclerc',
  );
  const voisin = ContentScope(
    type: ContentScopeType.establishment,
    establishmentId: 'lycee-voisin',
  );
  const global = ContentScope.global;

  const profLeclerc = ContentActor(
    uid: 'prof-1',
    role: AppRole.teacher,
    establishmentId: 'lycee-leclerc',
  );
  const adminLeclerc = ContentActor(
    uid: 'admin-1',
    role: AppRole.admin,
    establishmentId: 'lycee-leclerc',
  );
  const eleve = ContentActor(uid: 'eleve-1', role: AppRole.student);

  group('le super administrateur du terrain', () {
    // Tel que l'application le construit réellement : le rôle stocké
    // « super_admin » devient AppRole.admin, et le compte historique ne porte
    // aucun établissement. C'est le compte avec lequel INTELLIA publie.
    const superAdmin = ContentActor(
      uid: 'super-1',
      role: AppRole.admin,
      unrestricted: true,
    );

    test('il écrit le programme national sans établissement', () {
      expect(parseStoredAppRole('super_admin').role, AppRole.admin);
      expect(parseStoredAppRole('super_admin').isSuperAdmin, isTrue);
      expect(superAdmin.establishmentId, isNull);
      expect(superAdmin.canWriteInScope(global), isTrue);
    });

    test('il publie pour n’importe quel établissement', () {
      // Sans cette portée, l'administration générale ne pourrait alimenter
      // que le programme national : aucun contenu pour un lycée donné.
      for (final scope in [leclerc, voisin]) {
        expect(superAdmin.canWriteInScope(scope), isTrue, reason: '$scope');
        expect(superAdmin.canReadScope(scope), isTrue, reason: '$scope');
      }
    });

    test('un administrateur d’établissement reste borné au sien', () {
      expect(adminLeclerc.canWriteInScope(voisin), isFalse);
    });

    test('il mène une publication du brouillon à la mise en ligne', () {
      var metadata = const EditorialWorkflowMetadata(
        status: EditorialStatus.draft,
      );
      for (final next in const [
        EditorialStatus.inReview,
        EditorialStatus.approved,
        EditorialStatus.published,
      ]) {
        expect(
          ContentPermissions.canTransition(
            actor: superAdmin,
            scope: global,
            metadata: metadata,
            next: next,
            authorUid: superAdmin.uid,
          ),
          isTrue,
          reason: 'transition vers ${next.name} refusée',
        );
        metadata = EditorialWorkflowMetadata(status: next);
      }
    });

    test('un contenu en ligne ne redevient pas un brouillon en place', () {
      expect(
        ContentPermissions.canTransition(
          actor: superAdmin,
          scope: global,
          metadata: const EditorialWorkflowMetadata(
            status: EditorialStatus.published,
          ),
          next: EditorialStatus.draft,
        ),
        isFalse,
      );
    });
  });

  group('cloisonnement par établissement', () {
    test('un enseignant écrit dans son établissement', () {
      expect(profLeclerc.canWriteInScope(leclerc), isTrue);
    });

    test('il ne touche pas à l’établissement voisin', () {
      expect(profLeclerc.canWriteInScope(voisin), isFalse);
    });

    test('il ne touche pas au programme national', () {
      // Le programme officiel n'appartient à personne en particulier.
      expect(profLeclerc.canWriteInScope(global), isFalse);
    });

    test('un chef d’établissement n’écrit pas le programme national', () {
      // Le national est celui de toutes les écoles : l'administration d'un
      // établissement ne le rédige pas pour les autres.
      expect(adminLeclerc.canWriteInScope(global), isFalse);
    });

    test('un enseignant sans établissement n’écrit nulle part', () {
      const orphelin = ContentActor(uid: 'p', role: AppRole.teacher);
      expect(orphelin.canWriteInScope(leclerc), isFalse);
      expect(orphelin.canWriteInScope(global), isFalse);
    });

    test('un élève n’écrit jamais', () {
      expect(eleve.canWriteInScope(global), isFalse);
      expect(eleve.canWriteInScope(leclerc), isFalse);
    });

    test('le contenu national est lisible par tous', () {
      expect(eleve.canReadScope(global), isTrue);
    });

    test('le contenu d’un établissement ne sort pas de ses murs', () {
      expect(profLeclerc.canReadScope(voisin), isFalse);
      expect(profLeclerc.canReadScope(leclerc), isTrue);
    });
  });

  group('barrière éditoriale', () {
    const draft = EditorialWorkflowMetadata.draft;
    const inReview = EditorialWorkflowMetadata(
      status: EditorialStatus.inReview,
    );
    const published = EditorialWorkflowMetadata(
      status: EditorialStatus.published,
    );

    test('l’auteur soumet son brouillon à la relecture', () {
      expect(
        ContentPermissions.canTransition(
          actor: profLeclerc,
          scope: leclerc,
          metadata: draft,
          next: EditorialStatus.inReview,
          authorUid: 'prof-1',
        ),
        isTrue,
      );
    });

    test('un enseignant publie son contenu dans son établissement', () {
      expect(
        ContentPermissions.canTransition(
          actor: profLeclerc,
          scope: leclerc,
          metadata: inReview,
          next: EditorialStatus.published,
          authorUid: 'prof-1',
        ),
        isTrue,
      );
    });

    test('un enseignant ne publie pas le contenu d’un autre auteur', () {
      expect(
        ContentPermissions.canTransition(
          actor: profLeclerc,
          scope: leclerc,
          metadata: inReview,
          next: EditorialStatus.published,
          authorUid: 'autre-prof',
        ),
        isFalse,
      );
    });

    test('l’administration approuve puis publie', () {
      expect(
        ContentPermissions.canTransition(
          actor: adminLeclerc,
          scope: leclerc,
          metadata: inReview,
          next: EditorialStatus.approved,
        ),
        isTrue,
      );
      expect(
        ContentPermissions.canTransition(
          actor: adminLeclerc,
          scope: leclerc,
          metadata: inReview,
          next: EditorialStatus.published,
        ),
        isTrue,
      );
    });

    test(
      'publié ne redevient jamais brouillon, même pour l’administration',
      () {
        expect(
          ContentPermissions.canTransition(
            actor: adminLeclerc,
            scope: leclerc,
            metadata: published,
            next: EditorialStatus.draft,
          ),
          isFalse,
        );
      },
    );

    test('publié s’archive', () {
      expect(
        ContentPermissions.canTransition(
          actor: adminLeclerc,
          scope: leclerc,
          metadata: published,
          next: EditorialStatus.archived,
        ),
        isTrue,
      );
    });

    test('le périmètre prime sur le rôle', () {
      // Administrateur, mais d'un autre établissement : aucun geste possible.
      expect(
        ContentPermissions.canTransition(
          actor: adminLeclerc,
          scope: voisin,
          metadata: inReview,
          next: EditorialStatus.published,
        ),
        isFalse,
      );
    });

    test('modifier un contenu publié impose une révision', () {
      expect(ContentPermissions.requiresRevisionToEdit(published), isTrue);
      expect(ContentPermissions.requiresRevisionToEdit(draft), isFalse);
    });
  });

  group('gestes proposés à l’interface', () {
    test('l’enseignant peut soumettre ou publier son brouillon', () {
      final gestes = ContentPermissions.availableTransitions(
        actor: profLeclerc,
        scope: leclerc,
        metadata: EditorialWorkflowMetadata.draft,
        authorUid: 'prof-1',
      );

      expect(gestes, [EditorialStatus.inReview, EditorialStatus.published]);
    });

    test('l’administration dispose des gestes de publication', () {
      final gestes = ContentPermissions.availableTransitions(
        actor: adminLeclerc,
        scope: leclerc,
        metadata: const EditorialWorkflowMetadata(
          status: EditorialStatus.inReview,
        ),
      );

      expect(
        gestes,
        containsAll(<EditorialStatus>[
          EditorialStatus.approved,
          EditorialStatus.rejected,
          EditorialStatus.published,
        ]),
      );
    });

    test('un contenu publié n’offre que l’archivage', () {
      final gestes = ContentPermissions.availableTransitions(
        actor: adminLeclerc,
        scope: leclerc,
        metadata: const EditorialWorkflowMetadata(
          status: EditorialStatus.published,
        ),
      );

      expect(gestes, [EditorialStatus.archived]);
    });

    test('hors périmètre, aucun geste', () {
      final gestes = ContentPermissions.availableTransitions(
        actor: profLeclerc,
        scope: voisin,
        metadata: EditorialWorkflowMetadata.draft,
      );

      expect(gestes, isEmpty);
    });
  });
}
