import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intellia237/features/ai_companion/application/ai_companion_controller.dart';
import 'package:intellia237/features/ai_companion/data/ai_repository.dart';
import 'package:intellia237/features/ai_companion/data/cloud_ai_repository.dart';
import 'package:intellia237/features/ai_companion/data/companion_history_repository.dart';
import 'package:intellia237/features/ai_companion/domain/ai_companion_reply.dart';
import 'package:intellia237/features/ai_companion/domain/ai_message.dart';
import 'package:intellia237/features/ai_companion/domain/companion_conversation.dart';
import 'package:intellia237/features/ai_companion/domain/tutor_turn_options.dart';
import 'package:intellia237/features/ai_companion/presentation/ai_companion_screen.dart';
import 'package:intellia237/features/interactive_learning/domain/interactive_block.dart';
import 'package:intellia237/features/interactive_learning/presentation/ordering_exercise_view.dart';
import 'package:intellia237/features/learn/application/learn_providers.dart';
import 'package:intellia237/features/learn/domain/learn_academic_context.dart';
import 'package:intellia237/features/tutor/domain/tutor_persona.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kira et Léo peuvent joindre une activité à leur réponse : elle arrive
/// validée par le serveur, se relit strictement, se joue hors ligne et son
/// résultat revient au compagnon avec le message suivant.
Map<String, Object?> _blockJson({String type = 'word_order'}) => {
  'version': 1,
  'id': 'blk_chat',
  'type': type,
  'language': 'en',
  'items': [
    {'id': 'it_0', 'text': 'I'},
    {'id': 'it_1', 'text': 'want'},
    {'id': 'it_2', 'text': 'to'},
    {'id': 'it_3', 'text': 'go'},
  ],
  'solution': ['it_0', 'it_1', 'it_2', 'it_3'],
  'trailing': '.',
  'hints': ['Commence par le sujet.'],
  'explanation': 'Sujet, verbe, puis infinitif.',
  'difficulty': 1,
};

const _outcome = ActivityOutcome(
  blockId: 'blk_chat',
  type: InteractiveBlockType.wordOrder,
  correct: true,
  attempts: 2,
  hintsUsed: 1,
  solutionRevealed: false,
  duration: Duration(seconds: 40),
);

const _context = LearnAcademicContext(
  classLevel: '6eme',
  catalogClassLevel: '6eme',
  academicLevelId: 'fr_general_6e',
  tutorId: 'kira',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  final kira = TutorPersona.resolve('kira');

  group('contrat avec askTutor', () {
    test(
      'declares renderable activities, forwards the outcome, reads the block',
      () async {
        final gateway = _RecordingGateway({
          'text': 'À toi de jouer.',
          'limit': 10,
          'remaining': 9,
          'resetsAt': '2026-09-21T23:00:00.000Z',
          'block': _blockJson(),
        });
        final reply = await CloudAIRepository(gateway: gateway).sendMessage(
          tutor: kira,
          classLevel: '6eme',
          history: const <AIMessage>[],
          userMessage: 'Je veux m’entraîner',
          options: const TutorTurnOptions(activityOutcome: _outcome),
        );

        expect(
          gateway.payload['activities'],
          InteractiveBlockType.supportedWireNames,
        );
        final sent = gateway.payload['activityOutcome'] as Map;
        expect(sent['correct'], isTrue);
        expect(sent['attempts'], 2);
        // La durée reste sur l'appareil.
        expect(sent.containsKey('duration'), isFalse);
        expect(reply.message.block, isA<OrderingBlock>());
        expect(reply.message.text, 'À toi de jouer.');
      },
    );

    test('an invalid or unknown block is dropped, the text is kept', () async {
      for (final block in <Object?>[
        _blockJson(type: 'html'),
        {..._blockJson(), 'solution': 'it_0'},
        '<div>exercice</div>',
      ]) {
        final reply =
            await CloudAIRepository(
              gateway: _RecordingGateway({
                'text': 'Réponse.',
                'limit': 10,
                'remaining': 9,
                'resetsAt': '2026-09-21T23:00:00.000Z',
                'block': block,
              }),
            ).sendMessage(
              tutor: kira,
              classLevel: '6eme',
              history: const <AIMessage>[],
              userMessage: 'Question',
            );
        expect(reply.message.block, isNull, reason: '$block');
        expect(reply.message.text, 'Réponse.');
      }
    });

    test('no outcome is sent when there is none', () async {
      final gateway = _RecordingGateway({
        'text': 'Réponse.',
        'limit': 10,
        'remaining': 9,
        'resetsAt': '2026-09-21T23:00:00.000Z',
      });
      await CloudAIRepository(gateway: gateway).sendMessage(
        tutor: kira,
        classLevel: '6eme',
        history: const <AIMessage>[],
        userMessage: 'Question',
      );
      expect(gateway.payload.containsKey('activityOutcome'), isFalse);
    });
  });

  test('the activity survives a restart, offline, in the history', () async {
    SharedPreferences.setMockInitialValues(const {});
    final history = CompanionHistoryRepository(
      await SharedPreferences.getInstance(),
    );
    final at = DateTime(2026, 9, 21, 10);
    await history.saveConversation(
      learnerId: 'student-a',
      conversation: CompanionConversation(
        id: 'c1',
        learnerId: 'student-a',
        createdAt: at,
        lastActivityAt: at,
      ),
      messages: [
        AIMessage(
          id: 'u1',
          role: AIMessageRole.user,
          text: 'Je veux m’entraîner',
          createdAt: at,
        ),
        AIMessage(
          id: 'a1',
          role: AIMessageRole.assistant,
          text: 'À toi de jouer.',
          createdAt: at,
          companionId: 'kira',
          block: InteractiveLearningBlock.tryParse(_blockJson()),
        ),
      ],
    );

    final restored = history.readMessages('student-a', 'c1');
    final block = restored.last.block;
    expect(block, isA<OrderingBlock>());
    expect((block! as OrderingBlock).solution, [
      'it_0',
      'it_1',
      'it_2',
      'it_3',
    ]);
  });

  group('boucle compagnon', () {
    ProviderContainer containerWith(_ScriptedTutorRepository repository) {
      final container = ProviderContainer(
        overrides: [
          aiRepositoryProvider.overrideWithValue(repository),
          studentAcademicContextProvider.overrideWith((ref) async => _context),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('the outcome rides with the next message, exactly once', () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final repository = _ScriptedTutorRepository();
      final container = containerWith(repository);
      final controller = container.read(aiCompanionControllerProvider.notifier);

      controller.recordActivityOutcome(_outcome);
      await controller.continueAfterActivity('J’ai terminé l’exercice.');
      await controller.send('Et maintenant ?');

      expect(repository.outcomes, hasLength(2));
      expect(repository.outcomes.first?.blockId, 'blk_chat');
      expect(repository.outcomes.last, isNull);
      expect(controller.pendingActivityOutcome, isNull);
    });

    test('a failed turn keeps the outcome for the retry', () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final repository = _ScriptedTutorRepository(failFirst: true);
      final container = containerWith(repository);
      final controller = container.read(aiCompanionControllerProvider.notifier);

      controller.recordActivityOutcome(_outcome);
      await controller.continueAfterActivity('J’ai terminé l’exercice.');
      expect(controller.pendingActivityOutcome, isNotNull);
      await controller.retryLastMessage();

      expect(repository.outcomes, hasLength(2));
      expect(repository.outcomes.last?.blockId, 'blk_chat');
      expect(controller.pendingActivityOutcome, isNull);
    });
  });

  testWidgets('Kira’s activity renders under her reply, at 360 px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final repository = _ScriptedTutorRepository(
      block: InteractiveLearningBlock.tryParse(_blockJson()),
    );
    final container = ProviderContainer(
      overrides: [
        aiRepositoryProvider.overrideWithValue(repository),
        studentAcademicContextProvider.overrideWith((ref) async => _context),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: AICompanionScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await container
        .read(aiCompanionControllerProvider.notifier)
        .send('Je veux m’entraîner');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('À toi de jouer.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Vérifier'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byType(WordTile), findsNWidgets(4));
    expect(find.textContaining('Kira'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

class _RecordingGateway implements TutorFunctionsGateway {
  _RecordingGateway(this.result);

  final Object? result;
  Map<String, dynamic> payload = const {};

  @override
  Future<Object?> askTutor(Map<String, dynamic> payload) async {
    this.payload = payload;
    return result;
  }
}

class _ScriptedTutorRepository implements AIRepository {
  _ScriptedTutorRepository({this.failFirst = false, this.block});

  final bool failFirst;
  final InteractiveLearningBlock? block;
  final outcomes = <ActivityOutcome?>[];

  @override
  Future<AICompanionReply> sendMessage({
    required TutorPersona tutor,
    required String classLevel,
    required List<AIMessage> history,
    required String userMessage,
    TutorTurnOptions options = const TutorTurnOptions(),
  }) async {
    outcomes.add(options.activityOutcome);
    if (failFirst && outcomes.length == 1) {
      throw const AICompanionException(
        message: 'Délai dépassé.',
        kind: AICompanionFailureKind.network,
        normalizedErrorCode: 'deadline-exceeded',
        diagnosticId: 'TUTOR-NETWORK-504',
      );
    }
    return AICompanionReply(
      message: AIMessage(
        id: 'reply-${outcomes.length}',
        role: AIMessageRole.assistant,
        text: 'À toi de jouer.',
        createdAt: DateTime(2026, 9, 21),
        block: block,
      ),
      quota: AICompanionQuota(
        limit: 20,
        remaining: 19,
        resetsAt: DateTime.utc(2026, 9, 21, 23),
      ),
    );
  }
}
