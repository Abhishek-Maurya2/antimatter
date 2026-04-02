import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:antimatter/models/task.dart';

class TaskFloatingToolbar extends StatelessWidget {
  final List<Task> tasks;
  final VoidCallback onComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onArchive;
  final VoidCallback onRestore;
  final VoidCallback onClose;
  final ColorScheme colorTheme;

  const TaskFloatingToolbar({
    super.key,
    required this.tasks,
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
    double weight = 800,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: color, weight: weight),
      tooltip: tooltip,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    final isCompleted = tasks.every((t) => t.isCompleted);
    final isDeleted = tasks.every((t) => t.isDeleted);
    final isArchived = tasks.every((t) => t.isArchived);

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
            if (isDeleted) ...[
              _buildActionIcon(
                icon: Symbols.restore_from_trash_rounded,
                tooltip: 'Restore Task',
                onPressed: onRestore,
                color: colorTheme.onPrimaryContainer,
              ),
            ] else ...[
              _buildActionIcon(
                icon: isCompleted
                    ? Symbols.undo_rounded
                    : Symbols.check_rounded,
                tooltip: isCompleted ? 'Undo Complete' : 'Mark as Complete',
                onPressed: onComplete,
                color: colorTheme.onPrimaryContainer,
                weight: 900,
              ),
              if (tasks.length == 1)
                _buildActionIcon(
                  icon: Symbols.edit_rounded,
                  tooltip: 'Edit Task',
                  onPressed: onEdit,
                  color: colorTheme.onPrimaryContainer,
                ),
              _buildActionIcon(
                icon: isArchived
                    ? Symbols.unarchive_rounded
                    : Symbols.archive_rounded,
                tooltip: isArchived ? 'Unarchive Task' : 'Archive Task',
                onPressed: onArchive,
                color: colorTheme.onPrimaryContainer,
              ),
            ],
            _buildActionIcon(
              icon: Symbols.delete_rounded,
              tooltip: isDeleted ? 'Delete Permanently' : 'Move to Trash',
              onPressed: onDelete,
              color: colorTheme.error,
            ),
            Container(
              decoration: BoxDecoration(
                color: colorTheme.primary,
                borderRadius: BorderRadius.circular(50),
              ),
              child: _buildActionIcon(
                icon: Symbols.close_rounded,
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
