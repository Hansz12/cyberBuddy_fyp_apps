import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static const _dailyInactivityReminderId = 200;
  static const _lastAppOpenDateKey = 'last_app_open_date';
  static const _notificationPermissionRequestedKey =
      'notification_permission_requested';
  static const _exactAlarmPermissionRequestedKey =
      'exact_alarm_permission_requested';
  static const _reminderHour = 20;

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(initSettings);

    final androidNotifications = await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidNotifications?.createNotificationChannel(
      const AndroidNotificationChannel(
        'cyberbuddy_push_channel',
        'CyberBuddy Push Notifications',
        description: 'Firebase push notifications for CyberBuddy users',
        importance: Importance.high,
      ),
    );
    final preferences = await SharedPreferences.getInstance();
    final notificationsEnabled =
        await androidNotifications?.areNotificationsEnabled();
    if (notificationsEnabled != true &&
        preferences.getBool(_notificationPermissionRequestedKey) != true) {
      await androidNotifications?.requestNotificationsPermission();
      await preferences.setBool(_notificationPermissionRequestedKey, true);
    }

    final canScheduleExact =
        await androidNotifications?.canScheduleExactNotifications();
    if (canScheduleExact == false &&
        preferences.getBool(_exactAlarmPermissionRequestedKey) != true) {
      await androidNotifications?.requestExactAlarmsPermission();
      await preferences.setBool(_exactAlarmPermissionRequestedKey, true);
    }
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

  /// Records that the app was opened today and restarts the daily 8 PM
  /// reminder from tomorrow. If the user does not open the app tomorrow, the
  /// operating system delivers the reminder and continues it each inactive day.
  static Future<void> recordDailyAppOpen() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastAppOpenDateKey, _dateKey(now));

    await _notifications.cancel(_dailyInactivityReminderId);
    await _scheduleInactivityReminder(_tomorrowAtReminderTime(now));
  }

  /// Kept for existing callers; it now follows the inactivity-only rule.
  static Future<void> scheduleDailyReminder() => recordDailyAppOpen();

  static Future<void> _scheduleInactivityReminder(
    tz.TZDateTime scheduledDate,
  ) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_learning_channel',
        'Daily Learning Reminder',
        channelDescription: 'One daily reminder when CyberBuddy was not opened',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    Future<void> schedule(AndroidScheduleMode mode) {
      return _notifications.zonedSchedule(
        _dailyInactivityReminderId,
        'CyberBuddy mission is waiting',
        'Take a 2-minute cyber challenge and keep your streak alive.',
        scheduledDate,
        details,
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

    try {
      await schedule(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (_) {
      // Some phones restrict exact alarms. An inexact reminder is preferable
      // to silently giving the user no reminder at all.
      await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  static tz.TZDateTime _tomorrowAtReminderTime(DateTime now) {
    // DateTime creates 8 PM in the phone's local timezone. Converting that
    // instant to UTC avoids timezone package defaults while preserving the
    // user's local 8 PM trigger for this one-time notification.
    final tomorrowAtEight = DateTime(
      now.year,
      now.month,
      now.day + 1,
      _reminderHour,
    );
    return tz.TZDateTime.from(tomorrowAtEight, tz.UTC);
  }

  static String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
