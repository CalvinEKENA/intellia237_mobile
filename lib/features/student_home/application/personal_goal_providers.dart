import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/telemetry/intellia_telemetry.dart';
import '../../auth/application/auth_controller.dart';
import '../data/personal_goal_store.dart';
import '../domain/personal_goal.dart';

final personalGoalStoreProvider = FutureProvider<PersonalGoalStore>((ref) {
  return PersonalGoalStore.create();
});

/// Objectif hebdomadaire + jours actifs de la semaine, pour l'élève connecté.
final personalGoalControllerProvider =
    AsyncNotifierProvider<PersonalGoalController, WeeklyGoalProgress>(
      PersonalGoalController.new,
    );

class PersonalGoalController extends AsyncNotifier<WeeklyGoalProgress> {
  @override
  Future<WeeklyGoalProgress> build() async {
    final userId = ref.watch(
      authControllerProvider.select((auth) => auth.userId),
    );
    if (userId == null) {
      return const WeeklyGoalProgress(goal: null, activeDays: 0);
    }
    final store = await ref.watch(personalGoalStoreProvider.future);
    return WeeklyGoalProgress(
      goal: store.readGoal(userId),
      activeDays: store.activeDaysThisWeek(userId),
    );
  }

  Future<void> saveGoal(PersonalGoal goal) async {
    final userId = ref.read(authControllerProvider).userId;
    if (userId == null) return;
    final store = await ref.read(personalGoalStoreProvider.future);
    await store.saveGoal(userId, goal);
    unawaited(IntelliaTelemetry.goalSet(sessionsPerWeek: goal.sessionsPerWeek));
    state = AsyncData(
      WeeklyGoalProgress(
        goal: goal,
        activeDays: store.activeDaysThisWeek(userId),
      ),
    );
  }

  Future<void> clearGoal() async {
    final userId = ref.read(authControllerProvider).userId;
    if (userId == null) return;
    final store = await ref.read(personalGoalStoreProvider.future);
    await store.clearGoal(userId);
    state = AsyncData(
      WeeklyGoalProgress(
        goal: null,
        activeDays: store.activeDaysThisWeek(userId),
      ),
    );
  }

  /// À appeler après une activité pédagogique réelle (leçon terminée, quiz
  /// soumis, carte Flow validée). Idempotent pour la journée ; ne lève jamais
  /// (l'objectif est une commodité, pas un chemin critique).
  Future<void> recordActivityToday() async {
    try {
      final userId = ref.read(authControllerProvider).userId;
      if (userId == null) return;
      final store = await ref.read(personalGoalStoreProvider.future);

      final goal = store.readGoal(userId);
      final before = store.activeDaysThisWeek(userId);
      final after = await store.markActiveToday(userId);

      if (goal != null &&
          before < goal.sessionsPerWeek &&
          after >= goal.sessionsPerWeek) {
        unawaited(
          IntelliaTelemetry.goalWeekCompleted(
            sessionsPerWeek: goal.sessionsPerWeek,
          ),
        );
      }

      state = AsyncData(WeeklyGoalProgress(goal: goal, activeDays: after));
    } catch (_) {
      // Jamais bloquant.
    }
  }
}
