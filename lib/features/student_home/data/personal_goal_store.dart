import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/personal_goal.dart';

/// Persistance locale de l'objectif personnel et des jours actifs, par élève.
///
/// Un « jour actif » est un jour calendaire avec au moins une activité
/// pédagogique réelle. Les semaines suivent la norme ISO 8601 (lundi
/// premier jour) ; seules les 4 dernières semaines sont conservées.
class PersonalGoalStore {
  PersonalGoalStore._(this._prefs);

  static const _goalPrefix = 'personal_goal_v1_';
  static const _activityPrefix = 'weekly_activity_v1_';
  static const _keptWeeks = 4;

  final SharedPreferences _prefs;

  static Future<PersonalGoalStore> create() async =>
      PersonalGoalStore._(await SharedPreferences.getInstance());

  // ── Objectif ──────────────────────────────────────────────────────────

  PersonalGoal? readGoal(String userId) {
    final raw = _prefs.getString('$_goalPrefix$userId');
    if (raw == null || raw.isEmpty) return null;
    try {
      return PersonalGoal.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveGoal(String userId, PersonalGoal goal) async {
    await _prefs.setString('$_goalPrefix$userId', jsonEncode(goal.toJson()));
  }

  Future<void> clearGoal(String userId) async {
    await _prefs.remove('$_goalPrefix$userId');
  }

  // ── Jours actifs ──────────────────────────────────────────────────────

  /// Marque « aujourd'hui » comme jour actif. Idempotent pour la journée.
  /// Retourne le nombre de jours actifs de la semaine en cours après ajout.
  Future<int> markActiveToday(String userId, {DateTime? now}) async {
    final date = now ?? DateTime.now();
    final week = isoWeekKey(date);
    final day = _dayKey(date);

    final weeks = _readWeeks(userId);
    final days = List<String>.from(weeks[week] as List? ?? const []);
    if (!days.contains(day)) {
      days.add(day);
    }
    weeks[week] = days;

    _prune(weeks, date);
    await _prefs.setString('$_activityPrefix$userId', jsonEncode(weeks));
    return days.length;
  }

  /// Jours actifs de la semaine ISO en cours.
  int activeDaysThisWeek(String userId, {DateTime? now}) {
    final weeks = _readWeeks(userId);
    final days = weeks[isoWeekKey(now ?? DateTime.now())];
    return days is List ? days.length : 0;
  }

  Map<String, dynamic> _readWeeks(String userId) {
    final raw = _prefs.getString('$_activityPrefix$userId');
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  void _prune(Map<String, dynamic> weeks, DateTime now) {
    if (weeks.length <= _keptWeeks) return;
    final kept = <String>{
      for (var i = 0; i < _keptWeeks; i++)
        isoWeekKey(now.subtract(Duration(days: 7 * i))),
    };
    weeks.removeWhere((key, _) => !kept.contains(key));
  }

  static String _dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Clé de semaine ISO 8601 (ex. `2026-W29`). Le jeudi de la semaine porte
  /// toujours la bonne année ISO, ce qui règle les bords de janvier/décembre.
  static String isoWeekKey(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final thursday = day.add(Duration(days: 4 - day.weekday));
    final firstDayOfIsoYear = DateTime(thursday.year, 1, 1);
    final week = 1 + (thursday.difference(firstDayOfIsoYear).inDays ~/ 7);
    return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
  }
}
