import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'notification_navigation_bus.dart';

abstract final class LearningReminderService {
  static const _notificationId = 237;
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        NotificationNavigationBus.open(response.payload);
      },
    );
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'intellia_updates',
              'Actualités Intellia 237',
              description:
                  'Alertes scolaires, nouveaux contenus et informations du compte.',
              importance: Importance.high,
            ),
          );
    }
    tz_data.initializeTimeZones();
    // Intellia237 cible d'abord le Cameroun. Utiliser explicitement Douala
    // évite qu'un appareil mal configuré programme le rappel en UTC.
    tz.setLocalLocation(tz.getLocation('Africa/Douala'));
    _initialized = true;
  }

  static Future<void> showRemoteMessage(RemoteMessage message) async {
    if (kIsWeb) return;
    await initialize();
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();
    if (title == null || title.isEmpty) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'intellia_updates',
        'Actualités Intellia 237',
        channelDescription:
            'Alertes scolaires, nouveaux contenus et informations du compte.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      id:
          message.messageId?.hashCode ??
          DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: title,
      body: body,
      notificationDetails: details,
      payload: message.data['route']?.toString() ?? '/notifications',
    );
  }

  static Future<bool> enableDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return false;
    await initialize();

    bool granted = true;
    if (defaultTargetPlatform == TargetPlatform.android) {
      granted =
          await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      granted =
          await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      granted =
          await _plugin
              .resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    if (!granted) return false;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'learning_reminders',
        'Rappels d’apprentissage',
        channelDescription:
            'Un rappel quotidien facultatif lié à l’objectif choisi.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );
    await _plugin.cancel(id: _notificationId);
    await _plugin.zonedSchedule(
      id: _notificationId,
      title: 'Une petite séance aujourd’hui ?',
      body:
          'Reprends une leçon ou fais quelques exercices à ton rythme. Tu peux désactiver ce rappel à tout moment.',
      scheduledDate: _nextDailyInstance(hour: hour, minute: minute),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/student',
    );
    return true;
  }

  static tz.TZDateTime _nextDailyInstance({
    required int hour,
    required int minute,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour.clamp(0, 23),
      minute.clamp(0, 59),
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static Future<void> disableReminder() async {
    if (kIsWeb) return;
    await initialize();
    await _plugin.cancel(id: _notificationId);
  }
}
