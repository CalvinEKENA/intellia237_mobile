import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/student_home/data/personal_goal_store.dart';
import 'package:intellia237/features/student_home/domain/personal_goal.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('isoWeekKey — bords d\'année ISO 8601', () {
    test('le 1er janvier 2026 (jeudi) ouvre 2026-W01', () {
      expect(PersonalGoalStore.isoWeekKey(DateTime(2026, 1, 1)), '2026-W01');
    });

    test('le 1er janvier 2023 (dimanche) appartient à 2022-W52', () {
      expect(PersonalGoalStore.isoWeekKey(DateTime(2023, 1, 1)), '2022-W52');
    });

    test('le 30 décembre 2024 (lundi) ouvre déjà 2025-W01', () {
      expect(PersonalGoalStore.isoWeekKey(DateTime(2024, 12, 30)), '2025-W01');
    });

    test('lundi et dimanche d\'une même semaine partagent la clé', () {
      expect(
        PersonalGoalStore.isoWeekKey(DateTime(2026, 7, 13)), // lundi
        PersonalGoalStore.isoWeekKey(DateTime(2026, 7, 19)), // dimanche
      );
    });
  });

  group('PersonalGoalStore — jours actifs', () {
    late PersonalGoalStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues(const {});
      store = await PersonalGoalStore.create();
    });

    test('idempotent pour la journée', () async {
      final day = DateTime(2026, 7, 15, 9);
      expect(await store.markActiveToday('u1', now: day), 1);
      expect(
        await store.markActiveToday(
          'u1',
          now: day.add(const Duration(hours: 5)),
        ),
        1,
        reason: 'deux activités le même jour = une seule séance',
      );
      expect(store.activeDaysThisWeek('u1', now: day), 1);
    });

    test('deux jours distincts de la même semaine comptent double', () async {
      await store.markActiveToday('u1', now: DateTime(2026, 7, 13));
      await store.markActiveToday('u1', now: DateTime(2026, 7, 15));
      expect(store.activeDaysThisWeek('u1', now: DateTime(2026, 7, 16)), 2);
    });

    test(
      'le compteur repart à zéro la semaine suivante (sans pénalité)',
      () async {
        await store.markActiveToday('u1', now: DateTime(2026, 7, 15));
        expect(
          store.activeDaysThisWeek('u1', now: DateTime(2026, 7, 22)),
          0,
          reason: 'nouvelle semaine ISO = nouveau compteur',
        );
      },
    );

    test('les élèves sont isolés les uns des autres', () async {
      await store.markActiveToday('u1', now: DateTime(2026, 7, 15));
      expect(store.activeDaysThisWeek('u2', now: DateTime(2026, 7, 15)), 0);
    });

    test('les semaines anciennes sont élaguées (4 conservées)', () async {
      for (var i = 0; i < 8; i++) {
        await store.markActiveToday(
          'u1',
          now: DateTime(2026, 3, 2).add(Duration(days: 7 * i)),
        );
      }
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('weekly_activity_v1_u1')!;
      expect('-W'.allMatches(raw).length, lessThanOrEqualTo(4));
    });
  });

  group('PersonalGoalStore — objectif', () {
    test('aller-retour complet puis suppression', () async {
      SharedPreferences.setMockInitialValues(const {});
      final store = await PersonalGoalStore.create();

      expect(store.readGoal('u1'), isNull);

      await store.saveGoal(
        'u1',
        const PersonalGoal(
          sessionsPerWeek: 3,
          minutesPerSession: 20,
          prioritySubjectId: 'math',
          prioritySubjectTitle: 'Mathématiques',
        ),
      );

      final goal = store.readGoal('u1');
      expect(goal, isNotNull);
      expect(goal!.sessionsPerWeek, 3);
      expect(goal.minutesPerSession, 20);
      expect(goal.prioritySubjectId, 'math');
      expect(store.readGoal('u2'), isNull, reason: 'isolation par élève');

      await store.clearGoal('u1');
      expect(store.readGoal('u1'), isNull);
    });

    test('contenu corrompu → null, jamais d\'exception', () async {
      SharedPreferences.setMockInitialValues(const {
        'personal_goal_v1_u1': '{pas du json',
      });
      final store = await PersonalGoalStore.create();
      expect(store.readGoal('u1'), isNull);
    });
  });
}
