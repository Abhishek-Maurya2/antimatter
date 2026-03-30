import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../utils/preferences_helper.dart';
import 'notification_service.dart';

class AiCoachService {
  static final AiCoachService _instance = AiCoachService._internal();
  factory AiCoachService() => _instance;
  AiCoachService._internal();

  Future<void> triggerCoach() async {
    final bool enableAiCoach =
        PreferencesHelper.getBool('enableAiCoach') ?? false;
    final String apiKey = PreferencesHelper.getString('groqApiKey') ?? '';

    if (!enableAiCoach || apiKey.isEmpty) {
      return;
    }

    try {
      print("[AI Coach] Checking tasks and preparing coaching request...");
      final tasksBox = await Hive.openBox<Task>('tasksBox');
      final tasks = tasksBox.values.where((t) => !t.isDeleted).toList();

      final now = DateTime.now();
      final pendingTasks = tasks.where((t) => !t.isCompleted).toList();
      final overdueTasks = pendingTasks
          .where((t) => t.deadline != null && t.deadline!.isBefore(now))
          .toList();

      // Include tasks due today if not already overdue
      final todayTasks = pendingTasks.where((t) {
        if (t.deadline == null) return false;
        final d = t.deadline!;
        return d.year == now.year &&
            d.month == now.month &&
            d.day == now.day &&
            d.isAfter(now);
      }).toList();

      if (overdueTasks.isEmpty && todayTasks.isEmpty) {
        return; // No immediate pressure needed
      }

      // Formulate detailed task list for AI
      String taskContext = "OVERDUE TASKS:\n";
      for (var t in overdueTasks) {
        taskContext +=
            "- ${t.title}${t.categories.isNotEmpty ? ' [${t.categories.join(', ')}]' : ''}${t.description != null && t.description!.isNotEmpty ? ': ${t.description}' : ''}\n";
      }

      if (todayTasks.isNotEmpty) {
        taskContext += "\nTASKS DUE TODAY:\n";
        for (var t in todayTasks) {
          taskContext +=
              "- ${t.title}${t.categories.isNotEmpty ? ' [${t.categories.join(', ')}]' : ''}\n";
        }
      }

      // Formulate prompt
      String prompt =
          '''
You are an extremely aggressive, ruthless productivity coach for a UPSC aspirant. 
The user is slacking. Here is their current dashboard:
$taskContext
Total overall pending: ${pendingTasks.length}.

Your goal: Generate a maximum 2-sentence push notification to guilt trip them into studying immediately. 
CRITICAL: Mention at least one specific task from the list above to make it personal and targeted.
Be brutally honest, borderline rude. Do NOT use emojis. Do not give greetings. Just hit them with reality.
''';

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {"role": "system", "content": prompt},
          ],
          "max_tokens": 100,
          "temperature": 0.9, // Higher temperature for more "creative" insults
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("data:");
        print("data: $data");
        final String? message = data['choices']?[0]?['message']?['content'];
        
        if (message == null || message.isEmpty) {
          print("[AI Coach] Error: Groq API returned an empty message. Full response: \${response.body}");
          return;
        }

        // Clean up common AI artifacts like extra quotes
        String finalMessage = message.trim().replaceAll('"', '');
        print("AI Response:\n$finalMessage");
        await NotificationService().showCoachNotification(finalMessage);
      } else {
        print("Groq API Error (\${response.statusCode}): \${response.body}");
      }
    } catch (e) {
      print("AI Coach Error: \$e");
    }
  }
}
