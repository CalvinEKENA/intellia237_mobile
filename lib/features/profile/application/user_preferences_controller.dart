import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../../../core/notifications/learning_reminder_service.dart';

class UserPreferences {
  const UserPreferences({
    this.textScale = 1,
    this.reduceMotion = false,
    this.dataSaver = false,
    this.notifications = false,
    this.reminderHour = 18,
    this.reminderMinute = 30,
    this.diagnostics = false,
  });

  final double textScale;
  final bool reduceMotion;
  final bool dataSaver;
  final bool notifications;
  final int reminderHour;
  final int reminderMinute;
  final bool diagnostics;

  UserPreferences copyWith({
    double? textScale,
    bool? reduceMotion,
    bool? dataSaver,
    bool? notifications,
    int? reminderHour,
    int? reminderMinute,
    bool? diagnostics,
  }) => UserPreferences(
    textScale: textScale ?? this.textScale,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    dataSaver: dataSaver ?? this.dataSaver,
    notifications: notifications ?? this.notifications,
    reminderHour: reminderHour ?? this.reminderHour,
    reminderMinute: reminderMinute ?? this.reminderMinute,
    diagnostics: diagnostics ?? this.diagnostics,
  );
}

final userPreferencesProvider =
    NotifierProvider<UserPreferencesController, UserPreferences>(
      UserPreferencesController.new,
    );

class UserPreferencesController extends Notifier<UserPreferences> {
  bool _dirty = false;
  static const _textScaleKey = 'preferences_text_scale';
  static const _reduceMotionKey = 'preferences_reduce_motion';
  static const _dataSaverKey = 'preferences_data_saver';
  static const _notificationsKey = 'preferences_notifications';
  static const _reminderHourKey = 'preferences_reminder_hour';
  static const _reminderMinuteKey = 'preferences_reminder_minute';
  static const diagnosticsKey = 'preferences_diagnostics_consent';

  @override
  UserPreferences build() {
    Future<void>.microtask(_restore);
    return const UserPreferences();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (_dirty) return;
    state = UserPreferences(
      textScale: prefs.getDouble(_textScaleKey) ?? 1,
      reduceMotion: prefs.getBool(_reduceMotionKey) ?? false,
      dataSaver: prefs.getBool(_dataSaverKey) ?? false,
      notifications: prefs.getBool(_notificationsKey) ?? false,
      reminderHour: prefs.getInt(_reminderHourKey) ?? 18,
      reminderMinute: prefs.getInt(_reminderMinuteKey) ?? 30,
      diagnostics: prefs.getBool(diagnosticsKey) ?? false,
    );
  }

  Future<void> setTextScale(double value) async {
    _dirty = true;
    state = state.copyWith(textScale: value.clamp(0.9, 1.5));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textScaleKey, state.textScale);
  }

  Future<void> setReduceMotion(bool value) async {
    _dirty = true;
    state = state.copyWith(reduceMotion: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reduceMotionKey, value);
  }

  Future<void> setDataSaver(bool value) async {
    _dirty = true;
    state = state.copyWith(dataSaver: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dataSaverKey, value);
  }

  Future<void> setNotifications(bool value) async {
    _dirty = true;
    final enabled = value
        ? await LearningReminderService.enableDailyReminder(
            hour: state.reminderHour,
            minute: state.reminderMinute,
          )
        : false;
    if (!value) await LearningReminderService.disableReminder();
    state = state.copyWith(notifications: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
  }

  Future<void> setReminderTime({required int hour, required int minute}) async {
    _dirty = true;
    final nextHour = hour.clamp(0, 23);
    final nextMinute = minute.clamp(0, 59);
    state = state.copyWith(reminderHour: nextHour, reminderMinute: nextMinute);
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setInt(_reminderHourKey, nextHour),
      prefs.setInt(_reminderMinuteKey, nextMinute),
    ]);
    if (state.notifications) {
      final enabled = await LearningReminderService.enableDailyReminder(
        hour: nextHour,
        minute: nextMinute,
      );
      if (!enabled) {
        state = state.copyWith(notifications: false);
        await prefs.setBool(_notificationsKey, false);
      }
    }
  }

  Future<void> setDiagnostics(bool value) async {
    _dirty = true;
    state = state.copyWith(diagnostics: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(diagnosticsKey, value);
    if (Firebase.apps.isEmpty) return;
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(value);
    if (!kIsWeb) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(value);
    }
  }
}
