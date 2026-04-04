import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize timezones
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
          macOS: initializationSettingsIOS,
          linux: LinuxInitializationSettings(
            defaultActionName: 'Open notification',
          ),
          windows: WindowsInitializationSettings(
            appName: 'Antimatter',
            appUserModelId: 'com.example.antimatter',
            guid: 'b4a1b0b5-1e35-430c-80a2-231a4df8342f',
          ),
        );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
      },
    );

    _isInitialized = true;
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return true;

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        // Use MethodChannel directly to avoid using platform-specific types
        // that fail to compile on Windows.
        const MethodChannel channel =
            MethodChannel('dexterous.com/flutter_local_notifications');
        final bool? result =
            await channel.invokeMethod<bool>('requestNotificationsPermission');
        return result ?? false;
      } catch (e) {
        debugPrint('Error requesting notification permission: $e');
        return false;
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      // For iOS/macOS, we request permission during initialize/re-initialize
      // or we can just return true here since we handle it in init().
      return true;
    }

    return true;
  }

  Future<bool> isPermissionGranted() async {
    if (kIsWeb) return true;

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        const MethodChannel channel =
            MethodChannel('dexterous.com/flutter_local_notifications');
        final bool? result =
            await channel.invokeMethod<bool>('areNotificationsEnabled');
        return result ?? false;
      } catch (e) {
        return true;
      }
    }

    return true;
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> scheduleDeadlineReminder(
    Task task,
    int minutesBeforeDeadline,
  ) async {
    if (task.deadline == null) return;

    final dueDate = task.deadline!;
    final scheduledDate = dueDate.subtract(
      Duration(minutes: minutesBeforeDeadline),
    );

    // Don't schedule if the time has already passed
    if (scheduledDate.isBefore(DateTime.now())) return;

    final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'task_deadlines_channel',
          'Task Deadlines',
          channelDescription: 'Notifications for approaching task deadlines',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    // We use the task's unique ID for the notification ID so we can cancel it later
    // Task.id is a String, we need a stable integer
    final int notificationId = task.id.hashCode;

    await _notificationsPlugin.zonedSchedule(
      id: notificationId,
      title: 'Upcoming Deadline',
      body: '${task.title} is due in $minutesBeforeDeadline minutes',
      scheduledDate: tzScheduledDate,
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: task.id,
    );
  }

  Future<void> scheduleDailySummary(int pendingCount) async {
    // Schedule for 9:00 AM every day
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      9,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'daily_summary_channel',
          'Daily Summary',
          channelDescription: 'Daily overview of pending tasks',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    // Reserved ID for daily summary
    const int summaryNotificationId = 999999;

    await _notificationsPlugin.zonedSchedule(
      id: summaryNotificationId,
      title: 'Daily Summary',
      body: 'You have $pendingCount tasks pending.',
      scheduledDate: scheduledDate,
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
