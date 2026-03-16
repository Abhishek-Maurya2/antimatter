import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'settings_screen.dart';
import 'package:m3e_collection/m3e_collection.dart'
    hide ExpressiveLoadingIndicator;
import 'package:orches/screens/session_screen.dart';
import 'package:orches/screens/overview/overview_page.dart';
import 'package:orches/screens/task_screen.dart';
import 'package:orches/widgets/floating_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<TaskScreenState> _taskScreenKey =
      GlobalKey<TaskScreenState>();
  // Top-level nav: 0=Overview, 1=Tasks, 2=Session, 3=Settings
  int _navIndex = 0;
  NavigationRailM3EType _railType = NavigationRailM3EType.expanded;
  // Tasks sub-filter: 0=All, 1=Today, 2=Completed, 3=Categories, 4=Archive, 5=Trash
  int _taskSubFilter = 0;
  bool _isSessionAmbient = false;
  bool _taskHasSelection = false;

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isExpanded = constraints.maxWidth >= 840;

        // Build the body based on top-level nav index
        Widget bodyContent;
        if (_navIndex == 0) {
          final bool isRailExpanded = isExpanded &&
              MediaQuery.sizeOf(context).width >= 1000 &&
              _railType == NavigationRailM3EType.expanded;

          bodyContent = OverviewPage(
            isRailExpanded: isRailExpanded,
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
          bodyContent = TaskScreen(
            key: _taskScreenKey,
            isExpanded: isExpanded,
            onBack: () => setState(() => _navIndex = 0),
            onSelectionChanged: (hasSelection) {
              setState(() {
                _taskHasSelection = hasSelection;
              });
            },
          );
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
                            : (_taskHasSelection ? -100 : 32),
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
                                ? () => _taskScreenKey.currentState
                                      ?.openCreateTaskEditor()
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
      // Maps to taskSubFilters 0-5 (All Tasks through Trash) -> Rail 1-6
      railSelectedIndex = _taskSubFilter + 1;
    } else if (_navIndex == 2) {
      railSelectedIndex = 7; // Session
    } else if (_navIndex == 3) {
      railSelectedIndex = 8; // Settings
    } else {
      railSelectedIndex = 0;
    }

    return NavigationRailM3E(
      type: MediaQuery.sizeOf(context).width < 1000
          ? NavigationRailM3EType.alwaysCollapse
          : _railType,
      modality: NavigationRailM3EModality.standard,
      selectedIndex: railSelectedIndex,
      onDestinationSelected: (index) {
        setState(() {
          if (index == 0) {
            _navIndex = 0;
          } else if (index >= 1 && index <= 6) {
            _navIndex = 1;
            _taskSubFilter = index - 1;
            // Notify the task screen of the sub-filter change
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _taskScreenKey.currentState?.setSubFilter(_taskSubFilter);
            });
          } else if (index == 7) {
            _navIndex = 2;
          } else if (index == 8) {
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
              icon: const Icon(Symbols.add, fill: 1, weight: 600),
              label: 'Add Task',
              onPressed: () =>
                  _taskScreenKey.currentState?.openCreateTaskEditor(),
            )
          : null,
      background: colorTheme.surfaceContainer,
      sections: [
        NavigationRailM3ESection(
          header: const Text('Main'),
          destinations: [
            NavigationRailM3EDestination(
              icon: const Icon(Symbols.dashboard, fill: 0, weight: 400),
              selectedIcon: const Icon(Symbols.dashboard, fill: 1, weight: 400),
              label: 'Overview',
            ),
            NavigationRailM3EDestination(
              icon: const Icon(Symbols.task_alt, fill: 0, weight: 400),
              selectedIcon: const Icon(Symbols.task_alt, fill: 1, weight: 400),
              label: 'All Tasks',
            ),
            NavigationRailM3EDestination(
              icon: const Icon(Symbols.today, fill: 0, weight: 400),
              selectedIcon: const Icon(Symbols.today, fill: 1, weight: 400),
              label: 'Today',
            ),
            NavigationRailM3EDestination(
              icon: const Icon(Symbols.check_circle, fill: 0, weight: 400),
              selectedIcon: const Icon(Symbols.check_circle, fill: 1, weight: 400),
              label: 'Completed',
            ),
          ],
        ),
        NavigationRailM3ESection(
          header: const Text('More'),
          destinations: [
            NavigationRailM3EDestination(
              icon: const Icon(Symbols.category, fill: 0, weight: 400),
              selectedIcon: const Icon(Symbols.category, fill: 1, weight: 400),
              label: 'Categories',
            ),
            NavigationRailM3EDestination(
              icon: const Icon(Symbols.archive, fill: 0, weight: 400),
              selectedIcon: const Icon(Symbols.archive, fill: 1, weight: 400),
              label: 'Archive',
            ),
            NavigationRailM3EDestination(
              icon: const Icon(Symbols.delete, fill: 0, weight: 400),
              selectedIcon: const Icon(Symbols.delete, fill: 1, weight: 400),
              label: 'Trash',
            ),
            NavigationRailM3EDestination(
              icon: const Icon(Symbols.timer, fill: 0, weight: 400),
              selectedIcon: const Icon(Symbols.timer, fill: 1, weight: 400),
              label: 'Session',
            ),
            NavigationRailM3EDestination(
              icon: const Icon(Symbols.settings, fill: 0, weight: 400),
              selectedIcon: const Icon(Symbols.settings, fill: 1, weight: 400),
              label: 'Settings',
            ),
          ],
        ),
      ],
    );
  }
}
