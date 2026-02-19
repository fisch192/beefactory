import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _initialized = true;
  }

  static const _channel = AndroidNotificationDetails(
    'bee_tasks',
    'Bienenstock Aufgaben',
    channelDescription: 'Erinnerungen für Bienenstock-Aufgaben',
    importance: Importance.high,
    priority: Priority.high,
  );

  /// Schedule a reminder at 08:00 on the due date.
  static Future<void> scheduleTaskReminder({
    required int id,
    required String title,
    required String body,
    required DateTime dueAt,
  }) async {
    if (!_initialized) await initialize();

    final scheduled = tz.TZDateTime.from(
      DateTime(dueAt.year, dueAt.month, dueAt.day, 8, 0),
      tz.local,
    );
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(android: _channel),
      androidScheduleMode: AndroidScheduleMode.inexact,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancel a previously scheduled notification.
  static Future<void> cancel(int id) => _plugin.cancel(id);
}
