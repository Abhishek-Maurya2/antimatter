import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:intl/intl.dart';
import 'package:orches/models/task.dart';
import 'package:orches/services/audio_service.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:orches/utils/preferences_helper.dart';
import 'package:material_new_shapes/material_new_shapes.dart';
import 'package:orches/utils/ui_utils.dart';

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
  late List<String> _selectedCategories;
  List<String> _allCategories = [];

  @override
  void initState() {
    super.initState();
    _loadAllCategories();
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

  void _loadAllCategories() {
    _allCategories = PreferencesHelper.getStringList('categories') ?? [];
  }

  void _initFromTask() {
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _deadline = widget.task?.deadline;
    _subTasks =
        widget.task?.subTasks
            .map(
              (e) => Task(
                id: e.id,
                title: e.title,
                description: e.description,
                isCompleted: e.isCompleted,
                deadline: e.deadline,
                subTasks: [],
              ),
            )
            .toList() ??
        [];
    _selectedCategories = List<String>.from(widget.task?.categories ?? []);
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
        categories: _selectedCategories,
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

  void _showAddCategorySheet() {
    final colorTheme = Theme.of(context).colorScheme;
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colorTheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorTheme.onSurfaceVariant.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Add Category',
                style: TextStyle(
                  fontFamily: 'GoogleSansFlex',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colorTheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  ClipPath(
                    clipper: PolygonClipper(MaterialShapes.sunny),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colorTheme.primaryContainer,
                      ),
                      child: Icon(
                        Symbols.label,
                        fill: 1,
                        color: colorTheme.onPrimaryContainer,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      style: TextStyle(color: colorTheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Category name...',
                        filled: true,
                        fillColor: colorTheme.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(40),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 18,
                        ),
                      ),
                      onSubmitted: (val) {
                        _handleNewCategory(val);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ButtonM3E(
                      onPressed: () {
                        _handleNewCategory(controller.text);
                        Navigator.pop(context);
                      },
                      label: const Text('Save Category'),
                      style: ButtonM3EStyle.filled,
                      size: ButtonM3ESize.lg,
                      shape: ButtonM3EShape.round,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNewCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    if (!_allCategories.contains(trimmed)) {
      setState(() {
        _allCategories.add(trimmed);
        _selectedCategories.add(trimmed);
      });
      await PreferencesHelper.setStringList('categories', _allCategories);
    } else if (!_selectedCategories.contains(trimmed)) {
      setState(() {
        _selectedCategories.add(trimmed);
      });
    }
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
            TextFormField(
              controller: _titleController,
              autofocus: !widget.isStandaloneScreen && widget.task == null,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(fontSize: 16),
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
                        icon: const Icon(Symbols.close, weight: 500),
                        tooltip: 'Clear deadline',
                        variant: IconButtonM3EVariant.tonal,
                        width: IconButtonM3EWidth.narrow,
                        backgroundColor: colorTheme.tertiaryContainer,
                        foregroundColor: colorTheme.onTertiaryContainer,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            // Categories
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Symbols.category, color: colorTheme.onSurfaceVariant),
                    const SizedBox(width: 16),
                    Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorTheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: IconButtonM3E(
                    onPressed: _showAddCategorySheet,
                    icon: const Icon(Symbols.add_circle),
                    tooltip: 'add category',
                    variant: IconButtonM3EVariant.filled,
                    width: IconButtonM3EWidth.wide,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
              child: Builder(
                builder: (context) {
                    final sortedCategories = [
                      ..._allCategories.where(
                        (c) => _selectedCategories.contains(c),
                      ),
                      ..._allCategories.where(
                        (c) => !_selectedCategories.contains(c),
                      ),
                    ];

                    final actions = sortedCategories
                        .map(
                          (category) =>
                              _buildCategoryAction(category, colorTheme),
                        )
                        .toList();

                    if (actions.isEmpty) return const SizedBox.shrink();

                    // Split actions into two rows
                    final half = (actions.length / 2).ceil();
                    final row1 = actions.take(half).toList();
                    final row2 = actions.skip(half).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ButtonGroupM3E(
                          type: ButtonGroupM3EType.connected,
                          size: ButtonGroupM3ESize.sm,
                          style: ButtonM3EStyle.tonal,
                          actions: row1,
                        ),
                        if (row2.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ButtonGroupM3E(
                            type: ButtonGroupM3EType.connected,
                            size: ButtonGroupM3ESize.sm,
                            style: ButtonM3EStyle.tonal,
                            actions: row2,
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
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
                        decoration: const InputDecoration(
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
                      backgroundColor: colorTheme.tertiaryContainer,
                      foregroundColor: colorTheme.onTertiaryContainer,
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

  ButtonGroupM3EAction _buildCategoryAction(
    String category,
    ColorScheme colorTheme,
  ) {
    final isSelected = _selectedCategories.contains(category);
    return ButtonGroupM3EAction(
      label: Text(category),
      selected: isSelected,
      onPressed: () {
        setState(() {
          if (!isSelected) {
            _selectedCategories.add(category);
          } else {
            _selectedCategories.remove(category);
          }
        });
      },
      style: isSelected ? ButtonM3EStyle.filled : ButtonM3EStyle.tonal,
    );
  }
}
