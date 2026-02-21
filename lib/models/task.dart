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

  Task({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.deadline,
    this.subTasks = const [],
  });
}
