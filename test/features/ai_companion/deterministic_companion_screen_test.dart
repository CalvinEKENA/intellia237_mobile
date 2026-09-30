import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intellia237/core/network/network_status.dart';
import 'package:intellia237/features/ai_companion/application/ai_companion_controller.dart';
import 'package:intellia237/features/ai_companion/application/companion_engine_providers.dart';
import 'package:intellia237/features/ai_companion/data/companion_history_repository.dart';
import 'package:intellia237/features/ai_companion/domain/ai_message.dart';
import 'package:intellia237/features/ai_companion/domain/companion_conversation.dart';
import 'package:intellia237/features/ai_companion/presentation/ai_companion_screen.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/content_engine/application/content_providers.dart';
import 'package:intellia237/features/content_engine/data/content_delivery.dart';
import 'package:intellia237/features/content_engine/data/content_pack_repository.dart';
import 'package:intellia237/features/content_engine/data/learner_content_store.dart';
import 'package:intellia237/features/quiz/application/pack_quiz_providers.dart';
import 'package:intellia237/features/quiz/application/pack_quiz_session.dart';
import 'package:intellia237/features/quiz/domain/pack_quiz.dart';
import 'package:intellia237/features/quiz/presentation/pack_quiz_screen.dart';
import 'package:intellia237/features/tutor/application/tutor_preference_provider.dart';
import 'package:intellia237/features/tutor/domain/tutor_persona.dart';
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../content_engine/pack_fixture.dart';
import 'companion_fixture.dart';

/// L'onglet Compagnon, entièrement local : il répond hors ligne, propose de
/// vrais quiz, commente un quiz terminé et ne rejoue jamais les anciens fils.
void main() {
  Future<ProviderContainer> pump(
    WidgetTester tester, {
    Map<String, Object> prefs = const {},
    Size size = const Size(390, 844),
    double textScale = 1,
    String companion = 'kira',
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [
        contentPackRepositoryProvider.overrideWithValue(
          ContentPackRepository(source: DiskContentPackSource()),
        ),
        learnerContentStoreProvider.overrideWithValue(
          InMemoryLearnerContentStore(),
        ),
        contentClassKeyProvider.overrideWith((ref) async => terminaleD),
        contentPackCacheProvider.overrideWithValue(InMemoryContentPackCache()),
        remoteContentGatewayProvider.overrideWithValue(const OfflineGateway()),
        // Mode avion.
        isOfflineProvider.overrideWithValue(true),
        // Banque livrée, lue sur le disque : le cache d'assets de Flutter ne
        // survit pas d'un test à l'autre.
        companionDialogueBankProvider.overrideWith(
          (ref, language) async => loadBank(language == 'en' ? 'en' : 'fr'),
        ),
        selectedTutorProvider.overrideWith(
          (ref) => TutorPersona.resolve(companion),
        ),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(authControllerProvider.notifier)
        .setAuthenticatedUser(
          role: AppRole.student,
          userId: 'eleve-compagnon',
          email: 'eleve@example.com',
          firstName: 'Amina',
        );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              const Scaffold(body: AICompanionScreen(embedded: true)),
        ),
        GoRoute(
          path: '/quiz/pack/:setId',
          builder: (_, state) => PackQuizScreen(
            setId: state.pathParameters['setId']!,
            mode: PackQuizMode.fromName(state.uri.queryParameters['mode']),
          ),
        ),
        GoRoute(
          path: '/learn/pack-subject/:subjectKey',
          builder: (_, state) =>
              Text('matière ${state.pathParameters['subjectKey']}'),
        ),
        GoRoute(path: '/learn', builder: (_, _) => const Text('Apprendre')),
        GoRoute(path: '/quiz', builder: (_, _) => const Text('Quiz')),
        GoRoute(
          path: '/learn/local/:contentId',
          builder: (_, state) =>
              Text('séquence ${state.pathParameters['contentId']}'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('fr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: true,
            ),
            child: child!,
          ),
        ),
      ),
    );
    await settleSubjectJourneys(tester, container);
    await _settle(tester);
    return container;
  }

  Future<void> send(WidgetTester tester, String message) async {
    await tester.enterText(find.byType(TextField), message);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('companion-send')));
    await _settle(tester);
  }

  List<AIMessage> replies(ProviderContainer container) => [
    for (final message
        in container.read(aiCompanionControllerProvider).messages)
      if (message.role == AIMessageRole.assistant && message.id != 'welcome')
        message,
  ];

  testWidgets('mode avion : 20 messages, 20 réponses, aucune erreur réseau', (
    tester,
  ) async {
    final container = await pump(tester);
    const messages = [
      'Bonjour',
      'Ça va ?',
      'Je suis fatigué',
      "Je n'arrive pas à travailler",
      'Je veux réviser',
      'Aide-moi',
      'Je veux faire des maths',
      "On fait de l'anglais ?",
      'Je veux un quiz',
      "Qu'est-ce que je dois réviser ?",
      'Je suis nul en physique',
      "J'ai peur pour mon examen",
      'Je ne comprends rien',
      'Merci',
      'Tu es une IA ?',
      'Qui es-tu ?',
      'Je m’ennuie',
      'Surprends-moi',
      'Explique-moi la relativité générale',
      'À demain',
    ];
    for (final message in messages) {
      await send(tester, message);
    }
    expect(replies(container), hasLength(20));
    for (final forbidden in [
      'réseau',
      'connexion',
      'indisponible',
      'limite de questions',
      'réfléchit',
      'Recherche',
    ]) {
      expect(find.textContaining(forbidden), findsNothing, reason: forbidden);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('un quiz lancé depuis le Compagnon s’ouvre, hors ligne', (
    tester,
  ) async {
    await pump(tester);
    await send(tester, 'Je veux un quiz de physique');
    expect(
      find.byKey(
        const ValueKey('companion-reply-actions'),
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('companion-reply-actions'),
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    final training = find.text("S'entraîner");
    await tester.ensureVisible(training);
    await tester.tap(training);
    await _settle(tester);
    expect(find.byKey(const ValueKey('pack-quiz-intro')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('une matière proposée répond d’un toucher', (tester) async {
    final container = await pump(tester);
    await send(tester, 'Je veux travailler');
    final english = find.widgetWithText(OutlinedButton, 'Anglais');
    await tester.ensureVisible(english);
    await tester.tap(english);
    await _settle(tester);
    final last = replies(container).last;
    expect(last.actions.map((a) => a.subjectKey), everyElement('anglais'));
  });

  testWidgets('retour de quiz : le vrai score, commenté une seule fois', (
    tester,
  ) async {
    final container = await pump(tester);
    final catalog = container.read(packQuizCatalogProvider).requireValue;
    final set = catalog.subjects.first.sequences.first;
    await tester.runAsync(
      () => container
          .read(packQuizHistoryProvider.notifier)
          .record(
            PackQuizHistoryEntry(
              setId: set.id,
              subjectKey: set.subjectKey,
              title: set.title,
              mode: PackQuizMode.evaluation,
              score: 7,
              total: 10,
              completedAt: DateTime.now(),
            ),
          ),
    );
    await _settle(tester);
    final comment = replies(container).single;
    expect(comment.text, contains('7/10'));
    expect(comment.actions.first.setId, set.id);
    expect(find.text('Refaire ce quiz'), findsOneWidget);

    // Nouveau fil : le même quiz n'est pas commenté deux fois.
    container
        .read(aiCompanionControllerProvider.notifier)
        .startNewConversation();
    await _settle(tester);
    expect(replies(container), isEmpty);
  });

  testWidgets('historique : fils marqués deterministic_v1, anciens fils '
      'jamais rejoués', (tester) async {
    final legacy = CompanionConversation(
      id: 'ancien',
      learnerId: 'eleve-compagnon',
      createdAt: DateTime(2026, 9),
      lastActivityAt: DateTime(2026, 9),
    );
    final scope = CompanionHistoryRepository.scopeOf('eleve-compagnon')!;
    final container = await pump(
      tester,
      prefs: {
        'intellia_companion_index_v1_$scope': jsonEncode([legacy.toJson()]),
        'intellia_companion_thread_v1_${scope}_ancien': jsonEncode([
          {
            'id': 'x',
            'role': 'assistant',
            'text': 'Ancienne réponse du service en ligne',
            'createdAt': '2026-09-01T10:00:00.000',
          },
        ]),
      },
    );
    expect(find.text('Ancienne réponse du service en ligne'), findsNothing);
    await send(tester, 'Bonjour');
    final repository = await tester.runAsync(
      () => container.read(companionHistoryRepositoryProvider.future),
    );
    final conversations = repository!.listConversations('eleve-compagnon');
    expect(conversations.where((c) => c.isDeterministic), hasLength(1));
    expect(conversations.where((c) => c.id == 'ancien'), hasLength(1));
  });

  testWidgets('lecteur d’écran : bulles, actions et « Kira écrit… » '
      'annoncés', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'Je veux un quiz');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('companion-send')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump();
    await _settle(tester);
    final actions = find.byKey(
      const ValueKey('companion-reply-actions'),
      skipOffstage: false,
    );
    expect(actions, findsOneWidget);
    for (final button
        in find
            .descendant(of: actions, matching: find.byType(ButtonStyleButton))
            .evaluate()) {
      final node = tester.getSemantics(find.byWidget(button.widget));
      expect(node.label.trim(), isNotEmpty);
      expect(
        tester.getSize(find.byWidget(button.widget)).height,
        greaterThanOrEqualTo(44),
      );
    }
    handle.dispose();
  });

  for (final (width, scale) in [(320.0, 1.0), (360.0, 1.3), (412.0, 1.0)]) {
    testWidgets('lisible à ${width.toInt()} px, texte ×$scale', (tester) async {
      await pump(tester, size: Size(width, 780), textScale: scale);
      await send(tester, 'Je veux un quiz');
      await send(tester, 'Qu’est-ce que je dois réviser ?');
      final paragraphs = tester.renderObjectList<RenderParagraph>(
        find.descendant(
          of: find.byKey(
            const ValueKey('companion-reply-actions'),
            skipOffstage: false,
          ),
          matching: find.byType(RichText),
        ),
      );
      for (final paragraph in paragraphs) {
        expect(paragraph.didExceedMaxLines, isFalse);
      }
      expect(tester.takeException(), isNull);
    });
  }
}

/// Assets (banque de dialogues) et délais locaux : laisser le temps réel
/// avancer un peu, puis les images.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 150));
  }
}
