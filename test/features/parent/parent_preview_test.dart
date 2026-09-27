import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/parent/application/parent_preview.dart';

/// Contrôleur d'authentification de test : rend un état fixe et permet de le
/// faire évoluer, sans toucher à Firebase.
class _TestAuthController extends AuthController {
  _TestAuthController(this._initial);

  final AuthState _initial;

  @override
  AuthState build() => _initial;

  void emit(AuthState next) => state = next;
}

AuthState _superAdmin({
  String uid = 'super-admin-uid',
  String email = 'admin@example.com',
}) => AuthState.authenticated(
  role: AppRole.admin,
  userId: uid,
  email: email,
  isSuperAdmin: true,
);

ProviderContainer _containerFor(_TestAuthController controller) {
  final container = ProviderContainer(
    overrides: [authControllerProvider.overrideWith(() => controller)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('canActivateParentPreview (habilitation)', () {
    test('habilitation serveur requise, adresse sans effet', () {
      expect(canActivateParentPreview(_superAdmin()), isTrue);
      expect(
        canActivateParentPreview(_superAdmin(email: '  Admin@Example.com ')),
        isTrue,
      );
    });

    test('un autre e-mail conserve la même habilitation serveur', () {
      expect(
        canActivateParentPreview(_superAdmin(email: 'someone@else.com')),
        isTrue,
      );
    });

    test('refusé pour un admin non super-admin', () {
      expect(
        canActivateParentPreview(
          const AuthState.authenticated(
            role: AppRole.admin,
            userId: 'admin-uid',
            email: 'admin@example.com',
          ),
        ),
        isFalse,
      );
    });

    test('refusé pour parent/enseignant/élève et hors session', () {
      expect(
        canActivateParentPreview(
          const AuthState.authenticated(
            role: AppRole.parent,
            userId: 'p',
            email: 'admin@example.com',
            isSuperAdmin: true,
          ),
        ),
        isTrue,
        reason:
            'L’habilitation serveur fait autorité, indépendamment de l’adresse',
      );
      expect(
        canActivateParentPreview(const AuthState.unauthenticated()),
        isFalse,
      );
    });
  });

  group('ParentPreviewController', () {
    test('enter réussit pour le super-admin et active le mode', () {
      final container = _containerFor(_TestAuthController(_superAdmin()));
      final notifier = container.read(parentPreviewControllerProvider.notifier);

      expect(notifier.enter(), isTrue);
      expect(container.read(parentPreviewControllerProvider).active, isTrue);
    });

    test(
      'enter échoue sans habilitation serveur, même avec le même e-mail',
      () {
        final container = _containerFor(
          _TestAuthController(
            const AuthState.authenticated(
              role: AppRole.admin,
              userId: 'ordinary-admin',
              email: 'admin@example.com',
            ),
          ),
        );
        final notifier = container.read(
          parentPreviewControllerProvider.notifier,
        );

        expect(notifier.enter(targetParentUid: 'other'), isFalse);
        expect(container.read(parentPreviewControllerProvider).active, isFalse);
      },
    );

    test('exit désactive et revient au compte propre', () {
      final container = _containerFor(_TestAuthController(_superAdmin()));
      final notifier = container.read(parentPreviewControllerProvider.notifier);

      notifier.enter(targetParentUid: 'parent-42', targetParentLabel: 'Awa');
      expect(container.read(effectiveParentUidProvider), 'parent-42');

      notifier.exit();
      expect(container.read(parentPreviewControllerProvider).active, isFalse);
      expect(container.read(effectiveParentUidProvider), 'super-admin-uid');
    });

    test('la prévisualisation se réinitialise si l\'identité change', () {
      final controller = _TestAuthController(_superAdmin());
      final container = _containerFor(controller);
      final notifier = container.read(parentPreviewControllerProvider.notifier);
      notifier.enter(targetParentUid: 'parent-42');
      expect(container.read(parentPreviewControllerProvider).active, isTrue);

      controller.emit(
        const AuthState.authenticated(
          role: AppRole.parent,
          userId: 'someone-else',
        ),
      );
      expect(container.read(parentPreviewControllerProvider).active, isFalse);
    });
  });

  group('effectiveParentUidProvider (cible du tableau de bord)', () {
    test('utilise l\'UID cible pendant la prévisualisation', () {
      final container = _containerFor(_TestAuthController(_superAdmin()));
      container
          .read(parentPreviewControllerProvider.notifier)
          .enter(targetParentUid: 'target-parent-uid');
      expect(container.read(effectiveParentUidProvider), 'target-parent-uid');
    });

    test('retombe sur l\'UID propre quand aucune cible n\'est choisie', () {
      final container = _containerFor(_TestAuthController(_superAdmin()));
      container.read(parentPreviewControllerProvider.notifier).enter();
      expect(container.read(effectiveParentUidProvider), 'super-admin-uid');
    });
  });

  group('ParentPreviewState.isImpersonating (garde des paiements)', () {
    test('vrai seulement en prévisualisation d\'un AUTRE parent', () {
      const own = 'me';
      expect(
        const ParentPreviewState(
          active: true,
          targetParentUid: 'other',
        ).isImpersonating(own),
        isTrue,
      );
      expect(
        const ParentPreviewState(
          active: true,
          targetParentUid: 'me',
        ).isImpersonating(own),
        isFalse,
      );
      expect(
        const ParentPreviewState(active: true).isImpersonating(own),
        isFalse,
      );
      expect(
        const ParentPreviewState(targetParentUid: 'other').isImpersonating(own),
        isFalse,
        reason: 'inactif ⇒ jamais impersonation',
      );
    });
  });
}
