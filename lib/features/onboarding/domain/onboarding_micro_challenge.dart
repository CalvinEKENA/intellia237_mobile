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
}

abstract final class OnboardingMicroChallenges {
  static OnboardingMicroChallenge forContext({
    required String subject,
    String? academicLevel,
    String? subsystem,
  }) {
    final normalized = subject.toLowerCase();
    if (normalized.contains('fran')) {
      return OnboardingMicroChallenge(
        subject: 'Français',
        academicLevel: academicLevel,
        subsystem: subsystem,
        icon: Icons.menu_book_rounded,
        instruction: 'Choisis la phrase bien accordée',
        prompt: 'Laquelle est correcte ?',
        answers: const [
          'Les élèves avance.',
          'Les élèves avancent.',
          'Les élève avancent.',
        ],
        correctAnswerIndex: 1,
        explanation:
            'Le sujet « les élèves » est pluriel : le verbe devient « avancent ».',
      );
    }
    if (normalized.contains('english') || normalized.contains('anglais')) {
      return OnboardingMicroChallenge(
        subject: 'Anglais',
        academicLevel: academicLevel,
        subsystem: subsystem,
        icon: Icons.translate_rounded,
        instruction: 'Relie le mot à son sens',
        prompt: 'What does “careful” mean?',
        answers: const ['Rapide', 'Prudent', 'Bruyant'],
        correctAnswerIndex: 1,
        explanation: '“Careful” signifie « prudent » ou « attentif ».',
      );
    }
    if (normalized.contains('science')) {
      return OnboardingMicroChallenge(
        subject: 'Sciences',
        academicLevel: academicLevel,
        subsystem: subsystem,
        icon: Icons.science_rounded,
        instruction: 'Observe une transformation',
        prompt: 'Quand l’eau liquide devient vapeur, elle…',
        answers: const ['se condense', 's’évapore', 'se solidifie'],
        correctAnswerIndex: 1,
        explanation:
            'Le passage de l’état liquide à l’état gazeux s’appelle l’évaporation.',
      );
    }
    return OnboardingMicroChallenge(
      subject: 'Mathématiques',
      academicLevel: academicLevel,
      subsystem: subsystem,
      icon: Icons.functions_rounded,
      instruction: 'Repère la logique',
      prompt: 'Quel nombre complète : 2, 4, 8, … ?',
      answers: const ['10', '12', '16'],
      correctAnswerIndex: 2,
      explanation: 'Chaque nombre est multiplié par 2 : après 8 vient 16.',
    );
  }
}
