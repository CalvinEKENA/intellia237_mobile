import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'package:intellia237/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FailingTutorRepository implements AIRepository {
  _FailingTutorRepository(this.kind);

  final AICompanionFailureKind kind;

  @override
  Future<AICompanionReply> sendMessage({
    required TutorPersona tutor,
    required String classLevel,
    required List<AIMessage> history,
    required String userMessage,
    TutorTurnOptions options = const TutorTurnOptions(),
  }) async {
    throw AICompanionException(
      message: 'fallback',
      kind: kind,
      normalizedErrorCode: 'resource-exhausted',
      diagnosticId: 'TEST',
      retryable: false,
    );
  }
}

Future<String> _errorShownFor(
  WidgetTester tester,
  AICompanionFailureKind kind,
  Locale locale,
) async {
  SharedPreferences.setMockInitialValues(const <String, Object>{});
  final container = ProviderContainer(
    overrides: [
      aiRepositoryProvider.overrideWithValue(_FailingTutorRepository(kind)),
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
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const AICompanionScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.enterText(find.byType(TextField), 'Explique les fractions');
  await tester.pump();
  await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));

  expect(container.read(aiCompanionControllerProvider).errorKind, kind);
  final texts = tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
      .join('\n');
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  return texts;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'FR: empty study reserve and daily limit show different messages',
    (tester) async {
      final reserve = await _errorShownFor(
        tester,
        AICompanionFailureKind.studyReserveExhausted,
        const Locale('fr'),
      );
      expect(
        reserve,
        contains('Ta réserve d’étude est épuisée pour ce cycle.'),
      );
      expect(reserve, isNot(contains('questions du jour')));

      final daily = await _errorShownFor(
        tester,
        AICompanionFailureKind.quotaExhausted,
        const Locale('fr'),
      );
      expect(daily, contains('Tu as utilisé toutes tes questions du jour.'));
      expect(daily, isNot(contains('réserve d’étude est épuisée')));
    },
  );

  testWidgets(
    'EN: empty study reserve and daily limit show different messages',
    (tester) async {
      final reserve = await _errorShownFor(
        tester,
        AICompanionFailureKind.studyReserveExhausted,
        const Locale('en'),
      );
      expect(
        reserve,
        contains('Your study reserve is depleted for this cycle.'),
      );
      expect(reserve, isNot(contains('questions for today')));

      final daily = await _errorShownFor(
        tester,
        AICompanionFailureKind.quotaExhausted,
        const Locale('en'),
      );
      expect(daily, contains('You have used all your questions for today.'));
      expect(daily, isNot(contains('study reserve is depleted')));
    },
  );
}
