import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:material_new_shapes/material_new_shapes.dart';
import '../models/activity.dart';
import '../providers/activities_provider.dart';
import '../utils/ui_utils.dart';
import 'activity_editor_dialog.dart';

class DailyTrackerScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  final ValueChanged<String>? onNavigateToSession;

  const DailyTrackerScreen({super.key, this.onBack, this.onNavigateToSession});

  @override
  ConsumerState<DailyTrackerScreen> createState() => _DailyTrackerScreenState();
}

class _DailyTrackerScreenState extends ConsumerState<DailyTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  final ScrollController _dayScrollController = ScrollController();

  // Timer state for ticking the UI every second if an activity has an active session
  Timer? _tickerTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Start a periodic timer to update the running stopwatch every second
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final activities = ref.read(activitiesControllerProvider);
      final hasActive = activities.any((a) => a.activeSession != null);
      if (hasActive) {
        setState(() {}); // Rebuild UI to update elapsed timer ticks
      }
    });

    // Scroll day selector to focus today
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dayScrollController.hasClients) {
        _dayScrollController.animateTo(
          35.0 * 5, // Approximate center
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _tabController.dispose();
    _dayScrollController.dispose();
    super.dispose();
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainer,
        elevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Symbols.arrow_back_rounded),
                onPressed: widget.onBack,
              )
            : null,
        title: Text(
          'Daily Tracker',
          style: textTheme.titleLarge?.copyWith(
            fontFamily: 'GoogleSansFlex',
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'Tracker'),
            Tab(text: 'Analytics'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Symbols.calendar_today_rounded),
            tooltip: 'Go to Today',
            onPressed: () {
              final now = DateTime.now();
              _selectDate(now);
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildTrackerTab(context), _buildAnalyticsTab(context)],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          if (_tabController.index == 0) {
            return FloatingActionButton.extended(
              onPressed: () {
                ActivityEditorDialog.show(context, initialDate: _selectedDate);
              },
              icon: const Icon(Symbols.add_rounded),
              label: const Text('Add Activity'),
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ==================== TRACKER TAB ====================

  Widget _buildTrackerTab(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final activities = ref.watch(activitiesControllerProvider);
    final controller = ref.watch(activitiesControllerProvider.notifier);

    // Filter activities for selected date
    final dayActivities = activities.where((a) {
      return a.date.year == _selectedDate.year &&
          a.date.month == _selectedDate.month &&
          a.date.day == _selectedDate.day;
    }).toList();

    final streak = controller.getStreakCount();

    return RefreshIndicator(
      onRefresh: () async {
        // Just reload box data
        setState(() {});
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Streak Banner Card
          _buildStreakCard(streak, colorScheme, textTheme),
          const SizedBox(height: 16),

          // Date selector slider
          _buildDateSelector(colorScheme, textTheme),
          const SizedBox(height: 20),

          // Activities Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Activities',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                DateFormat('MMMM d, yyyy').format(_selectedDate),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (dayActivities.isEmpty)
            _buildEmptyState(context, colorScheme, textTheme)
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dayActivities.length,
              itemBuilder: (context, index) {
                final activity = dayActivities[index];
                return _ActivityCard(
                  activity: activity,
                  isFirst: index == 0,
                  isLast: index == dayActivities.length - 1,
                  onNavigateToSession: widget.onNavigateToSession,
                );
              },
            ),
          const SizedBox(height: 80), // Padding at bottom for FAB
        ],
      ),
    );
  }

  Widget _buildStreakCard(
    int streak,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          // Flashing/pulsing Fire Icon container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Symbols.local_fire_department_rounded,
              fill: 1,
              weight: 800,
              size: 40,
              color: Colors.amberAccent,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak Day Streak!',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontFamily: 'GoogleSansFlex',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  streak > 0
                      ? 'Keep it up! Complete activities to grow your fire.'
                      : 'Complete your first activity today to start a streak!',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(ColorScheme colorScheme, TextTheme textTheme) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Generates 15 days window centered on selected date
    final List<DateTime> days = List.generate(15, (index) {
      return today.subtract(Duration(days: 7 - index));
    });

    return SizedBox(
      height: 100,
      child: ListView.builder(
        controller: _dayScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected =
              day.year == _selectedDate.year &&
              day.month == _selectedDate.month &&
              day.day == _selectedDate.day;

          final isToday =
              day.year == today.year &&
              day.month == today.month &&
              day.day == today.day;

          final dayName = DateFormat(
            'E',
          ).format(day).substring(0, 1).toUpperCase();
          final dayNum = DateFormat('d').format(day);

          final BorderRadius cellBorderRadius;
          if (isSelected) {
            cellBorderRadius = BorderRadius.circular(30);
          } else if (index == 0) {
            cellBorderRadius = const BorderRadius.only(
              topLeft: Radius.circular(22),
              bottomLeft: Radius.circular(22),
              topRight: Radius.circular(6),
              bottomRight: Radius.circular(6),
            );
          } else if (index == days.length - 1) {
            cellBorderRadius = const BorderRadius.only(
              topLeft: Radius.circular(6),
              bottomLeft: Radius.circular(6),
              topRight: Radius.circular(22),
              bottomRight: Radius.circular(22),
            );
          } else {
            cellBorderRadius = BorderRadius.circular(6);
          }

          final Widget dayNameWidget;
          if (isSelected) {
            dayNameWidget = ClipPath(
              clipper: PolygonClipper(MaterialShapes.cookie4Sided),
              child: Container(
                width: 32,
                height: 32,
                color: colorScheme.primary,
                alignment: Alignment.center,
                child: Text(
                  dayName,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          } else {
            dayNameWidget = Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              child: Text(
                dayName,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          final Widget dayNumWidget;
          if (isSelected) {
            dayNumWidget = Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                dayNum,
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'GoogleSansFlex',
                ),
              ),
            );
          } else {
            dayNumWidget = Padding(
              padding: const EdgeInsets.symmetric(vertical: 7.0),
              child: Text(
                dayNum,
                style: textTheme.titleMedium?.copyWith(
                  color: isToday ? colorScheme.primary : colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'GoogleSansFlex',
                ),
              ),
            );
          }

          return GestureDetector(
            onTap: () => _selectDate(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: 55,
              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primaryContainer.withValues(alpha: 0.4)
                    : (isToday
                          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                          : colorScheme.surfaceContainerHigh),
                borderRadius: cellBorderRadius,
                border: isToday && !isSelected
                    ? Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.4),
                        width: 1.5,
                    )
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  dayNameWidget,
                  const SizedBox(height: 4),
                  dayNumWidget,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Center(
      child: Card(
        color: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: const EdgeInsets.symmetric(vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Symbols.view_agenda_rounded,
                size: 64,
                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'No activities scheduled',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add an activity to stay productive and track your focus hours throughout the day.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              ButtonM3E(
                onPressed: () {
                  ActivityEditorDialog.show(
                    context,
                    initialDate: _selectedDate,
                  );
                },
                style: ButtonM3EStyle.tonal,
                shape: ButtonM3EShape.round,
                label: const Text('Create Activity'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== ANALYTICS TAB ====================

  String _analyticsFilter = 'Weekly'; // 'Weekly' or 'Monthly'

  Widget _buildAnalyticsTab(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final activities = ref.watch(activitiesControllerProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Filter Selector
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('Weekly Wise'),
              selected: _analyticsFilter == 'Weekly',
              onSelected: (selected) {
                if (selected) setState(() => _analyticsFilter = 'Weekly');
              },
            ),
            const SizedBox(width: 12),
            ChoiceChip(
              label: const Text('Monthly Wise'),
              selected: _analyticsFilter == 'Monthly',
              onSelected: (selected) {
                if (selected) setState(() => _analyticsFilter = 'Monthly');
              },
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 1. Chart: Activity Duration (Weekly Bar or Monthly Line)
        Card(
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _analyticsFilter == 'Weekly'
                      ? 'Weekly Tracked Minutes'
                      : 'Monthly Trend (Mins)',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: _analyticsFilter == 'Weekly'
                      ? CustomPaint(
                          size: Size.infinite,
                          painter: WeeklyBarChartPainter(
                            activities: activities,
                            colorScheme: colorScheme,
                          ),
                        )
                      : CustomPaint(
                          size: Size.infinite,
                          painter: MonthlyLineChartPainter(
                            activities: activities,
                            colorScheme: colorScheme,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 2. Chart: Time Breakdown (Donut chart showing where time was spent)
        Card(
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Time Breakdown (Activities)',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                _buildBreakdownChart(activities, colorScheme, textTheme),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildBreakdownChart(
    List<Activity> activities,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    // Calculate total duration (seconds) grouped by Activity title
    final breakdown = <String, int>{};
    int totalTime = 0;

    // Filter by filter range
    final now = DateTime.now();
    final cutoffDate = _analyticsFilter == 'Weekly'
        ? now.subtract(const Duration(days: 7))
        : now.subtract(const Duration(days: 30));

    for (final act in activities) {
      if (act.date.isAfter(cutoffDate)) {
        final seconds = act.totalTrackedSeconds;
        if (seconds > 0) {
          breakdown[act.title] = (breakdown[act.title] ?? 0) + seconds;
          totalTime += seconds;
        }
      }
    }

    if (totalTime == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Text(
            'No tracked time recorded in this period.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final dataList = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Custom palettes
    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      colorScheme.error,
      Colors.indigo,
      Colors.teal,
      Colors.amber,
    ];

    return Row(
      children: [
        // Donut Chart
        SizedBox(
          width: 140,
          height: 140,
          child: CustomPaint(
            painter: DonutChartPainter(
              data: dataList.map((e) => e.value.toDouble()).toList(),
              colors: colors,
              colorScheme: colorScheme,
            ),
          ),
        ),
        const SizedBox(width: 20),
        // Legend
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(dataList.length.clamp(0, 5), (index) {
              final entry = dataList[index];
              final color = colors[index % colors.length];
              final percent = (entry.value / totalTime * 100).toStringAsFixed(
                1,
              );
              final mins = entry.value ~/ 60;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${mins}m ($percent%)',
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ==================== ACTIVITY CARD ====================

class _ActivityCard extends ConsumerStatefulWidget {
  final Activity activity;
  final bool isFirst;
  final bool isLast;
  final ValueChanged<String>? onNavigateToSession;

  const _ActivityCard({
    required this.activity,
    required this.isFirst,
    required this.isLast,
    this.onNavigateToSession,
  });

  @override
  ConsumerState<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends ConsumerState<_ActivityCard> {
  bool _isExpanded = false;
  final TextEditingController _taskController = TextEditingController();

  String _formatSeconds(int totalSecs) {
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    if (mins == 0) return '${secs}s';
    return '${mins}m ${secs}s';
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes mins';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final activity = widget.activity;

    final targetSeconds = activity.targetDurationMinutes * 60;
    final trackedSeconds = activity.totalTrackedSeconds;
    final progressFactor = (trackedSeconds / targetSeconds).clamp(0.0, 1.0);
    final progressPercent = (progressFactor * 100).toInt();

    final activeSession = activity.activeSession;
    final isTimerRunning = activeSession != null;

    final completedTasks = activity.tasks.where((t) => t.isCompleted).length;
    final totalTasks = activity.tasks.length;

    final bool isPopOut = _isExpanded || isTimerRunning;
    final BorderRadius cardBorderRadius;
    if (isPopOut) {
      cardBorderRadius = BorderRadius.circular(24);
    } else if (widget.isFirst && widget.isLast) {
      cardBorderRadius = BorderRadius.circular(24);
    } else if (widget.isFirst) {
      cardBorderRadius = const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
        bottomLeft: Radius.circular(6),
        bottomRight: Radius.circular(6),
      );
    } else if (widget.isLast) {
      cardBorderRadius = const BorderRadius.only(
        topLeft: Radius.circular(6),
        topRight: Radius.circular(6),
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      );
    } else {
      cardBorderRadius = BorderRadius.circular(6);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.symmetric(vertical: isPopOut ? 6 : 2),
      decoration: BoxDecoration(
        color: isTimerRunning
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surface,
        borderRadius: cardBorderRadius,
        border: isTimerRunning
            ? Border.all(color: colorScheme.primary, width: 2)
            : null,
        boxShadow: isPopOut
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: cardBorderRadius,
        child: Column(
          children: [
          // Primary header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
            child: Row(
              children: [
                // 1. Progress Indicator Ring
                GestureDetector(
                  onTap: () {
                    ref
                        .read(activitiesControllerProvider.notifier)
                        .updateActivity(
                          activity,
                          isCompleted: !activity.isCompleted,
                        );
                  },
                  child: Tooltip(
                    message: '$progressPercent% of target completed',
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: CircularProgressIndicator(
                            value: progressFactor,
                            strokeWidth: 5,
                            backgroundColor: colorScheme.primary.withValues(
                              alpha: 0.15,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              activity.isCompleted
                                  ? Colors.green
                                  : colorScheme.primary,
                            ),
                          ),
                        ),
                        Icon(
                          activity.isCompleted
                              ? Symbols.check_circle_rounded
                              : (isTimerRunning
                                    ? Symbols.pause_rounded
                                    : Symbols.timer_rounded),
                          fill: activity.isCompleted ? 1 : 0,
                          size: 24,
                          color: activity.isCompleted
                              ? Colors.green
                              : (isTimerRunning
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // 2. Info text area
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: activity.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: activity.isCompleted
                              ? colorScheme.onSurfaceVariant.withOpacity(0.6)
                              : colorScheme.onSurface,
                        ),
                      ),
                      if (activity.description != null &&
                          activity.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          activity.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Symbols.schedule_rounded,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Target: ${_formatDuration(activity.targetDurationMinutes)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (totalTasks > 0) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Symbols.playlist_add_check_rounded,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$completedTasks/$totalTasks tasks',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. Action controls
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Ticking / Saved timer label
                    Text(
                      _formatSeconds(trackedSeconds),
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isTimerRunning
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        fontFamily: 'GoogleSansFlex',
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Action controls
                    Row(
                      children: [
                        // Play/Pause Session Timer
                        IconButton(
                          icon: Icon(
                            isTimerRunning
                                ? Symbols.pause_circle_rounded
                                : Symbols.play_circle_rounded,
                            fill: 1,
                            size: 28,
                            color: isTimerRunning
                                ? colorScheme.error
                                : colorScheme.primary,
                          ),
                          onPressed: () {
                            final notifier = ref.read(
                              activitiesControllerProvider.notifier,
                            );
                            if (isTimerRunning) {
                              notifier.stopSession(activity);
                            } else {
                              notifier.startSession(activity);
                              widget.onNavigateToSession?.call(activity.id);
                            }
                          },
                        ),
                        // Expand Details Arrow
                        IconButton(
                          icon: Icon(
                            _isExpanded
                                ? Symbols.keyboard_arrow_up_rounded
                                : Symbols.keyboard_arrow_down_rounded,
                          ),
                          onPressed: () {
                            setState(() {
                              _isExpanded = !_isExpanded;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Collapsible Expanded tasks list & details
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Task Header / Add button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sub-tasks',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Options popup menu
                      PopupMenuButton<String>(
                        icon: const Icon(Symbols.more_horiz_rounded, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 120,
                          maxWidth: 120,
                        ),
                        onSelected: (val) async {
                          final notifier = ref.read(
                            activitiesControllerProvider.notifier,
                          );
                          if (val == 'edit') {
                            ActivityEditorDialog.show(
                              context,
                              activity: activity,
                              initialDate: activity.date,
                            );
                          } else if (val == 'delete') {
                            bool deleteAllFuture = false;
                            if (activity.repeatGroupId != null) {
                              final choice = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Activity'),
                                  content: const Text(
                                    'Do you want to delete this activity instance only, or this and all future instances in the recurrence series?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('This instance only'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('All future instances'),
                                    ),
                                  ],
                                ),
                              );
                              if (choice == null) return; // cancelled
                              deleteAllFuture = choice;
                            }
                            await notifier.deleteActivity(
                              activity,
                              deleteAllFuture: deleteAllFuture,
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Symbols.edit_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Symbols.delete_rounded,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Subtasks checklists
                  if (activity.tasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'No sub-tasks added yet.',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    ...activity.tasks.map((task) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: Checkbox(
                                value: task.isCompleted,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (_) {
                                  ref
                                      .read(
                                        activitiesControllerProvider.notifier,
                                      )
                                      .toggleSubTask(activity, task.id);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                task.title,
                                style: textTheme.bodyMedium?.copyWith(
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: task.isCompleted
                                      ? colorScheme.onSurfaceVariant
                                            .withOpacity(0.6)
                                      : colorScheme.onSurface,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Symbols.delete_rounded,
                                size: 18,
                              ),
                              onPressed: () {
                                ref
                                    .read(activitiesControllerProvider.notifier)
                                    .deleteSubTask(activity, task.id);
                              },
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 8),
                  // Add task input bar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _taskController,
                          decoration: InputDecoration(
                            hintText: 'Add a sub-task...',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              ref
                                  .read(activitiesControllerProvider.notifier)
                                  .addSubTask(activity, val.trim());
                              _taskController.clear();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Symbols.add_circle_rounded, size: 28),
                        color: colorScheme.primary,
                        onPressed: () {
                          if (_taskController.text.trim().isNotEmpty) {
                            ref
                                .read(activitiesControllerProvider.notifier)
                                .addSubTask(
                                  activity,
                                  _taskController.text.trim(),
                                );
                            _taskController.clear();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }
}

// ==================== CUSTOM PAINTER CHARTS ====================

// 1. Weekly Bar Chart Painter
class WeeklyBarChartPainter extends CustomPainter {
  final List<Activity> activities;
  final ColorScheme colorScheme;

  WeeklyBarChartPainter({required this.activities, required this.colorScheme});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Calculate last 7 days completed minutes
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final dailyMins = <DateTime, double>{};
    for (int i = 6; i >= 0; i--) {
      dailyMins[today.subtract(Duration(days: i))] = 0;
    }

    for (final act in activities) {
      final actDay = DateTime(act.date.year, act.date.month, act.date.day);
      if (dailyMins.containsKey(actDay)) {
        dailyMins[actDay] =
            (dailyMins[actDay] ?? 0) + (act.totalTrackedSeconds / 60.0);
      }
    }

    final data = dailyMins.entries.toList();
    double maxVal = 60.0; // Min scale of 60 mins
    for (final entry in data) {
      if (entry.value > maxVal) maxVal = entry.value;
    }

    // Grid details
    const double paddingLeft = 30.0;
    const double paddingBottom = 24.0;
    final chartHeight = size.height - paddingBottom;
    final chartWidth = size.width - paddingLeft;
    final barWidth = (chartWidth / 7) * 0.5;
    final spacing = (chartWidth / 7);

    // Draw Y-axis labels and lines
    final gridLineCount = 3;
    paint.color = colorScheme.onSurfaceVariant.withOpacity(0.1);
    for (int i = 0; i <= gridLineCount; i++) {
      final y = chartHeight - (i * chartHeight / gridLineCount);
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width, y), paint);

      // Y Label
      final labelVal = (i * maxVal / gridLineCount).toInt();
      textPainter.text = TextSpan(
        text: '${labelVal}m',
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 6));
    }

    // Draw Bars
    for (int i = 0; i < 7; i++) {
      final entry = data[i];
      final val = entry.value;
      final x = paddingLeft + (i * spacing) + (spacing - barWidth) / 2;

      final barHeight = (val / maxVal) * chartHeight;
      final y = chartHeight - barHeight;

      // Color selection (today gets special color)
      final isToday = entry.key.day == today.day;
      paint.color = isToday
          ? colorScheme.primary
          : colorScheme.primary.withOpacity(0.5);

      // Capsule shape for bar (RRect)
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x,
          y.clamp(0.0, chartHeight - 4),
          barWidth,
          barHeight.clamp(4.0, chartHeight),
        ),
        const Radius.circular(8),
      );
      canvas.drawRRect(rrect, paint);

      // Day labels
      final dayStr = DateFormat('E').format(entry.key).substring(0, 1);
      textPainter.text = TextSpan(
        text: dayStr,
        style: TextStyle(
          color: isToday ? colorScheme.primary : colorScheme.onSurfaceVariant,
          fontSize: 10,
          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + (barWidth - textPainter.width) / 2, chartHeight + 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant WeeklyBarChartPainter oldDelegate) => true;
}

// 2. Monthly Line Chart Painter
class MonthlyLineChartPainter extends CustomPainter {
  final List<Activity> activities;
  final ColorScheme colorScheme;

  MonthlyLineChartPainter({
    required this.activities,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Group last 30 days
    final dailyMins = <DateTime, double>{};
    for (int i = 29; i >= 0; i--) {
      dailyMins[today.subtract(Duration(days: i))] = 0;
    }

    for (final act in activities) {
      final actDay = DateTime(act.date.year, act.date.month, act.date.day);
      if (dailyMins.containsKey(actDay)) {
        dailyMins[actDay] =
            (dailyMins[actDay] ?? 0) + (act.totalTrackedSeconds / 60.0);
      }
    }

    final data = dailyMins.entries.toList();
    double maxVal = 60.0;
    for (final entry in data) {
      if (entry.value > maxVal) maxVal = entry.value;
    }

    const double paddingLeft = 32.0;
    const double paddingBottom = 24.0;
    final chartHeight = size.height - paddingBottom;
    final chartWidth = size.width - paddingLeft;
    final spacing = chartWidth / 29;

    final paint = Paint()..isAntiAlias = true;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw grid
    paint.color = colorScheme.onSurfaceVariant.withOpacity(0.08);
    for (int i = 0; i <= 3; i++) {
      final y = chartHeight - (i * chartHeight / 3);
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width, y), paint);

      // Y Label
      final labelVal = (i * maxVal / 3).toInt();
      textPainter.text = TextSpan(
        text: '${labelVal}m',
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 6));
    }

    // Line Path
    final path = Path();
    final fillPath = Path();

    // Start fill path at bottom-left corner of chart
    fillPath.moveTo(paddingLeft, chartHeight);

    for (int i = 0; i < 30; i++) {
      final entry = data[i];
      final val = entry.value;
      final x = paddingLeft + (i * spacing);
      final y = chartHeight - (val / maxVal) * chartHeight;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.lineTo(x, y);
      } else {
        // Smooth line using bezier
        final prevX = paddingLeft + ((i - 1) * spacing);
        final prevVal = data[i - 1].value;
        final prevY = chartHeight - (prevVal / maxVal) * chartHeight;

        // Control points
        final cx1 = prevX + (x - prevX) / 2;
        final cy1 = prevY;
        final cx2 = prevX + (x - prevX) / 2;
        final cy2 = y;

        path.cubicTo(cx1, cy1, cx2, cy2, x, y);
        fillPath.cubicTo(cx1, cy1, cx2, cy2, x, y);
      }
    }

    // Close fill path
    fillPath.lineTo(paddingLeft + (29 * spacing), chartHeight);
    fillPath.close();

    // 1. Draw Fill under line
    final gradient = LinearGradient(
      colors: [
        colorScheme.primary.withOpacity(0.25),
        colorScheme.primary.withOpacity(0.0),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    paint.shader = gradient.createShader(
      Rect.fromLTRB(paddingLeft, 0, size.width, chartHeight),
    );
    paint.style = PaintingStyle.fill;
    canvas.drawPath(fillPath, paint);
    paint.shader = null; // Clear shader

    // 2. Draw Stroke line
    paint.color = colorScheme.primary;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3.0;
    canvas.drawPath(path, paint);

    // 3. Draw dates on X-axis (start, middle, end)
    final labelIndexes = [0, 14, 29];
    for (final idx in labelIndexes) {
      final entry = data[idx];
      final x = paddingLeft + (idx * spacing);
      final dateStr = DateFormat('d MMM').format(entry.key);
      textPainter.text = TextSpan(
        text: dateStr,
        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 8),
      );
      textPainter.layout();

      // Adjust offset for end labels
      double alignOffset = textPainter.width / 2;
      if (idx == 0) alignOffset = 0;
      if (idx == 29) alignOffset = textPainter.width;

      textPainter.paint(canvas, Offset(x - alignOffset, chartHeight + 6));
    }
  }

  @override
  bool shouldRepaint(covariant MonthlyLineChartPainter oldDelegate) => true;
}

// 3. Donut Chart Painter
class DonutChartPainter extends CustomPainter {
  final List<double> data;
  final List<Color> colors;
  final ColorScheme colorScheme;

  DonutChartPainter({
    required this.data,
    required this.colors,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22.0
      ..isAntiAlias = true;

    final double total = data.fold(0, (prev, val) => prev + val);
    if (total == 0) return;

    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (size.width - 24) / 2,
    );

    double startAngle = -3.14159 / 2; // Start at top center

    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i] / total) * 2 * 3.14159;
      paint.color = colors[i % colors.length];
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) => true;
}
