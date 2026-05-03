import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import '../utils/preferences_helper.dart';

class SupabaseSyncService {
  final _supabase = Supabase.instance.client;
  final Box<Task> _tasksBox;

  // Track if we are currently syncing to prevent infinite loops when Hive triggers listeners
  bool _isSyncingFromServer = false;
  final Set<String> _pendingPushTaskIds = HashSet<String>();
  final Set<String> _pendingDeleteTaskIds = HashSet<String>();
  final Map<String, Timer> _debounceTimers = {};
  RealtimeChannel? _realtimeChannel;

  // Queue to serialize realtime event processing and avoid interleaving
  Future<void> _realtimeQueue = Future.value();

  SupabaseSyncService(this._tasksBox);

  /// Pull all tasks from Supabase and merge them into the local Hive box
  Future<void> pullTasks() async {
    try {
      _isSyncingFromServer = true;
      List<Map<String, dynamic>>? response;
      int retryCount = 0;
      const maxRetries = 3;

      final lastSync = PreferencesHelper.getString('tasks_last_sync');

      while (retryCount < maxRetries) {
        try {
          var query = _supabase.from('tasks').select();
          if (lastSync != null) {
            query = query.gte('updated_at', lastSync);
          }
          response = await query.timeout(const Duration(seconds: 15));
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
          final existingTask = _tasksBox.get(task.id);
          _mergeCompletedAt(task, existingTask);
          // Put the remote task into the local box (upsert by ID)
          await _tasksBox.put(task.id, task);
        }
        debugPrint(
          'Supabase Sync: Successfully pulled ${response.length} tasks.',
        );
        PreferencesHelper.setString('tasks_last_sync', DateTime.now().toUtc().subtract(const Duration(minutes: 1)).toIso8601String());
      }
    } catch (e) {
      debugPrint('Supabase Sync: Error pulling tasks - $e');
    } finally {
      _isSyncingFromServer = false;
      await _flushPendingPushes();
      await _runAutoCleanup();
    }
  }

  /// Push a single task up to Supabase
  Future<void> pushTask(Task task) async {
    // If this update was triggered by a pull from the server, don't push it back!
    if (_isSyncingFromServer) {
      _pendingDeleteTaskIds.remove(task.id);
      _pendingPushTaskIds.add(task.id);
      return;
    }

    if (_pendingDeleteTaskIds.contains(task.id)) {
      return;
    }

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

      // debugPrint('Supabase Sync: Pushed task ${task.id}');
    } catch (e) {
      debugPrint('Supabase Sync: Error pushing task ${task.id} - $e');
    }
  }

  /// Permanently delete a task in Supabase by ID
  Future<void> deleteTask(String taskId) async {
    if (_isSyncingFromServer) {
      _pendingPushTaskIds.remove(taskId);
      _pendingDeleteTaskIds.add(taskId);
      return;
    }

    try {
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          await _supabase
              .from('tasks')
              .delete()
              .eq('id', taskId)
              .timeout(const Duration(seconds: 15));
          break;
        } catch (e) {
          retryCount++;
          if (retryCount >= maxRetries) {
            rethrow;
          }
          await Future.delayed(Duration(seconds: 2 * retryCount));
        }
      }

      debugPrint('Supabase Sync: Deleted task $taskId');
    } catch (e) {
      debugPrint('Supabase Sync: Error deleting task $taskId - $e');
    }
  }

  /// Listen to the local Hive box for any changes and push them to Supabase
  void startListening() {
    _tasksBox.watch().listen((event) {
      if (_isSyncingFromServer) {
        if (event.deleted) {
          _pendingDeleteTaskIds.add(event.key.toString());
        } else {
          _pendingPushTaskIds.add(event.key.toString());
        }
        return;
      }

      if (event.deleted) {
        deleteTask(event.key.toString());
      } else {
        final task = event.value as Task;
        _scheduleDebouncedPush(task);
      }
    });
  }

  void _scheduleDebouncedPush(Task task) {
    _debounceTimers[task.id]?.cancel();
    _debounceTimers[task.id] = Timer(const Duration(milliseconds: 500), () {
      pushTask(task);
      _debounceTimers.remove(task.id);
    });
  }

  /// Preserves the local completedAt timestamp when the remote record omits it,
  /// and clears it when the task is marked incomplete. Extracted to avoid
  /// duplicating this logic across pull and realtime paths.
  void _mergeCompletedAt(Task remoteTask, Task? localTask) {
    if (remoteTask.isCompleted && remoteTask.completedAt == null) {
      remoteTask.completedAt = localTask?.completedAt;
    } else if (!remoteTask.isCompleted) {
      remoteTask.completedAt = null;
    }
  }

  Future<void> _runAutoCleanup() async {
    final now = DateTime.now();
    final List<String> toDelete = [];

    for (final task in _tasksBox.values) {
      if (task.isArchived) continue;

      if (task.isDeleted && task.deletedAt != null) {
        if (now.difference(task.deletedAt!).inDays >= 30) {
          toDelete.add(task.id);
          continue;
        }
      }

      if (task.isCompleted && !task.isDeleted) {
        final completedAt = task.completedAt;
        if (completedAt != null && now.difference(completedAt).inDays >= 15) {
          task.isDeleted = true;
          task.deletedAt = now;
          await task.save();
        }
      }
    }

    for (final id in toDelete) {
      await _tasksBox.delete(id);
      await deleteTask(id);
    }
  }

  Future<void> _flushPendingPushes() async {
    if (_pendingPushTaskIds.isEmpty && _pendingDeleteTaskIds.isEmpty) return;

    final pendingDeleteIds = _pendingDeleteTaskIds.toList();
    _pendingDeleteTaskIds.clear();
    for (final id in pendingDeleteIds) {
      await deleteTask(id);
    }

    final pendingIds = _pendingPushTaskIds.toList();
    _pendingPushTaskIds.clear();

    for (final id in pendingIds) {
      final task = _tasksBox.get(id);
      if (task != null) {
        await pushTask(task);
      }
    }
  }

  /// Subscribe to Supabase Realtime so that changes made on other devices are
  /// immediately applied to the local Hive box without requiring a manual refresh.
  void subscribeToRealtime() {
    _realtimeChannel = _supabase
        .channel('public:tasks')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tasks',
          callback: _handleRealtimeEvent,
        )
        .subscribe();
    debugPrint('Supabase Realtime: Subscribed to tasks table.');
  }

  Future<void> _handleRealtimeEvent(PostgresChangePayload payload) {
    // Enqueue to serialize processing and prevent flag interleaving
    _realtimeQueue = _realtimeQueue.then((_) => _processRealtimeEvent(payload));
    return _realtimeQueue;
  }

  Future<void> _processRealtimeEvent(PostgresChangePayload payload) async {
    try {
      _isSyncingFromServer = true;
      if (payload.eventType == PostgresChangeEvent.delete) {
        final id = payload.oldRecord['id'] as String?;
        if (id != null) {
          await _tasksBox.delete(id);
          debugPrint('Supabase Realtime: Deleted task $id from local box.');
        }
      } else {
        // INSERT or UPDATE
        final task = Task.fromJson(payload.newRecord);
        final existingTask = _tasksBox.get(task.id);
        _mergeCompletedAt(task, existingTask);
        await _tasksBox.put(task.id, task);
        debugPrint('Supabase Realtime: Upserted task ${task.id} in local box.');
      }
    } catch (e) {
      debugPrint('Supabase Realtime: Error handling task event - $e');
    } finally {
      _isSyncingFromServer = false;
    }
  }

  /// Unsubscribe from Supabase Realtime and cancel all debounce timers.
  void dispose() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
  }
}
