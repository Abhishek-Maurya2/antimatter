import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  bool isCompleted;

  @HiveField(4)
  DateTime? deadline;

  @HiveField(5)
  List<Task> subTasks;

  @HiveField(6, defaultValue: false)
  bool isArchived;

  @HiveField(7, defaultValue: false)
  bool isDeleted;

  @HiveField(8, defaultValue: [])
  List<String> labels;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.deadline,
    this.subTasks = const [],
    this.isArchived = false,
    this.isDeleted = false,
    this.labels = const [],
  });

  /// Factory constructor to create a Task from JSON (e.g. from Supabase)
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String).toLocal()
          : null,
      subTasks:
          (json['sub_tasks'] as List<dynamic>?)
              ?.map((e) => Task.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isArchived: json['is_archived'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      labels:
          (json['labels'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  /// Convert this Task to JSON (e.g. to send to Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_completed': isCompleted,
      'deadline': deadline?.toUtc().toIso8601String(),
      'sub_tasks': subTasks.map((t) => t.toJson()).toList(),
      'is_archived': isArchived,
      'is_deleted': isDeleted,
      'labels': labels,
    };
  }
}
