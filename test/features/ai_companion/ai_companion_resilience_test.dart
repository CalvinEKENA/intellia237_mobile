import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/ai_companion/application/ai_companion_controller.dart';
import 'package:intellia237/features/ai_companion/domain/tutor_turn_options.dart';
import 'package:intellia237/features/ai_companion/data/ai_repository.dart';
import 'package:intellia237/features/ai_companion/domain/ai_companion_reply.dart';
import 'package:intellia237/features/ai_companion/domain/ai_message.dart';
import 'package:intellia237/features/ai_companion/presentation/ai_companion_screen.dart';
import 'package:intellia237/features/learn/application/learn_providers.dart';
import 'package:intellia237/features/learn/domain/learn_academic_context.dart';
import 'package:intellia237/features/tutor/domain/tutor_persona.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Kira remains visible when the live askTutor service fails', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final repository = _UnavailableTutorRepository();
    final container = ProviderContainer(
      overrides: [
        aiRepositoryProvider.overrideWithValue(repository),
        studentAcademicContextProvider.overrideWith(
          (ref) async => const LearnAcademicContext(
            classLevel: '6eme',
            catalogClassLevel: '6eme',
            academicLevelId: 'fr_general_6e',
            tutorId: 'kira',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AICompanionScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Kira'), findsOneWidget);
    expect(_hasAvatar(tester, 'assets/companions/kira.png'), isTrue);

    await tester.enterText(find.byType(TextField), 'Explique les fractions');
    await tester.pump();
    // Le composeur ne porte qu'un seul verbe : « Parler » devient « Envoyer »
    // dès qu'un caractère utile est saisi.
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(repository.calls, 1);
    expect(find.text('Kira'), findsOneWidget);
    expect(_hasAvatar(tester, 'assets/companions/kira.png'), isTrue);
    expect(find.textContaining('cours et exercices'), findsOneWidget);
    expect(
      container.read(aiCompanionControllerProvider).errorKind,
      AICompanionFailureKind.serviceUnavailable,
    );
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  test('first message waits for the asynchronous academic profile', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final profile = Completer<LearnAcademicContext>();
    final repository = _CapturingTutorRepository();
    final container = ProviderContainer(
      overrides: [
        aiRepositoryProvider.overrideWithValue(repository),
        studentAcademicContextProvider.overrideWith((ref) => profile.future),
      ],
    );
    addTearDown(container.dispose);

    final send = container
        .read(aiCompanionControllerProvider.notifier)
        .send('Explique les fractions');
    await Future<void>.delayed(Duration.zero);
    expect(repository.calls, 0);
    expect(container.read(aiCompanionControllerProvider).isSending, isTrue);

    profile.complete(
      const LearnAcademicContext(
        classLevel: '6eme',
        catalogClassLevel: '6eme',
        academicLevelId: 'fr_general_6e',
        tutorId: 'kira',
      ),
    );
    await send;

    expect(repository.calls, 1);
    expect(repository.classLevel, '6eme');
    expect(
      repository.history?.where(
        (item) => item.text == 'Explique les fractions',
      ),
      isEmpty,
    );
    expect(container.read(aiCompanionControllerProvider).errorMessage, isNull);
  });
}

bool _hasAvatar(WidgetTester tester, String assetName) {
  return tester.widgetList<Container>(find.byType(Container)).any((container) {
    final decoration = container.decoration;
    if (decoration is! BoxDecoration) return false;
    final provider = decoration.image?.image;
    return provider is AssetImage && provider.assetName == assetName;
  });
}

class _UnavailableTutorRepository implements AIRepository {
  int calls = 0;

  @override
  Future<AICompanionReply> sendMessage({
    required TutorPersona tutor,
    required String classLevel,
    required List<AIMessage> history,
    required String userMessage,
    TutorTurnOptions options = const TutorTurnOptions(),
  }) async {
    calls += 1;
    throw const AICompanionException(
      message:
          'Kira n’arrive pas à répondre pour le moment. '
          'Tu peux continuer à consulter tes cours et exercices.',
      kind: AICompanionFailureKind.serviceUnavailable,
      normalizedErrorCode: 'not-found',
      diagnosticId: 'TUTOR-SERVICE-505',
    );
  }
}

class _CapturingTutorRepository implements AIRepository {
  int calls = 0;
  String? classLevel;
  List<AIMessage>? history;

  @override
  Future<AICompanionReply> sendMessage({
    required TutorPersona tutor,
    required String classLevel,
    required List<AIMessage> history,
    required String userMessage,
    TutorTurnOptions options = const TutorTurnOptions(),
  }) async {
    calls += 1;
    this.classLevel = classLevel;
    this.history = history;
    return AICompanionReply(
      message: AIMessage(
        id: 'reply',
        role: AIMessageRole.assistant,
        text: 'Voici une explication.',
        createdAt: DateTime(2026),
      ),
      quota: AICompanionQuota(
        limit: 20,
        remaining: 19,
        resetsAt: DateTime(2026, 1, 2),
      ),
    );
  }
}
