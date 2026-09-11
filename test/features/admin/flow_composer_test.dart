import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/admin/application/flow_composer_providers.dart';
import 'package:intellia237/features/admin/domain/content_permissions.dart';
import 'package:intellia237/features/admin/domain/content_scope.dart';
import 'package:intellia237/features/admin/domain/editorial_workflow.dart';
import 'package:intellia237/features/admin/presentation/flow_composer_screen.dart';
import 'package:intellia237/features/admin/presentation/flow_publications_tab.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/flow/domain/flow_item.dart';

/// Le compositeur ne recopie jamais le média source, et rien n'atteint l'élève
/// sans passer par le workflow éditorial.
void main() {
  FlowItem draft(String id, {String status = 'draft', String? createdBy}) =>
      FlowItem(
        id: id,
        type: FlowItemType.notion,
        title: 'Pythagore',
        hook: 'En une image',
        subjectId: 'maths',
        classLevels: const ['terminale'],
        status: status,
        createdBy: createdBy,
        payload: const {'insight': 'Le carré de l’hypoténuse.'},
      );

  Future<void> pumpComposer(
    WidgetTester tester, {
    required _RecordingRepository repository,
    FlowItem? initial,
  }) async {
    // Écran large : l'aperçu est alors à côté du formulaire, donc réellement
    // construit. En colonne il vit sous la ligne de flottaison d'une liste
    // paresseuse, et un test ne verrait qu'un widget non monté.
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [adminFlowRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          // Le compositeur se referme sur lui-même après enregistrement : il
          // lui faut une route en dessous, comme dans le Studio.
          home: const Scaffold(body: SizedBox.shrink()),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: SizedBox.shrink()),
          ),
        ),
      ),
    );

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(
      navigator.push(
        MaterialPageRoute<bool>(
          builder: (_) =>
              FlowComposerScreen(classLevel: 'terminale', initial: initial),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Les cartes du fil s'animent à l'entrée ; on démonte l'arbre en fin de
    // test pour que leurs minuteries n'y survivent pas.
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });
  }

  group('compositeur', () {
    testWidgets('un titre est requis avant d’enregistrer', (tester) async {
      final repository = _RecordingRepository();
      await pumpComposer(tester, repository: repository);

      final save = tester.widget<TextButton>(
        find.byKey(const ValueKey('flow-composer-save')),
      );
      expect(save.onPressed, isNull);
    });

    testWidgets('une publication complète s’enregistre en brouillon', (
      tester,
    ) async {
      final repository = _RecordingRepository();
      await pumpComposer(tester, repository: repository, initial: draft('a'));

      await tester.tap(find.byKey(const ValueKey('flow-composer-save')));
      await tester.pump();

      expect(repository.saved, hasLength(1));
      // Rien ne part publié : la mise en ligne est un geste distinct.
      expect(repository.saved.single.status, 'draft');
    });

    testWidgets('le média est référencé, jamais recopié', (tester) async {
      final repository = _RecordingRepository();
      await pumpComposer(tester, repository: repository, initial: draft('a'));

      await tester.enterText(
        find.byKey(const ValueKey('flow-composer-storage-path')),
        'educational_assets/global/terminale/maths/l1/a1/capsule.mp3',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('flow-composer-save')));
      await tester.pump();

      final saved = repository.saved.single;
      expect(
        saved.ref.storagePath,
        'educational_assets/global/terminale/maths/l1/a1/capsule.mp3',
      );
      // La charge utile ne contient que du texte court.
      expect(saved.payload.values.whereType<List<int>>(), isEmpty);
    });

    testWidgets('l’aperçu montre le rendu élève réel', (tester) async {
      final repository = _RecordingRepository();
      await pumpComposer(tester, repository: repository, initial: draft('a'));

      expect(find.byKey(const ValueKey('flow-preview-card')), findsOneWidget);
    });

    testWidgets('une publication incomplète est signalée, pas rendue', (
      tester,
    ) async {
      final repository = _RecordingRepository();
      // Un type audio sans média référencé n'est pas présentable.
      await pumpComposer(
        tester,
        repository: repository,
        initial: draft('a').copyWith(type: FlowItemType.audio),
      );

      expect(find.byKey(const ValueKey('flow-preview-empty')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('flow-composer-incomplete')),
        findsOneWidget,
      );
    });
  });

  group('permissions de publication', () {
    // L'administration générale publie le national ; une direction
    // d'établissement publie pour son école seulement.
    const admin = ContentActor(
      uid: 'admin-1',
      role: AppRole.admin,
      unrestricted: true,
    );
    const head = ContentActor(
      uid: 'head-1',
      role: AppRole.admin,
      establishmentId: 'lycee-a',
    );
    const prof = ContentActor(uid: 'prof-1', role: AppRole.teacher);

    test('l’administration publie', () async {
      final repository = _RecordingRepository();
      final service = FlowPublicationService(repository);

      final published = await service.transition(
        item: draft('a', status: 'inReview'),
        next: EditorialStatus.published,
        actor: admin,
      );

      expect(published.status, 'published');
      expect(published.publishedAt, isNotNull);
    });

    test('une direction publie pour son école, pas au national', () async {
      final repository = _RecordingRepository();
      final service = FlowPublicationService(repository);
      const school = ContentScope(
        type: ContentScopeType.establishment,
        establishmentId: 'lycee-a',
      );

      final published = await service.transition(
        item: draft('b', status: 'inReview').copyWith(scope: school),
        next: EditorialStatus.published,
        actor: head,
      );
      expect(published.status, 'published');
      expect(published.scope, school);

      await expectLater(
        service.transition(
          item: draft('c', status: 'inReview'),
          next: EditorialStatus.published,
          actor: head,
        ),
        throwsStateError,
      );
    });

    test('un enseignant ne publie pas', () async {
      final repository = _RecordingRepository();
      final service = FlowPublicationService(repository);

      await expectLater(
        service.transition(
          item: draft('a', status: 'inReview', createdBy: 'prof-1'),
          next: EditorialStatus.published,
          actor: prof,
        ),
        throwsA(isA<StateError>()),
      );
      expect(repository.saved, isEmpty);
    });

    test('une publication en ligne ne redevient pas brouillon', () async {
      final repository = _RecordingRepository();
      final service = FlowPublicationService(repository);

      await expectLater(
        service.transition(
          item: draft('a', status: 'published'),
          next: EditorialStatus.draft,
          actor: admin,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('seuls les rôles pédagogiques composent', () {
      expect(canComposeFlow(AppRole.admin), isTrue);
      expect(canComposeFlow(AppRole.teacher), isTrue);
      expect(canComposeFlow(AppRole.student), isFalse);
      expect(canComposeFlow(AppRole.parent), isFalse);
      expect(canComposeFlow(null), isFalse);
    });
  });

  group('liste des publications', () {
    testWidgets('un fil vide invite à composer la première', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminFlowItemsProvider(
              'terminale',
            ).overrideWith((ref) async => <FlowItem>[]),
          ],
          child: const MaterialApp(
            home: FlowPublicationsTab(classLevel: 'terminale'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.byKey(const ValueKey('flow-publications-empty')),
        findsOneWidget,
      );
    });

    testWidgets('les brouillons sont visibles du Studio', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminFlowItemsProvider(
              'terminale',
            ).overrideWith((ref) async => [draft('a'), draft('b')]),
          ],
          child: const MaterialApp(
            home: FlowPublicationsTab(classLevel: 'terminale'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      // L'élève ne recevrait aucun des deux : le Studio, si.
      expect(find.byKey(const ValueKey('flow-item-a')), findsOneWidget);
      expect(find.byKey(const ValueKey('flow-item-b')), findsOneWidget);
    });
  });
}

class _RecordingRepository implements AdminFlowRepository {
  final saved = <FlowItem>[];
  final deleted = <String>[];

  @override
  Future<List<FlowItem>> listForClass(String classLevel) async => saved;

  @override
  Future<String> save(FlowItem item) async {
    saved.add(item);
    return item.id.isEmpty ? 'generated-id' : item.id;
  }

  @override
  Future<void> delete(String id) async => deleted.add(id);
}
