import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../models/activity.dart';
import '../providers/activities_provider.dart';

class ActivityEditorDialog extends ConsumerStatefulWidget {
  final Activity? activity; // Null when creating
  final DateTime initialDate;

  const ActivityEditorDialog({
    super.key,
    this.activity,
    required this.initialDate,
  });

  static Future<void> show(
    BuildContext context, {
    Activity? activity,
    required DateTime initialDate,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ActivityEditorDialog(
        activity: activity,
        initialDate: initialDate,
      ),
    );
  }

  @override
  ConsumerState<ActivityEditorDialog> createState() => _ActivityEditorDialogState();
}

class _ActivityEditorDialogState extends ConsumerState<ActivityEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late int _targetDurationMinutes;
  late DateTime _selectedDate;

  late String _repeat;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.activity?.title ?? '');
    _descController = TextEditingController(text: widget.activity?.description ?? '');
    _targetDurationMinutes = widget.activity?.targetDurationMinutes ?? 30;
    _selectedDate = widget.activity?.date ?? widget.initialDate;
    _repeat = widget.activity?.repeat ?? 'none';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes mins';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(activitiesControllerProvider.notifier);

    if (widget.activity == null) {
      await controller.addActivity(
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        targetDurationMinutes: _targetDurationMinutes,
        date: _selectedDate,
        repeat: _repeat,
      );
    } else {
      bool updateAllFuture = false;
      if (widget.activity!.repeatGroupId != null) {
        final choice = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Recurring Activity'),
            content: const Text('Do you want to save changes to this activity instance only, or to this and all future instances?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('This instance only'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('All future instances'),
              ),
            ],
          ),
        );
        if (choice == null) return; // cancelled
        updateAllFuture = choice;
      }

      await controller.updateActivity(
        widget.activity!,
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        targetDurationMinutes: _targetDurationMinutes,
        repeat: _repeat,
        updateAllFuture: updateAllFuture,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle bar
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.activity == null ? 'Create Activity' : 'Edit Activity',
                style: textTheme.headlineSmall?.copyWith(
                  fontFamily: 'GoogleSansFlex',
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),

              // Title Field
              TextFormField(
                controller: _titleController,
                style: textTheme.bodyLarge,
                decoration: InputDecoration(
                  labelText: 'Title',
                  prefixIcon: const Icon(Symbols.auto_awesome_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descController,
                style: textTheme.bodyLarge,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  prefixIcon: const Icon(Symbols.notes_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Repeat Selector
              DropdownButtonFormField<String>(
                value: _repeat,
                decoration: InputDecoration(
                  labelText: 'Repeat',
                  prefixIcon: const Icon(Symbols.repeat_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('Does not repeat')),
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'weekdays', child: Text('Every weekday (Mon-Fri)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _repeat = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),

              // Target Duration Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Target Duration',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    _formatDuration(_targetDurationMinutes),
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.primary,
                      fontFamily: 'GoogleSansFlex',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Duration Slider
              Slider(
                value: _targetDurationMinutes.toDouble(),
                min: 5,
                max: 240,
                divisions: 47, // 5 min increments
                onChanged: (val) {
                  setState(() {
                    _targetDurationMinutes = val.round();
                  });
                },
              ),
              const SizedBox(height: 8),

              // Quick presets
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [15, 30, 45, 60, 90, 120].map((mins) {
                    final isSelected = _targetDurationMinutes == mins;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(_formatDuration(mins)),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _targetDurationMinutes = mins;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ButtonM3E(
                    onPressed: _save,
                    style: ButtonM3EStyle.filled,
                    shape: ButtonM3EShape.round,
                    label: Text(widget.activity == null ? 'Create' : 'Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
