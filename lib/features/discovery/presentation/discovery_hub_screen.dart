import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../auth/application/auth_controller.dart';

/// Interactive Discovery Mode Hub for visitors and unverified Google users.
///
/// Invariant: Completely isolated from private school data, zero Firestore
/// queries for school entities, zero Gemini API invocation costs.
/// Presents curated, local educational demonstrations.
class DiscoveryHubScreen extends ConsumerStatefulWidget {
  const DiscoveryHubScreen({super.key});

  @override
  ConsumerState<DiscoveryHubScreen> createState() => _DiscoveryHubScreenState();
}

class _DiscoveryHubScreenState extends ConsumerState<DiscoveryHubScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final visitorName = authState.firstName ?? 'Visiteur';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'DÉCOUVERTE',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003366),
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'INTELLIA237',
              style: TextStyle(
                fontFamily: 'Didot',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            key: const ValueKey('discovery-exit-button'),
            onPressed: () {
              ref.read(authControllerProvider.notifier).exitDiscoveryMode();
              context.go(AppRoutes.authGateway);
            },
            icon: const Icon(
              Icons.exit_to_app_rounded,
              color: Colors.white,
              size: 18,
            ),
            label: const Text(
              'Quitter',
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTabIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedTabIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF003366).withValues(alpha: 0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(
              Icons.psychology_rounded,
              color: Color(0xFF003366),
            ),
            label: 'Tuteurs IA',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(
              Icons.auto_stories_rounded,
              color: Color(0xFF003366),
            ),
            label: 'Parcours',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz_rounded, color: Color(0xFF003366)),
            label: 'Quiz',
          ),
          NavigationDestination(
            icon: Icon(Icons.family_restroom_outlined),
            selectedIcon: Icon(
              Icons.family_restroom_rounded,
              color: Color(0xFF003366),
            ),
            label: 'Espace Parent',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcoming banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF003366), Color(0xFF004080)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF003366).withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour $visitorName !',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Bienvenue dans la découverte interactive d’INTELLIA237. Découvrez comment notre plateforme transforme la réussite scolaire au Cameroun.',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      height: 1.4,
                      color: Color(0xFFE0E0E0),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton.icon(
                        key: const ValueKey('discovery-cta-join-code'),
                        onPressed: () =>
                            context.push(AppRoutes.studentAccessCode),
                        icon: const Icon(
                          Icons.key_rounded,
                          size: 16,
                          color: Color(0xFF003366),
                        ),
                        label: const Text(
                          'J’ai un code élève',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF003366),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        key: const ValueKey('discovery-cta-register'),
                        onPressed: () => context.push(AppRoutes.register),
                        icon: const Icon(
                          Icons.person_add_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Créer un compte',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.white,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tab content
            switch (_selectedTabIndex) {
              0 => _TutorsShowcase(),
              1 => _ParcoursShowcase(),
              2 => _QuizShowcase(),
              3 => _ParentDashboardShowcase(),
              _ => const SizedBox.shrink(),
            },
          ],
        ),
      ),
    );
  }
}

class _TutorsShowcase extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Les Tuteurs Pédagogiques Intelligents',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Conçus pour guider les élèves avec méthode sans donner les réponses directement.',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 13,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 16),
        _TutorCard(
          name: 'KIRA',
          role: 'Tuteur Socratique & Sciences',
          accent: const Color(0xFF5444D8),
          tagline:
              '« Je ne te donne pas la formule, je t’aide à la reconstruire. »',
          description:
              'KIRA pose des questions guidées pas-à-pas pour aider l’élève à comprendre les concepts de Mathématiques, Physique et Chimie du programme camerounais.',
          sampleQuestion: 'Comment résoudre l’équation : 2x + 6 = 14 ?',
          sampleReply:
              'Pour isoler x, quelle opération devrais-tu d’abord faire des deux côtés de l’égalité pour éliminer le 6 ?',
        ),
        const SizedBox(height: 16),
        _TutorCard(
          name: 'LÉO',
          role: 'Coach Méthodologique & Langues',
          accent: const Color(0xFF0099FF),
          tagline: '« Structurons tes idées et renforçons tes arguments. »',
          description:
              'LÉO accompagne l’élève dans la rédaction, la dissertation, l’histoire-géographie et l’apprentissage du Français et de l’Anglais.',
          sampleQuestion:
              'Aide-moi à faire le plan de ma rédaction sur la solidarité.',
          sampleReply:
              'Commençons par définir ce qu’évoque pour toi la solidarité dans ton quartier. Peux-tu me citer deux exemples concrets ?',
        ),
      ],
    );
  }
}

class _TutorCard extends StatelessWidget {
  const _TutorCard({
    required this.name,
    required this.role,
    required this.accent,
    required this.tagline,
    required this.description,
    required this.sampleQuestion,
    required this.sampleReply,
  });

  final String name;
  final String role;
  final Color accent;
  final String tagline;
  final String description;
  final String sampleQuestion;
  final String sampleReply;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: accent.withValues(alpha: 0.15),
                child: Text(
                  name[0],
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  Text(
                    role,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tagline,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontStyle: FontStyle.italic,
              fontSize: 12.5,
              color: Color(0xFF555555),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF444444),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 14,
                      color: Color(0xFF777777),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Élève : ',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        sampleQuestion,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.smart_toy_outlined, size: 14, color: accent),
                    const SizedBox(width: 6),
                    Text(
                      '$name : ',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: accent,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        sampleReply,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParcoursShowcase extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Parcours & Fiches de Révision',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Alignés sur le curriculum officiel du Ministère des Enseignements Secondaires (MINESEC).',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 13,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 16),
        _ParcoursItem(
          subject: 'Mathématiques — 3ème & Seconde C',
          chapter: 'Équations & Inéquations du 1er degré',
          lessonsCount: '4 leçons • 12 exercices',
          progress: 0.75,
        ),
        const SizedBox(height: 12),
        _ParcoursItem(
          subject: 'Physique — Première C/D',
          chapter: 'Cinématique du point matériel',
          lessonsCount: '5 leçons • 8 exercices',
          progress: 0.40,
        ),
        const SizedBox(height: 12),
        _ParcoursItem(
          subject: 'SVT — Terminale D',
          chapter: 'Génétique mendélienne & transmission',
          lessonsCount: '6 leçons • 15 exercices',
          progress: 0.90,
        ),
      ],
    );
  }
}

class _ParcoursItem extends StatelessWidget {
  const _ParcoursItem({
    required this.subject,
    required this.chapter,
    required this.lessonsCount,
    required this.progress,
  });

  final String subject;
  final String chapter;
  final String lessonsCount;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subject,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF003366),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003366),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            chapter,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFEEEEEE),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF003366)),
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          Text(
            lessonsCount,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 11,
              color: Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizShowcase extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quiz Interactifs & Auto-Évaluation',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Correction immédiate, explications détaillées et badges de maîtrise.',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 13,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'EXEMPLE DE QUIZ',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF80643D),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Question 1 / 5',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Quelle est la capitale politique du Cameroun ?',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 14),
              _QuizOption(text: 'A. Douala', isCorrect: false),
              const SizedBox(height: 8),
              _QuizOption(
                text: 'B. Yaoundé',
                isCorrect: true,
                isSelected: true,
              ),
              const SizedBox(height: 8),
              _QuizOption(text: 'C. Bafoussam', isCorrect: false),
              const SizedBox(height: 8),
              _QuizOption(text: 'D. Garoua', isCorrect: false),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF2E7D32),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bravo ! Yaoundé est le siège des institutions politiques, tandis que Douala est la capitale économique.',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuizOption extends StatelessWidget {
  const _QuizOption({
    required this.text,
    required this.isCorrect,
    this.isSelected = false,
  });

  final String text;
  final bool isCorrect;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF2E7D32).withValues(alpha: 0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFDDDDDD),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF333333),
              ),
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle, size: 18, color: Color(0xFF2E7D32)),
        ],
      ),
    );
  }
}

class _ParentDashboardShowcase extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'L’Espace Parent Intellia',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Suivez le travail, la régularité et les progrès de votre enfant sans intrusion.',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 13,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF5444D8).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFF0EADB),
                    child: Icon(
                      Icons.person,
                      size: 18,
                      color: Color(0xFF003366),
                    ),
                  ),
                  SizedBox(width: 10),
                  const Text(
                    'Exemple : Samuel (Classe de 3ème)',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MetricPill(label: 'Temps d’étude', value: '4h 15m'),
                  _MetricPill(label: 'Exercices', value: '28 terminés'),
                  _MetricPill(label: 'Taux réussite', value: '86%'),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Liaison sécurisée :',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF555555),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Chaque élève dispose d’un code famille unique. Le parent relie son numéro camerounais au code de l’élève pour activer le suivi en direct.',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  height: 1.35,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF003366),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 11,
            color: Color(0xFF888888),
          ),
        ),
      ],
    );
  }
}
