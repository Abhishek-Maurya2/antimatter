import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:antimatter/models/task.dart';

/// A GitHub-style activity heat map that shows how many tasks
/// were completed on each day over the past several months.
class ActivityHeatMap extends StatelessWidget {
  const ActivityHeatMap({super.key});

  static const double _cellSize = 20.0;
  static const double _cellGap = 6.0;
  static const double _labelWidth = 25.0;
  static const int _weeksToShow = 36; // ~6 months

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

class _HeatMapContent extends StatefulWidget {
  final Map<DateTime, int> completionMap;

  const _HeatMapContent({required this.completionMap});

  @override
  State<_HeatMapContent> createState() => _HeatMapContentState();
}

class _HeatMapContentState extends State<_HeatMapContent> {
  final ScrollController _scrollController = ScrollController();
  bool _isHovering = false;
  bool _isStatsExpanded = false;

  static const double _cellSize = ActivityHeatMap._cellSize;
  static const double _cellGap = ActivityHeatMap._cellGap;
  static const double _labelWidth = ActivityHeatMap._labelWidth;
  static const int _weeksToShow = ActivityHeatMap._weeksToShow;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final int totalCompleted = widget.completionMap.values.fold<int>(
      0,
      (a, b) => a + b,
    );
    final int todayCompleted = widget.completionMap[todayDate] ?? 0;

    int sevenDayTotal = 0;
    int activeDaysLast7 = 0;
    for (int i = 0; i < 7; i++) {
      final date = todayDate.subtract(Duration(days: i));
      final count = widget.completionMap[date] ?? 0;
      sevenDayTotal += count;
      if (count > 0) activeDaysLast7++;
    }
    final double avgPerDay = sevenDayTotal / 7;

    int currentStreak = 0;
    for (int i = 0; ; i++) {
      final date = todayDate.subtract(Duration(days: i));
      final count = widget.completionMap[date] ?? 0;
      if (count == 0) break;
      currentStreak++;
    }

    int bestDayCount = 0;
    String bestDayLabel = '-';
    if (widget.completionMap.isNotEmpty) {
      final bestDayEntry = widget.completionMap.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );
      bestDayCount = bestDayEntry.value;
      bestDayLabel = _formatDayLabel(bestDayEntry.key);
    }

    // --- NEW: Generate calendar-style grouped months ---
    final monthGroups = <_MonthGroup>[];

    // We'll show approximately _weeksToShow weeks, but grouped by month
    int monthsBack = (_weeksToShow / 4.3).ceil();

    for (int i = monthsBack; i >= 0; i--) {
      // Calculate start and end of the month
      final startOfMonth = DateTime(todayDate.year, todayDate.month - i, 1);
      final nextMonth = DateTime(startOfMonth.year, startOfMonth.month + 1, 1);
      final endOfMonth = nextMonth.subtract(const Duration(days: 1));

      final List<DateTime?> daysInBlocks = [];

      // Padding before the 1st: Monday is weekday 1
      final firstWeekday = startOfMonth.weekday;
      for (int p = 1; p < firstWeekday; p++) {
        daysInBlocks.add(null);
      }

      // Fill the days for THIS month only
      for (int d = 1; d <= endOfMonth.day; d++) {
        final currentDay = DateTime(startOfMonth.year, startOfMonth.month, d);
        if (currentDay.isAfter(todayDate)) {
          daysInBlocks.add(null);
        } else {
          daysInBlocks.add(currentDay);
        }
      }

      // Padding at the end of the month to complete the last week of the month
      while (daysInBlocks.length % 7 != 0) {
        daysInBlocks.add(null);
      }

      // Split days in blocks into weeks for this month
      final List<List<DateTime?>> weeksInMonth = [];
      for (int s = 0; s < daysInBlocks.length; s += 7) {
        weeksInMonth.add(daysInBlocks.sublist(s, s + 7));
      }

      monthGroups.add(
        _MonthGroup(
          month: startOfMonth.month,
          name: _getMonthName(startOfMonth.month),
          weeks: weeksInMonth,
        ),
      );
    }
    // ----------------------------------------------------

    // Find max value for color scaling
    final maxCount = widget.completionMap.values.fold<int>(
      1,
      (prev, val) => val > prev ? val : prev,
    );

    // Day labels for all days
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final gridHeight = _cellSize * 7 + _cellGap * 6;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
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
                    '$totalCompleted done',
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
                const SizedBox(width: 8),
                IconButtonM3E(
                  onPressed: () {
                    setState(() {
                      _isStatsExpanded = !_isStatsExpanded;
                    });
                  },
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    weight: 800,
                    size: 32,
                  ),
                  selectedIcon: const Icon(
                    Icons.keyboard_arrow_up_rounded,
                    weight: 800,
                    size: 32,
                  ),
                  isSelected: _isStatsExpanded,
                  variant: IconButtonM3EVariant.tonal,
                  backgroundColor: colorScheme.surfaceContainer,
                  width: IconButtonM3EWidth.narrow,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Today Done',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$todayCompleted ${_taskWord(todayCompleted)}',
              style: TextStyle(
                fontFamily: 'GoogleSansFlex',
                fontSize: 30,
                color: colorScheme.onSurface,
                fontVariations: const [
                  FontVariation('wght', 700),
                  FontVariation('wdth', 100),
                  FontVariation('ROND', 180),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _isStatsExpanded
                  ? Column(
                      key: const ValueKey('expanded_activity_stats'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          '7D Total: $sevenDayTotal ${_taskWord(sevenDayTotal)}',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Avg/Day: ${avgPerDay.toStringAsFixed(1)}',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Active Days (7D): $activeDaysLast7/7',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Current Streak: $currentStreak ${_dayWord(currentStreak)}',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Best Day: $bestDayCount ${_taskWord(bestDayCount)} · $bestDayLabel',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(
                      key: ValueKey('collapsed_activity_stats'),
                    ),
            ),
            const SizedBox(height: 16),

            // Combined scrollable area for headers and grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fixed Day labels column
                Padding(
                  padding: const EdgeInsets.only(top: 20), // Align with grid
                  child: SizedBox(
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
                ),
                const SizedBox(width: 8),

                // Scrollable content (Months + Grid)
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: _isHovering,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 12),
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Month names row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: monthGroups.map((group) {
                              final weeksCount = group.weeks.length;
                              final groupWidth =
                                  weeksCount * _cellSize +
                                  (weeksCount - 1) * _cellGap;
                              return SizedBox(
                                width:
                                    groupWidth + 16, // match month spacing (16)
                                child: Text(
                                  group.name,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 4),

                          // Grid rows
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: monthGroups.map((group) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: Row(
                                  spacing: _cellGap,
                                  children: group.weeks.map((week) {
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
                                        final count =
                                            widget.completionMap[day] ?? 0;
                                        return Tooltip(
                                          message: _tooltipText(day, count),
                                          child: Container(
                                            width: _cellSize,
                                            height: _cellSize,
                                            decoration: BoxDecoration(
                                              color: count == 0
                                                  ? Colors.transparent
                                                  : _getCellColor(
                                                      count,
                                                      maxCount,
                                                      colorScheme,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              border: count == 0
                                                  ? Border.all(
                                                      color: colorScheme
                                                          .outlineVariant,
                                                      width: 1,
                                                    )
                                                  : null,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  }).toList(),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
      ),
    );
  }

  Color _getCellColor(int count, int maxCount, ColorScheme colorScheme) {
    if (count == 0) {
      return Colors.transparent;
    }
    const baseColor = Color.fromARGB(255, 72, 198, 72);
    // Scale opacity from 0.2 to 1.0 based on intensity
    final opacity = 0.2 + (0.8 * count / maxCount).clamp(0.0, 1.0);
    return baseColor.withOpacity(opacity);
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

  String _getMonthName(int month) {
    const names = [
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
    return names[month - 1];
  }

  String _taskWord(int count) => count == 1 ? 'task' : 'tasks';

  String _dayWord(int count) => count == 1 ? 'day' : 'days';

  String _formatDayLabel(DateTime day) {
    const names = [
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
    return '${names[day.month - 1]} ${day.day}'.toUpperCase();
  }

  List<Widget> _buildLegendCells(ColorScheme colorScheme) {
    return [0.0, 0.3, 0.5, 0.7, 1.0].map((intensity) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          width: 19,
          height: 19,
          decoration: BoxDecoration(
            color: intensity == 0.0
                ? Colors.transparent
                : const Color(0xFF80DA88).withOpacity(0.2 + 0.8 * intensity),
            borderRadius: BorderRadius.circular(5),
            border: intensity == 0.0
                ? Border.all(color: colorScheme.outlineVariant, width: 1.5)
                : null,
          ),
        ),
      );
    }).toList();
  }
}

class _MonthGroup {
  final int month;
  final String name;
  final List<List<DateTime?>> weeks;

  _MonthGroup({required this.month, required this.name, required this.weeks});
}
