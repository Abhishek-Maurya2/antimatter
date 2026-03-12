import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:orches/models/task.dart';
import 'package:material_new_shapes/material_new_shapes.dart';
import 'package:orches/utils/ui_utils.dart';

class ListCard extends StatelessWidget {
  final String title;
  final List<Task> tasks;
  final Color? containerColor;
  final VoidCallback? onTap;

  const ListCard({
    super.key,
    required this.title,
    required this.tasks,
    this.containerColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;
    final bgColor = containerColor ?? colorTheme.surface;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
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
                    style: TextStyle(
                      fontFamily: 'GoogleSansFlex',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: colorTheme.onSurface,
                      fontVariations: const [
                        FontVariation('wght', 800),
                        FontVariation('wdth', 100),
                        FontVariation('ROND', 80),
                        FontVariation('GRAD', 0),
                        FontVariation('opsz', 22),
                        FontVariation('slnt', 0),
                      ],
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
                    style: TextStyle(
                      fontFamily: 'GoogleSansFlex',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorTheme.primary,
                      fontVariations: const [
                        FontVariation('wght', 700),
                        FontVariation('wdth', 100),
                        FontVariation('ROND', 100),
                        FontVariation('GRAD', 0),
                        FontVariation('opsz', 14),
                        FontVariation('slnt', 0),
                      ],
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
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: ClipPath(
                              clipper: PolygonClipper(MaterialShapes.sunny),
                              child: ColoredBox(
                                color: colorTheme.secondaryContainer,
                                child: Center(
                                  child: Icon(
                                    Symbols.event_available,
                                    fill: 1,
                                    weight: 300,
                                    size: 35,
                                    color: colorTheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No today tasks',
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
                        return _TaskItem(task: task);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final Task task;

  const _TaskItem({required this.task});

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + due date row
          Text(
            task.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: colorTheme.onSurface),
          ),
          if (task.deadline != null) ...[
            const SizedBox(height: 4),
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
          // Categories row - renamed from Labels
          if (task.categories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: task.categories.map((category) {
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
                      category,
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
