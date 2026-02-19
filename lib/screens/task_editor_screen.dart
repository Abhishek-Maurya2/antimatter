import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:intl/intl.dart';
import 'package:orches/models/task.dart';
import 'package:orches/screens/settings_screen.dart'; // reusing iconContainer if needed, or better to copy/make util

class TaskEditorScreen extends StatefulWidget {
  final Task? task;

  const TaskEditorScreen({super.key, this.task});

  @override
  State<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends State<TaskEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _deadline;
  late List<Task> _subTasks;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _deadline = widget.task?.deadline;
    // Deep copy subtasks to avoid mutating original task until save
    _subTasks =
        widget.task?.subTasks
            .map(
              (e) => Task(
                id: e.id,
                title: e.title,
                description: e.description,
                isCompleted: e.isCompleted,
                deadline: e.deadline,
                subTasks:
                    [], // simplified for now, assuming 1 level deep nesting
              ),
            )
            .toList() ??
        [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final newTask = Task(
        id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        isCompleted: widget.task?.isCompleted ?? false,
        deadline: _deadline,
        subTasks: _subTasks,
      );
      Navigator.of(context).pop(newTask);
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_deadline ?? DateTime.now()),
      );
      if (time != null && mounted) {
        setState(() {
          _deadline = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _addSubTask() {
    setState(() {
      _subTasks.add(
        Task(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: '',
          isCompleted: false,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorTheme.surfaceContainer,
      appBar: AppBar(
        title: Text(widget.task == null ? 'New Task' : 'Edit Task'),
        backgroundColor: colorTheme.surfaceContainer,
        leadingWidth: 80,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            width: 64,
            height: 48,
            decoration: BoxDecoration(
              color: colorTheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(50),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Symbols.arrow_back, color: colorTheme.onSurface),
              tooltip: 'Back',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: 64,
              height: 48,
              decoration: BoxDecoration(
                color: colorTheme.primary,
                borderRadius: BorderRadius.circular(50),
              ),
              child: IconButton(
                onPressed: _saveTask,
                icon: Icon(Symbols.check, color: colorTheme.onPrimary),
                tooltip: 'Save',
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Task Title',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: colorTheme.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            // Description
            TextFormField(
              controller: _descriptionController,
              style: TextStyle(fontSize: 16),
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Add details',
                icon: Icon(Symbols.subject, color: colorTheme.onSurfaceVariant),
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: colorTheme.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Deadline
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 0,
                ),
                child: Row(
                  children: [
                    Icon(Symbols.event, color: colorTheme.onSurfaceVariant),
                    const SizedBox(width: 16),
                    Text(
                      _deadline == null
                          ? 'Set Date & Time'
                          : DateFormat('MMM d, yyyy h:mm a').format(_deadline!),
                      style: TextStyle(
                        fontSize: 16,
                        color: _deadline == null
                            ? colorTheme.onSurfaceVariant
                            : colorTheme.onSurface,
                      ),
                    ),
                    if (_deadline != null) ...[
                      const Spacer(),
                      IconButton(
                        onPressed: () => setState(() => _deadline = null),
                        icon: Icon(Symbols.close, size: 20),
                        tooltip: 'Clear deadline',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            // Subtasks Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtasks',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorTheme.primary,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Container(
                    width: 50,
                    height: 35,
                    decoration: BoxDecoration(
                      color: colorTheme.primary,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: IconButton(
                      onPressed: _addSubTask,
                      icon: Icon(
                        Symbols.add_circle,
                        color: colorTheme.onPrimary,
                      ),
                      tooltip: 'add subtask',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
              ],
            ),
            // Subtasks List
            ..._subTasks.asMap().entries.map((entry) {
              final index = entry.key;
              final subTask = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Checkbox(
                      value: subTask.isCompleted,
                      shape: const CircleBorder(),
                      onChanged: (value) {
                        setState(() {
                          subTask.isCompleted = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: TextFormField(
                        initialValue: subTask.title,
                        decoration: InputDecoration(
                          hintText: 'Subtask title',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (value) {
                          subTask.title = value;
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Symbols.close, size: 20),
                      onPressed: () {
                        setState(() {
                          _subTasks.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
