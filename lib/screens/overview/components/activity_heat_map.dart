import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:orches/models/task.dart';

/// A GitHub-style activity heat map that shows how many tasks
/// were completed on each day over the past several months.
class ActivityHeatMap extends StatelessWidget {
  const ActivityHeatMap({super.key});

  static const double _cellSize = 14.0;
  static const double _cellGap = 3.0;
  static const double _labelWidth = 28.0;
  static const int _weeksToShow = 26; // ~6 months

  @override
  Widget build(BuildContext context) {
    final tasksBox = Hive.box<Task>('tasksBox');

    return ValueListenableBuilder(
      valueListenable: tasksBox.listenable(),
      builder: (context, Box<Task> box, _) {
        final completionMap = _buildCompletionMap(box);
        return _HeatMapContent(completionMap: completionMap);
      },
    );
  }

  /// Groups completed tasks by date and returns
  /// { DateTime(year,month,day) : count }
  Map<DateTime, int> _buildCompletionMap(Box<Task> box) {
    final map = <DateTime, int>{};
    for (final task in box.values) {
      if (!task.isCompleted) continue;
      // Use completedAt if available, otherwise fall back to deadline
      final date = task.completedAt ?? task.deadline;
      if (date == null) continue;
      final key = DateTime(date.year, date.month, date.day);
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }
}

class _HeatMapContent extends StatelessWidget {
  final Map<DateTime, int> completionMap;

  const _HeatMapContent({required this.completionMap});

  static const double _cellSize = ActivityHeatMap._cellSize;
  static const double _cellGap = ActivityHeatMap._cellGap;
  static const double _labelWidth = ActivityHeatMap._labelWidth;
  static const int _weeksToShow = ActivityHeatMap._weeksToShow;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Find the Monday of the current week
    final currentWeekMonday = todayDate.subtract(
      Duration(days: todayDate.weekday - 1),
    );
    // Go back _weeksToShow weeks
    final startDate = currentWeekMonday.subtract(
      Duration(days: (_weeksToShow - 1) * 7),
    );

    // Build the list of weeks (each week = list of 7 days)
    final weeks = <List<DateTime?>>[];
    var weekStart = startDate;
    while (!weekStart.isAfter(currentWeekMonday)) {
      final week = <DateTime?>[];
      for (int d = 0; d < 7; d++) {
        final day = weekStart.add(Duration(days: d));
        if (day.isAfter(todayDate)) {
          week.add(null); // future days
        } else {
          week.add(day);
        }
      }
      weeks.add(week);
      weekStart = weekStart.add(const Duration(days: 7));
    }

    // Find max value for color scaling
    final maxCount = completionMap.values.fold<int>(
      1,
      (prev, val) => val > prev ? val : prev,
    );

    // Day labels (only show Mon, Wed, Fri for compactness)
    final dayLabels = ['M', '', 'W', '', 'F', '', ''];

    // Build month labels
    final monthLabels = _buildMonthLabels(weeks);

    final gridHeight = _cellSize * 7 + _cellGap * 6;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Activity',
                style: TextStyle(
                  fontFamily: 'GoogleSansFlex',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  fontVariations: const [
                    FontVariation('wght', 600),
                    FontVariation('wdth', 100),
                    FontVariation('ROND', 80),
                    FontVariation('GRAD', 0),
                    FontVariation('opsz', 18),
                    FontVariation('slnt', 0),
                  ],
                ),
              ),
              const Spacer(),
              // Summary chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${completionMap.values.fold<int>(0, (a, b) => a + b)} done',
                  style: TextStyle(
                    fontFamily: 'GoogleSansFlex',
                    fontSize: 12,
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                    fontVariations: const [
                      FontVariation('wght', 600),
                      FontVariation('wdth', 100),
                      FontVariation('ROND', 100),
                      FontVariation('GRAD', 0),
                      FontVariation('opsz', 12),
                      FontVariation('slnt', 0),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Month header row
          SizedBox(
            height: 16,
            child: Row(
              children: [
                SizedBox(width: _labelWidth + 4),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      children: monthLabels.map((label) {
                        return SizedBox(
                          width: _cellSize + _cellGap,
                          child: label != null
                              ? Text(
                                  label,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 10,
                                  ),
                                )
                              : null,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Heat map grid
          SizedBox(
            height: gridHeight,
            child: Row(
              children: [
                // Day labels column
                SizedBox(
                  width: _labelWidth,
                  height: gridHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) {
                      return SizedBox(
                        height: _cellSize,
                        child: Center(
                          child: Text(
                            dayLabels[i],
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 4),

                // Scrollable grid
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true, // scroll to show most recent first
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: _cellGap,
                      children: weeks.map((week) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          spacing: _cellGap,
                          children: week.map((day) {
                            if (day == null) {
                              return SizedBox(
                                width: _cellSize,
                                height: _cellSize,
                              );
                            }
                            final count = completionMap[day] ?? 0;
                            return Tooltip(
                              message: _tooltipText(day, count),
                              child: Container(
                                width: _cellSize,
                                height: _cellSize,
                                decoration: BoxDecoration(
                                  color: _getCellColor(
                                    count,
                                    maxCount,
                                    colorScheme,
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Less',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 4),
              ..._buildLegendCells(colorScheme),
              const SizedBox(width: 4),
              Text(
                'More',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCellColor(int count, int maxCount, ColorScheme colorScheme) {
    if (count == 0) {
      return colorScheme.surfaceContainerHighest;
    }
    // Scale opacity from 0.3 to 1.0
    final intensity = 0.3 + (0.7 * count / maxCount);
    return Color.lerp(
      colorScheme.surfaceContainerHighest,
      colorScheme.primary,
      intensity,
    )!;
  }

  String _tooltipText(DateTime day, int count) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dayStr = '${months[day.month - 1]} ${day.day}, ${day.year}';
    if (count == 0) return 'No tasks on $dayStr';
    if (count == 1) return '1 task on $dayStr';
    return '$count tasks on $dayStr';
  }

  List<String?> _buildMonthLabels(List<List<DateTime?>> weeks) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final labels = <String?>[];
    int? lastMonth;
    for (final week in weeks) {
      // Use the Monday of each week
      final monday = week.firstWhere((d) => d != null, orElse: () => null);
      if (monday != null && monday.month != lastMonth) {
        labels.add(months[monday.month - 1]);
        lastMonth = monday.month;
      } else {
        labels.add(null);
      }
    }
    return labels;
  }

  List<Widget> _buildLegendCells(ColorScheme colorScheme) {
    return [0.0, 0.3, 0.5, 0.7, 1.0].map((intensity) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: intensity == 0.0
                ? colorScheme.surfaceContainerHighest
                : Color.lerp(
                    colorScheme.surfaceContainerHighest,
                    colorScheme.primary,
                    0.3 + 0.7 * intensity,
                  )!,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
    }).toList();
  }
}
