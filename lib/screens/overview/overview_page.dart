import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:intl/intl.dart';
import 'package:orches/models/task.dart';
import 'package:orches/screens/overview/components/status_card.dart';
import 'package:orches/screens/overview/components/progress_card.dart';
import 'package:orches/screens/overview/components/list_card.dart';

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
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorTheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, MMMM d').format(now),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: colorTheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Staggered grid content
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.crossAxisExtent;
                    final crossAxisCount = width >= 600 ? 3 : 2;

                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.1,
                      ),
                      delegate: SliverChildListDelegate([
                        // All Tasks card
                        StatusCard(
                          icon: Symbols.task_alt,
                          title: 'All Tasks',
                          count: totalTasks,
                          containerColor: colorTheme.surfaceContainerHighest,
                          onTap: onNavigateToTasks,
                        ),
                        // Completed card
                        StatusCard(
                          icon: Symbols.check_circle,
                          title: 'Completed',
                          count: completedTasks,
                          containerColor: colorTheme.secondaryContainer,
                          contentColor: colorTheme.onSecondaryContainer,
                        ),
                        // Pending card
                        StatusCard(
                          icon: Symbols.pending,
                          title: 'Pending',
                          count: pendingTasks,
                          containerColor: colorTheme.errorContainer,
                          contentColor: colorTheme.onErrorContainer,
                        ),
                      ]),
                    );
                  },
                ),
              ),

              // Today's Progress
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: ProgressCard(
                    title: "Today's Tasks",
                    total: todayTasks.length,
                    completed: todayCompleted,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Upcoming Tasks List
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverToBoxAdapter(
                  child: ListCard(
                    title: 'Upcoming Tasks',
                    tasks: upcomingTasks,
                  ),
                ),
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
