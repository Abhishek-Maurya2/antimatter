import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';

class HomeWidgetService {
  static const String appGroupId = 'com.example.antimatter';
  static const String androidWidgetName = 'TasksWidgetReceiver';

  /// Returns true if home widgets are supported on this platform.
  static bool get _isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<void> updateTasksWidget(List<Task> allTasks) async {
    if (!_isSupported) return;

    // Filter active tasks (not completed, not deleted, not archived)
    final activeTasks = allTasks
        .where((t) => !t.isCompleted && !t.isDeleted && !t.isArchived)
        .toList();

    // Convert to a simple List of Maps tailored for the widget
    final tasksData = activeTasks
        .map((t) => {'id': t.id, 'title': t.title})
        .toList();

    // Save as JSON string
    final jsonString = jsonEncode(tasksData);

    await HomeWidget.saveWidgetData<String>('active_tasks', jsonString);
    await HomeWidget.updateWidget(androidName: androidWidgetName);
  }

  /// Sync tasks completed from the widget back to Hive.
  /// Called on app startup.
  static Future<void> syncWidgetCompletions(Box<Task> box) async {
    if (!_isSupported) return;

    final completedIdsJson = await HomeWidget.getWidgetData<String>(
      'widget_completed_ids',
    );
    if (completedIdsJson == null || completedIdsJson == '[]') return;

    try {
      final List<dynamic> completedIds = jsonDecode(completedIdsJson);

      for (final id in completedIds) {
        try {
          final task = box.values.firstWhere((t) => t.id == id);
          if (!task.isCompleted) {
            task.isCompleted = true;
            task.completedAt = DateTime.now();
            await task.save();
          }
        } catch (_) {
          // Task not found in box — skip
        }
      }

      // Clear the completed IDs after syncing
      await HomeWidget.saveWidgetData<String>('widget_completed_ids', '[]');
    } catch (_) {
      // JSON parse error — clear bad data
      await HomeWidget.saveWidgetData<String>('widget_completed_ids', '[]');
    }
  }
}
