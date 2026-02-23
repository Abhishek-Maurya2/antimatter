import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import '../models/task.dart';

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
