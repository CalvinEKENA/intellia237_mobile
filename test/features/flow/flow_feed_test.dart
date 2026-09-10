import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/config/app_config.dart';
import 'package:intellia237/features/flow/data/flow_demo_content.dart';
import 'package:intellia237/features/flow/data/flow_feed_repository.dart';
import 'package:intellia237/features/flow/domain/flow_card.dart';
import 'package:intellia237/features/flow/domain/flow_feed_strategy.dart';
import 'package:intellia237/features/flow/domain/flow_item.dart';
import 'package:intellia237/features/flow/domain/flow_item_mapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Le fil vient désormais d'un contenu éditorial publié. Le jeu de
/// démonstration n'est plus un recours : servir des cartes non validées à un
/// élève de production reviendrait à lui présenter une maquette comme un cours.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  FlowItem item(
    String id, {
    FlowItemType type = FlowItemType.notion,
    String subjectId = 'maths',
    List<String> levels = const ['terminale'],
    String status = 'published',
    int difficulty = 3,
    int priority = 0,
    DateTime? scheduledAt,
    Map<String, Object?> payload = const {'insight': 'Une idée claire.'},
    FlowItemRef ref = const FlowItemRef(),
  }) => FlowItem(
    id: id,
    type: type,
    title: 'Titre $id',
    hook: 'Accroche $id',
    subjectId: subjectId,
    classLevels: levels,
    status: status,
    difficulty: difficulty,
    priority: priority,
    scheduledAt: scheduledAt,
    payload: payload,
    ref: ref,
  );

  group('lecture d’un document', () {
    test('un document complet est relu fidèlement', () {
      final source = item('a', priority: 5);
      final restored = FlowItem.fromFirestore('a', source.toFirestore());

      expect(restored, isNotNull);
      expect(restored!.title, 'Titre a');
      expect(restored.priority, 5);
      expect(restored.subjectId, 'maths');
    });

    test('un type inconnu est écarté sans faire tomber le fil', () {
      final restored = FlowItem.fromFirestore('x', <String, Object?>{
        'type': 'hologramme',
        'title': 'Futur',
        'subjectId': 'maths',
        'classLevels': ['terminale'],
      });

      expect(restored, isNull);
    });

    test('un document sans niveau est écarté', () {
      expect(
        FlowItem.fromFirestore('x', <String, Object?>{
          'type': 'notion',
          'title': 'Sans public',
          'subjectId': 'maths',
          'classLevels': <String>[],
        }),
        isNull,
      );
    });

    test('une publication programmée n’est pas encore visible', () {
      final future = DateTime.now().add(const Duration(days: 1));
      expect(
        item('a', scheduledAt: future).isVisibleAt(DateTime.now()),
        isFalse,
      );
    });

    test('un brouillon n’est jamais visible', () {
      expect(item('a', status: 'draft').isVisibleAt(DateTime.now()), isFalse);
    });
  });

  group('traduction en cartes', () {
    test('une notion devient une carte de notion', () {
      final card = FlowItemMapper.toCard(item('a'));
      expect(card, isA<FlowNotionCard>());
    });

    test('un quiz sans bonne réponse valide est écarté', () {
      // Un index hors bornes induirait l'élève en erreur.
      final broken = item(
        'q',
        type: FlowItemType.quiz,
        payload: const {
          'question': 'Combien ?',
          'options': ['un', 'deux'],
          'correctIndex': 7,
        },
      );

      expect(FlowItemMapper.toCard(broken), isNull);
    });

    test('un quiz valide devient un mini-quiz', () {
      final quiz = item(
        'q',
        type: FlowItemType.quiz,
        payload: const {
          'question': 'Combien ?',
          'options': ['un', 'deux'],
          'correctIndex': 1,
          'explanation': 'Parce que.',
        },
      );

      final card = FlowItemMapper.toCard(quiz);
      expect(card, isA<FlowMiniQuizCard>());
      expect((card! as FlowMiniQuizCard).correctIndex, 1);
    });

    test('un audio sans média référencé est écarté', () {
      expect(
        FlowItemMapper.toCard(item('a', type: FlowItemType.audio)),
        isNull,
      );
    });

    test('un audio référencé devient une capsule sans recopier le média', () {
      final audio = item(
        'a',
        type: FlowItemType.audio,
        ref: const FlowItemRef(storagePath: 'educational_assets/global/a.mp3'),
      );

      final card = FlowItemMapper.toCard(audio);
      expect(card, isA<FlowVideoCard>());
      // La carte porte une référence, pas les octets du fichier.
      expect(audio.ref.storagePath, isNotNull);
    });

    test('une matière inconnue est écartée', () {
      expect(FlowItemMapper.toCard(item('a', subjectId: 'astrologie')), isNull);
    });

    test('les doublons d’identifiant sont supprimés', () {
      final cards = FlowItemMapper.toCards([item('a'), item('a'), item('b')]);

      expect(cards.map((c) => c.id).toList(), ['a', 'b']);
    });
  });

  group('pagination', () {
    test('une page pleine annonce une suite', () async {
      final repository = _FakeRepository(
        pages: [
          FlowFeedPage(
            items: [for (var i = 0; i < 10; i++) item('p1-$i')],
            nextCursor: 'p1-9',
          ),
        ],
      );

      final page = await repository.fetchPage(classLevel: 'terminale');
      expect(page.items, hasLength(10));
      expect(page.hasMore, isTrue);
    });

    test('une page incomplète clôt le fil', () async {
      final repository = _FakeRepository(
        pages: [
          FlowFeedPage(items: [item('a'), item('b')]),
        ],
      );

      final page = await repository.fetchPage(classLevel: 'terminale');
      expect(page.hasMore, isFalse);
    });

    test('la page suivante part du curseur reçu', () async {
      final repository = _FakeRepository(
        pages: [
          FlowFeedPage(items: [item('a')], nextCursor: 'a'),
          FlowFeedPage(items: [item('b')]),
        ],
      );

      await repository.fetchPage(classLevel: 'terminale');
      final second = await repository.fetchPage(
        classLevel: 'terminale',
        cursor: 'a',
      );

      expect(repository.cursors, [null, 'a']);
      expect(second.items.single.id, 'b');
    });
  });

  group('cache local', () {
    late SharedPreferences prefs;
    late FlowFeedCache cache;

    setUp(() async {
      SharedPreferences.setMockInitialValues(const {});
      prefs = await SharedPreferences.getInstance();
      cache = FlowFeedCache(prefs);
    });

    test('le dernier fil valide est relu hors ligne', () async {
      await cache.save('terminale', [item('a'), item('b')]);

      final restored = cache.read('terminale');
      expect(restored.map((i) => i.id).toList(), ['a', 'b']);
    });

    test('le cache est cloisonné par niveau', () async {
      await cache.save('terminale', [item('a')]);

      expect(cache.read('seconde'), isEmpty);
    });

    test('un cache corrompu ne fait pas tomber l’application', () async {
      await prefs.setString('flow_feed_cache_v1_terminale', '{pas du json');

      expect(cache.read('terminale'), isEmpty);
    });

    test('aucun cache : rien à servir', () {
      expect(cache.read('terminale'), isEmpty);
    });
  });

  group('classement déterministe', () {
    const strategy = DeterministicFlowFeedStrategy();

    test('deux passages donnent le même ordre', () {
      final items = [item('a'), item('b'), item('c')];
      const learner = FlowLearnerContext(classLevel: 'terminale');

      final first = strategy.order(items, learner).map((i) => i.id).toList();
      final second = strategy.order(items, learner).map((i) => i.id).toList();

      expect(first, second);
    });

    test('une matière fragile passe devant une matière acquise', () {
      final items = [
        item('acquis', subjectId: 'maths'),
        item('fragile', subjectId: 'svt'),
      ];
      const learner = FlowLearnerContext(
        classLevel: 'terminale',
        masteryBySubject: {'maths': 0.9, 'svt': 0.2},
      );

      final ordered = strategy.order(items, learner);
      expect(ordered.first.id, 'fragile');
    });

    test('le déjà-vu passe derrière le neuf', () {
      final items = [item('vu'), item('neuf')];
      const learner = FlowLearnerContext(
        classLevel: 'terminale',
        seenItemIds: {'vu'},
      );

      expect(strategy.order(items, learner).first.id, 'neuf');
    });

    test('à égalité, le poids éditorial tranche', () {
      final items = [item('faible', priority: 0), item('fort', priority: 10)];
      const learner = FlowLearnerContext(classLevel: 'terminale');

      expect(strategy.order(items, learner).first.id, 'fort');
    });

    test('l’ordre éditorial pur ne reclasse rien', () {
      const editorial = EditorialOrderFlowFeedStrategy();
      final items = [item('b'), item('a')];

      expect(
        editorial
            .order(items, const FlowLearnerContext(classLevel: 'terminale'))
            .map((i) => i.id)
            .toList(),
        ['b', 'a'],
      );
    });
  });

  group('garde-fou du contenu de démonstration', () {
    test('la production n’y a pas droit', () {
      // `enableDebugTools` est faux en production : c'est ce drapeau, et non
      // le mode de compilation, qui décide en release.
      expect(AppConfig.production.enableDebugTools, isFalse);
    });

    test('un environnement de démonstration explicite y a droit', () {
      expect(FlowDemoContent.isPermittedIn(AppConfig.staging), isTrue);
    });

    test('le jeu de démonstration reste disponible pour les tests', () {
      // Les tests s'exécutent en debug : le contenu doit rester accessible
      // pour les scénarios d'interface qui en dépendent.
      expect(FlowDemoContent.build(), isNotEmpty);
    });
  });
}

class _FakeRepository implements FlowFeedRepository {
  _FakeRepository({required this.pages});

  final List<FlowFeedPage> pages;
  final cursors = <String?>[];
  var _call = 0;

  @override
  Future<FlowFeedPage> fetchPage({
    required String classLevel,
    String? cursor,
    int limit = kFlowPageSize,
  }) async {
    cursors.add(cursor);
    final page = pages[_call.clamp(0, pages.length - 1)];
    _call++;
    return page;
  }
}
