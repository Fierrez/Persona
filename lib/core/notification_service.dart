import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings();
    const LinuxInitializationSettings linuxSettings = 
    LinuxInitializationSettings(defaultActionName: 'Open notification');

    // Windows initialization is required when running on Windows platform
    // but the plugin often doesn't need specific settings for simple cases.
    // However, initialize() will fail if settings are null for the current platform.

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
      linux: linuxSettings,
    );

    // If we're on Windows, we need to handle it or the app will crash on startup
    // during the .initialize() call in main.dart
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      // For Windows, it's often better to skip notification init if not needed
      // or provide empty settings if the platform-specific package is installed.
      // But since the user is getting an error, we should provide default settings.
      return; 
    }

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle tap
      },
    );
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) return;

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'persona_tasks',
          'Task Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> cancelAll() async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) return;
    await _notifications.cancelAll();
  }
}