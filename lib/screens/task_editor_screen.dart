import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:intl/intl.dart';
import 'package:orches/models/task.dart';
import 'package:orches/services/audio_service.dart';
import 'package:m3e_collection/m3e_collection.dart';

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
      backgroundColor: widget.isStandaloneScreen
          ? colorTheme.surfaceContainer
          : colorTheme.surfaceContainerHigh,
      appBar: AppBar(
        title: widget.isStandaloneScreen
            ? Text(widget.task == null ? 'New Task' : 'Edit Task')
            : null,
        backgroundColor: widget.isStandaloneScreen
            ? colorTheme.surfaceContainer
            : colorTheme.surfaceContainerHigh,
        leadingWidth: 80,
        leading: Center(
          child: IconButtonM3E(
            onPressed: widget.onClose,
            icon: Icon(
              widget.isStandaloneScreen ? Symbols.arrow_back : Symbols.close,
            ),
            tooltip: widget.isStandaloneScreen ? 'Back' : 'Close',
            variant: IconButtonM3EVariant.tonal,
            width: IconButtonM3EWidth.wide,
          ),
        ),
        actions: [
          if (widget.task != null) ...[
            IconButtonM3E(
              onPressed: () {
                widget.onResult('DELETE');
              },
              icon: const Icon(Symbols.delete),
              tooltip: 'Delete',
              variant: IconButtonM3EVariant.tonal,
              width: IconButtonM3EWidth.narrow,
              backgroundColor: colorTheme.errorContainer,
              foregroundColor: colorTheme.onErrorContainer,
            ),

            const SizedBox(width: 8),
          ],
          IconButtonM3E(
            onPressed: _saveTask,
            icon: const Icon(Symbols.check),
            tooltip: 'Save',
            variant: IconButtonM3EVariant.filled,
            width: IconButtonM3EWidth.wide,
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
                      IconButtonM3E(
                        onPressed: () => setState(() => _deadline = null),
                        icon: Icon(Symbols.close, weight: 500),
                        tooltip: 'Clear deadline',
                        variant: IconButtonM3EVariant.tonal,
                        width: IconButtonM3EWidth.narrow,
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
                IconButtonM3E(
                  icon: Icon(
                    Symbols.add,
                    color: colorTheme.primary,
                    weight: 500,
                  ),
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
                  tooltip: 'Clear deadline',
                  variant: IconButtonM3EVariant.tonal,
                  width: IconButtonM3EWidth.narrow,
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
                  child: IconButtonM3E(
                    onPressed: _addSubTask,
                    icon: const Icon(Symbols.add_circle),
                    tooltip: 'add subtask',
                    variant: IconButtonM3EVariant.filled,
                    width: IconButtonM3EWidth.wide,
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
                          if (subTask.isCompleted) {
                            AudioService().playTickSound();
                          }
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
                    IconButtonM3E(
                      icon: const Icon(Symbols.close, size: 18, weight: 600),
                      variant: IconButtonM3EVariant.tonal,
                      width: IconButtonM3EWidth.narrow,
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
