import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'notification_service.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background notification handler.
}

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    await _requestPermission();
    await _saveTokenForTesting();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;

      final title =
          notification?.title ?? message.data['title'] ?? 'CyberBuddy Alert';

      final body =
          notification?.body ??
          message.data['body'] ??
          'You have a new CyberBuddy notification.';

      NotificationService.showPushNotification(title: title, body: body);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Later boleh navigate ke screen tertentu kalau mahu.
    });
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
