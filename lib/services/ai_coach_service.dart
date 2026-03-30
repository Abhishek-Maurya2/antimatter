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
      final tasksBox = await Hive.openBox<Task>('tasksBox');
      final tasks = tasksBox.values.where((t) => !t.isDeleted).toList();

      final now = DateTime.now();
      final pendingTasks = tasks.where((t) => !t.isCompleted).toList();
      final overdueTasks = pendingTasks
          .where((t) => t.deadline != null && t.deadline!.isBefore(now))
          .toList();

      // Formulate prompt
      String prompt = '''
You are an extremely aggressive, ruthless productivity coach for a UPSC aspirant. 
They have completely missed ${overdueTasks.length} deadlines.
They have ${pendingTasks.length} tasks still pending.
Generate a maximum 2-sentence push notification to guilt trip them into studying immediately. Be brutally honest. Do NOT use emojis. Do not give greetings. Just hit them with reality.
''';

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "llama3-8b-8192",
          "messages": [
            {"role": "system", "content": prompt}
          ],
          "max_tokens": 100,
          "temperature": 0.8,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String message = data['choices'][0]['message']['content'];
        await NotificationService().showCoachNotification(message.trim());
      } else {
        print("Groq API Error: \${response.body}");
      }
    } catch (e) {
      print("AI Coach Error: \$e");
    }
  }
}
