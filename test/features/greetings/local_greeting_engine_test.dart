import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/greetings/domain/local_greeting_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  test('avoids immediate repetition for the same learner', () async {
    final preferences = await SharedPreferences.getInstance();
    const context = GreetingContext(
      learnerId: 'student-a',
      companionId: 'kira',
      languageCode: 'fr',
      firstName: 'Calvin',
      classLevel: 'Terminale',
      event: GreetingEvent.morning,
    );

    final greetings = <String>[];
    for (var index = 0; index < 4; index++) {
      final greeting = await LocalGreetingEngine.select(
        context,
        now: DateTime(2026, 9, 4, 8),
        preferences: preferences,
      );
      greetings.add(greeting.id);
    }

    expect(greetings.toSet(), hasLength(4));
  });

  test('covers every contextual family in French and English', () async {
    final preferences = await SharedPreferences.getInstance();
    for (final event in GreetingEvent.values) {
      final french = await LocalGreetingEngine.select(
        GreetingContext(
          learnerId: 'fr-${event.name}',
          companionId: 'kira',
          languageCode: 'fr',
          firstName: 'Amina',
          classLevel: '1ère',
          event: event,
        ),
        preferences: preferences,
      );
      final english = await LocalGreetingEngine.select(
        GreetingContext(
          learnerId: 'en-${event.name}',
          companionId: 'leo',
          languageCode: 'en',
          firstName: 'Maya',
          classLevel: 'Upper Sixth',
          event: event,
        ),
        preferences: preferences,
      );

      expect(french.text.trim(), isNotEmpty, reason: event.name);
      expect(english.text.trim(), isNotEmpty, reason: event.name);
      expect(
        french.text.toLowerCase(),
        isNot(contains('intelligence artificielle')),
      );
      expect(
        english.text.toLowerCase(),
        isNot(contains('artificial intelligence')),
      );
    }
  });

  test('adapts tone by level and companion without stereotypes', () async {
    final preferences = await SharedPreferences.getInstance();
    final early = await LocalGreetingEngine.select(
      const GreetingContext(
        learnerId: 'early',
        companionId: 'kira',
        languageCode: 'fr',
        classLevel: '6ème',
        event: GreetingEvent.neutral,
      ),
      preferences: preferences,
    );
    final finalYear = await LocalGreetingEngine.select(
      const GreetingContext(
        learnerId: 'final',
        companionId: 'leo',
        languageCode: 'en',
        classLevel: 'Upper Sixth',
        event: GreetingEvent.neutral,
      ),
      preferences: preferences,
    );

    expect(
      early.text,
      anyOf(contains('tranquillement'), contains('étape'), contains('défi')),
    );
    expect(
      finalYear.text.toLowerCase(),
      anyOf(contains('exam'), contains('goals'), contains('preparation')),
    );
    expect(early.text, isNot(equals(finalYear.text)));
  });
}
