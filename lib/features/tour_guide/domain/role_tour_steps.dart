import 'package:flutter/material.dart';

import '../../auth/domain/app_role.dart';
import 'tour_guide_step_data.dart';
import 'tour_guide_target_ids.dart';

List<TourGuideStepData> roleTourSteps(AppRole role) {
  return switch (role) {
    AppRole.student => const [
      TourGuideStepData(
        targetId: TourGuideTargetIds.studentHeader,
        title: 'Accueil personnalisé',
        description:
            'Tu retrouves ici tes notifications et l’accès à ton profil.',
        icon: Icons.waving_hand_rounded,
      ),
      TourGuideStepData(
        targetId: TourGuideTargetIds.studentStreak,
        title: 'Série quotidienne',
        description:
            'Garde ton rythme pour cumuler plus de points chaque jour.',
        icon: Icons.local_fire_department_rounded,
      ),
      TourGuideStepData(
        targetId: TourGuideTargetIds.studentResume,
        title: 'Continuer ton cours',
        description: 'Reprends ta dernière leçon exactement au bon chapitre.',
        icon: Icons.play_circle_fill_rounded,
      ),
      TourGuideStepData(
        targetId: TourGuideTargetIds.studentSubjects,
        title: 'Matières',
        description:
            'Navigue rapidement entre tes matières et leur progression.',
        icon: Icons.auto_stories_rounded,
      ),
      TourGuideStepData(
        targetId: TourGuideTargetIds.studentRecommendations,
        title: 'Recommandations IA',
        description:
            'Contenus proposés selon tes forces et les points à renforcer.',
        icon: Icons.menu_book_rounded,
      ),
      TourGuideStepData(
        targetId: TourGuideTargetIds.studentChallenges,
        title: 'Défis du jour',
        description: 'Des objectifs courts pour maintenir ta motivation.',
        icon: Icons.bolt_rounded,
      ),
      TourGuideStepData(
        targetId: TourGuideTargetIds.studentQuickQuiz,
        title: 'Quiz express',
        description: 'Lance un quiz d’un geste pour progresser rapidement.',
        icon: Icons.quiz_rounded,
      ),
      TourGuideStepData(
        targetId: TourGuideTargetIds.studentQuickAi,
        title: 'Assistant IA',
        description: 'Pose tes questions et reçois une aide immédiate.',
        icon: Icons.smart_toy_rounded,
      ),
      TourGuideStepData(
        targetId: TourGuideTargetIds.studentBottomNav,
        title: 'Navigation',
        description:
            'Accède à Accueil, Apprendre, Quiz, Compagnon et Profil ici.',
        icon: Icons.navigation_rounded,
      ),
    ],
    AppRole.parent => const [
      TourGuideStepData(
        targetId: TourGuideTargetIds.roleHero,
        title: 'Espace parent',
        description:
            'Vue principale pour suivre les enfants et leurs activités.',
        icon: Icons.family_restroom_rounded,
      ),
      TourGuideStepData(
        targetId: TourGuideTargetIds.roleSignOut,
        title: 'Déconnexion',
        description: 'Quitte la session en toute sécurité.',
        icon: Icons.logout_rounded,
      ),
    ],
    AppRole.teacher => const [
      TourGuideStepData(
        targetId: TourGuideTargetIds.roleHero,
        title: 'Espace enseignant',
        description:
            'Zone centrale pour les cours, classes et activités à venir.',
        icon: Icons.school_rounded,
      ),
      TourGuideStepData(
        targetId: TourGuideTargetIds.roleSignOut,
        title: 'Déconnexion',
        description: 'Termine proprement la session active.',
        icon: Icons.logout_rounded,
      ),
    ],
    AppRole.admin => const [
      TourGuideStepData(
        targetId: TourGuideTargetIds.roleHero,
        title: 'Espace administration',
        description:
            'Accès principal pour le pilotage et la supervision globale.',
        icon: Icons.admin_panel_settings_rounded,
      ),
      TourGuideStepData(
        targetId: TourGuideTargetIds.roleSignOut,
        title: 'Déconnexion',
        description: 'Ferme la session en toute sécurité.',
        icon: Icons.logout_rounded,
      ),
    ],
  };
}
