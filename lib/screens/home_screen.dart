import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'settings_screen.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/services.dart';
import 'package:settings_tiles/settings_tiles.dart';
import 'package:orches/utils/date_utils.dart';
import 'package:orches/models/task.dart';
import 'package:orches/screens/task_editor_screen.dart';
import 'package:m3e_collection/m3e_collection.dart'
    hide ExpressiveLoadingIndicator;
import 'package:orches/widgets/task_floating_toolbar.dart';
import 'package:orches/screens/session_screen.dart';
import 'package:orches/screens/overview/overview_page.dart';
import 'package:orches/utils/preferences_helper.dart';
import 'package:orches/main.dart';
import 'package:orches/services/notification_service.dart';
import 'package:orches/services/audio_service.dart';
import 'package:orches/widgets/floating_nav_bar.dart';

enum TaskSortOption { newest, oldest, dueDate }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Duration _completedRetention = Duration(days: 7);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late Box<Task> _tasksBox;
  List<Task> _tasks = [];
  TaskSortOption _currentSort = TaskSortOption.oldest;
  List<Task> _selectedTasksForToolbar = [];
  List<Task> _previousTasksForToolbar =
      []; // Used to keep the toolbar rendered while it animates out
  // Top-level nav: 0=Overview, 1=Tasks, 2=Session, 3=Settings
  int _navIndex = 0;
  NavigationRailM3EType _railType = NavigationRailM3EType.expanded;
  // Tasks sub-filter: 0=All, 1=Today, 2=Upcoming, 3=Completed, 4=Labels, 5=Archive, 6=Trash
  int _taskSubFilter = 0;
  String? _selectedLabelFilter;
  Task? _editingTask;
  bool _isEditingNewTask = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSessionAmbient = false;

  void _toggleTaskSelection(Task task) {
    setState(() {
      if (_selectedTasksForToolbar.contains(task)) {
        _selectedTasksForToolbar.remove(task);
      } else {
        _selectedTasksForToolbar.add(task);
      }
    });
  }

  Future<void> _openCreateTaskEditor(bool isExpanded) async {
    if (isExpanded) {
      setState(() {
        _editingTask = null;
        _isEditingNewTask = true;
      });
      return;
    }

    final newTask = await Navigator.of(
      context,
    ).push<Task>(MaterialPageRoute(builder: (_) => const TaskEditorScreen()));

    if (newTask != null) {
      setState(() {
        _tasks.add(newTask);
        _tasksBox.put(newTask.id, newTask);
      });
    }
  }

  Future<void> _setTaskCompleted(Task task, bool isCompleted) async {
    task.isCompleted = isCompleted;
    task.completedAt = isCompleted
        ? (task.completedAt ?? DateTime.now())
        : null;

    await task.save();

    if (task.isCompleted) {
      AudioService().playTickSound();
      await NotificationService().cancelNotification(task.id.hashCode);
    } else {
      final bool notificationsEnabled =
          PreferencesHelper.getBool('notificationsEnabled') ?? false;
      final bool deadlineReminders =
          PreferencesHelper.getBool('deadlineReminders') ?? true;
      final String savedKey =
          PreferencesHelper.getString('reminderTime') ?? '30min';
      int minutes = 30;
      if (savedKey == '15min') {
        minutes = 15;
      } else if (savedKey == '1hr') {
        minutes = 60;
      } else if (savedKey == '1day') {
        minutes = 1440;
      }

      if (notificationsEnabled && deadlineReminders && task.deadline != null) {
        await NotificationService().scheduleDeadlineReminder(task, minutes);
      }
    }
  }

  Future<void> _autoMoveOldCompletedTasksToTrash() async {
    final now = DateTime.now();
    bool changed = false;

    for (final task in _tasksBox.values) {
      if (!task.isCompleted || task.isDeleted) continue;

      final completedAt = task.completedAt;
      if (completedAt == null) {
        task.completedAt = now;
        await task.save();
        changed = true;
        continue;
      }

      if (now.difference(completedAt) >= _completedRetention) {
        task.isDeleted = true;
        await task.save();
        changed = true;
      }
    }

    if (changed && mounted) {
      setState(() {
        _tasks = _tasksBox.values.toList();
      });
    }
  }

  void _handleTaskResult(dynamic result) async {
    if (result == null) return;

    final bool notificationsEnabled =
        PreferencesHelper.getBool('notificationsEnabled') ?? false;
    final bool deadlineReminders =
        PreferencesHelper.getBool('deadlineReminders') ?? true;
    final String savedKey =
        PreferencesHelper.getString('reminderTime') ?? '30min';
    int minutes = 30;
    if (savedKey == '15min')
      minutes = 15;
    else if (savedKey == '1hr')
      minutes = 60;
    else if (savedKey == '1day')
      minutes = 1440;

    if (result == 'DELETE' && _editingTask != null && !_isEditingNewTask) {
      final deletedTaskId = _editingTask!.id;
      final index = _tasks.indexWhere((t) => t.id == _editingTask!.id);
      if (index != -1) {
        setState(() {
          _tasks.removeAt(index);
        });
        await _tasksBox.delete(_editingTask!.id);
        await syncService.deleteTask(deletedTaskId);
        await NotificationService().cancelNotification(
          _editingTask!.id.hashCode,
        );
      }
    } else if (result is Task) {
      if (_isEditingNewTask) {
        if (result.isCompleted && result.completedAt == null) {
          result.completedAt = DateTime.now();
        } else if (!result.isCompleted) {
          result.completedAt = null;
        }
        setState(() {
          _tasks.add(result);
        });
        await _tasksBox.put(result.id, result);
        if (notificationsEnabled &&
            deadlineReminders &&
            result.deadline != null &&
            !result.isCompleted) {
          await NotificationService().scheduleDeadlineReminder(result, minutes);
        }
      } else if (_editingTask != null) {
        final index = _tasks.indexWhere((t) => t.id == _editingTask!.id);
        if (index != -1) {
          setState(() {
            _tasks[index] = result;
          });
          if (result.isCompleted && result.completedAt == null) {
            result.completedAt = DateTime.now();
          } else if (!result.isCompleted) {
            result.completedAt = null;
          }
          await _tasksBox.put(result.id, result);
          if (notificationsEnabled &&
              deadlineReminders &&
              result.deadline != null &&
              !result.isCompleted) {
            await NotificationService().scheduleDeadlineReminder(
              result,
              minutes,
            );
          } else if (result.isCompleted || result.deadline == null) {
            await NotificationService().cancelNotification(result.id.hashCode);
          }
        }
      }
    }
    setState(() {
      _editingTask = null;
      _isEditingNewTask = false;
    });

    await _autoMoveOldCompletedTasksToTrash();
  }

  List<String> get _uniqueLabels {
    final Set<String> labels = {};
    for (final task in _tasksBox.values) {
      if (!task.isDeleted) {
        labels.addAll(task.labels);
      }
    }
    final sorted = labels.toList();
    sorted.sort();
    return sorted;
  }

  List<Task> get _filteredTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final query = _searchQuery.toLowerCase().trim();

    return _tasks.where((task) {
      // Apply search filter first
      if (query.isNotEmpty) {
        final titleMatch = task.title.toLowerCase().contains(query);
        final descMatch = (task.description ?? '').toLowerCase().contains(
          query,
        );
        final labelMatch = task.labels.any(
          (l) => l.toLowerCase().contains(query),
        );
        if (!titleMatch && !descMatch && !labelMatch) return false;
      }

      if (_taskSubFilter == 6) {
        // Trash
        return task.isDeleted;
      }

      // For all other views, exclude deleted tasks
      if (task.isDeleted) return false;

      switch (_taskSubFilter) {
        case 0: // All tasks
          return !task.isArchived;
        case 1: // Today
          if (task.isArchived || task.deadline == null) return false;
          final taskDate = DateTime(
            task.deadline!.year,
            task.deadline!.month,
            task.deadline!.day,
          );
          return taskDate.isAtSameMomentAs(today);
        case 2: // Upcoming
          if (task.isArchived || task.deadline == null) return false;
          final taskDate = DateTime(
            task.deadline!.year,
            task.deadline!.month,
            task.deadline!.day,
          );
          return taskDate.isAfter(today);
        case 3: // Completed
          return task.isCompleted && !task.isArchived;
        case 4: // Labels
          if (_selectedLabelFilter != null) {
            return task.labels.contains(_selectedLabelFilter) &&
                !task.isArchived;
          }
          return task.labels.isNotEmpty && !task.isArchived;
        case 5: // Archive
          return task.isArchived;
        default:
          return !task.isArchived;
      }
    }).toList();
  }

  List<Task> get _sortedTasks {
    final sorted = List<Task>.from(_filteredTasks);
    sorted.sort((a, b) {
      switch (_currentSort) {
        case TaskSortOption.newest:
          final idA = int.tryParse(a.id) ?? 0;
          final idB = int.tryParse(b.id) ?? 0;
          return idB.compareTo(idA);
        case TaskSortOption.oldest:
          final idA = int.tryParse(a.id) ?? 0;
          final idB = int.tryParse(b.id) ?? 0;
          return idA.compareTo(idB);
        case TaskSortOption.dueDate:
          if (a.deadline == null && b.deadline == null) return 0;
          if (a.deadline == null) return 1;
          if (b.deadline == null) return -1;
          return a.deadline!.compareTo(b.deadline!);
      }
    });
    return sorted;
  }

  @override
  void initState() {
    super.initState();
    _tasksBox = Hive.box<Task>('tasksBox');
    _tasks = _tasksBox.values.toList();

    final savedSort = PreferencesHelper.getString('task_sort_preference');
    if (savedSort != null) {
      _currentSort = TaskSortOption.values.firstWhere(
        (e) => e.name == savedSort,
        orElse: () => TaskSortOption.oldest,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoMoveOldCompletedTasksToTrash();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isExpanded = constraints.maxWidth >= 840;

        // Build the body based on top-level nav index
        Widget bodyContent;
        if (_navIndex == 0) {
          bodyContent = OverviewPage(
            onNavigateToTasks: () {
              setState(() {
                _navIndex = 1;
                _taskSubFilter = 0;
              });
            },
          );
        } else if (_navIndex == 2) {
          bodyContent = SessionScreen(
            onBack: () => setState(() => _navIndex = 0),
            onAmbientModeChanged: (isAmbient) {
              setState(() {
                _isSessionAmbient = isAmbient;
              });
            },
          );
        } else if (_navIndex == 3) {
          bodyContent = SettingsScreen(
            onBack: () => setState(() => _navIndex = 0),
          );
        } else {
          // Nav 1 = Tasks page
          bodyContent = _buildTasksPage(context, colorTheme, isExpanded);
        }

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: colorTheme.surfaceContainer,
          body: Row(
            children: [
              if (isExpanded && !_isSessionAmbient)
                _buildNavigationRail(context, colorTheme, isExpanded: true),
              Expanded(
                child: Stack(
                  children: [
                    bodyContent,
                    if (!isExpanded)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        bottom: _isSessionAmbient
                            ? -150
                            : (_selectedTasksForToolbar.isNotEmpty ? -100 : 32),
                        left: 0,
                        right: 0,
                        child: Center(
                          child: FloatingNavBar(
                            selectedIndex: _navIndex,
                            onItemSelected: (index) {
                              setState(() {
                                _navIndex = index;
                                if (index == 1 && _taskSubFilter == -1) {
                                  _taskSubFilter = 0;
                                }
                              });
                            },
                            pageActionIcon: _navIndex == 1 ? Symbols.add : null,
                            pageActionTooltip: _navIndex == 1
                                ? 'Add task'
                                : null,
                            onPageActionTap: _navIndex == 1
                                ? () => _openCreateTaskEditor(isExpanded)
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (isExpanded && (_editingTask != null || _isEditingNewTask))
                Container(
                  width: 350,
                  decoration: BoxDecoration(
                    color: colorTheme.surfaceContainerHigh,
                    border: Border(
                      left: BorderSide(
                        color: colorTheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  child: TaskEditorWidget(
                    task: _isEditingNewTask ? null : _editingTask,
                    onClose: () {
                      setState(() {
                        _editingTask = null;
                        _isEditingNewTask = false;
                      });
                    },
                    onResult: _handleTaskResult,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTasksPage(
    BuildContext context,
    ColorScheme colorTheme,
    bool isExpanded,
  ) {
    return Stack(
      children: [
        CustomRefreshIndicator(
          onRefresh: () async {
            await syncService.pullTasks();
            await _autoMoveOldCompletedTasksToTrash();
            if (context.mounted) {
              setState(() {
                _tasks = _tasksBox.values.toList();
              });
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Tasks refreshed'),
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
                    final double opacity = (controller.value * 2).clamp(
                      0.0,
                      1.0,
                    );
                    final double scale = (controller.value * 1.5).clamp(
                      0.0,
                      1.0,
                    );

                    return Positioned(
                      top: 110 * controller.value, // Move down as we pull
                      left: 0,
                      right: 0,
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: scale,
                          child: Center(
                            child: LoadingIndicatorM3E(
                              variant: LoadingIndicatorM3EVariant.contained,
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
                        // Search bar
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorTheme.surface,
                              borderRadius: BorderRadius.circular(28),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.centerLeft,
                            height: 58,
                            child: TextField(
                              controller: _searchController,
                              textAlignVertical: TextAlignVertical.center,
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Search Tasks',
                                hintStyle: TextStyle(
                                  color: colorTheme.onSurfaceVariant,
                                ),
                                border: InputBorder.none,
                                isCollapsed: true,
                                prefixIcon: Icon(
                                  Symbols.search,
                                  fill: 0,
                                  weight: 400,
                                  color: colorTheme.onSurfaceVariant,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Symbols.close,
                                          fill: 0,
                                          weight: 400,
                                          color: colorTheme.onSurfaceVariant,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _searchController.clear();
                                            _searchQuery = '';
                                          });
                                        },
                                      )
                                    : null,
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
                              radius: 24,
                              backgroundColor: colorTheme.primaryContainer,
                              backgroundImage: const AssetImage(
                                'assets/profile.jpg',
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
                        if (isExpanded &&
                            _taskSubFilter != 5 &&
                            _taskSubFilter != 6)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              right: 16.0,
                              top: 4.0,
                              bottom: 8.0,
                            ),
                            child: SplitButtonM3E<TaskSortOption>(
                              onPressed: () {
                                final nextIndex =
                                    (TaskSortOption.values.indexOf(
                                          _currentSort,
                                        ) +
                                        1) %
                                    TaskSortOption.values.length;
                                final nextSort =
                                    TaskSortOption.values[nextIndex];
                                setState(() {
                                  _currentSort = nextSort;
                                });
                                PreferencesHelper.setString(
                                  'task_sort_preference',
                                  nextSort.name,
                                );
                              },
                              label: _currentSort == TaskSortOption.newest
                                  ? 'Newest first'
                                  : _currentSort == TaskSortOption.oldest
                                  ? 'Oldest first'
                                  : 'Due Date',
                              leadingIcon: Symbols.sort,
                              items: [
                                SplitButtonM3EItem(
                                  value: TaskSortOption.newest,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Newest first'),
                                      if (_currentSort ==
                                          TaskSortOption.newest) ...[
                                        const SizedBox(width: 12),
                                        Icon(
                                          Symbols.check,
                                          size: 18,
                                          color: colorTheme.primary,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                SplitButtonM3EItem(
                                  value: TaskSortOption.oldest,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Oldest first'),
                                      if (_currentSort ==
                                          TaskSortOption.oldest) ...[
                                        const SizedBox(width: 12),
                                        Icon(
                                          Symbols.check,
                                          size: 18,
                                          color: colorTheme.primary,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                SplitButtonM3EItem(
                                  value: TaskSortOption.dueDate,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Due Date'),
                                      if (_currentSort ==
                                          TaskSortOption.dueDate) ...[
                                        const SizedBox(width: 12),
                                        Icon(
                                          Symbols.check,
                                          size: 18,
                                          color: colorTheme.primary,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (option) {
                                setState(() {
                                  _currentSort = option;
                                });
                                PreferencesHelper.setString(
                                  'task_sort_preference',
                                  option.name,
                                );
                              },
                            ),
                          ),
                        ),
                        if (_taskSubFilter == 4)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ChoiceChip(
                                    label: Text('All Labeled'),
                                    selected: _selectedLabelFilter == null,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() {
                                          _selectedLabelFilter = null;
                                        });
                                      }
                                    },
                                    selectedColor:
                                        colorTheme.secondaryContainer,
                                    labelStyle: TextStyle(
                                      color: _selectedLabelFilter == null
                                          ? colorTheme.onSecondaryContainer
                                          : colorTheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ..._uniqueLabels.map((label) {
                                    final isSelected =
                                        _selectedLabelFilter == label;
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8.0,
                                      ),
                                      child: ChoiceChip(
                                        label: Text(label),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          setState(() {
                                            _selectedLabelFilter = selected
                                                ? label
                                                : null;
                                          });
                                        },
                                        selectedColor:
                                            colorTheme.secondaryContainer,
                                        labelStyle: TextStyle(
                                          color: isSelected
                                              ? colorTheme.onSecondaryContainer
                                              : colorTheme.onSurface,
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        if (_sortedTasks
                            .where((t) => !t.isCompleted)
                            .isNotEmpty) ...[
                          SettingSection(
                            title: Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                                bottom: 8,
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
                            tiles: _sortedTasks.where((t) => !t.isCompleted).map((
                              task,
                            ) {
                              return TaskTile(
                                title: Text(task.title),
                                description:
                                    (task.description != null &&
                                            task.description!.isNotEmpty) ||
                                        task.labels.isNotEmpty
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (task.description != null &&
                                              task.description!.isNotEmpty)
                                            Text(task.description!),
                                          if (task.labels.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4.0,
                                              ),
                                              child: Wrap(
                                                spacing: 4,
                                                runSpacing: 4,
                                                children: task.labels
                                                    .map(
                                                      (label) => Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: colorTheme
                                                              .surfaceContainerHigh,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                          border: Border.all(
                                                            color: colorTheme
                                                                .outlineVariant,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          label,
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: colorTheme
                                                                .onSurfaceVariant,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                              ),
                                            ),
                                        ],
                                      )
                                    : null,
                                isDeadlineMissed:
                                    task.deadline != null &&
                                    task.deadline!.isBefore(DateTime.now()),
                                deadline: task.deadline != null
                                    ? Text(formatDeadline(task.deadline)!)
                                    : null,
                                subTasks: task.subTasks.map((subTask) {
                                  return TaskTile(
                                    backgroundColor:
                                        colorTheme.surfaceContainerHigh,
                                    title: Text(
                                      subTask.title,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                    description:
                                        subTask.description != null &&
                                            subTask.description!.isNotEmpty
                                        ? Text(
                                            subTask.description!,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          )
                                        : null,
                                    checked: subTask.isCompleted,
                                    onChanged: (value) {
                                      setState(() {
                                        subTask.isCompleted = value ?? false;
                                        if (subTask.isCompleted) {
                                          AudioService().playTickSound();
                                        }
                                        task.save();
                                      });
                                    },
                                  );
                                }).toList(),
                                isSelected: _selectedTasksForToolbar.contains(
                                  task,
                                ),
                                checked: task.isCompleted,
                                onChanged: (value) async {
                                  final isCompleted = value ?? false;
                                  setState(() {
                                    task.isCompleted = isCompleted;
                                  });
                                  await _setTaskCompleted(task, isCompleted);
                                  await _autoMoveOldCompletedTasksToTrash();
                                },
                                onLongPress: () {
                                  _toggleTaskSelection(task);
                                },
                                onPressed: () async {
                                  if (_selectedTasksForToolbar.isNotEmpty) {
                                    _toggleTaskSelection(task);
                                    return;
                                  }
                                  if (isExpanded) {
                                    setState(() {
                                      _editingTask = task;
                                      _isEditingNewTask = false;
                                    });
                                  } else {
                                    final updatedTask =
                                        await Navigator.of(
                                          context,
                                        ).push<dynamic>(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                TaskEditorScreen(task: task),
                                          ),
                                        );
                                    if (updatedTask != null) {
                                      setState(() {
                                        _editingTask = task;
                                        _isEditingNewTask = false;
                                      });
                                      _handleTaskResult(updatedTask);
                                    }
                                  }
                                },
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 16),
                        ],
                        if (_sortedTasks.where((t) => t.isCompleted).isNotEmpty)
                          SettingSection(
                            title: Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                                bottom: 8,
                              ),
                              child: Text(
                                'Completed',
                                style: TextStyle(
                                  color: colorTheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            styleTile: true,
                            tiles: _sortedTasks.where((t) => t.isCompleted).map((
                              task,
                            ) {
                              return TaskTile(
                                title: Text(
                                  task.title,
                                  style: TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: colorTheme.onSurfaceVariant,
                                  ),
                                ),
                                description:
                                    (task.description != null &&
                                            task.description!.isNotEmpty) ||
                                        task.labels.isNotEmpty
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (task.description != null &&
                                              task.description!.isNotEmpty)
                                            Text(
                                              task.description!,
                                              style: TextStyle(
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                color:
                                                    colorTheme.onSurfaceVariant,
                                              ),
                                            ),
                                          if (task.labels.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4.0,
                                              ),
                                              child: Wrap(
                                                spacing: 4,
                                                runSpacing: 4,
                                                children: task.labels
                                                    .map(
                                                      (label) => Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: colorTheme
                                                              .surfaceContainerHigh,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                          border: Border.all(
                                                            color: colorTheme
                                                                .outlineVariant
                                                                .withValues(
                                                                  alpha: 0.5,
                                                                ),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          label,
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: colorTheme
                                                                .onSurfaceVariant
                                                                .withValues(
                                                                  alpha: 0.6,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                              ),
                                            ),
                                        ],
                                      )
                                    : null,
                                deadline: task.deadline != null
                                    ? Text(
                                        formatDeadline(task.deadline)!,
                                        style: TextStyle(
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      )
                                    : null,
                                subTasks: task.subTasks.map((subTask) {
                                  return TaskTile(
                                    backgroundColor:
                                        colorTheme.surfaceContainerHigh,
                                    title: Text(
                                      subTask.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            decoration:
                                                TextDecoration.lineThrough,
                                            color: colorTheme.onSurfaceVariant,
                                          ),
                                    ),
                                    description:
                                        subTask.description != null &&
                                            subTask.description!.isNotEmpty
                                        ? Text(
                                            subTask.description!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                  color: colorTheme
                                                      .onSurfaceVariant,
                                                ),
                                          )
                                        : null,
                                    checked: subTask.isCompleted,
                                    onChanged: (value) {
                                      setState(() {
                                        subTask.isCompleted = value ?? false;
                                        if (subTask.isCompleted) {
                                          AudioService().playTickSound();
                                        }
                                        task.save();
                                      });
                                    },
                                  );
                                }).toList(),
                                isSelected: _selectedTasksForToolbar.contains(
                                  task,
                                ),
                                checked: task.isCompleted,
                                onChanged: (value) async {
                                  final isCompleted = value ?? false;
                                  setState(() {
                                    task.isCompleted = isCompleted;
                                  });
                                  await _setTaskCompleted(task, isCompleted);
                                  await _autoMoveOldCompletedTasksToTrash();
                                },
                                onLongPress: () {
                                  _toggleTaskSelection(task);
                                },
                                onPressed: () async {
                                  if (_selectedTasksForToolbar.isNotEmpty) {
                                    _toggleTaskSelection(task);
                                    return;
                                  }
                                  if (isExpanded) {
                                    setState(() {
                                      _editingTask = task;
                                      _isEditingNewTask = false;
                                    });
                                  } else {
                                    final updatedTask =
                                        await Navigator.of(
                                          context,
                                        ).push<dynamic>(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                TaskEditorScreen(task: task),
                                          ),
                                        );
                                    if (updatedTask != null) {
                                      setState(() {
                                        _editingTask = task;
                                        _isEditingNewTask = false;
                                      });
                                      _handleTaskResult(updatedTask);
                                    }
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
        // The floating toolbar itself, animating in and out
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          bottom: _selectedTasksForToolbar.isNotEmpty ? 32 : -100,
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.bottomCenter,
            child:
                _selectedTasksForToolbar.isNotEmpty ||
                    _previousTasksForToolbar.isNotEmpty
                ? TaskFloatingToolbar(
                    tasks: _selectedTasksForToolbar.isNotEmpty
                        ? _selectedTasksForToolbar
                        : _previousTasksForToolbar,
                    colorTheme: colorTheme,
                    onComplete: () async {
                      final tasksToComplete = List<Task>.from(
                        _selectedTasksForToolbar,
                      );
                      if (tasksToComplete.isEmpty) return;

                      final allCompleted = tasksToComplete.every(
                        (t) => t.isCompleted,
                      );
                      final newState = !allCompleted;

                      for (final task in tasksToComplete) {
                        setState(() {
                          task.isCompleted = newState;
                        });
                        await _setTaskCompleted(task, newState);
                      }

                      await _autoMoveOldCompletedTasksToTrash();

                      setState(() {
                        _previousTasksForToolbar = List.from(
                          _selectedTasksForToolbar,
                        );
                        _selectedTasksForToolbar.clear();
                      });
                    },
                    onEdit: () async {
                      if (_selectedTasksForToolbar.length != 1) return;
                      final taskToEdit = _selectedTasksForToolbar.first;

                      setState(() {
                        _previousTasksForToolbar = List.from(
                          _selectedTasksForToolbar,
                        );
                        _selectedTasksForToolbar.clear();
                      });

                      // Wait for animation
                      await Future.delayed(const Duration(milliseconds: 200));

                      if (isExpanded) {
                        setState(() {
                          _editingTask = taskToEdit;
                          _isEditingNewTask = false;
                        });
                      } else {
                        final updatedTask = await Navigator.of(context)
                            .push<dynamic>(
                              MaterialPageRoute(
                                builder: (_) =>
                                    TaskEditorScreen(task: taskToEdit),
                              ),
                            );
                        if (updatedTask != null) {
                          setState(() {
                            _editingTask = taskToEdit;
                            _isEditingNewTask = false;
                          });
                          _handleTaskResult(updatedTask);
                        }
                      }
                    },
                    onDelete: () async {
                      final tasksToDelete = List<Task>.from(
                        _selectedTasksForToolbar,
                      );
                      if (tasksToDelete.isEmpty) return;

                      for (final task in tasksToDelete) {
                        if (task.isDeleted) {
                          setState(() {
                            final index = _tasks.indexWhere(
                              (t) => t.id == task.id,
                            );
                            if (index != -1) {
                              _tasks.removeAt(index);
                            }
                          });
                          await _tasksBox.delete(task.id);
                          await syncService.deleteTask(task.id);
                        } else {
                          setState(() {
                            task.isDeleted = true;
                          });
                          await task.save();
                          await syncService.pushTask(task);
                        }
                      }

                      setState(() {
                        _previousTasksForToolbar = List.from(
                          _selectedTasksForToolbar,
                        );
                        _selectedTasksForToolbar.clear();
                      });
                    },
                    onArchive: () async {
                      final tasksToArchive = List<Task>.from(
                        _selectedTasksForToolbar,
                      );
                      if (tasksToArchive.isEmpty) return;

                      final allArchived = tasksToArchive.every(
                        (t) => t.isArchived,
                      );
                      final newState = !allArchived;

                      for (final task in tasksToArchive) {
                        setState(() {
                          task.isArchived = newState;
                        });
                        await task.save();
                        await syncService.pushTask(task);
                      }

                      setState(() {
                        _previousTasksForToolbar = List.from(
                          _selectedTasksForToolbar,
                        );
                        _selectedTasksForToolbar.clear();
                      });
                    },
                    onRestore: () async {
                      final tasksToRestore = List<Task>.from(
                        _selectedTasksForToolbar,
                      );
                      if (tasksToRestore.isEmpty) return;

                      for (final task in tasksToRestore) {
                        setState(() {
                          task.isDeleted = false;
                        });
                        await task.save();
                        await syncService.pushTask(task);
                      }

                      setState(() {
                        _previousTasksForToolbar = List.from(
                          _selectedTasksForToolbar,
                        );
                        _selectedTasksForToolbar.clear();
                      });
                    },
                    onClose: () {
                      setState(() {
                        _previousTasksForToolbar = List.from(
                          _selectedTasksForToolbar,
                        );
                        _selectedTasksForToolbar.clear();
                      });
                    },
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationRail(
    BuildContext context,
    ColorScheme colorTheme, {
    required bool isExpanded,
  }) {
    // Map _navIndex and _taskSubFilter to a flat index for the rail selection
    int railSelectedIndex;
    if (_navIndex == 0) {
      railSelectedIndex = 0; // Overview
    } else if (_navIndex == 1) {
      // Maps to taskSubFilters 0-6 (All Tasks through Trash) -> Rail 1-7
      railSelectedIndex = _taskSubFilter + 1;
    } else if (_navIndex == 2) {
      railSelectedIndex = 8; // Session
    } else if (_navIndex == 3) {
      railSelectedIndex = 9; // Settings
    } else {
      railSelectedIndex = 0;
    }

    return NavigationRailM3E(
      type: _railType,
      modality: NavigationRailM3EModality.standard,
      selectedIndex: railSelectedIndex,
      onDestinationSelected: (index) {
        setState(() {
          if (index == 0) {
            _navIndex = 0;
          } else if (index >= 1 && index <= 7) {
            _navIndex = 1;
            _taskSubFilter = index - 1;
          } else if (index == 8) {
            _navIndex = 2;
          } else if (index == 9) {
            _navIndex = 3;
          }
        });
      },
      onTypeChanged: (type) {
        setState(() {
          _railType = type;
        });
      },
      fab: _navIndex == 1
          ? NavigationRailM3EFabSlot(
              icon: Icon(Symbols.add, fill: 1, weight: 600),
              label: 'Add Task',
              onPressed: () => _openCreateTaskEditor(isExpanded),
            )
          : null,
      background: colorTheme.surfaceContainer,
      sections: [
        NavigationRailM3ESection(
          header: const Text('Main'),
          destinations: [
            NavigationRailM3EDestination(
              icon: Icon(Symbols.dashboard, fill: 0, weight: 400),
              selectedIcon: Icon(Symbols.dashboard, fill: 1, weight: 400),
              label: 'Overview',
            ),
            NavigationRailM3EDestination(
              icon: Icon(Symbols.task_alt, fill: 0, weight: 400),
              selectedIcon: Icon(Symbols.task_alt, fill: 1, weight: 400),
              label: 'All Tasks',
            ),
            NavigationRailM3EDestination(
              icon: Icon(Symbols.today, fill: 0, weight: 400),
              selectedIcon: Icon(Symbols.today, fill: 1, weight: 400),
              label: 'Today',
            ),
            NavigationRailM3EDestination(
              icon: Icon(Symbols.calendar_month, fill: 0, weight: 400),
              selectedIcon: Icon(Symbols.calendar_month, fill: 1, weight: 400),
              label: 'Upcoming',
            ),
            NavigationRailM3EDestination(
              icon: Icon(Symbols.check_circle, fill: 0, weight: 400),
              selectedIcon: Icon(Symbols.check_circle, fill: 1, weight: 400),
              label: 'Completed',
            ),
          ],
        ),
        NavigationRailM3ESection(
          header: const Text('More'),
          destinations: [
            NavigationRailM3EDestination(
              icon: Icon(Symbols.label, fill: 0, weight: 400),
              selectedIcon: Icon(Symbols.label, fill: 1, weight: 400),
              label: 'Labels',
            ),
            NavigationRailM3EDestination(
              icon: Icon(Symbols.archive, fill: 0, weight: 400),
              selectedIcon: Icon(Symbols.archive, fill: 1, weight: 400),
              label: 'Archive',
            ),
            NavigationRailM3EDestination(
              icon: Icon(Symbols.delete, fill: 0, weight: 400),
              selectedIcon: Icon(Symbols.delete, fill: 1, weight: 400),
              label: 'Trash',
            ),
            NavigationRailM3EDestination(
              icon: Icon(Symbols.timer, fill: 0, weight: 400),
              selectedIcon: Icon(Symbols.timer, fill: 1, weight: 400),
              label: 'Session',
            ),
            NavigationRailM3EDestination(
              icon: Icon(Symbols.settings, fill: 0, weight: 400),
              selectedIcon: Icon(Symbols.settings, fill: 1, weight: 400),
              label: 'Settings',
            ),
          ],
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
  return SystemDateUtils.formatRelativeDeadline(deadline);
}
