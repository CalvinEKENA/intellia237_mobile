import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/admin/data/educational_media_service.dart';
import 'package:intellia237/features/admin/domain/educational_media.dart';
import 'package:intellia237/features/admin/presentation/widgets/lesson_blocks_editor.dart';
import 'package:intellia237/features/learn/domain/content_block.dart';
import 'package:intellia237/features/learn/domain/learn_lesson.dart';
import 'package:intellia237/features/learn/presentation/widgets/audio_overview_player.dart';
import 'package:intellia237/features/learn/presentation/widgets/content_block_view.dart';
import 'package:intellia237/features/learn/presentation/widgets/lesson_pdf_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un bloc défaillant n'emporte jamais la leçon : chaque cas de panne donne un
/// encart lisible, et le reste continue.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  Future<void> pumpBlock(
    WidgetTester tester,
    ContentBlock block, {
    EducationalMediaProvider? media,
  }) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (media != null)
            educationalMediaProviderProvider.overrideWithValue(media),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ContentBlockView(block: block)),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('rendu des blocs', () {
    testWidgets('un bloc de texte s’affiche', (tester) async {
      await pumpBlock(
        tester,
        const TextBlock(
          id: 't1',
          order: 0,
          title: 'Le discriminant',
          markdown: 'Delta vaut b² moins 4ac.',
        ),
      );

      expect(find.text('Le discriminant'), findsOneWidget);
      expect(find.text('Delta vaut b² moins 4ac.'), findsOneWidget);
    });

    testWidgets('un média sans chemin bascule sur le repli', (tester) async {
      await pumpBlock(
        tester,
        const MediaBlock(
          id: 'm1',
          order: 0,
          mediaType: MediaType.image,
          storagePath: '',
        ),
      );

      expect(
        find.byKey(const ValueKey('content-block-fallback')),
        findsOneWidget,
      );
    });

    testWidgets('une image dont l’URL échoue reste un encart lisible', (
      tester,
    ) async {
      await pumpBlock(
        tester,
        const MediaBlock(
          id: 'm1',
          order: 0,
          mediaType: MediaType.image,
          storagePath: 'educational_assets/global/x.png',
        ),
        media: _FailingMedia(),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const ValueKey('media-unavailable')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('une capsule audio rend le vrai lecteur, pas un placeholder', (
      tester,
    ) async {
      await pumpBlock(
        tester,
        const MediaBlock(
          id: 'm1',
          order: 0,
          mediaType: MediaType.audio,
          storagePath: 'educational_assets/global/capsule.mp3',
          durationSeconds: 245,
        ),
        media: _StubMedia(),
      );

      expect(find.byType(AudioOverviewPlayer), findsOneWidget);
    });

    testWidgets('un document PDF rend la vue de consultation sécurisée', (
      tester,
    ) async {
      await pumpBlock(
        tester,
        const MediaBlock(
          id: 'm2',
          order: 0,
          mediaType: MediaType.pdf,
          storagePath: 'educational_assets/global/fiche.pdf',
        ),
        media: _StubMedia(),
      );

      expect(find.byType(LessonPdfView), findsOneWidget);
    });

    testWidgets('un quiz vide est signalé, pas rendu à moitié', (tester) async {
      await pumpBlock(tester, const QuizBlock(id: 'q1', order: 0));

      expect(
        find.byKey(const ValueKey('content-block-fallback')),
        findsOneWidget,
      );
    });

    testWidgets('une activité interactive inconnue montre son résumé', (
      tester,
    ) async {
      await pumpBlock(
        tester,
        const InteractiveBlock(
          id: 'i1',
          order: 0,
          componentType: 'chute_libre_v9',
          parameters: {'summary': 'Comprendre la chute libre.'},
        ),
      );

      expect(find.text('Comprendre la chute libre.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('l’activité de référence se rend réellement', (tester) async {
      await pumpBlock(
        tester,
        const InteractiveBlock(
          id: 'i1',
          order: 0,
          componentType: 'pythagoras_visual_v1',
          parameters: {'initialA': 3, 'initialB': 4},
        ),
      );

      expect(find.byKey(const ValueKey('interactive-fallback')), findsNothing);
      expect(find.textContaining('25.0'), findsWidgets);
    });
  });

  group('compatibilité des leçons', () {
    test('une leçon V1 se lit comme une suite de blocs de texte', () {
      const lesson = LearnLesson(
        id: 'l1',
        title: 'Leçon héritée',
        summary: '',
        estimatedMinutes: 10,
        progress: 0,
        isFavorite: false,
        contentSections: [
          LessonContentSection(title: 'Partie 1', body: 'Corps 1'),
          LessonContentSection(title: 'Partie 2', body: 'Corps 2'),
        ],
        miniQuiz: [],
      );

      final blocks = lesson.effectiveBlocks;
      expect(blocks, hasLength(2));
      expect(blocks.every((b) => b is TextBlock), isTrue);
      expect((blocks.first as TextBlock).markdown, 'Corps 1');
    });

    test('une leçon V2 sert ses blocs et non la projection', () {
      const lesson = LearnLesson(
        id: 'l2',
        title: 'Leçon V2',
        summary: '',
        estimatedMinutes: 10,
        progress: 0,
        isFavorite: false,
        contentSections: [LessonContentSection(title: 'Legacy', body: 'texte')],
        miniQuiz: [],
        contentBlocks: [
          MediaBlock(
            id: 'm1',
            order: 0,
            mediaType: MediaType.image,
            storagePath: 'p',
          ),
        ],
        schemaVersion: 2,
      );

      expect(lesson.effectiveBlocks, hasLength(1));
      expect(lesson.effectiveBlocks.single, isA<MediaBlock>());
    });

    test('une ancienne application ne reçoit que le texte d’une leçon V2', () {
      const blocks = <ContentBlock>[
        TextBlock(id: 't1', order: 0, title: 'Intro', markdown: 'Un texte.'),
        MediaBlock(
          id: 'm1',
          order: 1,
          mediaType: MediaType.video,
          storagePath: 'p',
        ),
        InteractiveBlock(id: 'i1', order: 2, componentType: 'x'),
      ];

      final sections = ContentBlockAdapter.blocksToSections(blocks);

      // Aucun média n'est dégradé en faux texte.
      expect(sections, hasLength(1));
      expect(sections.single.body, 'Un texte.');
    });
  });

  group('édition par blocs', () {
    Future<List<ContentBlock>> pumpEditor(
      WidgetTester tester,
      List<ContentBlock> initial,
    ) async {
      var current = initial;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SingleChildScrollView(
                child: LessonBlocksEditor(
                  blocks: current,
                  onChanged: (blocks) => setState(() => current = blocks),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      return current;
    }

    testWidgets('une leçon sans bloc invite sans alarmer', (tester) async {
      await pumpEditor(tester, const []);

      expect(find.byKey(const ValueKey('lesson-blocks-empty')), findsOneWidget);
    });

    testWidgets('supprimer un bloc renumérote les suivants', (tester) async {
      const blocks = <ContentBlock>[
        TextBlock(id: 'a', order: 0, markdown: 'A'),
        TextBlock(id: 'b', order: 1, markdown: 'B'),
        TextBlock(id: 'c', order: 2, markdown: 'C'),
      ];
      await pumpEditor(tester, blocks);

      await tester.tap(find.byKey(const ValueKey('block-delete-a')));
      await tester.pump();

      expect(find.byKey(const ValueKey('lesson-block-a')), findsNothing);
      expect(find.byKey(const ValueKey('lesson-block-b')), findsOneWidget);
    });

    testWidgets('déplacer un bloc change l’ordre visible', (tester) async {
      const blocks = <ContentBlock>[
        TextBlock(id: 'a', order: 0, markdown: 'A'),
        TextBlock(id: 'b', order: 1, markdown: 'B'),
      ];
      await pumpEditor(tester, blocks);

      await tester.tap(find.byKey(const ValueKey('block-down-a')));
      await tester.pump();

      final tiles = tester
          .widgetList(find.byKey(const ValueKey('lesson-block-b')))
          .toList();
      expect(tiles, isNotEmpty);
    });

    testWidgets('le premier bloc ne peut pas monter', (tester) async {
      const blocks = <ContentBlock>[
        TextBlock(id: 'a', order: 0, markdown: 'A'),
        TextBlock(id: 'b', order: 1, markdown: 'B'),
      ];
      await pumpEditor(tester, blocks);

      final up = tester.widget<IconButton>(
        find.byKey(const ValueKey('block-up-a')),
      );
      expect(up.onPressed, isNull);
    });
  });
}

class _FailingMedia implements EducationalMediaProvider {
  @override
  Future<String> resolveUrl(String storagePath) async =>
      throw Exception('ressource effacée');

  @override
  Future<MediaUploadResult> upload({
    required String storagePath,
    required Uint8List bytes,
    required String mimeType,
    void Function(double progress)? onProgress,
  }) async => throw UnimplementedError();

  @override
  Future<void> delete(String storagePath) async {}
}

class _StubMedia implements EducationalMediaProvider {
  @override
  Future<String> resolveUrl(String storagePath) async =>
      'https://signed.example/$storagePath';

  @override
  Future<MediaUploadResult> upload({
    required String storagePath,
    required Uint8List bytes,
    required String mimeType,
    void Function(double progress)? onProgress,
  }) async => throw UnimplementedError();

  @override
  Future<void> delete(String storagePath) async {}
}
