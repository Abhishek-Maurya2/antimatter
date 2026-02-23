import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:intl/intl.dart';
import 'package:orches/models/task.dart';

class TaskEditorScreen extends StatelessWidget {
  final Task? task;

  const TaskEditorScreen({super.key, this.task});

  @override
  Widget build(BuildContext context) {
    return TaskEditorWidget(
      task: task,
      onClose: () => Navigator.of(context).pop(),
      onResult: (result) => Navigator.of(context).pop(result),
      isStandaloneScreen: true,
    );
  }
}

class TaskEditorWidget extends StatefulWidget {
  final Task? task;
  final VoidCallback onClose;
  final ValueChanged<dynamic> onResult;
  final bool isStandaloneScreen;

  const TaskEditorWidget({
    super.key,
    this.task,
    required this.onClose,
    required this.onResult,
    this.isStandaloneScreen = false,
  });

  @override
  State<TaskEditorWidget> createState() => _TaskEditorWidgetState();
}

class _TaskEditorWidgetState extends State<TaskEditorWidget> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _deadline;
  late List<Task> _subTasks;
  late List<String> _labels;
  final TextEditingController _labelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initFromTask();
  }

  @override
  void didUpdateWidget(covariant TaskEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task?.id != widget.task?.id ||
        oldWidget.task == null && widget.task != null) {
      _initFromTask();
    }
  }

  void _initFromTask() {
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
    _labels = List<String>.from(widget.task?.labels ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _labelController.dispose();
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
        labels: _labels,
      );
      widget.onResult(newTask);
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
        title: widget.isStandaloneScreen
            ? Text(widget.task == null ? 'New Task' : 'Edit Task')
            : null,
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
              onPressed: widget.onClose,
              icon: Icon(
                widget.isStandaloneScreen ? Symbols.arrow_back : Symbols.close,
                color: colorTheme.onSurface,
              ),
              tooltip: widget.isStandaloneScreen ? 'Back' : 'Close',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ),
        actions: [
          if (widget.task != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Container(
                width: 64,
                height: 48,
                decoration: BoxDecoration(
                  color: colorTheme.errorContainer,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: IconButton(
                  onPressed: () {
                    widget.onResult('DELETE');
                  },
                  icon: Icon(
                    Symbols.delete,
                    color: colorTheme.onErrorContainer,
                  ),
                  tooltip: 'Delete',
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
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
              autofocus: !widget.isStandaloneScreen && widget.task == null,
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
            // Labels
            Row(
              children: [
                Icon(Symbols.label, color: colorTheme.onSurfaceVariant),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _labelController,
                    decoration: InputDecoration(
                      hintText: 'Add a label...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onFieldSubmitted: (value) {
                      if (value.trim().isNotEmpty &&
                          !_labels.contains(value.trim())) {
                        setState(() {
                          _labels.add(value.trim());
                          _labelController.clear();
                        });
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Symbols.add, color: colorTheme.primary),
                  onPressed: () {
                    final value = _labelController.text;
                    if (value.trim().isNotEmpty &&
                        !_labels.contains(value.trim())) {
                      setState(() {
                        _labels.add(value.trim());
                        _labelController.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            if (_labels.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8, left: 40),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _labels.map((label) {
                    return InputChip(
                      label: Text(label),
                      labelStyle: TextStyle(fontSize: 12),
                      backgroundColor: colorTheme.secondaryContainer,
                      deleteIcon: Icon(Symbols.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _labels.remove(label);
                        });
                      },
                    );
                  }).toList(),
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
