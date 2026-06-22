import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'notification_service.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Notification payloads are displayed by Android while the app is in the
  // background. Data-only payload handling can be added here when a backend
  // route is available.
}

class PushNotification {
  final String title;
  final String body;

  const PushNotification({required this.title, required this.body});

  String get missionLogEntry => '$title: $body';
}

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final StreamController<PushNotification> _foregroundNotifications =
      StreamController<PushNotification>.broadcast();
  static final List<PushNotification> _pendingNotifications = [];

  static Stream<PushNotification> get foregroundNotifications =>
      _foregroundNotifications.stream;

  static List<PushNotification> takePendingNotifications() {
    final pending = List<PushNotification>.from(_pendingNotifications);
    _pendingNotifications.clear();
    return pending;
  }

  static Future<void> init() async {
    await _requestPermission();
    await _saveTokenForTesting();

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _publish(_messageFrom(initialMessage));
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final pushNotification = _messageFrom(message);
      await NotificationService.showPushNotification(
        title: pushNotification.title,
        body: pushNotification.body,
      );
      _publish(pushNotification);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Make notifications opened from the system tray visible in the app's
      // Mission Log too. Navigation can be added when routes are defined.
      _publish(_messageFrom(message));
    });
  }

  static void _publish(PushNotification notification) {
    if (_foregroundNotifications.hasListener) {
      _foregroundNotifications.add(notification);
    } else {
      _pendingNotifications.add(notification);
    }
  }

  static PushNotification _messageFrom(RemoteMessage message) {
    final notification = message.notification;
    return PushNotification(
      title:
          notification?.title ?? message.data['title'] ?? 'CyberBuddy Alert',
      body:
          notification?.body ??
          message.data['body'] ??
          'You have a new CyberBuddy notification.',
    );
  }

  static Future<void> _requestPermission() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  static Future<void> _saveTokenForTesting() async {
    try {
      final token = await _messaging.getToken();

      debugPrint("========== FCM TOKEN ==========");
      debugPrint(token);
      debugPrint("================================");
    } catch (e) {
      debugPrint("FCM ERROR: $e");
    }
  }
}
