import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:intl/intl.dart';
import 'package:orches/models/task.dart';
import 'package:orches/screens/overview/components/status_card.dart';
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

        final todayTasks = allTasks.where((t) {
          if (t.deadline == null) return false;
          return t.deadline!.isAfter(todayStart) &&
              t.deadline!.isBefore(tomorrowStart);
        }).toList();

        final todayCompleted = todayTasks.where((t) => t.isCompleted).length;

        final weekFromToday = todayStart.add(const Duration(days: 8));
        final upcomingTasks =
            allTasks.where((t) {
              if (t.deadline == null || t.isCompleted) return false;
              return t.deadline!.isAfter(todayStart) &&
                  t.deadline!.isBefore(weekFromToday);
            }).toList()..sort((a, b) {
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
                      final isWide = constraints.maxWidth >= 760;
                      final availableWidth = constraints.maxWidth;
                      final halfWidth = (availableWidth - spacing) / 2;

                      final allCardWidth = halfWidth;
                      final completedCardWidth = halfWidth;
                      final pendingCardWidth = halfWidth;
                      final upcomingCardWidth = halfWidth;
                      final progressCardWidth = halfWidth;
                      final topCardHeight = isWide ? 180.0 : 160.0;
                      final pendingHeight = isWide ? 180.0 : 160.0;
                      final upcomingHeight = isWide ? 300.0 : 260.0;
                      final allCardHeight = topCardHeight;
                      final completedCardHeight = topCardHeight;
                      final pendingCardHeight = pendingHeight;
                      final progressCardHeight =
                          pendingCardHeight + spacing + upcomingHeight;

                      return Column(
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: allCardWidth,
                                height: allCardHeight,
                                child: StatusCard(
                                  icon: Symbols.task_alt,
                                  title: 'All Tasks',
                                  count: totalTasks,
                                  containerColor: colorTheme.surface,
                                  onTap: onNavigateToTasks,
                                ),
                              ),
                              const SizedBox(width: spacing),
                              SizedBox(
                                width: completedCardWidth,
                                height: completedCardHeight,
                                child: StatusCard(
                                  icon: Symbols.check_circle,
                                  title: 'Completed',
                                  count: completedTasks,
                                  containerColor: colorTheme.secondaryContainer,
                                  contentColor: colorTheme.onSecondaryContainer,
                                  onTap: onNavigateToTasks,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: spacing),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: pendingCardWidth,
                                child: Column(
                                  children: [
                                    SizedBox(
                                      width: pendingCardWidth,
                                      height: pendingCardHeight,
                                      child: StatusCard(
                                        icon: Symbols.pending,
                                        title: 'Pending',
                                        count: pendingTasks,
                                        containerColor:
                                            colorTheme.errorContainer,
                                        contentColor:
                                            colorTheme.onErrorContainer,
                                        onTap: onNavigateToTasks,
                                      ),
                                    ),
                                    const SizedBox(height: spacing),
                                    SizedBox(
                                      width: upcomingCardWidth,
                                      height: upcomingHeight,
                                      child: ListCard(
                                        title: 'Upcoming',
                                        tasks: upcomingTasks,
                                        onTap: onNavigateToTasks,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: spacing),
                              SizedBox(
                                width: progressCardWidth,
                                height: 280,
                                child: ProgressCard(
                                  title: "Today's Tasks",
                                  total: todayTasks.length,
                                  completed: todayCompleted,
                                  onTap: onNavigateToTasks,
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
