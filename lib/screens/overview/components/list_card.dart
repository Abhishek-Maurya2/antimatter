import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:orches/models/task.dart';

class ListCard extends StatelessWidget {
  final String title;
  final List<Task> tasks;
  final Color? containerColor;

  const ListCard({
    super.key,
    required this.title,
    required this.tasks,
    this.containerColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;
    final bgColor = containerColor ?? colorTheme.surface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorTheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (tasks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${tasks.length}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorTheme.primary,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),

          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: colorTheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Symbols.event_available,
                            fill: 1,
                            weight: 300,
                            size: 28,
                            color: colorTheme.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No upcoming tasks',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorTheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    physics: const BouncingScrollPhysics(),
                    itemCount: tasks.length,
                    separatorBuilder: (_, _2) => Divider(
                      height: 1,
                      color: colorTheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _UpcomingTaskItem(task: task);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingTaskItem extends StatelessWidget {
  final Task task;

  const _UpcomingTaskItem({required this.task});

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + due date row
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorTheme.onSurface,
                  ),
                ),
              ),
              if (task.deadline != null)
                Text(
                  _formatRelativeTime(task.deadline!),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: _isOverdue()
                        ? colorTheme.error
                        : colorTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          // Labels row
          if (task.labels.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: task.labels.map((label) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorTheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Color _getPriorityColor(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;
    if (_isOverdue()) return colorTheme.error;
    return colorTheme.primary;
  }

  bool _isOverdue() {
    if (task.deadline == null) return false;
    return task.deadline!.isBefore(DateTime.now());
  }

  String _formatRelativeTime(DateTime deadline) {
    final now = DateTime.now();
    final diff = deadline.difference(now);

    if (diff.isNegative) {
      if (diff.inDays.abs() > 0) return '${diff.inDays.abs()}d overdue';
      if (diff.inHours.abs() > 0) return '${diff.inHours.abs()}h overdue';
      return 'Just now';
    }

    if (diff.inDays > 0) {
      if (diff.inDays == 1) return 'Tomorrow';
      return 'In ${diff.inDays}d';
    }
    if (diff.inHours > 0) return 'In ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'In ${diff.inMinutes}m';
    return 'Now';
  }
}
