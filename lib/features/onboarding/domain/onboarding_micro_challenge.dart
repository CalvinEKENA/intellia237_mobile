import 'package:flutter/material.dart';

@immutable
class OnboardingMicroChallenge {
  const OnboardingMicroChallenge({
    required this.subject,
    required this.academicLevel,
    required this.subsystem,
    required this.icon,
    required this.instruction,
    required this.prompt,
    required this.answers,
    required this.correctAnswerIndex,
    required this.explanation,
    this.isNumberPattern = false,
  });

  final String subject;
  final String? academicLevel;
  final String? subsystem;
  final IconData icon;
  final String instruction;
  final String prompt;
  final List<String> answers;
  final int correctAnswerIndex;
  final String explanation;
  final bool isNumberPattern;
}

abstract final class OnboardingMicroChallenges {
  static OnboardingMicroChallenge forContext({
    required String subject,
    String? academicLevel,
    String? subsystem,
    String languageCode = 'fr',
  }) {
    final normalized = subject.toLowerCase();
    final english = languageCode == 'en';
    if (normalized.contains('fran') || normalized.contains('french')) {
      return OnboardingMicroChallenge(
        subject: english ? 'French' : 'Français',
        academicLevel: academicLevel,
        subsystem: subsystem,
        icon: Icons.menu_book_rounded,
        instruction: english
            ? 'Find the sentence with the correct agreement'
            : 'Choisis la phrase bien accordée',
        prompt: english
            ? 'Which sentence is correct?'
            : 'Laquelle est correcte ?',
        answers: const [
          'Les élèves avance.',
          'Les élèves avancent.',
          'Les élève avancent.',
        ],
        correctAnswerIndex: 1,
        explanation: english
            ? '“Les élèves” is plural, so the verb takes the plural form “avancent”.'
            : 'Le sujet « les élèves » est pluriel : le verbe devient « avancent ».',
      );
    }
    if (normalized.contains('english') || normalized.contains('anglais')) {
      return OnboardingMicroChallenge(
        subject: english ? 'English' : 'Anglais',
        academicLevel: academicLevel,
        subsystem: subsystem,
        icon: Icons.translate_rounded,
        instruction: english
            ? 'Match the word to its meaning'
            : 'Relie le mot à son sens',
        prompt: 'What does “careful” mean?',
        answers: english
            ? const ['Fast', 'Cautious', 'Noisy']
            : const ['Rapide', 'Prudent', 'Bruyant'],
        correctAnswerIndex: 1,
        explanation: english
            ? '“Careful” means being cautious and paying attention.'
            : '“Careful” signifie « prudent » ou « attentif ».',
      );
    }
    if (normalized.contains('science')) {
      return OnboardingMicroChallenge(
        subject: english ? 'Science' : 'Sciences',
        academicLevel: academicLevel,
        subsystem: subsystem,
        icon: Icons.science_rounded,
        instruction: english
            ? 'Observe a transformation'
            : 'Observe une transformation',
        prompt: english
            ? 'When liquid water becomes vapour, it…'
            : 'Quand l’eau liquide devient vapeur, elle…',
        answers: english
            ? const ['condenses', 'evaporates', 'solidifies']
            : const ['se condense', 's’évapore', 'se solidifie'],
        correctAnswerIndex: 1,
        explanation: english
            ? 'The change from a liquid to a gas is called evaporation.'
            : 'Le passage de l’état liquide à l’état gazeux s’appelle l’évaporation.',
      );
    }
    return OnboardingMicroChallenge(
      subject: english ? 'Mathematics' : 'Mathématiques',
      academicLevel: academicLevel,
      subsystem: subsystem,
      icon: Icons.functions_rounded,
      instruction: english ? 'Find the pattern' : 'Repère la logique',
      prompt: english
          ? 'Which number comes next: 2, 4, 8, …?'
          : 'Quel nombre complète : 2, 4, 8, … ?',
      answers: const ['10', '12', '16'],
      correctAnswerIndex: 2,
      isNumberPattern: true,
      explanation: english
          ? 'Multiply each number by 2: after 8 comes 16.'
          : 'Chaque nombre est multiplié par 2 : après 8 vient 16.',
    );
  }
}
