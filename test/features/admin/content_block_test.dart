import 'package:flutter_test/flutter_test.dart';

import 'package:intellia237/features/learn/domain/content_block.dart';
import 'package:intellia237/features/learn/domain/learn_lesson.dart';
import 'package:intellia237/features/admin/domain/content_scope.dart';
import 'package:intellia237/features/admin/domain/content_origin.dart';
import 'package:intellia237/features/admin/domain/editorial_workflow.dart';
import 'package:intellia237/features/admin/domain/admin_content_models.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // ContentBlock polymorphic serialization
  // ─────────────────────────────────────────────────────────────────────────

  group('ContentBlock polymorphic serialization', () {
    test('TextBlock round-trips through Firestore', () {
      const block = TextBlock(
        id: 'tb1',
        order: 0,
        title: 'Introduction',
        markdown: '# Hello World\n\nCeci est un paragraphe.',
      );

      final json = block.toFirestore();
      final restored = ContentBlock.fromFirestore(json);

      expect(restored, isA<TextBlock>());
      final text = restored as TextBlock;
      expect(text.id, 'tb1');
      expect(text.order, 0);
      expect(text.title, 'Introduction');
      expect(text.markdown, '# Hello World\n\nCeci est un paragraphe.');
      expect(text.type, ContentBlockType.text);
    });

    test('TextBlock reads legacy "body" key as fallback for "markdown"', () {
      final json = <String, dynamic>{
        'id': 'legacy1',
        'type': 'text',
        'order': 0,
        'body': 'Legacy body content',
      };

      final restored = ContentBlock.fromFirestore(json) as TextBlock;
      expect(restored.markdown, 'Legacy body content');
    });

    test('MediaBlock round-trips through Firestore', () {
      const block = MediaBlock(
        id: 'mb1',
        order: 1,
        mediaType: MediaType.audio,
        storagePath:
            '/educational_assets/global/6eme/math01/lesson01/asset01/overview.mp3',
        caption: 'Audio Overview de la leçon',
        durationSeconds: 420,
        fileSizeBytes: 5242880,
        mimeType: 'audio/mpeg',
        transcriptionText: 'Bonjour et bienvenue...',
      );

      final json = block.toFirestore();
      final restored = ContentBlock.fromFirestore(json);

      expect(restored, isA<MediaBlock>());
      final media = restored as MediaBlock;
      expect(media.id, 'mb1');
      expect(media.mediaType, MediaType.audio);
      expect(media.storagePath, contains('educational_assets'));
      expect(media.caption, 'Audio Overview de la leçon');
      expect(media.durationSeconds, 420);
      expect(media.fileSizeBytes, 5242880);
      expect(media.mimeType, 'audio/mpeg');
      expect(media.transcriptionText, 'Bonjour et bienvenue...');
      expect(media.hasTimedTranscript, isFalse);
    });

    test('MediaBlock hasTimedTranscript is true when VTT present', () {
      const block = MediaBlock(
        id: 'mb2',
        order: 1,
        mediaType: MediaType.audio,
        storagePath: '/path/to/audio.mp3',
        transcriptionVtt: 'WEBVTT\n\n00:00:00.000 --> 00:00:05.000\nBonjour',
      );
      expect(block.hasTimedTranscript, isTrue);
    });

    test('QuizBlock round-trips through Firestore', () {
      const block = QuizBlock(
        id: 'qb1',
        order: 2,
        quizId: 'quiz_abc',
        inlineQuestions: [
          LessonMiniQuizQuestion(
            id: 'q1',
            prompt: 'Combien font 2+2 ?',
            options: ['3', '4', '5'],
            correctIndex: 1,
            explanation: '2+2 = 4',
          ),
        ],
      );

      final json = block.toFirestore();
      final restored = ContentBlock.fromFirestore(json);

      expect(restored, isA<QuizBlock>());
      final quiz = restored as QuizBlock;
      expect(quiz.quizId, 'quiz_abc');
      expect(quiz.inlineQuestions.length, 1);
      expect(quiz.inlineQuestions.first.prompt, 'Combien font 2+2 ?');
      expect(quiz.inlineQuestions.first.correctIndex, 1);
    });

    test('InteractiveBlock round-trips through Firestore', () {
      const block = InteractiveBlock(
        id: 'ib1',
        order: 3,
        componentType: 'pythagoras_visual_v1',
        parameters: {'a': 3, 'b': 4},
        minAppVersion: '3.2.0',
      );

      final json = block.toFirestore();
      final restored = ContentBlock.fromFirestore(json);

      expect(restored, isA<InteractiveBlock>());
      final interactive = restored as InteractiveBlock;
      expect(interactive.componentType, 'pythagoras_visual_v1');
      expect(interactive.parameters, {'a': 3, 'b': 4});
      expect(interactive.minAppVersion, '3.2.0');
    });

    test('unknown type defaults to TextBlock', () {
      final json = <String, dynamic>{
        'id': 'unknown',
        'type': 'future_block_type',
        'order': 0,
        'markdown': 'fallback content',
      };

      final restored = ContentBlock.fromFirestore(json);
      expect(restored, isA<TextBlock>());
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // ContentBlockAdapter (V1 ↔ V2)
  // ─────────────────────────────────────────────────────────────────────────

  group('ContentBlockAdapter', () {
    test('sectionsToBlocks converts legacy sections to TextBlocks', () {
      final sections = [
        const LessonContentSection(title: 'Intro', body: 'Le théorème...'),
        const LessonContentSection(title: '', body: 'Suite du cours'),
      ];

      final blocks = ContentBlockAdapter.sectionsToBlocks(sections);
      expect(blocks.length, 2);
      expect(blocks[0], isA<TextBlock>());
      expect((blocks[0] as TextBlock).title, 'Intro');
      expect((blocks[0] as TextBlock).markdown, 'Le théorème...');
      expect((blocks[1] as TextBlock).title, isNull); // empty → null
    });

    test(
      'blocksToSections projects only TextBlocks, ignores media/quiz/interactive',
      () {
        final blocks = <ContentBlock>[
          const TextBlock(id: 't1', order: 0, markdown: 'Paragraphe 1'),
          const MediaBlock(
            id: 'm1',
            order: 1,
            mediaType: MediaType.image,
            storagePath: '/img.png',
          ),
          const TextBlock(
            id: 't2',
            order: 2,
            title: 'Section 2',
            markdown: 'Paragraphe 2',
          ),
          const QuizBlock(id: 'q1', order: 3),
          const InteractiveBlock(
            id: 'i1',
            order: 4,
            componentType: 'pythagoras_visual_v1',
          ),
        ];

        final sections = ContentBlockAdapter.blocksToSections(blocks);
        expect(sections.length, 2);
        expect(sections[0].title, '');
        expect(sections[0].body, 'Paragraphe 1');
        expect(sections[1].title, 'Section 2');
        expect(sections[1].body, 'Paragraphe 2');
      },
    );

    test('blocksToSections respects order', () {
      final blocks = <ContentBlock>[
        const TextBlock(id: 't2', order: 5, markdown: 'Second'),
        const TextBlock(id: 't1', order: 1, markdown: 'First'),
      ];

      final sections = ContentBlockAdapter.blocksToSections(blocks);
      expect(sections[0].body, 'First');
      expect(sections[1].body, 'Second');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // ContentScope
  // ─────────────────────────────────────────────────────────────────────────

  group('ContentScope', () {
    test('global scope has scopeId "global"', () {
      const scope = ContentScope.global;
      expect(scope.isGlobal, isTrue);
      expect(scope.scopeId, 'global');
    });

    test('establishment scope requires establishmentId', () {
      const scope = ContentScope(
        type: ContentScopeType.establishment,
        establishmentId: 'lycee_abc',
      );
      expect(scope.isEstablishment, isTrue);
      expect(scope.scopeId, 'lycee_abc');
    });

    test('round-trips through Firestore', () {
      const scope = ContentScope(
        type: ContentScopeType.establishment,
        establishmentId: 'college_xyz',
      );
      final json = scope.toFirestore();
      final restored = ContentScope.fromFirestore(json);
      expect(restored.type, ContentScopeType.establishment);
      expect(restored.establishmentId, 'college_xyz');
    });

    test('fromFirestore null returns global', () {
      final scope = ContentScope.fromFirestore(null);
      expect(scope.isGlobal, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // ContentOrigin
  // ─────────────────────────────────────────────────────────────────────────

  group('ContentOrigin', () {
    test('manual origin round-trips', () {
      const origin = ContentOrigin.manual;
      final json = origin.toFirestore();
      final restored = ContentOrigin.fromFirestore(json);
      expect(restored.source, ContentSourceType.manual);
    });

    test('NotebookLM origin preserves metadata', () {
      final now = DateTime(2026, 9, 9, 12, 0);
      final origin = ContentOrigin(
        source: ContentSourceType.notebooklm,
        sourceDocumentName: 'Cours_Pythagore_Audio.mp3',
        importedAt: now,
        importedByUid: 'uid_teacher_001',
        notebookId: 'nb_xyz',
      );
      final json = origin.toFirestore();
      final restored = ContentOrigin.fromFirestore(json);
      expect(restored.isNotebookLm, isTrue);
      expect(restored.sourceDocumentName, 'Cours_Pythagore_Audio.mp3');
      expect(restored.importedByUid, 'uid_teacher_001');
      expect(restored.notebookId, 'nb_xyz');
    });

    test('fromFirestore null returns manual', () {
      final origin = ContentOrigin.fromFirestore(null);
      expect(origin.source, ContentSourceType.manual);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // EditorialWorkflowMetadata
  // ─────────────────────────────────────────────────────────────────────────

  group('EditorialWorkflowMetadata', () {
    test('draft → inReview allowed for author', () {
      const wf = EditorialWorkflowMetadata.draft;
      expect(
        wf.canTransitionTo(
          EditorialStatus.inReview,
          isReviewerOrAdmin: false,
          isAuthor: true,
        ),
        isTrue,
      );
    });

    test('draft → published requires reviewer/admin', () {
      const wf = EditorialWorkflowMetadata.draft;
      expect(
        wf.canTransitionTo(
          EditorialStatus.published,
          isReviewerOrAdmin: false,
          isAuthor: true,
        ),
        isFalse,
      );
      expect(
        wf.canTransitionTo(
          EditorialStatus.published,
          isReviewerOrAdmin: true,
          isAuthor: false,
        ),
        isTrue,
      );
    });

    test('published → draft is FORBIDDEN (no in-place wipe)', () {
      const wf = EditorialWorkflowMetadata(status: EditorialStatus.published);
      expect(
        wf.canTransitionTo(
          EditorialStatus.draft,
          isReviewerOrAdmin: true,
          isAuthor: true,
        ),
        isFalse,
      );
    });

    test('published → archived allowed for reviewer', () {
      const wf = EditorialWorkflowMetadata(status: EditorialStatus.published);
      expect(
        wf.canTransitionTo(
          EditorialStatus.archived,
          isReviewerOrAdmin: true,
          isAuthor: false,
        ),
        isTrue,
      );
    });

    test('rejected → draft allowed', () {
      const wf = EditorialWorkflowMetadata(status: EditorialStatus.rejected);
      expect(
        wf.canTransitionTo(
          EditorialStatus.draft,
          isReviewerOrAdmin: false,
          isAuthor: true,
        ),
        isTrue,
      );
    });

    test('submitForReview sets correct fields', () {
      const wf = EditorialWorkflowMetadata.draft;
      final submitted = wf.submitForReview(uid: 'teacher_001');
      expect(submitted.status, EditorialStatus.inReview);
      expect(submitted.submittedByUid, 'teacher_001');
      expect(submitted.submittedAt, isNotNull);
    });

    test('approve sets reviewer fields', () {
      const wf = EditorialWorkflowMetadata(status: EditorialStatus.inReview);
      final approved = wf.approve(reviewerUid: 'admin_001');
      expect(approved.status, EditorialStatus.approved);
      expect(approved.reviewedByUid, 'admin_001');
    });

    test('reject requires reason', () {
      const wf = EditorialWorkflowMetadata(status: EditorialStatus.inReview);
      final rejected = wf.reject(
        reviewerUid: 'admin_001',
        reason: 'Contenu incomplet',
      );
      expect(rejected.status, EditorialStatus.rejected);
      expect(rejected.rejectionReason, 'Contenu incomplet');
    });

    test('publier enregistre qui a rendu le contenu visible', () {
      const meta = EditorialWorkflowMetadata(status: EditorialStatus.approved);
      final published = meta.publish(reviewerUid: 'admin-1');

      expect(published.status, EditorialStatus.published);
      expect(published.publishedByUid, 'admin-1');
      expect(published.publishedAt, isNotNull);
    });

    test('archiver horodate le retrait', () {
      const meta = EditorialWorkflowMetadata(status: EditorialStatus.published);
      final archived = meta.archive();

      expect(archived.status, EditorialStatus.archived);
      expect(archived.archivedAt, isNotNull);
    });

    test('une révision incrémente la version sans toucher la publiée', () {
      final live = const EditorialWorkflowMetadata(
        status: EditorialStatus.published,
      ).publish(reviewerUid: 'admin-1');
      expect(live.version, 1);

      final revision = live.spawnRevisionDraft(
        currentPublishedLessonId: 'lesson-42',
        authorUid: 'prof-7',
      );

      expect(revision.version, 2);
      expect(revision.status, EditorialStatus.draft);
      expect(revision.previousVersionId, 'lesson-42');
      // La révision n'a été ni relue ni publiée : rien n'est recopié.
      expect(revision.publishedAt, isNull);
      expect(revision.publishedByUid, isNull);
      // La version en ligne reste intacte pour les élèves.
      expect(live.status, EditorialStatus.published);
      expect(live.version, 1);
    });

    test('les métadonnées de version traversent Firestore', () {
      final live = const EditorialWorkflowMetadata(
        status: EditorialStatus.published,
      ).publish(reviewerUid: 'admin-1');
      final revision = live.spawnRevisionDraft(
        currentPublishedLessonId: 'lesson-42',
        authorUid: 'prof-7',
      );

      final restored = EditorialWorkflowMetadata.fromFirestore(
        revision.toFirestore(),
      );

      expect(restored.version, 2);
      expect(restored.previousVersionId, 'lesson-42');
      expect(restored, revision);
    });

    test('un document antérieur au Studio est la version 1', () {
      final restored = EditorialWorkflowMetadata.fromFirestore(
        <String, dynamic>{'status': 'published'},
      );

      expect(restored.version, 1);
      expect(restored.publishedByUid, isNull);
    });

    test('spawnRevisionDraft links to previous version', () {
      const wf = EditorialWorkflowMetadata(status: EditorialStatus.published);
      final revision = wf.spawnRevisionDraft(
        currentPublishedLessonId: 'lesson_v1',
        authorUid: 'teacher_001',
      );
      expect(revision.status, EditorialStatus.draft);
      expect(revision.previousVersionId, 'lesson_v1');
    });

    test('round-trips through Firestore', () {
      final now = DateTime(2026, 9, 9, 12, 0);
      final wf = EditorialWorkflowMetadata(
        status: EditorialStatus.approved,
        submittedByUid: 'teacher_001',
        submittedAt: now,
        reviewedByUid: 'admin_001',
        reviewedAt: now,
        previousVersionId: 'prev_lesson',
      );
      final json = wf.toFirestore();
      final restored = EditorialWorkflowMetadata.fromFirestore(json);
      expect(restored.status, EditorialStatus.approved);
      expect(restored.submittedByUid, 'teacher_001');
      expect(restored.reviewedByUid, 'admin_001');
      expect(restored.previousVersionId, 'prev_lesson');
    });

    test('fromFirestore with legacy status falls back correctly', () {
      final restored = EditorialWorkflowMetadata.fromFirestore(
        null,
        legacyStatus: 'published',
      );
      expect(restored.status, EditorialStatus.published);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // AdminLessonModel V2 dual-write
  // ─────────────────────────────────────────────────────────────────────────

  group('AdminLessonModel V2 dual-write', () {
    test('toFirestore writes both contentBlocks and contentSections', () {
      final lesson = AdminLessonModel(
        id: 'lesson1',
        subjectId: 'math',
        chapterId: 'ch1',
        classLevel: '6eme',
        title: 'Théorème de Pythagore',
        summary: 'Introduction',
        estimatedMinutes: 30,
        order: 0,
        status: 'draft',
        contentSections: const [],
        miniQuiz: const [],
        contentBlocks: const [
          TextBlock(
            id: 't1',
            order: 0,
            title: 'Intro',
            markdown: 'Le théorème...',
          ),
          MediaBlock(
            id: 'm1',
            order: 1,
            mediaType: MediaType.image,
            storagePath:
                '/educational_assets/global/6eme/math/lesson1/img1/triangle.png',
          ),
          TextBlock(id: 't2', order: 2, markdown: 'Conclusion'),
        ],
        schemaVersion: 2,
      );

      final json = lesson.toFirestore();

      // V2: contentBlocks are all 3 blocks
      final blocks = json['contentBlocks'] as List;
      expect(blocks.length, 3);

      // V1 dual-write: contentSections are only text blocks (2 of 3)
      final sections = json['contentSections'] as List;
      expect(sections.length, 2);
      expect((sections[0] as Map)['body'], 'Le théorème...');
      expect((sections[1] as Map)['body'], 'Conclusion');

      // schema version promoted to 2
      expect(json['schemaVersion'], 2);

      // V2 metadata present
      expect(json['scope'], isA<Map>());
      expect(json['origin'], isA<Map>());
      expect(json['editorialWorkflow'], isA<Map>());
    });

    test(
      'legacy V1 lesson effectiveBlocks projects sections to TextBlocks',
      () {
        const lesson = AdminLessonModel(
          id: 'legacy1',
          subjectId: 'french',
          chapterId: 'ch1',
          classLevel: '6eme',
          title: 'Grammaire',
          summary: 'Les verbes',
          estimatedMinutes: 20,
          order: 0,
          status: 'published',
          contentSections: [
            LessonContentSection(title: 'Section 1', body: 'Contenu'),
          ],
          miniQuiz: [],
          schemaVersion: 1,
        );

        final blocks = lesson.effectiveBlocks;
        expect(blocks.length, 1);
        expect(blocks[0], isA<TextBlock>());
        expect((blocks[0] as TextBlock).markdown, 'Contenu');
      },
    );

    test('fromFirestore parses V2 contentBlocks', () {
      final data = <String, dynamic>{
        'title': 'Test Lesson',
        'summary': 'Summary',
        'estimatedMinutes': 25,
        'order': 1,
        'status': 'draft',
        'aiGenerated': false,
        'schemaVersion': 2,
        'contentBlocks': [
          {'id': 'tb1', 'type': 'text', 'order': 0, 'markdown': 'Hello'},
          {
            'id': 'mb1',
            'type': 'media',
            'order': 1,
            'mediaType': 'audio',
            'storagePath': '/path/to/audio.mp3',
          },
        ],
        'contentSections': [
          {'title': '', 'body': 'Hello'},
        ],
        'miniQuiz': <dynamic>[],
      };

      final lesson = AdminLessonModel.fromFirestore(
        'id1',
        'math',
        'ch1',
        '6eme',
        data,
      );

      expect(lesson.schemaVersion, 2);
      expect(lesson.contentBlocks.length, 2);
      expect(lesson.contentBlocks[0], isA<TextBlock>());
      expect(lesson.contentBlocks[1], isA<MediaBlock>());
      // Legacy sections still readable
      expect(lesson.contentSections.length, 1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // LearnLesson V2 effectiveBlocks
  // ─────────────────────────────────────────────────────────────────────────

  group('LearnLesson V2 effectiveBlocks', () {
    test('effectiveBlocks returns contentBlocks when populated', () {
      const lesson = LearnLesson(
        id: 'l1',
        title: 'Test',
        summary: 'Summary',
        estimatedMinutes: 20,
        progress: 0,
        isFavorite: false,
        contentSections: [LessonContentSection(title: 'Old', body: 'Legacy')],
        miniQuiz: [],
        contentBlocks: [
          TextBlock(id: 't1', order: 0, markdown: 'V2 content'),
          MediaBlock(
            id: 'm1',
            order: 1,
            mediaType: MediaType.pdf,
            storagePath: '/path/to/doc.pdf',
          ),
        ],
        schemaVersion: 2,
      );

      final blocks = lesson.effectiveBlocks;
      expect(blocks.length, 2);
      expect(blocks[0], isA<TextBlock>());
      expect((blocks[0] as TextBlock).markdown, 'V2 content');
    });

    test('effectiveBlocks falls back to sections for V1 lessons', () {
      const lesson = LearnLesson(
        id: 'l2',
        title: 'Legacy',
        summary: 'Old style',
        estimatedMinutes: 15,
        progress: 0.5,
        isFavorite: true,
        contentSections: [
          LessonContentSection(title: 'Part 1', body: 'Legacy content'),
        ],
        miniQuiz: [],
        schemaVersion: 1,
      );

      final blocks = lesson.effectiveBlocks;
      expect(blocks.length, 1);
      expect(blocks[0], isA<TextBlock>());
      expect((blocks[0] as TextBlock).markdown, 'Legacy content');
      expect((blocks[0] as TextBlock).title, 'Part 1');
    });
  });
}
