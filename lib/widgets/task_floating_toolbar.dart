import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:orches/models/task.dart';

class TaskFloatingToolbar extends StatelessWidget {
  final Task task;
  final VoidCallback onComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onClose;
  final ColorScheme colorTheme;

  const TaskFloatingToolbar({
    super.key,
    required this.task,
    required this.onComplete,
    required this.onEdit,
    required this.onDelete,
    required this.onClose,
    required this.colorTheme,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.isCompleted;

    return Material(
      elevation: 4,
      shadowColor: colorTheme.shadow,
      borderRadius: BorderRadius.circular(50),
      color: colorTheme.primaryContainer,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onComplete,
              icon: Icon(
                isCompleted ? Symbols.undo : Symbols.check,
                color: colorTheme.onPrimaryContainer,
              ),
              tooltip: isCompleted ? 'Undo Complete' : 'Mark as Complete',
            ),
            IconButton(
              onPressed: onEdit,
              icon: Icon(Symbols.edit, color: colorTheme.onPrimaryContainer),
              tooltip: 'Edit Task',
            ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(Symbols.delete_outline, color: colorTheme.error),
              tooltip: 'Delete Task',
            ),
            Container(
              width: 1,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: colorTheme.outlineVariant,
            ),
            IconButton(
              onPressed: onClose,
              icon: Icon(Symbols.close, color: colorTheme.onPrimaryContainer),
              tooltip: 'Close',
            ),
          ],
        ),
      ),
    );
  }
}
