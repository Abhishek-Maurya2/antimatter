import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/task.dart';

part 'tasks_provider.g.dart';

@Riverpod(keepAlive: true)
class TasksController extends _$TasksController {
  late final Box<Task> _box;

  @override
  List<Task> build() {
    _box = Hive.box<Task>('tasksBox');

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

  Box<Task> get box => _box;
}
