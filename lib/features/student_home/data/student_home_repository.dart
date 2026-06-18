import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../domain/student_home_snapshot.dart';

abstract class StudentHomeRepository {
  Future<StudentHomeSnapshot> fetchHomeSnapshot({required String firstName});
}

final studentHomeRepositoryProvider = Provider<StudentHomeRepository>(
  (ref) => DemoStudentHomeRepository(),
);

final studentFirstNameProvider = Provider<String>((ref) {
  final auth = ref.watch(authControllerProvider);
  return auth.firstName?.trim().isNotEmpty == true
      ? auth.firstName!.trim()
      : 'Champion';
});

class DemoStudentHomeRepository implements StudentHomeRepository {
  @override
  Future<StudentHomeSnapshot> fetchHomeSnapshot({
    required String firstName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    return StudentHomeSnapshot(
      firstName: firstName,
      streakDays: 7,
      motivationText: 'Progression stable cette semaine. Continue comme ca.',
      lastCourseTitle: 'Fonctions affines',
      lastCourseChapter: 'Chapitre 3 - Equation de droite',
      lastCourseProgress: 0.64,
      globalProgress: 0.58,
      level: 12,
      currentXp: 1840,
      subjects: const [
        SubjectOverview(
          id: 'math',
          title: 'Mathematiques',
          progress: 0.71,
          colorHex: 0xFF1451E1,
        ),
        SubjectOverview(
          id: 'phys',
          title: 'Physique',
          progress: 0.52,
          colorHex: 0xFF0F766E,
        ),
        SubjectOverview(
          id: 'fr',
          title: 'Francais',
          progress: 0.46,
          colorHex: 0xFF7C3AED,
        ),
        SubjectOverview(
          id: 'hist',
          title: 'Histoire',
          progress: 0.63,
          colorHex: 0xFFBE123C,
        ),
      ],
      recommendations: const [
        RecommendationItem(
          title: 'Serie d\'exercices: equations du 1er degre',
          subtitle: 'Renforcer precision et vitesse',
          estimatedMinutes: 18,
        ),
        RecommendationItem(
          title: 'Video: Loi d\'Ohm en pratique',
          subtitle: 'Mieux comprendre les circuits simples',
          estimatedMinutes: 12,
        ),
      ],
      challenges: const [
        DailyChallengeItem(
          title: 'Terminer 1 quiz de mathematiques',
          rewardXp: 35,
          completed: false,
        ),
        DailyChallengeItem(
          title: 'Lire une fiche methode',
          rewardXp: 20,
          completed: true,
        ),
      ],
    );
  }
}
