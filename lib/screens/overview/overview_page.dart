import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:orches/models/task.dart';
import 'package:orches/screens/overview/components/stats_card.dart';
import 'package:orches/screens/overview/components/progress_card.dart';
import 'package:orches/screens/overview/components/list_card.dart';
import 'package:orches/screens/overview/components/activity_heat_map.dart';

class OverviewPage extends StatelessWidget {
  final VoidCallback? onNavigateToTasks;

  const OverviewPage({super.key, this.onNavigateToTasks});

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;
    final tasksBox = Hive.box<Task>('tasksBox');

    return ValueListenableBuilder(
      valueListenable: tasksBox.listenable(),
      builder: (context, Box<Task> box, _) {
        final allTasks = box.values
            .where((t) => !t.isDeleted && !t.isArchived)
            .toList();
        final totalTasks = allTasks.length;
        final completedTasks = allTasks.where((t) => t.isCompleted).length;
        final pendingTasks = totalTasks - completedTasks;

        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final tomorrowStart = todayStart.add(const Duration(days: 1));

        final todayTotalTasks = allTasks.where((t) {
          if (t.deadline == null) return false;
          return t.deadline!.isAfter(todayStart) &&
              t.deadline!.isBefore(tomorrowStart);
        }).toList();

        final todayTasks = todayTotalTasks.where((t) => !t.isCompleted).toList();

        final todayCompletedCount = todayTotalTasks.where((t) => t.isCompleted).length;

        final upcomingTasks =
            allTasks.where((t) {
              return !t.isCompleted;
            }).toList()..sort((a, b) {
              if (a.deadline == null && b.deadline == null)
                return a.title.compareTo(b.title);
              if (a.deadline == null) return 1;
              if (b.deadline == null) return -1;
              final cmp = a.deadline!.compareTo(b.deadline!);
              if (cmp != 0) return cmp;
              return a.title.compareTo(b.title);
            });

        return Scaffold(
          backgroundColor: colorTheme.surfaceContainer,
          body: CustomScrollView(
            slivers: [
              // App bar area
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: TextStyle(
                            fontFamily: 'GoogleSansFlex',
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: colorTheme.onSurface,
                            fontVariations: const [
                              FontVariation('wght', 700),
                              FontVariation('wdth', 100),
                              FontVariation('ROND', 100),
                              FontVariation('GRAD', 0),
                              FontVariation('opsz', 28),
                              FontVariation('slnt', 0),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, MMMM d').format(now),
                          style: TextStyle(
                            fontFamily: 'GoogleSansFlex',
                            fontSize: 16,
                            color: colorTheme.onSurfaceVariant,
                            fontVariations: const [
                              FontVariation('wght', 400),
                              FontVariation('wdth', 100),
                              FontVariation('ROND', 50),
                              FontVariation('GRAD', 0),
                              FontVariation('opsz', 16),
                              FontVariation('slnt', 0),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bento content
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                sliver: SliverToBoxAdapter(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 12.0;
                      final upcomingHeight = 265.0;

                      return Column(
                        children: [
                          // Combined Stats Card (full width)
                          StatsCard(
                            totalTasks: totalTasks,
                            completedTasks: completedTasks,
                            pendingTasks: pendingTasks,
                            onTap: onNavigateToTasks,
                          ),
                          const SizedBox(height: spacing),
                          // Bottom row: Today's Tasks + Progress
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: upcomingHeight,
                                  child: ListCard(
                                    title: "Pending Tasks",
                                    tasks: upcomingTasks,
                                    onTap: onNavigateToTasks,
                                  ),
                                ),
                              ),
                              const SizedBox(width: spacing),
                              Expanded(
                                child: SizedBox(
                                  height: upcomingHeight,
                                  child: ProgressCard(
                                    title: "Progress",
                                    total: todayTotalTasks.length,
                                    completed: todayCompletedCount,
                                    onTap: onNavigateToTasks,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              

              // Activity Heat Map
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverToBoxAdapter(child: ActivityHeatMap()),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}