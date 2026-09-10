import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/student_home/domain/learner_activity.dart';
import 'package:intellia237/features/student_home/domain/student_home_snapshot.dart';

/// Le compagnon annonçait « Belle régularité » à un élève venant de créer son
/// compte. La cause : « progression disponible » était confondu avec
/// « progression réalisée ». `globalProgress` vaut 0 dès qu'une matière
/// existe, donc n'était jamais nul pour un élève ayant une classe.
void main() {
  const subject = SubjectOverview(
    id: 'maths',
    title: 'Mathématiques',
    progress: 0,
    colorHex: 0xFF1451E1,
  );

  test(
    'un élève avec un catalogue mais aucune trace reste en première séance',
    () {
      final snapshot = StudentHomeSnapshot(
        firstName: 'Calvin',
        subjects: const [subject],
        // Moyenne d'un catalogue intact : présente, mais nulle.
        globalProgress: 0,
      );

      final activity = LearnerActivity.fromSnapshot(snapshot);

      expect(activity.hasLearningEvidence, isFalse);
      expect(activity.status, LearnerActivityStatus.firstSession);
      expect(activity.isFirstSession, isTrue);
    },
  );

  test('un instantané entièrement vide reste en première séance', () {
    final activity = LearnerActivity.fromSnapshot(
      const StudentHomeSnapshot(firstName: 'Calvin'),
    );

    expect(activity.status, LearnerActivityStatus.firstSession);
    expect(activity.lastActivityAt, isNull);
  });

  group('une seule trace réelle suffit à prouver un retour', () {
    final cases = <String, StudentHomeSnapshot>{
      'une leçon ouverte': StudentHomeSnapshot(
        firstName: 'Calvin',
        resume: ResumeTarget(
          subjectId: 'maths',
          chapterId: 'c1',
          lessonId: 'l1',
          lessonTitle: 'Équations',
          progress: 0.2,
          updatedAt: DateTime(2026, 9, 6, 8),
        ),
      ),
      'une progression strictement positive': const StudentHomeSnapshot(
        firstName: 'Calvin',
        subjects: [subject],
        globalProgress: 0.05,
      ),
      'des points gagnés': const StudentHomeSnapshot(
        firstName: 'Calvin',
        gamification: StudentGamification(currentPoints: 20, level: 1),
      ),
      'une série reconnue': const StudentHomeSnapshot(
        firstName: 'Calvin',
        gamification: StudentGamification(
          currentPoints: 0,
          level: 1,
          streakDays: 2,
        ),
      ),
    };

    cases.forEach((label, snapshot) {
      test(label, () {
        final activity = LearnerActivity.fromSnapshot(snapshot);
        expect(activity.status, LearnerActivityStatus.returning);
      });
    });
  });

  test('une carte Flow validée compte comme activité réelle', () {
    final activity = LearnerActivity.fromSnapshot(
      const StudentHomeSnapshot(firstName: 'Calvin'),
      completedFlowCards: 1,
    );

    expect(activity.status, LearnerActivityStatus.returning);
  });

  test('un quiz enregistré compte comme activité réelle', () {
    final activity = LearnerActivity.fromSnapshot(
      const StudentHomeSnapshot(firstName: 'Calvin'),
      quizAttempts: 1,
    );

    expect(activity.status, LearnerActivityStatus.returning);
  });

  test('la dernière activité datée provient du signet de reprise', () {
    final moment = DateTime(2026, 9, 5, 19, 30);
    final activity = LearnerActivity.fromSnapshot(
      StudentHomeSnapshot(
        firstName: 'Calvin',
        resume: ResumeTarget(
          subjectId: 'maths',
          chapterId: 'c1',
          lessonId: 'l1',
          lessonTitle: 'Équations',
          progress: 0.4,
          updatedAt: moment,
        ),
      ),
    );

    expect(activity.lastActivityAt, moment);
  });
}
