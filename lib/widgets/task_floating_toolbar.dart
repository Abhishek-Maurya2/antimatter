import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:orches/models/task.dart';

class TaskFloatingToolbar extends StatelessWidget {
  final Task task;
  final VoidCallback onComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onArchive;
  final VoidCallback onRestore;
  final VoidCallback onClose;
  final ColorScheme colorTheme;

  const TaskFloatingToolbar({
    super.key,
    required this.task,
    required this.onComplete,
    required this.onEdit,
    required this.onDelete,
    required this.onArchive,
    required this.onRestore,
    required this.onClose,
    required this.colorTheme,
  });

  Widget _buildActionIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required Color color,
    double weight = 400,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: color, weight: weight),
      tooltip: tooltip,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.isCompleted;

    return Material(
      elevation: 4,
      shadowColor: colorTheme.shadow,
      borderRadius: BorderRadius.circular(50),
      color: colorTheme.primaryContainer,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            if (task.isDeleted) ...[
              _buildActionIcon(
                icon: Symbols.restore_from_trash,
                tooltip: 'Restore Task',
                onPressed: onRestore,
                color: colorTheme.onPrimaryContainer,
              ),
            ] else ...[
              _buildActionIcon(
                icon: isCompleted ? Symbols.undo : Symbols.check,
                tooltip: isCompleted ? 'Undo Complete' : 'Mark as Complete',
                onPressed: onComplete,
                color: colorTheme.onPrimaryContainer,
                weight: 900,
              ),
              _buildActionIcon(
                icon: Symbols.edit,
                tooltip: 'Edit Task',
                onPressed: onEdit,
                color: colorTheme.onPrimaryContainer,
              ),
              _buildActionIcon(
                icon: task.isArchived ? Symbols.unarchive : Symbols.archive,
                tooltip: task.isArchived ? 'Unarchive Task' : 'Archive Task',
                onPressed: onArchive,
                color: colorTheme.onPrimaryContainer,
              ),
            ],
            _buildActionIcon(
              icon: Symbols.delete_outline,
              tooltip: task.isDeleted ? 'Delete Permanently' : 'Move to Trash',
              onPressed: onDelete,
              color: colorTheme.error,
            ),
            Container(
              decoration: BoxDecoration(
                color: colorTheme.primary,
                borderRadius: BorderRadius.circular(50),
              ),
              child: _buildActionIcon(
                icon: Symbols.close,
                tooltip: 'Close',
                onPressed: onClose,
                color: colorTheme.onPrimary,
                weight: 900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
