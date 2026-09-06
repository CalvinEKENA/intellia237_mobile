import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/ai_companion/data/companion_history_repository.dart';
import 'package:intellia237/features/ai_companion/domain/ai_message.dart';
import 'package:intellia237/features/ai_companion/domain/companion_conversation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// L'élève doit retrouver ses conversations après avoir quitté l'écran ou
/// fermé l'application, et ces conversations sont privées : un autre élève du
/// même appareil ne peut pas les lire.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CompanionHistoryRepository repository;

  AIMessage user(String text, DateTime at) => AIMessage(
    id: 'u-$at',
    role: AIMessageRole.user,
    text: text,
    createdAt: at,
  );

  AIMessage companion(String text, DateTime at, String id) => AIMessage(
    id: 'a-$at',
    role: AIMessageRole.assistant,
    text: text,
    createdAt: at,
    companionId: id,
  );

  CompanionConversation blank(String id, String learnerId, DateTime at) =>
      CompanionConversation(
        id: id,
        learnerId: learnerId,
        createdAt: at,
        lastActivityAt: at,
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues(const {});
    repository = CompanionHistoryRepository(
      await SharedPreferences.getInstance(),
    );
  });

  group('persistance', () {
    test('un fil enregistré se retrouve avec ses messages', () async {
      final at = DateTime(2026, 9, 6, 10);
      await repository.saveConversation(
        learnerId: 'student-a',
        conversation: blank('c1', 'student-a', at),
        messages: [
          user('Explique les fractions', at),
          companion(
            'Voici comment faire.',
            at.add(const Duration(minutes: 1)),
            'kira',
          ),
        ],
      );

      final conversations = repository.listConversations('student-a');
      expect(conversations, hasLength(1));
      expect(conversations.single.title, 'Explique les fractions');
      expect(conversations.single.preview, contains('Voici comment faire'));
      expect(conversations.single.companionId, 'kira');

      final messages = repository.readMessages('student-a', 'c1');
      expect(messages, hasLength(2));
      expect(messages.last.text, 'Voici comment faire.');
    });

    test('chaque message garde un horodatage fiable', () async {
      final at = DateTime(2026, 9, 6, 14, 32);
      await repository.saveConversation(
        learnerId: 'student-a',
        conversation: blank('c1', 'student-a', at),
        messages: [user('Bonjour', at)],
      );

      final restored = repository.readMessages('student-a', 'c1').single;
      expect(restored.createdAt, at);
    });

    test('les fils sont classés par activité récente', () async {
      final old = DateTime(2026, 9, 1, 9);
      final recent = DateTime(2026, 9, 6, 9);
      await repository.saveConversation(
        learnerId: 'student-a',
        conversation: blank('old', 'student-a', old),
        messages: [user('Ancienne question', old)],
      );
      await repository.saveConversation(
        learnerId: 'student-a',
        conversation: blank('recent', 'student-a', recent),
        messages: [user('Question du jour', recent)],
      );

      final ids = repository
          .listConversations('student-a')
          .map((c) => c.id)
          .toList();
      expect(ids, ['recent', 'old']);
    });

    test('un fil sans échange réel n’encombre pas l’historique', () async {
      final at = DateTime(2026, 9, 6, 10);
      await repository.saveConversation(
        learnerId: 'student-a',
        conversation: blank('c1', 'student-a', at),
        messages: [
          AIMessage(
            id: 'welcome',
            role: AIMessageRole.assistant,
            text: 'Bienvenue',
            createdAt: at,
          ),
        ],
      );

      expect(repository.listConversations('student-a'), isEmpty);
    });

    test('supprimer un fil retire aussi ses messages', () async {
      final at = DateTime(2026, 9, 6, 10);
      await repository.saveConversation(
        learnerId: 'student-a',
        conversation: blank('c1', 'student-a', at),
        messages: [user('Question', at)],
      );

      await repository.deleteConversation('student-a', 'c1');

      expect(repository.listConversations('student-a'), isEmpty);
      expect(repository.readMessages('student-a', 'c1'), isEmpty);
    });
  });

  group('isolation par élève', () {
    test('un second élève du même appareil ne voit rien du premier', () async {
      final at = DateTime(2026, 9, 6, 10);
      await repository.saveConversation(
        learnerId: 'student-a',
        conversation: blank('c1', 'student-a', at),
        messages: [user('Ma question privée', at)],
      );

      expect(repository.listConversations('student-b'), isEmpty);
      expect(repository.readMessages('student-b', 'c1'), isEmpty);
    });

    test('chaque élève garde son propre historique', () async {
      final at = DateTime(2026, 9, 6, 10);
      await repository.saveConversation(
        learnerId: 'student-a',
        conversation: blank('c1', 'student-a', at),
        messages: [user('Question A', at)],
      );
      await repository.saveConversation(
        learnerId: 'student-b',
        conversation: blank('c1', 'student-b', at),
        messages: [user('Question B', at)],
      );

      expect(
        repository.listConversations('student-a').single.title,
        'Question A',
      );
      expect(
        repository.listConversations('student-b').single.title,
        'Question B',
      );
    });

    test('une session sans identifiant n’écrit ni ne lit rien', () async {
      final at = DateTime(2026, 9, 6, 10);
      await repository.saveConversation(
        learnerId: null,
        conversation: blank('c1', 'anonymous', at),
        messages: [user('Question', at)],
      );

      expect(repository.listConversations(null), isEmpty);
      expect(CompanionHistoryRepository.scopeOf('  '), isNull);
    });

    test('un fil rangé sous une autre identité reste invisible', () async {
      // Défense en profondeur : même si l'index était corrompu, le
      // propriétaire déclaré du fil est vérifié à la lecture.
      final prefs = await SharedPreferences.getInstance();
      final scope = CompanionHistoryRepository.scopeOf('student-a')!;
      await prefs.setString(
        'intellia_companion_index_v1_$scope',
        jsonEncode([
          {
            'id': 'intrus',
            'learnerId': 'student-b',
            'createdAt': DateTime(2026, 9, 6).toIso8601String(),
            'lastActivityAt': DateTime(2026, 9, 6).toIso8601String(),
            'title': 'Fil d’un autre élève',
            'preview': '',
          },
        ]),
      );
      final fresh = CompanionHistoryRepository(prefs);

      expect(fresh.listConversations('student-a'), isEmpty);
    });
  });

  group('changement de compagnon', () {
    test('Kira puis Léo : rien n’est perdu ni réattribué', () async {
      final at = DateTime(2026, 9, 6, 10);
      await repository.saveConversation(
        learnerId: 'student-a',
        conversation: blank('c1', 'student-a', at),
        messages: [
          user('Première question', at),
          companion(
            'Réponse de Kira',
            at.add(const Duration(minutes: 1)),
            'kira',
          ),
          user('Deuxième question', at.add(const Duration(minutes: 2))),
          companion(
            'Réponse de Léo',
            at.add(const Duration(minutes: 3)),
            'leo',
          ),
        ],
      );

      final messages = repository.readMessages('student-a', 'c1');
      expect(messages, hasLength(4));
      // Le passé garde son auteur ; seul le message suivant change de persona.
      expect(messages[1].companionId, 'kira');
      expect(messages[3].companionId, 'leo');
      expect(messages[1].text, 'Réponse de Kira');
    });
  });

  group('reprise de l’ancien historique unique', () {
    test('le fil précédent devient la première conversation', () async {
      final prefs = await SharedPreferences.getInstance();
      final scope = CompanionHistoryRepository.scopeOf('student-a')!;
      final at = DateTime(2026, 9, 5, 18);
      await prefs.setString(
        'intellia_companion_history_v2_$scope',
        jsonEncode([
          {
            'id': 'm1',
            'role': 'user',
            'text': 'Ancienne question',
            'createdAt': at.toIso8601String(),
          },
        ]),
      );
      final fresh = CompanionHistoryRepository(prefs);

      final migrated = await fresh.migrateLegacyThread('student-a');

      expect(migrated, isNotNull);
      expect(
        fresh.listConversations('student-a').single.title,
        'Ancienne question',
      );
      // L'ancienne clé est consommée : la reprise ne se rejoue pas.
      expect(prefs.getString('intellia_companion_history_v2_$scope'), isNull);
      expect(await fresh.migrateLegacyThread('student-a'), isNull);
    });

    test('un historique illisible ne bloque pas le compagnon', () async {
      final prefs = await SharedPreferences.getInstance();
      final scope = CompanionHistoryRepository.scopeOf('student-a')!;
      await prefs.setString(
        'intellia_companion_index_v1_$scope',
        'ceci n’est pas du JSON',
      );
      final fresh = CompanionHistoryRepository(prefs);

      expect(fresh.listConversations('student-a'), isEmpty);
    });
  });
}
