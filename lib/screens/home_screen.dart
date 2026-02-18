import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'settings_screen.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/services.dart';
import 'package:settings_tiles/settings_tiles.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isGridView = false;

  final List<Task> _tasks = [
    Task(
      id: '1',
      title: 'Complete Project Proposal',
      description: 'Draft the initial requirements and timeline.',
      isCompleted: false,
      deadline: DateTime(2026, 2, 21, 11, 23),
      subTasks: [
        Task(id: '1-1', title: 'Draft Introduction', isCompleted: true),
        Task(id: '1-2', title: 'Budget Analysis', isCompleted: false),
      ],
    ),
    Task(
      id: '2',
      title: 'Review Pull Requests',
      description: 'Check the latest changes in the main repository.',
      isCompleted: true,
      deadline: DateTime(2026, 2, 19, 16, 0),
    ),
    Task(
      id: '3',
      title: 'Team Meeting',
      description: 'Discuss the roadmap for Q4.',
      isCompleted: false,
      deadline: DateTime(2026, 2, 20, 9, 30),
    ),
    Task(
      id: '4',
      title: 'Team rest',
      description: 'this is a description',
      isCompleted: false,
    ),
    Task(id: '5', title: 'Title 2', isCompleted: true),
    Task(
      id: '6',
      title: 'Grocery Shopping',
      description: 'Buy milk, eggs, and bread.',
      isCompleted: false,
      deadline: DateTime(2026, 2, 22, 18, 0),
    ),
    Task(
      id: '7',
      title: 'Gym Workout',
      isCompleted: true,
      subTasks: [
        Task(id: '7-1', title: 'Warm up', isCompleted: true),
        Task(id: '7-2', title: 'Cardio', isCompleted: true),
        Task(id: '7-3', title: 'Weights', isCompleted: true),
      ],
    ),
    Task(
      id: '8',
      title: 'Call Mom',
      description: 'Catch up on family news.',
      isCompleted: false,
    ),
    Task(
      id: '9',
      title: 'Pay Bills',
      description: 'Electricity and Internet bills due.',
      isCompleted: true,
      deadline: DateTime(2026, 2, 15, 10, 0),
    ),
    Task(
      id: '10',
      title: 'Read Book',
      description: 'Finish reading "Clean Code".',
      isCompleted: false,
      subTasks: [
        Task(id: '10-1', title: 'Chapter 5', isCompleted: true),
        Task(id: '10-2', title: 'Chapter 6', isCompleted: false),
      ],
    ),
    Task(
      id: '11',
      title: 'Water Plants',
      isCompleted: false,
      deadline: DateTime(2026, 2, 23, 8, 30),
    ),
    Task(id: '12', title: 'Schedule Dentist Appointment', isCompleted: true),
    Task(
      id: '13',
      title: 'Plan Weekend Trip',
      description: 'Look for hotels and flights.',
      isCompleted: false,
      subTasks: [
        Task(id: '13-1', title: 'Book Flight', isCompleted: false),
        Task(id: '13-2', title: 'Book Hotel', isCompleted: false),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: colorTheme.surfaceContainer,
      drawer: _buildDrawer(context, colorTheme),
      body: CustomRefreshIndicator(
        onRefresh: () async {
          // Simulate network refresh
          await Future.delayed(const Duration(seconds: 3));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Tasks refreshed'),
                behavior: SnackBarBehavior.floating,
                width: 500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        builder: (context, child, controller) {
          return Stack(
            children: [
              child,
              AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final double opacity = (controller.value * 2).clamp(0.0, 1.0);
                  final double scale = (controller.value * 1.5).clamp(0.0, 1.0);

                  return Positioned(
                    top: 110 * controller.value, // Move down as we pull
                    left: 0,
                    right: 0,
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorTheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: ExpressiveLoadingIndicator(
                                activeSize: 52,
                                color: colorTheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
        child: CustomScrollView(
          slivers: [
            // Search bar app bar
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(1, 8, 16, 8),
                  child: Row(
                    children: [
                      // Hamburger menu
                      IconButton(
                        onPressed: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                        icon: Icon(
                          Symbols.menu,
                          fill: 0,
                          weight: 400,
                          color: colorTheme.onSurface,
                        ),
                      ),
                      // Search bar
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorTheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.centerLeft,
                          height: 58,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search Tasks',
                              hintStyle: TextStyle(
                                color: colorTheme.onSurfaceVariant,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              color: colorTheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Avatar → Settings
                      Padding(
                        padding: const EdgeInsets.only(right: 0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: colorTheme.primaryContainer,
                            child: Text(
                              'A',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: colorTheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            if (_tasks.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(context, colorTheme),
              )
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    children: [
                      if (_tasks.where((t) => !t.isCompleted).isNotEmpty) ...[
                        SettingSection(
                          title: Padding(
                            padding: const EdgeInsets.only(
                              left: 0,
                              bottom: 8,
                              top: 8,
                            ),
                            child: Text(
                              'Active',
                              style: TextStyle(
                                color: colorTheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          styleTile: true,
                          tiles: _tasks.where((t) => !t.isCompleted).map((
                            task,
                          ) {
                            return TaskTile(
                              title: Text(task.title),
                              description:
                                  task.description != null &&
                                      task.description!.isNotEmpty
                                  ? Text(task.description!)
                                  : null,
                              deadline: task.deadline != null
                                  ? Text(formatDeadline(task.deadline)!)
                                  : null,
                              subTasks: task.subTasks.map((subTask) {
                                return TaskTile(
                                  backgroundColor:
                                      colorTheme.surfaceContainerHigh,
                                  title: Text(
                                    subTask.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  description:
                                      subTask.description != null &&
                                          subTask.description!.isNotEmpty
                                      ? Text(
                                          subTask.description!,
                                          style: TextStyle(fontSize: 12),
                                        )
                                      : null,
                                  checked: subTask.isCompleted,
                                  onChanged: (value) {
                                    setState(() {
                                      subTask.isCompleted = value ?? false;
                                    });
                                  },
                                );
                              }).toList(),
                              checked: task.isCompleted,
                              onChanged: (value) {
                                setState(() {
                                  task.isCompleted = value ?? false;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 16),
                      ],
                      if (_tasks.where((t) => t.isCompleted).isNotEmpty)
                        SettingSection(
                          title: Padding(
                            padding: const EdgeInsets.only(left: 0, bottom: 8),
                            child: Text(
                              'Completed',
                              style: TextStyle(
                                color: colorTheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          styleTile: true,
                          tiles: _tasks.where((t) => t.isCompleted).map((task) {
                            return TaskTile(
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: colorTheme.onSurfaceVariant,
                                ),
                              ),
                              description:
                                  task.description != null &&
                                      task.description!.isNotEmpty
                                  ? Text(
                                      task.description!,
                                      style: TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: colorTheme.onSurfaceVariant,
                                      ),
                                    )
                                  : null,
                              deadline: task.deadline != null
                                  ? Text(
                                      formatDeadline(task.deadline)!,
                                      style: TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    )
                                  : null,
                              subTasks: task.subTasks.map((subTask) {
                                return TaskTile(
                                  backgroundColor:
                                      colorTheme.surfaceContainerHigh,
                                  title: Text(
                                    subTask.title,
                                    style: TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: colorTheme.onSurfaceVariant,
                                      fontSize: 14,
                                    ),
                                  ),
                                  description:
                                      subTask.description != null &&
                                          subTask.description!.isNotEmpty
                                      ? Text(
                                          subTask.description!,
                                          style: TextStyle(
                                            decoration:
                                                TextDecoration.lineThrough,
                                            color: colorTheme.onSurfaceVariant,
                                            fontSize: 12,
                                          ),
                                        )
                                      : null,
                                  checked: subTask.isCompleted,
                                  onChanged: (value) {
                                    setState(() {
                                      subTask.isCompleted = value ?? false;
                                    });
                                  },
                                );
                              }).toList(),
                              checked: task.isCompleted,
                              onChanged: (value) {
                                setState(() {
                                  task.isCompleted = value ?? false;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      SizedBox(height: 25),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Task creation coming soon!'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
        backgroundColor: colorTheme.primaryContainer,
        foregroundColor: colorTheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Icon(Symbols.add, fill: 1, weight: 500, size: 24),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, ColorScheme colorTheme) {
    return NavigationDrawer(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 16, 16),
          child: Text(
            'Orches',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: colorTheme.primary,
            ),
          ),
        ),
        Divider(indent: 28, endIndent: 28),
        NavigationDrawerDestination(
          icon: Icon(Symbols.task_alt, fill: 0, weight: 400),
          selectedIcon: Icon(Symbols.task_alt, fill: 1, weight: 400),
          label: Text('All Tasks'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Symbols.today, fill: 0, weight: 400),
          selectedIcon: Icon(Symbols.today, fill: 1, weight: 400),
          label: Text('Today'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Symbols.calendar_month, fill: 0, weight: 400),
          selectedIcon: Icon(Symbols.calendar_month, fill: 1, weight: 400),
          label: Text('Upcoming'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Symbols.check_circle, fill: 0, weight: 400),
          selectedIcon: Icon(Symbols.check_circle, fill: 1, weight: 400),
          label: Text('Completed'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Divider(),
        ),
        NavigationDrawerDestination(
          icon: Icon(Symbols.label, fill: 0, weight: 400),
          selectedIcon: Icon(Symbols.label, fill: 1, weight: 400),
          label: Text('Labels'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Symbols.archive, fill: 0, weight: 400),
          selectedIcon: Icon(Symbols.archive, fill: 1, weight: 400),
          label: Text('Archive'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Symbols.delete, fill: 0, weight: 400),
          selectedIcon: Icon(Symbols.delete, fill: 1, weight: 400),
          label: Text('Trash'),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorTheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colorTheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(
              Symbols.task_alt,
              fill: 1,
              weight: 300,
              size: 64,
              color: colorTheme.primary,
            ),
          ),
          Text(
            'No tasks yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: colorTheme.onSurface,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Tap the + button to create your first task and start organizing your day.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorTheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(height: 80),
        ],
      ),
    );
  }
}

class Task {
  final String id;
  String title;
  String? description;
  bool isCompleted;
  DateTime? deadline;
  List<Task> subTasks;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.deadline,
    this.subTasks = const [],
  });
}

String? formatDeadline(DateTime? deadline) {
  if (deadline == null) return null;
  final time = DateFormat('h:mm a').format(deadline);
  final day = DateFormat('E d').format(deadline);
  return '$time, $day';
}
