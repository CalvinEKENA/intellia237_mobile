import 'package:flutter/material.dart';

import '../../auth/domain/app_role.dart';
import 'tour_guide_step_data.dart';
import 'tour_guide_target_ids.dart';

List<TourGuideStepData> roleTourSteps(AppRole role) {
  return switch (role) {
    AppRole.student => const [
      TourGuideStepData(
        targetId: TourGuideTargetIds.studentHeader,
        title: 'Accueil personnalise',
        description: 'Tu retrouves ici tes notifications et ton acces profil.',
        icon: Icons.waving_hand_rounded,
      ),
      TourGuideStepData(
        targetId: TourGuideTargetIds.studentStreak,
        title: 'Streak quotidien',
        description: 'Garde ton rythme pour cumuler plus d\'XP chaque jour.',
        icon: Icons.local_fire_department_rounded,
      ),
      TourGuideStepData(
        targetId: TourGuideTargetIds.studentResume,
        title: 'Continuer ton cours',
        description: 'Reprends ta derniere lecon exactement au bon chapitre.',
        icon: Icons.play_circle_fill_rounded,
      ),
      TourGuideStepData(
        targetId: TourGuideTargetIds.studentSubjects,
        title: 'Matieres',
        description:
            'Navigue rapidement entre tes matieres et leur progression.',
        icon: Icons.auto_stories_rounded,
      ),
      TourGuideStepData(
        targetId: TourGuideTargetIds.studentRecommendations,
        title: 'Recommandations IA',
        description:
            'Contenus proposes selon tes forces et points a renforcer.',
        icon: Icons.auto_awesome_rounded,
      ),
      TourGuideStepData(
        targetId: TourGuideTargetIds.studentChallenges,
        title: 'Defis du jour',
        description: 'Des objectifs courts pour maintenir ta motivation.',
        icon: Icons.bolt_rounded,
      ),
      TourGuideStepData(
        targetId: TourGuideTargetIds.studentQuickQuiz,
        title: 'Quiz express',
        description: 'Lance un quiz en un tap pour progresser rapidement.',
        icon: Icons.quiz_rounded,
      ),
      TourGuideStepData(
        targetId: TourGuideTargetIds.studentQuickAi,
        title: 'Assistant IA',
        description: 'Pose tes questions et recois une aide immediate.',
        icon: Icons.smart_toy_rounded,
      ),
      TourGuideStepData(
        targetId: TourGuideTargetIds.studentBottomNav,
        title: 'Navigation',
        description: 'Accede a Accueil, Apprendre, Quiz, IA et Profil ici.',
        icon: Icons.navigation_rounded,
      ),
    ],
    AppRole.parent => const [
      TourGuideStepData(
        targetId: TourGuideTargetIds.roleHero,
        title: 'Espace Parent',
        description:
            'Vue principale pour suivre les enfants et leurs activites.',
        icon: Icons.family_restroom_rounded,
      ),
      TourGuideStepData(
        targetId: TourGuideTargetIds.roleSignOut,
        title: 'Deconnexion',
        description: 'Quitte la session en toute securite.',
        icon: Icons.logout_rounded,
      ),
    ],
    AppRole.teacher => const [
      TourGuideStepData(
        targetId: TourGuideTargetIds.roleHero,
        title: 'Espace Enseignant',
        description: 'Zone centrale pour cours, classes et activites a venir.',
        icon: Icons.school_rounded,
      ),
      TourGuideStepData(
        targetId: TourGuideTargetIds.roleSignOut,
        title: 'Deconnexion',
        description: 'Termine proprement la session active.',
        icon: Icons.logout_rounded,
      ),
    ],
    AppRole.admin => const [
      TourGuideStepData(
        targetId: TourGuideTargetIds.roleHero,
        title: 'Espace Administration',
        description: 'Acces principal pour pilotage et supervision globale.',
        icon: Icons.admin_panel_settings_rounded,
      ),
      TourGuideStepData(
        targetId: TourGuideTargetIds.roleSignOut,
        title: 'Deconnexion',
        description: 'Ferme la session avec securite.',
        icon: Icons.logout_rounded,
      ),
    ],
  };
}
