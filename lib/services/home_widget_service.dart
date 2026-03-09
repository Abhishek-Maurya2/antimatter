import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';

@pragma('vm:entry-point')
Future<void> interactiveCallback(Uri? uri) async {
  if (uri?.host == 'check') {
    final String? id = uri?.queryParameters['id'];
    if (id != null) {
      await Hive.initFlutter();
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(TaskAdapter());
      }
      final box = await Hive.openBox<Task>('tasksBox');

      try {
        final task = box.values.firstWhere((t) => t.id == id);
        task.isCompleted = true;
        task.completedAt = DateTime.now();
        await task.save();

        await HomeWidgetService.updateTasksWidget(box.values.toList());
      } catch (e) {
        // Task not found
      }
    }
  }
}

class HomeWidgetService {
  static const String appGroupId = 'com.example.orches';
  static const String androidWidgetName = 'TasksWidgetReceiver';

  static Future<void> updateTasksWidget(List<Task> allTasks) async {
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
}
