import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/activity.dart';

part 'activities_provider.g.dart';

@Riverpod(keepAlive: true)
class ActivitiesController extends _$ActivitiesController {
  late final Box<Activity> _box;
  final _random = Random();

  String _generateId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(1000)}';

  @override
  List<Activity> build() {
    _box = Hive.box<Activity>('activitiesBox');

    // Listen to Hive box changes
    final listenable = _box.listenable();
    void listener() {
      state = _box.values.toList();
    }

    listenable.addListener(listener);
    ref.onDispose(() {
      listenable.removeListener(listener);
    });

    return _box.values.toList();
  }

  Box<Activity> get box => _box;

  // Add a new activity
  Future<void> addActivity({
    required String title,
    String? description,
    required int targetDurationMinutes,
    required DateTime date,
    String repeat = 'none',
  }) async {
    // Normalize date to midnight (date only)
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    if (repeat == 'none') {
      final activity = Activity(
        id: _generateId(),
        title: title,
        description: description,
        targetDurationMinutes: targetDurationMinutes,
        date: normalizedDate,
        createdAt: DateTime.now(),
        repeat: repeat,
      );
      await _box.put(activity.id, activity);
    } else {
      final groupId = _generateId();
      final List<DateTime> occurrences = [];
      
      if (repeat == 'daily') {
        for (int i = 0; i < 30; i++) {
          occurrences.add(normalizedDate.add(Duration(days: i)));
        }
      } else if (repeat == 'weekly') {
        for (int i = 0; i < 12; i++) {
          occurrences.add(normalizedDate.add(Duration(days: i * 7)));
        }
      } else if (repeat == 'weekdays') {
        DateTime current = normalizedDate;
        int count = 0;
        while (count < 30) {
          if (current.weekday != DateTime.saturday && current.weekday != DateTime.sunday) {
            occurrences.add(current);
            count++;
          }
          current = current.add(const Duration(days: 1));
        }
      }
      
      for (final occDate in occurrences) {
        final activity = Activity(
          id: _generateId(),
          title: title,
          description: description,
          targetDurationMinutes: targetDurationMinutes,
          date: occDate,
          createdAt: DateTime.now(),
          repeat: repeat,
          repeatGroupId: groupId,
        );
        await _box.put(activity.id, activity);
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Update activity details
  Future<void> updateActivity(
    Activity activity, {
    String? title,
    String? description,
    int? targetDurationMinutes,
    bool? isCompleted,
    String? repeat,
    bool updateAllFuture = false,
  }) async {
    final oldRepeat = activity.repeat;
    final repeatChanged = repeat != null && repeat != oldRepeat;

    if (updateAllFuture && activity.repeatGroupId != null) {
      final futureActivities = _box.values.where((a) =>
          a.repeatGroupId == activity.repeatGroupId &&
          (a.date.isAfter(activity.date) || _isSameDay(a.date, activity.date))).toList();
      
      if (repeatChanged) {
        // Delete strictly future occurrences in this group
        final strictlyFuture = _box.values.where((a) =>
            a.repeatGroupId == activity.repeatGroupId &&
            a.date.isAfter(activity.date)).toList();
        for (final a in strictlyFuture) {
          await a.delete();
        }

        // Generate new occurrences for the new pattern starting after this date
        final List<DateTime> occurrences = [];
        if (repeat == 'daily') {
          for (int i = 1; i < 30; i++) {
            occurrences.add(activity.date.add(Duration(days: i)));
          }
        } else if (repeat == 'weekly') {
          for (int i = 1; i < 12; i++) {
            occurrences.add(activity.date.add(Duration(days: i * 7)));
          }
        } else if (repeat == 'weekdays') {
          DateTime current = activity.date.add(const Duration(days: 1));
          int count = 0;
          while (count < 30) {
            if (current.weekday != DateTime.saturday && current.weekday != DateTime.sunday) {
              occurrences.add(current);
              count++;
            }
            current = current.add(const Duration(days: 1));
          }
        }

        for (final occDate in occurrences) {
          final newOcc = Activity(
            id: _generateId(),
            title: title ?? activity.title,
            description: description ?? activity.description,
            targetDurationMinutes: targetDurationMinutes ?? activity.targetDurationMinutes,
            date: occDate,
            createdAt: DateTime.now(),
            repeat: repeat,
            repeatGroupId: activity.repeatGroupId,
          );
          await _box.put(newOcc.id, newOcc);
        }
      }

      for (final a in futureActivities) {
        if (title != null) a.title = title;
        if (description != null) a.description = description;
        if (targetDurationMinutes != null) {
          a.targetDurationMinutes = targetDurationMinutes;
        }
        if (repeat != null) {
          a.repeat = repeat;
        }
        await a.save();
      }
    } else {
      if (title != null) activity.title = title;
      if (description != null) activity.description = description;
      if (targetDurationMinutes != null) {
        activity.targetDurationMinutes = targetDurationMinutes;
      }
      if (isCompleted != null) activity.isCompleted = isCompleted;

      if (repeatChanged) {
        if (repeat == 'none') {
          activity.repeat = 'none';
          activity.repeatGroupId = null;
        } else {
          final newGroupId = _generateId();
          activity.repeat = repeat;
          activity.repeatGroupId = newGroupId;

          final List<DateTime> occurrences = [];
          if (repeat == 'daily') {
            for (int i = 1; i < 30; i++) {
              occurrences.add(activity.date.add(Duration(days: i)));
            }
          } else if (repeat == 'weekly') {
            for (int i = 1; i < 12; i++) {
              occurrences.add(activity.date.add(Duration(days: i * 7)));
            }
          } else if (repeat == 'weekdays') {
            DateTime current = activity.date.add(const Duration(days: 1));
            int count = 0;
            while (count < 30) {
              if (current.weekday != DateTime.saturday && current.weekday != DateTime.sunday) {
                occurrences.add(current);
                count++;
              }
              current = current.add(const Duration(days: 1));
            }
          }

          for (final occDate in occurrences) {
            final newOcc = Activity(
              id: _generateId(),
              title: title ?? activity.title,
              description: description ?? activity.description,
              targetDurationMinutes: targetDurationMinutes ?? activity.targetDurationMinutes,
              date: occDate,
              createdAt: DateTime.now(),
              repeat: repeat,
              repeatGroupId: newGroupId,
            );
            await _box.put(newOcc.id, newOcc);
          }
        }
      }

      await activity.save();
    }
    state = _box.values.toList();
  }

  // Delete activity
  Future<void> deleteActivity(Activity activity, {bool deleteAllFuture = false}) async {
    if (deleteAllFuture && activity.repeatGroupId != null) {
      final futureActivities = _box.values.where((a) =>
          a.repeatGroupId == activity.repeatGroupId &&
          (a.date.isAfter(activity.date) || _isSameDay(a.date, activity.date)))
          .toList();
      
      for (final a in futureActivities) {
        await a.delete();
      }
    } else {
      await activity.delete();
    }
    state = _box.values.toList();
  }

  // Subtask management
  Future<void> addSubTask(Activity activity, String taskTitle) async {
    final currentTasks = List<ActivityTask>.from(activity.tasks);
    final newTask = ActivityTask(
      id: _generateId(),
      title: taskTitle,
    );
    currentTasks.add(newTask);
    activity.tasks = currentTasks;
    await activity.save();
    state = _box.values.toList();
  }

  Future<void> toggleSubTask(Activity activity, String taskId) async {
    final currentTasks = List<ActivityTask>.from(activity.tasks);
    for (final task in currentTasks) {
      if (task.id == taskId) {
        task.isCompleted = !task.isCompleted;
        break;
      }
    }
    activity.tasks = currentTasks;
    await activity.save();
    state = _box.values.toList();
  }

  Future<void> deleteSubTask(Activity activity, String taskId) async {
    final currentTasks = List<ActivityTask>.from(activity.tasks);
    currentTasks.removeWhere((t) => t.id == taskId);
    activity.tasks = currentTasks;
    await activity.save();
    state = _box.values.toList();
  }

  // Session timer management
  Future<void> startSession(Activity activity) async {
    // Ensure no other session is active for this activity
    if (activity.activeSession != null) return;

    final currentSessions = List<ActivitySession>.from(activity.sessions);
    final newSession = ActivitySession(
      id: _generateId(),
      startTime: DateTime.now(),
    );
    currentSessions.add(newSession);
    activity.sessions = currentSessions;
    await activity.save();
    state = _box.values.toList();
  }

  Future<void> stopSession(Activity activity) async {
    final active = activity.activeSession;
    if (active == null) return;

    final currentSessions = List<ActivitySession>.from(activity.sessions);
    for (final s in currentSessions) {
      if (s.id == active.id) {
        s.endTime = DateTime.now();
        s.durationSeconds = s.endTime!.difference(s.startTime).inSeconds;
        break;
      }
    }
    activity.sessions = currentSessions;
    await activity.save();
    state = _box.values.toList();
  }

  // Calculate Streak
  int getStreakCount() {
    final activities = state;
    if (activities.isEmpty) return 0;

    final completedDays = <DateTime>{};
    for (final act in activities) {
      final hasCompletedTasks = act.tasks.isNotEmpty && act.tasks.every((t) => t.isCompleted);
      final hasTrackedTime = act.totalTrackedSeconds >= 60; // at least 1 minute
      if (act.isCompleted || hasCompletedTasks || hasTrackedTime) {
        final day = DateTime(act.date.year, act.date.month, act.date.day);
        completedDays.add(day);
      }
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    int streak = 0;
    DateTime currentDay = today;

    if (completedDays.contains(today)) {
      streak = 1;
      currentDay = today.subtract(const Duration(days: 1));
      while (completedDays.contains(currentDay)) {
        streak++;
        currentDay = currentDay.subtract(const Duration(days: 1));
      }
    } else if (completedDays.contains(yesterday)) {
      streak = 1;
      currentDay = yesterday.subtract(const Duration(days: 1));
      while (completedDays.contains(currentDay)) {
        streak++;
        currentDay = currentDay.subtract(const Duration(days: 1));
      }
    }

    return streak;
  }
}
