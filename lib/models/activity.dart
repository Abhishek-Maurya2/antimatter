import 'package:hive/hive.dart';

part 'activity.g.dart';

class ActivityTask {
  final String id;
  String title;
  bool isCompleted;

  ActivityTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  factory ActivityTask.fromMap(Map<dynamic, dynamic> map) {
    return ActivityTask(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
    };
  }
}

class ActivitySession {
  final String id;
  final DateTime startTime;
  DateTime? endTime;
  int durationSeconds;

  ActivitySession({
    required this.id,
    required this.startTime,
    this.endTime,
    this.durationSeconds = 0,
  });

  factory ActivitySession.fromMap(Map<dynamic, dynamic> map) {
    return ActivitySession(
      id: map['id'] as String? ?? '',
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime'] as String) : null,
      durationSeconds: map['durationSeconds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationSeconds': durationSeconds,
    };
  }
}

@HiveType(typeId: 2)
class Activity extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  int targetDurationMinutes;

  @HiveField(4)
  DateTime date; // Normalized date (midnight)

  @HiveField(5)
  List<Map> rawTasks;

  @HiveField(6)
  List<Map> rawSessions;

  @HiveField(7)
  bool isCompleted;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9, defaultValue: 'none')
  String repeat; // 'none', 'daily', 'weekly', 'weekdays'

  @HiveField(10)
  String? repeatGroupId;

  Activity({
    required this.id,
    required this.title,
    this.description,
    required this.targetDurationMinutes,
    required this.date,
    this.rawTasks = const [],
    this.rawSessions = const [],
    this.isCompleted = false,
    required this.createdAt,
    this.repeat = 'none',
    this.repeatGroupId,
  });

  List<ActivityTask> get tasks =>
      rawTasks.map((e) => ActivityTask.fromMap(Map<dynamic, dynamic>.from(e))).toList();

  List<ActivitySession> get sessions =>
      rawSessions.map((e) => ActivitySession.fromMap(Map<dynamic, dynamic>.from(e))).toList();

  set tasks(List<ActivityTask> newTasks) {
    rawTasks = newTasks.map((t) => t.toMap()).toList();
  }

  set sessions(List<ActivitySession> newSessions) {
    rawSessions = newSessions.map((s) => s.toMap()).toList();
  }

  ActivitySession? get activeSession {
    final list = sessions;
    for (final s in list) {
      if (s.endTime == null) return s;
    }
    return null;
  }

  int get totalTrackedSeconds {
    return sessions.fold(0, (sum, s) {
      if (s.endTime != null) {
        return sum + s.durationSeconds;
      } else {
        final running = DateTime.now().difference(s.startTime).inSeconds;
        return sum + (running > 0 ? running : 0);
      }
    });
  }
}
