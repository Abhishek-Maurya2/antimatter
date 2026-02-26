import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';

class SupabaseSyncService {
  final _supabase = Supabase.instance.client;
  final Box<Task> _tasksBox;

  // Track if we are currently syncing to prevent infinite loops when Hive triggers listeners
  bool _isSyncingFromServer = false;

  SupabaseSyncService(this._tasksBox);

  /// Pull all tasks from Supabase and merge them into the local Hive box
  Future<void> pullTasks() async {
    try {
      _isSyncingFromServer = true;
      List<Map<String, dynamic>>? response;
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          response = await _supabase
              .from('tasks')
              .select()
              .timeout(const Duration(seconds: 15));
          break; // Success
        } catch (e) {
          retryCount++;
          if (retryCount >= maxRetries) {
            rethrow;
          }
          // Exponential backoff
          await Future.delayed(Duration(seconds: 2 * retryCount));
        }
      }

      if (response != null) {
        for (final row in response) {
          final task = Task.fromJson(row);
          // Put the remote task into the local box (upsert by ID)
          await _tasksBox.put(task.id, task);
        }
        debugPrint(
          'Supabase Sync: Successfully pulled ${response.length} tasks.',
        );
      }
    } catch (e) {
      debugPrint('Supabase Sync: Error pulling tasks - $e');
    } finally {
      _isSyncingFromServer = false;
    }
  }

  /// Push a single task up to Supabase
  Future<void> pushTask(Task task) async {
    // If this update was triggered by a pull from the server, don't push it back!
    if (_isSyncingFromServer) return;

    try {
      final taskJson = task.toJson();
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          await _supabase
              .from('tasks')
              .upsert(taskJson)
              .timeout(const Duration(seconds: 15));
          break; // Success
        } catch (e) {
          retryCount++;
          if (retryCount >= maxRetries) {
            rethrow;
          }
          await Future.delayed(Duration(seconds: 2 * retryCount));
        }
      }

      debugPrint('Supabase Sync: Pushed task ${task.id}');
    } catch (e) {
      debugPrint('Supabase Sync: Error pushing task ${task.id} - $e');
    }
  }

  /// Listen to the local Hive box for any changes and push them to Supabase
  void startListening() {
    _tasksBox.listenable().addListener(() {
      if (_isSyncingFromServer) return;

      // When the box changes, we could inspect the specific changes, but Hive's listenable
      // just tells us *something* changed. We will iterate and ensure all tasks are synced.
      // For a more robust solution, we can hook into singular put/delete operations at the repository level.
      for (final task in _tasksBox.values) {
        pushTask(task);
      }
    });
  }
}
