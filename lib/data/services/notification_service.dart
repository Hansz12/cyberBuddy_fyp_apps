import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(initSettings);

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  static NotificationDetails _notificationDetails({
    required String channelId,
    required String channelName,
    required String description,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: description,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  static Future<void> showPushNotification({
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      _notificationDetails(
        channelId: 'cyberbuddy_push_channel',
        channelName: 'CyberBuddy Push Notifications',
        description: 'Firebase push notifications for CyberBuddy users',
      ),
    );
  }

  static Future<void> showInstantNotification() async {
    await _notifications.show(
      1,
      '🛡️ CyberBuddy Tip',
      'Never click suspicious links from unknown senders.',
      _notificationDetails(
        channelId: 'cyberbuddy_tip_channel',
        channelName: 'CyberBuddy Tips',
        description: 'Cybersecurity tips for CyberBuddy users',
      ),
    );
  }

  static Future<void> showStreakReminder() async {
    await _notifications.show(
      3,
      '🔥 Streak Alert!',
      "Don't lose your learning streak. Complete a lesson today!",
      _notificationDetails(
        channelId: 'cyberbuddy_streak_channel',
        channelName: 'Streak Reminder',
        description: 'Reminder to maintain learning streak',
      ),
    );
  }

  static Future<void> showDailyQuestReminder() async {
    await _notifications.show(
      4,
      '🎯 Daily Quest Available',
      'Answer 5 cybersecurity quiz questions and earn XP!',
      _notificationDetails(
        channelId: 'cyberbuddy_quest_channel',
        channelName: 'Daily Quest Reminder',
        description: 'Daily quest reminders for CyberBuddy users',
      ),
    );
  }

  static Future<void> showBadgeReminder() async {
    await _notifications.show(
      5,
      '🏆 New Badge Awaits',
      'Complete one module to unlock your next achievement badge.',
      _notificationDetails(
        channelId: 'cyberbuddy_badge_channel',
        channelName: 'Badge Reminder',
        description: 'Badge and achievement reminders',
      ),
    );
  }

  static Future<void> scheduleDailyReminder() async {
    await _notifications.zonedSchedule(
      2,
      '🎯 Daily Quest Available',
      'Answer 5 cybersecurity quiz questions and earn XP!',
      _nextInstanceOfTime(20, 0),
      _notificationDetails(
        channelId: 'daily_learning_channel',
        channelName: 'Daily Learning Reminder',
        description: 'Daily reminder to study cybersecurity',
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
