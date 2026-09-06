import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/ai_companion/data/companion_history_repository.dart';
import 'package:intellia237/features/ai_companion/domain/ai_message.dart';
import 'package:intellia237/features/ai_companion/domain/companion_conversation.dart';
import 'package:intellia237/features/learn/application/learn_providers.dart';
import 'package:intellia237/features/learn/domain/learn_academic_context.dart';
import 'package:intellia237/features/tutor/application/tutor_preference_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Depuis le profil, choisir un compagnon répondait « Ce compagnon ne peut pas
/// être enregistré sur ton profil » et l'élève ne sortait qu'avec « Passer ».
///
/// Deux mécanismes s'y opposaient : l'échec d'écriture annulait la sélection,
/// et la valeur encore stockée au profil reprenait systématiquement la main.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer containerFor({String? profileTutorId}) {
    final container = ProviderContainer(
      overrides: [
        studentAcademicContextProvider.overrideWith(
          (ref) async => LearnAcademicContext(
            classLevel: 'Terminale',
            tutorId: profileTutorId,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  group('changement depuis le profil', () {
    test('Kira → Léo prend effet même sans synchronisation', () async {
      final container = containerFor(profileTutorId: 'kira');
      await container.read(studentAcademicContextProvider.future);

      await container
          .read(tutorPreferenceProvider.notifier)
          .select('leo', pendingSync: true);

      expect(container.read(selectedTutorIdProvider), 'leo');
      expect(container.read(tutorSelectionPendingProvider), isTrue);
      // Le profil porte encore « kira » : le choix local doit primer, sinon le
      // changement paraîtrait impossible.
      expect(container.read(selectedTutorProvider)?.id, 'leo');
    });

    test('Léo → Kira prend effet de la même façon', () async {
      final container = containerFor(profileTutorId: 'leo');
      await container.read(studentAcademicContextProvider.future);

      await container
          .read(tutorPreferenceProvider.notifier)
          .select('kira', pendingSync: true);

      expect(container.read(selectedTutorProvider)?.id, 'kira');
    });

    test(
      'le profil reprend la main une fois la synchronisation confirmée',
      () async {
        final container = containerFor(profileTutorId: 'kira');
        await container.read(studentAcademicContextProvider.future);

        await container
            .read(tutorPreferenceProvider.notifier)
            .select('leo', pendingSync: true);
        await container.read(tutorPreferenceProvider.notifier).markSynced();

        expect(container.read(tutorSelectionPendingProvider), isFalse);
        // Le profil redevient autoritaire : il porte le choix des autres
        // appareils.
        expect(container.read(selectedTutorProvider)?.id, 'kira');
      },
    );

    test(
      'le choix survit à un redémarrage tant qu’il n’est pas synchronisé',
      () async {
        SharedPreferences.setMockInitialValues(const {
          'selected_tutor_id': 'leo',
          'selected_tutor_pending_sync': true,
        });
        final container = containerFor(profileTutorId: 'kira');
        await container.read(studentAcademicContextProvider.future);
        container.read(selectedTutorIdProvider);
        await Future<void>.delayed(Duration.zero);

        expect(container.read(selectedTutorIdProvider), 'leo');
        expect(container.read(tutorSelectionPendingProvider), isTrue);
        expect(container.read(selectedTutorProvider)?.id, 'leo');
      },
    );

    test(
      'un identifiant hérité reste résolu vers un compagnon officiel',
      () async {
        final container = containerFor();
        await container.read(studentAcademicContextProvider.future);

        await container
            .read(tutorPreferenceProvider.notifier)
            .select('Grace', pendingSync: true);

        expect(container.read(selectedTutorIdProvider), 'kira');
      },
    );
  });

  group('l’historique traverse le changement', () {
    test('les messages gardent le compagnon qui les a écrits', () async {
      final prefs = await SharedPreferences.getInstance();
      final repository = CompanionHistoryRepository(prefs);
      final at = DateTime(2026, 9, 6, 10);

      await repository.saveConversation(
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
            text: 'Une question',
            createdAt: at,
          ),
          AIMessage(
            id: 'a1',
            role: AIMessageRole.assistant,
            companionId: 'kira',
            text: 'Réponse de Kira',
            createdAt: at.add(const Duration(minutes: 1)),
          ),
        ],
      );

      // L'élève passe à Léo.
      final container = containerFor(profileTutorId: 'kira');
      await container.read(studentAcademicContextProvider.future);
      await container
          .read(tutorPreferenceProvider.notifier)
          .select('leo', pendingSync: true);

      final restored = repository.readMessages('student-a', 'c1');
      expect(restored, hasLength(2));
      // Rien n'est perdu, rien n'est réattribué.
      expect(restored.last.companionId, 'kira');
      expect(restored.last.text, 'Réponse de Kira');
      expect(repository.listConversations('student-a'), hasLength(1));
    });
  });
}
