import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'settings_screen.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/services.dart';
import 'package:settings_tiles/settings_tiles.dart';
import 'package:intl/intl.dart';
import 'package:orches/models/task.dart';
import 'package:orches/screens/task_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isGridView = false;

  late Box<Task> _tasksBox;
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _tasksBox = Hive.box<Task>('tasksBox');
    _tasks = _tasksBox.values.toList();
  }

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
                                      task.save();
                                    });
                                  },
                                );
                              }).toList(),
                              checked: task.isCompleted,
                              onChanged: (value) {
                                setState(() {
                                  task.isCompleted = value ?? false;
                                  task.save();
                                });
                              },
                              onPressed: () async {
                                final updatedTask = await Navigator.of(context)
                                    .push<dynamic>(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            TaskEditorScreen(task: task),
                                      ),
                                    );
                                if (updatedTask != null) {
                                  setState(() {
                                    final index = _tasks.indexWhere(
                                      (t) => t.id == task.id,
                                    );
                                    if (index != -1) {
                                      if (updatedTask == 'DELETE') {
                                        _tasks.removeAt(index);
                                        _tasksBox.delete(task.id);
                                      } else if (updatedTask is Task) {
                                        _tasks[index] = updatedTask;
                                        _tasksBox.put(
                                          updatedTask.id,
                                          updatedTask,
                                        );
                                      }
                                    }
                                  });
                                }
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
                                      task.save();
                                    });
                                  },
                                );
                              }).toList(),
                              checked: task.isCompleted,
                              onChanged: (value) {
                                setState(() {
                                  task.isCompleted = value ?? false;
                                  task.save();
                                });
                              },
                              onPressed: () async {
                                final updatedTask = await Navigator.of(context)
                                    .push<dynamic>(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            TaskEditorScreen(task: task),
                                      ),
                                    );
                                if (updatedTask != null) {
                                  setState(() {
                                    final index = _tasks.indexWhere(
                                      (t) => t.id == task.id,
                                    );
                                    if (index != -1) {
                                      if (updatedTask == 'DELETE') {
                                        _tasks.removeAt(index);
                                        _tasksBox.delete(task.id);
                                      } else if (updatedTask is Task) {
                                        _tasks[index] = updatedTask;
                                        _tasksBox.put(
                                          updatedTask.id,
                                          updatedTask,
                                        );
                                      }
                                    }
                                  });
                                }
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
        onPressed: () async {
          final newTask = await Navigator.of(context).push<Task>(
            MaterialPageRoute(builder: (_) => const TaskEditorScreen()),
          );

          if (newTask != null) {
            setState(() {
              _tasks.add(newTask);
              _tasksBox.put(newTask.id, newTask);
            });
          }
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

String? formatDeadline(DateTime? deadline) {
  if (deadline == null) return null;
  final time = DateFormat('h:mm a').format(deadline);
  final day = DateFormat('E d').format(deadline);
  return '$time, $day';
}
