import '../../tutor/domain/tutor_persona.dart';
import '../domain/ai_message.dart';
import 'ai_repository.dart';

class MockAIRepository implements AIRepository {
  @override
  Future<AIMessage> sendMessage({
    required TutorPersona tutor,
    required String classLevel,
    required List<AIMessage> history,
    required String userMessage,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final lower = userMessage.toLowerCase();
    final lessonContext =
        _docContextByClass[classLevel] ?? _docContextByClass['Seconde']!;

    // Ton du tuteur basé sur son id/nom
    final opening = 'En tant que ton tuteur ${tutor.name}, ';

    String pedagogicBlock;
    if (lower.contains('explique')) {
      pedagogicBlock =
          'je vais t\'expliquer cela simplement : $lessonContext. C\'est essentiel pour réussir ton ${tutor.levelLabel}.';
    } else if (lower.contains('resume')) {
      pedagogicBlock =
          'voici ce qu\'il faut retenir en priorité pour le ${tutor.levelLabel} : $lessonContext.';
    } else if (lower.contains('exemple')) {
      pedagogicBlock =
          'prenons un exemple concret tiré des annales du ${tutor.levelLabel} pour illustrer $lessonContext.';
    } else if (lower.contains('3 questions') ||
        lower.contains('trois questions')) {
      pedagogicBlock =
          'testons tes connaissances pour le ${tutor.levelLabel} :\n'
          '1) Question de cours sur la définition.\n'
          '2) Application directe.\n'
          '3) Cas particulier à analyser.';
    } else {
      pedagogicBlock =
          'je suis là pour t\'accompagner vers la réussite de ton ${tutor.levelLabel}. Sur quoi souhaites-tu travailler ?';
    }

    final answer =
        '$opening$pedagogicBlock\n\n'
        'Devise : ${tutor.motto}';

    return AIMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: AIMessageRole.assistant,
      text: answer,
      createdAt: DateTime.now(),
    );
  }

  static const Map<String, String> _docContextByClass = {
    '6eme':
        'Fractions simples, proportionnalite de base et vocabulaire scientifique debutant',
    '5eme':
        'Calcul litteral elementaire, geometrie plane et lecture de documents',
    '4eme':
        'Equations simples, statistiques debutantes et redaction argumentee',
    '3eme':
        'Fonctions lineaires, raisonnement scientifique et synthese de texte',
    'Seconde': 'Fonctions affines, interpretation graphique et loi d\'Ohm',
    'Premiere': 'Derivation de base, probabilites et argumentation avancee',
    'Terminale':
        'Modelisation, analyse critique et resolution de problemes complexes',
  };
}
