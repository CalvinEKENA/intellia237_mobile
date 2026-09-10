import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/greetings/domain/local_greeting_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sur un vrai téléphone, Léo accueillait un compte créé la minute précédente
/// par « Belle régularité Calvin. Reprenons sans perdre le fil. »
///
/// Deux défauts se combinaient : le repère mémorisé datait d'un *affichage de
/// salutation* et non d'une séance, et « progression disponible » valait
/// « progression réalisée ». Ces tests verrouillent les deux.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  /// Formulations qui affirment un passé scolaire.
  const claimsPastWork = [
    'régularité',
    'Reprenons',
    'derniers progrès',
    'Te revoilà',
    'Bon retour',
    'consistency',
    'Welcome back',
    'still fresh',
    'back at it',
    'It has been a few days',
  ];

  void expectNoInventedPast(String text) {
    for (final claim in claimsPastWork) {
      expect(
        text.toLowerCase(),
        isNot(contains(claim.toLowerCase())),
        reason:
            'un élève sans historique ne peut pas se voir dire « $claim » '
            'dans : $text',
      );
    }
  }

  test('la toute première séance accueille sans inventer de passé', () async {
    final preferences = await SharedPreferences.getInstance();
    const context = GreetingContext(
      learnerId: 'new-student',
      companionId: 'leo',
      languageCode: 'fr',
      firstName: 'Calvin',
      classLevel: 'Terminale',
    );

    final greeting = await LocalGreetingEngine.select(
      context,
      now: DateTime(2026, 9, 6, 9),
      preferences: preferences,
    );

    expect(greeting.id, contains(GreetingEvent.beginningSession.name));
    expectNoInventedPast(greeting.text);
  });

  test(
    'revenir sans avoir rien fait ne crée jamais de fausse régularité',
    () async {
      final preferences = await SharedPreferences.getInstance();
      const context = GreetingContext(
        learnerId: 'new-student',
        companionId: 'leo',
        languageCode: 'fr',
        firstName: 'Calvin',
        classLevel: 'Terminale',
      );

      // Premier affichage : le moteur mémorise l'instant de la salutation.
      await LocalGreetingEngine.select(
        context,
        now: DateTime(2026, 9, 6, 9),
        preferences: preferences,
      );

      // Second affichage quelques minutes plus tard, toujours sans aucune
      // activité d'apprentissage. C'est exactement le scénario observé.
      final second = await LocalGreetingEngine.select(
        context,
        now: DateTime(2026, 9, 6, 9, 20),
        preferences: preferences,
      );

      expectNoInventedPast(second.text);
      expect(
        second.id,
        isNot(contains(GreetingEvent.returnAfterRecentStudy.name)),
      );
      expect(
        second.id,
        isNot(contains(GreetingEvent.returnAfterSeveralDays.name)),
      );
    },
  );

  test(
    'trois jours d’absence sans activité ne déclenchent pas de retour',
    () async {
      final preferences = await SharedPreferences.getInstance();
      const context = GreetingContext(
        learnerId: 'idle-student',
        companionId: 'kira',
        languageCode: 'fr',
        firstName: 'Calvin',
      );

      await LocalGreetingEngine.select(
        context,
        now: DateTime(2026, 9, 1, 9),
        preferences: preferences,
      );
      final later = await LocalGreetingEngine.select(
        context,
        now: DateTime(2026, 9, 6, 9),
        preferences: preferences,
      );

      expectNoInventedPast(later.text);
    },
  );

  test(
    'une reprise récente n’est annoncée que sur une activité datée',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final context = GreetingContext(
        learnerId: 'active-student',
        companionId: 'leo',
        languageCode: 'fr',
        firstName: 'Calvin',
        hasProgress: true,
        lastActivityAt: DateTime(2026, 9, 6, 8),
      );

      await LocalGreetingEngine.select(
        context,
        now: DateTime(2026, 9, 6, 8, 30),
        preferences: preferences,
      );
      final second = await LocalGreetingEngine.select(
        context,
        now: DateTime(2026, 9, 6, 9),
        preferences: preferences,
      );

      expect(second.id, contains(GreetingEvent.returnAfterRecentStudy.name));
    },
  );

  test('un vrai retour après plusieurs jours reste possible', () async {
    final preferences = await SharedPreferences.getInstance();
    final context = GreetingContext(
      learnerId: 'returning-student',
      companionId: 'kira',
      languageCode: 'fr',
      firstName: 'Calvin',
      hasProgress: true,
      lastActivityAt: DateTime(2026, 9, 1, 10),
    );

    await LocalGreetingEngine.select(
      context,
      now: DateTime(2026, 9, 1, 10),
      preferences: preferences,
    );
    final later = await LocalGreetingEngine.select(
      context,
      now: DateTime(2026, 9, 6, 10),
      preferences: preferences,
    );

    expect(later.id, contains(GreetingEvent.returnAfterSeveralDays.name));
  });

  test('le repli n’accueille pas un nouvel élève par « Bon retour »', () {
    const french = GreetingContext(
      learnerId: 'new-student',
      companionId: 'kira',
      languageCode: 'fr',
      firstName: 'Calvin',
    );
    const english = GreetingContext(
      learnerId: 'new-student',
      companionId: 'kira',
      languageCode: 'en',
      firstName: 'Calvin',
    );

    expect(LocalGreetingEngine.fallback(french), startsWith('Bienvenue'));
    expect(LocalGreetingEngine.fallback(english), startsWith('Welcome,'));

    // L'élève qui a réellement travaillé garde sa formulation de retour.
    const returning = GreetingContext(
      learnerId: 'returning',
      companionId: 'kira',
      languageCode: 'fr',
      firstName: 'Calvin',
      hasProgress: true,
    );
    expect(LocalGreetingEngine.fallback(returning), startsWith('Bon retour'));
  });
}
