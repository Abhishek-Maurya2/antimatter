class Task {
  final String id;
  String title;
  String? description;
  bool isCompleted;
  DateTime? deadline;
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
