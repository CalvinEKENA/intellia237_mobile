import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_user_id.dart';
import '../../learn/application/learn_providers.dart';
import '../../learn/data/lesson_resume_store.dart';
import '../domain/student_home_snapshot.dart';

abstract class StudentHomeRepository {
  Future<StudentHomeSnapshot> fetchHomeSnapshot({required String firstName});
}

/// Mode démo explicite : jamais actif par défaut. Quand il est vrai, l'accueil
/// est alimenté par [DemoStudentHomeRepository] et le marque comme tel
/// (`isDemoData`). Registre de décisions : aucune donnée fictive présentée
/// comme réelle en production.
final homeDemoModeProvider = Provider<bool>((ref) => false);

final studentHomeRepositoryProvider = Provider<StudentHomeRepository>((ref) {
  if (ref.watch(homeDemoModeProvider)) {
    return DemoStudentHomeRepository();
  }
  return FirestoreStudentHomeRepository(ref);
});

final studentFirstNameProvider = Provider<String>((ref) {
  final auth = ref.watch(authControllerProvider);
  return auth.firstName?.trim().isNotEmpty == true
      ? auth.firstName!.trim()
      : 'Champion';
});

/// Accueil réel : compose les mêmes sources que le reste de l'application.
///
/// - Matières : [learnHubProvider] — mêmes identifiants et complétions que
///   l'onglet Apprendre (une seule requête, cache partagé, jamais d'ID fictif).
/// - Reprise : [LessonResumeStore] (signet local de la dernière leçon ouverte).
/// - Points/niveau/série : champs d'agrégats du profil élève s'ils existent
///   (`points`, `progress.level`, `streakDays`), sinon absents — l'UI ne
///   montre alors tout simplement pas ces cartes.
/// - Recommandations/défis : vides tant qu'aucune source réelle n'existe.
class FirestoreStudentHomeRepository implements StudentHomeRepository {
  FirestoreStudentHomeRepository(this._ref, {FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final Ref _ref;
  final FirebaseFirestore _db;

  @override
  Future<StudentHomeSnapshot> fetchHomeSnapshot({
    required String firstName,
  }) async {
    final userId = requireAuthenticatedUserId(
      _ref.read(authControllerProvider),
    );

    final hub = await _ref.read(learnHubProvider.future);
    final subjects = [
      for (final subject in hub.subjects)
        SubjectOverview(
          id: subject.id,
          title: subject.title,
          progress: subject.completion,
          colorHex: subject.colorHex,
          iconKey: subject.iconKey,
        ),
    ];

    final globalProgress = subjects.isEmpty
        ? null
        : subjects.fold<double>(0, (total, s) => total + s.progress) /
              subjects.length;

    ResumeTarget? resume;
    try {
      final store = await _ref.read(lessonResumeStoreProvider.future);
      resume = store.read(userId);
    } catch (_) {
      resume = null; // Le signet local ne doit jamais bloquer l'accueil.
    }

    return StudentHomeSnapshot(
      firstName: firstName,
      resume: resume,
      subjects: subjects,
      globalProgress: globalProgress,
      gamification: await _fetchGamification(userId),
    );
  }

  Future<StudentGamification?> _fetchGamification(String userId) async {
    try {
      final doc = await _db.collection('student_profiles').doc(userId).get();
      final data = doc.data();
      if (data == null) return null;

      final progress = data['progress'];
      final progressMap = progress is Map ? progress : const {};
      final points = studentPointsFromProfile(data);
      final level = ((progressMap['level'] ?? data['level']) as num?)?.toInt();
      final streak = (data['streakDays'] as num?)?.toInt();

      // Contrat d'agrégats futurs : tant que le serveur n'écrit pas ces
      // champs, on n'invente rien — la carte n'apparaît pas.
      if (points == null || level == null) return null;

      return StudentGamification(
        currentPoints: points,
        level: level,
        streakDays: streak,
      );
    } catch (_) {
      // Statistiques indisponibles ≠ accueil en panne : on les omet.
      return null;
    }
  }
}

/// Lit le cumul canonique sans rendre obligatoire une migration immédiate des
/// profils existants. Les points nouveaux gagnent toujours sur l'ancienne clé.
int? studentPointsFromProfile(Map<String, dynamic> data) {
  final progress = data['progress'];
  final progressMap = progress is Map ? progress : const {};
  return ((progressMap['points'] ??
              data['points'] ??
              progressMap['xp'] ??
              data['xp'])
          as num?)
      ?.toInt();
}

/// Données de démonstration — identifiées comme telles (`isDemoData: true`),
/// jamais câblées par défaut. Servent aux revues produit et à l'outillage.
class DemoStudentHomeRepository implements StudentHomeRepository {
  @override
  Future<StudentHomeSnapshot> fetchHomeSnapshot({
    required String firstName,
  }) async {
    return StudentHomeSnapshot(
      firstName: firstName,
      isDemoData: true,
      resume: const ResumeTarget(
        subjectId: 'demo-math',
        chapterId: 'demo-chap-3',
        lessonId: 'demo-lecon-2',
        lessonTitle: 'Fonctions affines',
        subjectTitle: 'Mathématiques',
        progress: 0.64,
      ),
      subjects: const [
        SubjectOverview(
          id: 'demo-math',
          title: 'Mathématiques',
          progress: 0.71,
          colorHex: 0xFF1451E1,
          iconKey: 'math',
        ),
        SubjectOverview(
          id: 'demo-phys',
          title: 'Physique',
          progress: 0.52,
          colorHex: 0xFF0F766E,
          iconKey: 'physic',
        ),
        SubjectOverview(
          id: 'demo-fr',
          title: 'Français',
          progress: 0.46,
          colorHex: 0xFF7C3AED,
          iconKey: 'french',
        ),
      ],
      globalProgress: 0.56,
      gamification: const StudentGamification(
        currentPoints: 1840,
        level: 12,
        streakDays: 7,
        motivationText: 'Progression stable cette semaine. Continue comme ça.',
      ),
      recommendations: const [
        RecommendationItem(
          title: 'Série d\'exercices : équations du 1er degré',
          subtitle: 'Renforcer précision et vitesse',
          estimatedMinutes: 18,
          destination: HomeDestination.learnTab,
        ),
      ],
      challenges: const [
        DailyChallengeItem(
          title: 'Terminer 1 quiz de mathématiques',
          rewardPoints: 35,
          completed: false,
          destination: HomeDestination.quizTab,
        ),
      ],
    );
  }
}
