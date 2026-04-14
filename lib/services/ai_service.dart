import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/task.dart';

class GroqService {
  final Dio _dio = Dio();
  static const String _apiKey = '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';
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  Future<List<Task>> generateTasks(String prompt, {List<String>? existingCategories}) async {
    final systemPrompt = '''
You are an intelligent task manager assistant for the "AntiMatter" app.
Your goal is to parse user input and generate one or more structured tasks.

CRITICAL: You MUST respond with a valid JSON object ONLY. Do not include any conversational text before or after the JSON.

JSON structure:
{
  "tasks": [
    {
      "title": "Clear task title",
      "description": "Elaborate details if possible",
      "deadline": "ISO8601 string or null",
      "categories": ["Simple Category Tags"],
      "subtasks": [
        { "title": "Subtask title", "description": "Subtask details or null" }
      ]
    }
  ]
}

- Categories: Use existing categories if they fit: ${existingCategories?.join(', ') ?? 'None'}. You can also suggest new, concise category names.
- Subtasks: Break down complex requests into logical sub-steps.
- Deadlines: If the user mentions time/date, interpret it into ISO8601. Current time: ${DateTime.now().toIso8601String()}.
''';

    try {
      final response = await _dio.post(
        _baseUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500, // Handle 400 errors manually to log them
        ),
        data: {
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': 'Generate JSON tasks for the following prompt: $prompt'},
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.1, // Lower temperature for more deterministic JSON
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final content = data['choices'][0]['message']['content'];
        final Map<String, dynamic> jsonResponse = json.decode(content);
        
        final List<dynamic> tasksJson = jsonResponse['tasks'] ?? [];
        return tasksJson.map((t) {
          // Convert the prompt-result JSON into Task objects
          // Note: Task model expects a unique ID. We generate temporary ones here.
          final tempId = DateTime.now().microsecondsSinceEpoch.toString() + (tasksJson.indexOf(t)).toString();
          
          return Task(
            id: tempId,
            title: t['title'] ?? 'Untitled Task',
            description: t['description'],
            deadline: t['deadline'] != null ? DateTime.tryParse(t['deadline']) : null,
            categories: (t['categories'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
            subTasks: (t['subtasks'] as List<dynamic>?)?.map((st) => Task(
              id: DateTime.now().microsecondsSinceEpoch.toString() + '_sub',
              title: st['title'] ?? 'Subtask',
              description: st['description'],
              isCompleted: false,
            )).toList() ?? [],
          );
        }).toList();
      } else {
        debugPrint('Groq API Error Response: ${response.data}');
        throw Exception('Failed to generate tasks: ${response.statusCode} - ${response.statusMessage}\nDetails: ${response.data}');
      }
    } on DioException catch (e) {
      debugPrint('Groq Dio Error: ${e.response?.data ?? e.message}');
      throw Exception('API Communication Error: ${e.response?.data ?? e.message}');
    } catch (e) {
      debugPrint('GroqService Unknown Error: $e');
      rethrow;
    }
  }
}
