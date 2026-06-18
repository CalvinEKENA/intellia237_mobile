import '../domain/parent_announcement.dart';
import '../domain/parent_child_profile.dart';
import '../domain/parent_dashboard.dart';
import 'parent_repository.dart';

class MockParentRepository implements ParentRepository {
  @override
  Future<ParentDashboard> fetchDashboard({required String parentUid}) async {
    await Future<void>.delayed(const Duration(milliseconds: 320));
    return ParentDashboard(
      children: const [
        ParentChildProfile(
          id: 'child_1',
          firstName: 'Alya',
          classLevel: 'Seconde',
          series: 'A',
          globalProgress: 0.64,
          studyMinutesToday: 42,
          studyMinutesTarget: 60,
          strongSubjects: ['Francais', 'Histoire'],
          weakSubjects: ['Physique', 'Mathematiques'],
          weeklyProgress: [0.45, 0.48, 0.51, 0.56, 0.59, 0.62, 0.64],
        ),
        ParentChildProfile(
          id: 'child_2',
          firstName: 'Noe',
          classLevel: '4eme',
          series: null,
          globalProgress: 0.58,
          studyMinutesToday: 35,
          studyMinutesTarget: 55,
          strongSubjects: ['Mathematiques', 'Anglais'],
          weakSubjects: ['Francais'],
          weeklyProgress: [0.4, 0.44, 0.47, 0.49, 0.52, 0.56, 0.58],
        ),
      ],
      announcements: [
        ParentAnnouncement(
          id: 'ann_1',
          title: 'Reunion parents-professeurs',
          body: 'Jeudi a 17h30 en salle polyvalente.',
          publishedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        ParentAnnouncement(
          id: 'ann_2',
          title: 'Mise a jour planning evaluations',
          body: 'Le calendrier du mois est disponible sur l\'espace parent.',
          publishedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ],
    );
  }
}
