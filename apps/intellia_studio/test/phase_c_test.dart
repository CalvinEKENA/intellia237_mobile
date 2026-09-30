import 'package:flutter_test/flutter_test.dart';
import 'package:intellia_studio/features/audiences/domain/audience_models.dart';
import 'package:intellia_studio/features/content/domain/content_models.dart';
import 'package:intellia_studio/features/flow/domain/flow_models.dart';
import 'package:intellia_studio/features/quiz/domain/quiz_models.dart';

void main() {
  group('Phase C — Content Models & Dual-Write Serialization', () {
    test(
      'StudioLesson generates both contentBlocks (V2) and contentSections (V1)',
      () {
        const lesson = StudioLesson(
          id: 'lsn_01',
          subjectId: 'sub_math_t',
          chapterId: 'ch_01',
          classLevel: 'Terminale',
          title: 'Théorème des Valeurs Intermédiaires',
          summary: 'Énoncé et corollaires',
          estimatedMinutes: 25,
          order: 1,
          status: 'published',
          scope: 'global',
          updatedAt: '2026-03-15T00:00:00Z',
          origin: StudioContentOrigin(
            source: ContentOriginSource.notebooklm,
            sourceDocumentName: 'Math_Bacc_2026.pdf',
            notebookId: 'ntb_test_123',
          ),
          contentBlocks: [
            StudioContentBlock(
              id: 'b1',
              type: ContentBlockType.text,
              title: 'Introduction',
              body: 'Texte d\'introduction',
            ),
            StudioContentBlock(
              id: 'b2',
              type: ContentBlockType.callout,
              title: 'Formule clé',
              body: 'f(c) = k',
            ),
            StudioContentBlock(
              id: 'b3',
              type: ContentBlockType.video,
              title: 'Vidéo illustrative',
              body: '',
              storagePath: 'educational_assets/videos/tvi.mp4',
            ),
          ],
        );

        final payload = lesson.toDualWritePayload();

        // Schema version must be 2
        expect(payload['schemaVersion'], 2);
        expect(payload['title'], 'Théorème des Valeurs Intermédiaires');

        // V2 contentBlocks must have all 3 blocks
        final blocks = payload['contentBlocks'] as List;
        expect(blocks.length, 3);
        expect(blocks[0]['type'], 'text');
        expect(blocks[1]['type'], 'callout');
        expect(blocks[2]['type'], 'video');

        // V1 contentSections projection must only contain text/callout for backward compatibility
        final sections = payload['contentSections'] as List;
        expect(sections.length, 2);
        expect(sections[0]['title'], 'Introduction');
        expect(sections[1]['title'], 'Formule clé');

        // Origin provenance tracking
        final origin = payload['origin'] as Map<String, dynamic>;
        expect(origin['source'], 'notebooklm');
        expect(origin['sourceDocumentName'], 'Math_Bacc_2026.pdf');
        expect(origin['notebookId'], 'ntb_test_123');
      },
    );
  });

  group('Phase C — FLOW Publication Server-Parity Contract', () {
    test('Validates required fields: title, hook, classLevels, subjectId', () {
      const invalidItem = StudioFlowItem(
        id: 'f1',
        type: FlowCardType.notion,
        title: '',
        hook: '',
        subjectId: '',
        classLevels: [],
        status: FlowStatus.published,
        createdBy: 'usr_1',
        createdAt: '2026-03-01',
        updatedAt: '2026-03-01',
      );

      final error = StudioFlowItem.validateForPublication(invalidItem);
      expect(error, isNotNull);
      expect(error, contains('titre est obligatoire'));
    });

    test(
      'Validates Quiz payload: requires >= 2 options and valid correctIndex',
      () {
        const invalidQuiz = StudioFlowItem(
          id: 'f_quiz',
          type: FlowCardType.quiz,
          title: 'Quiz dérivées',
          hook: 'Testez-vous !',
          subjectId: 'sub_math',
          classLevels: ['Terminale'],
          status: FlowStatus.published,
          payload: {
            'question': 'Quelle est la dérivée de x^2 ?',
            'options': ['2x'],
            'correctIndex': 0,
          },
          createdBy: 'usr_1',
          createdAt: '2026-03-01',
          updatedAt: '2026-03-01',
        );

        final error = StudioFlowItem.validateForPublication(invalidQuiz);
        expect(error, isNotNull);
        expect(error, contains('au moins 2 options'));

        const badIndexQuiz = StudioFlowItem(
          id: 'f_quiz_2',
          type: FlowCardType.quiz,
          title: 'Quiz dérivées',
          hook: 'Testez-vous !',
          subjectId: 'sub_math',
          classLevels: ['Terminale'],
          status: FlowStatus.published,
          payload: {
            'question': 'Quelle est la dérivée de x^2 ?',
            'options': ['2x', 'x', '3x'],
            'correctIndex': 5,
          },
          createdBy: 'usr_1',
          createdAt: '2026-03-01',
          updatedAt: '2026-03-01',
        );

        final error2 = StudioFlowItem.validateForPublication(badIndexQuiz);
        expect(error2, isNotNull);
        expect(error2, contains('Index de réponse correcte invalide'));

        const validQuiz = StudioFlowItem(
          id: 'f_quiz_ok',
          type: FlowCardType.quiz,
          title: 'Quiz dérivées',
          hook: 'Testez-vous !',
          subjectId: 'sub_math',
          classLevels: ['Terminale'],
          status: FlowStatus.published,
          payload: {
            'question': 'Quelle est la dérivée de x^2 ?',
            'options': ['2x', 'x', '3x'],
            'correctIndex': 0,
          },
          createdBy: 'usr_1',
          createdAt: '2026-03-01',
          updatedAt: '2026-03-01',
        );

        expect(StudioFlowItem.validateForPublication(validQuiz), isNull);
      },
    );

    test('Validates shortVideo requires valid storagePath in ref', () {
      const videoItem = StudioFlowItem(
        id: 'f_vid',
        type: FlowCardType.shortVideo,
        title: 'Vidéo explicative',
        hook: 'Regardez la vidéo',
        subjectId: 'sub_phy',
        classLevels: ['Terminale'],
        status: FlowStatus.published,
        ref: {},
        createdBy: 'usr_1',
        createdAt: '2026-03-01',
        updatedAt: '2026-03-01',
      );

      final error = StudioFlowItem.validateForPublication(videoItem);
      expect(error, isNotNull);
      expect(error, contains('storagePath'));
    });
  });

  group('Phase C — Quiz & Audience Targeting Rules', () {
    test('StudioQuizQuestion validates prompt, options and correctIndex', () {
      const validQ = StudioQuizQuestion(
        id: 'q1',
        subjectId: 'sub_math',
        classLevel: 'Terminale',
        prompt: '1 + 1 = ?',
        options: ['1', '2', '3'],
        correctIndex: 1,
        explanation: '1 + 1 fait 2.',
      );
      expect(validQ.isValid, isTrue);

      const invalidQ = StudioQuizQuestion(
        id: 'q2',
        subjectId: 'sub_math',
        classLevel: 'Terminale',
        prompt: '',
        options: ['1'],
        correctIndex: 0,
        explanation: '',
      );
      expect(invalidQ.isValid, isFalse);
    });

    test(
      'StudioAudienceRule correctly segments students by class, series and tier',
      () {
        const rulePremiumTerminaleC = StudioAudienceRule(
          id: 'aud_1',
          name: 'Terminale C Premium',
          classLevels: ['Terminale'],
          series: ['C'],
          accessTier: AccessTier.premiumOnly,
        );

        // Matches: Terminale, Série C, Premium
        expect(
          rulePremiumTerminaleC.matches(
            studentClassLevel: 'Terminale',
            studentSeries: 'C',
            isPremium: true,
          ),
          isTrue,
        );

        // Does not match: Not premium
        expect(
          rulePremiumTerminaleC.matches(
            studentClassLevel: 'Terminale',
            studentSeries: 'C',
            isPremium: false,
          ),
          isFalse,
        );

        // Does not match: Wrong series
        expect(
          rulePremiumTerminaleC.matches(
            studentClassLevel: 'Terminale',
            studentSeries: 'D',
            isPremium: true,
          ),
          isFalse,
        );

        // Does not match: Wrong class level
        expect(
          rulePremiumTerminaleC.matches(
            studentClassLevel: 'Premiere',
            studentSeries: 'C',
            isPremium: true,
          ),
          isFalse,
        );
      },
    );
  });
}
