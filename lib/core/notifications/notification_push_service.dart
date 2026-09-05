import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show appFlavor;
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/config/app_config.dart';
import '../../firebase_options.dart';
import 'learning_reminder_service.dart';
import 'notification_navigation_bus.dart';

@pragma('vm:entry-point')
Future<void> intelliaFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  if (Firebase.apps.isEmpty) {
    final config = appFlavor == AppEnvironment.staging.name
        ? AppConfig.staging
        : AppConfig.production;
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform(config),
    );
  }
}

enum NotificationPermissionState { unsupported, undecided, denied, enabled }

/// Synchronise l'appareil avec FCM et distribue les événements natifs à l'UI.
///
/// L'inbox Firestore demeure la source de vérité : FCM accélère l'alerte mais
/// une notification reste consultable même si Android/iOS retarde le push.
abstract final class NotificationPushService {
  static const _installationIdKey = 'notification_installation_id_v1';
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _initialized = false;
  static String? _activeUserId;
  static StreamSubscription<String>? _tokenSubscription;

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<void> initialize() async {
    if (_initialized || Firebase.apps.isEmpty || !isSupported) return;

    FirebaseMessaging.onBackgroundMessage(
      intelliaFirebaseMessagingBackgroundHandler,
    );
    FirebaseMessaging.onMessage.listen((message) {
      unawaited(LearningReminderService.showRemoteMessage(message));
    });
    FirebaseMessaging.onMessageOpenedApp.listen(_openMessage);
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _openMessage(initialMessage);
    _initialized = true;
  }

  static Future<NotificationPermissionState> permissionState() async {
    if (!isSupported || Firebase.apps.isEmpty) {
      return NotificationPermissionState.unsupported;
    }
    final settings = await _messaging.getNotificationSettings();
    return _mapAuthorization(settings.authorizationStatus);
  }

  static Future<NotificationPermissionState> requestAndRegister(
    String userId,
  ) async {
    if (!isSupported || Firebase.apps.isEmpty) {
      return NotificationPermissionState.unsupported;
    }
    await initialize();
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    final state = _mapAuthorization(settings.authorizationStatus);
    if (state == NotificationPermissionState.enabled) {
      await syncForUser(userId);
    }
    return state;
  }

  static Future<void> syncForUser(String? userId) async {
    if (!isSupported || Firebase.apps.isEmpty) return;
    await initialize();
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    if (userId == null || userId.isEmpty) {
      // Révoque le jeton natif au changement de session : sur un appareil
      // partagé, l'ancien compte ne doit plus recevoir de push après logout.
      if (_activeUserId != null) await _messaging.deleteToken();
      _activeUserId = null;
      return;
    }
    _activeUserId = userId;

    final settings = await _messaging.getNotificationSettings();
    if (_mapAuthorization(settings.authorizationStatus) !=
        NotificationPermissionState.enabled) {
      return;
    }

    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _saveToken(userId: userId, token: token, settings: settings);
    }
    _tokenSubscription = _messaging.onTokenRefresh.listen((nextToken) {
      final currentUser = _activeUserId;
      if (currentUser == null || currentUser.isEmpty) return;
      unawaited(
        _saveToken(userId: currentUser, token: nextToken, settings: settings),
      );
    });
  }

  static Future<void> _saveToken({
    required String userId,
    required String token,
    required NotificationSettings settings,
  }) async {
    final installationId = await _installationId();
    final deviceDocumentId = notificationDeviceDocumentId(
      userId: userId,
      installationId: installationId,
    );
    await FirebaseFirestore.instance
        .collection('notification_devices')
        .doc(deviceDocumentId)
        .set({
          'userId': userId,
          'token': token,
          'platform': defaultTargetPlatform.name,
          'authorizationStatus': settings.authorizationStatus.name,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  static Future<String> _installationId() async {
    final preferences = await SharedPreferences.getInstance();
    final existing = preferences.getString(_installationIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final random = Random.secure();
    final bytes = List<int>.generate(20, (_) => random.nextInt(256));
    final id = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    await preferences.setString(_installationIdKey, id);
    return id;
  }

  static void _openMessage(RemoteMessage message) {
    NotificationNavigationBus.open(message.data['route']?.toString());
  }

  static NotificationPermissionState _mapAuthorization(
    AuthorizationStatus status,
  ) => switch (status) {
    AuthorizationStatus.authorized ||
    AuthorizationStatus.provisional => NotificationPermissionState.enabled,
    AuthorizationStatus.denied ||
    AuthorizationStatus.deniedPermanently => NotificationPermissionState.denied,
    AuthorizationStatus.notDetermined => NotificationPermissionState.undecided,
  };
}

@visibleForTesting
String notificationDeviceDocumentId({
  required String userId,
  required String installationId,
}) => '${userId}_$installationId';
