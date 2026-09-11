import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/admin/application/flow_composer_providers.dart';
import 'package:intellia237/features/admin/domain/content_permissions.dart';
import 'package:intellia237/features/admin/domain/content_scope.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';

/// Où naît ce que l'on compose. Le super-admin publie pour une classe, et ce
/// contenu paraît dans cette classe de chaque établissement : il ne doit
/// jamais retomber dans le périmètre d'une seule école.
void main() {
  ContentScope scopeFor(ContentActor? actor) {
    final container = ProviderContainer(
      overrides: [contentActorProvider.overrideWithValue(actor)],
    );
    addTearDown(container.dispose);
    return container.read(contentAuthoringScopeProvider);
  }

  test('le super-admin compose au national, même rattaché à une école', () {
    expect(
      scopeFor(
        const ContentActor(
          uid: 'root',
          role: AppRole.admin,
          establishmentId: 'lycee-a',
          unrestricted: true,
        ),
      ),
      ContentScope.global,
    );
  });

  test('une direction compose pour son école', () {
    expect(
      scopeFor(
        const ContentActor(
          uid: 'head',
          role: AppRole.admin,
          establishmentId: 'lycee-a',
        ),
      ),
      const ContentScope(
        type: ContentScopeType.establishment,
        establishmentId: 'lycee-a',
      ),
    );
  });

  test('sans école, l’auteur retombe sur le national, que les règles '
      'lui refusent', () {
    expect(
      scopeFor(const ContentActor(uid: 'prof', role: AppRole.teacher)),
      ContentScope.global,
    );
  });
}
