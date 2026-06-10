import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animations/animations.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'settings_screen.dart';
import 'package:m3e_collection/m3e_collection.dart'
    hide ExpressiveLoadingIndicator;
import 'package:antimatter/screens/session_screen.dart';
import 'package:antimatter/screens/overview/overview_page.dart';
import 'package:antimatter/screens/task_screen.dart';
import 'package:antimatter/widgets/floating_nav_bar.dart';
import 'package:antimatter/utils/ui_utils.dart';
import 'package:antimatter/utils/m3_motion.dart';

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
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initAppLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _initAppLinks() async {
    _appLinks = AppLinks();

    // Check pre-existing link
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint("Failed to get initial app link: $e");
    }

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'antimatter' && uri.host == 'action') {
      final action = uri.pathSegments.firstOrNull ?? '';
      if (action == 'create') {
        final queryParams = uri.queryParameters;
        final taskName = queryParams['q'] ?? '';
        setState(() {
          _navIndex = 1; // Go to Tasks Page
        });

        // Wait for page transition then trigger creation if applicable
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_taskScreenKey.currentState != null && taskName.isNotEmpty) {
            _taskScreenKey.currentState!.triggerGlobalCreate(
              taskName: taskName,
            );
          }
        });
      } else if (action == 'read') {
        setState(() {
          _navIndex = 1; // Go to Tasks Page
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isExpanded = context.isExpanded;

        // Build the body based on top-level nav index
        Widget bodyContent;
        if (_navIndex == 0) {
          final bool isRailExpanded =
              isExpanded &&
              context.isLarge &&
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
            onNavigateToSettings: () => setState(() => _navIndex = 3),
            onSelectionChanged: (hasSelection) {
              setState(() {
                _taskHasSelection = hasSelection;
              });
            },
          );
        }

        void handleTaskCreateShortcut() {
          if (FocusManager.instance.primaryFocus?.context?.widget is! EditableText) {
            if (_navIndex == 1) {
              _taskScreenKey.currentState?.openCreateTaskEditor();
            } else {
              setState(() {
                _navIndex = 1;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _taskScreenKey.currentState?.openCreateTaskEditor();
              });
            }
          }
        }

        void handleSettingsShortcut() {
          if (FocusManager.instance.primaryFocus?.context?.widget is! EditableText) {
            setState(() {
              _navIndex = 3;
            });
          }
        }

        void handleDeleteShortcut() {
          if (FocusManager.instance.primaryFocus?.context?.widget is! EditableText) {
            if (_navIndex == 1) {
              _taskScreenKey.currentState?.deleteSelectedTasks();
            }
          }
        }

        void handleCancelSelectionShortcut() {
          if (FocusManager.instance.primaryFocus?.context?.widget is! EditableText) {
            if (_navIndex == 1) {
              _taskScreenKey.currentState?.clearSelection();
            }
          }
        }

        return CallbackShortcuts(
          bindings: {
            // Create Task
            SingleActivator(LogicalKeyboardKey.keyN, control: true): handleTaskCreateShortcut,
            SingleActivator(LogicalKeyboardKey.keyN, meta: true): handleTaskCreateShortcut,
            SingleActivator(LogicalKeyboardKey.keyN, alt: true): handleTaskCreateShortcut,
            
            // Go to Settings
            SingleActivator(LogicalKeyboardKey.keyI, control: true): handleSettingsShortcut,
            SingleActivator(LogicalKeyboardKey.keyI, meta: true): handleSettingsShortcut,
            SingleActivator(LogicalKeyboardKey.keyI, alt: true): handleSettingsShortcut,
            
            // Delete Selected Tasks
            SingleActivator(LogicalKeyboardKey.delete): handleDeleteShortcut,

            // Cancel Task Selection / Deselect
            SingleActivator(LogicalKeyboardKey.escape): handleCancelSelectionShortcut,
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: colorTheme.surfaceContainer,
            body: Row(
              children: [
                if (isExpanded && !_isSessionAmbient)
                  _buildNavigationRail(context, colorTheme, isExpanded: true),
                Expanded(
                  child: Stack(
                    children: [
                      PageTransitionSwitcher(
                        duration: M3Motion.durationMedium4,
                        transitionBuilder:
                            (child, primaryAnimation, secondaryAnimation) {
                              return FadeThroughTransition(
                                animation: primaryAnimation,
                                secondaryAnimation: secondaryAnimation,
                                fillColor: Colors.transparent,
                                child: child,
                              );
                            },
                        child: KeyedSubtree(
                          key: ValueKey<int>(_navIndex),
                          child: bodyContent,
                        ),
                      ),
                      if (!isExpanded)
                        AnimatedPositioned(
                          duration: M3Motion.durationMedium2,
                          curve: M3Motion.emphasizedDecelerate,
                          bottom: _isSessionAmbient
                              ? -150
                              : (_taskHasSelection ? -100 : 20),
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
                              pageActionIcon: _navIndex == 1
                                  ? Symbols.add_rounded
                                  : null,
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
          ),
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
      type: !context.isLarge ? NavigationRailM3EType.alwaysCollapse : _railType,
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
              icon: const Icon(Symbols.add_rounded, fill: 1, weight: 800),
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
              icon: const Icon(Symbols.dashboard_rounded, fill: 0, weight: 600),
              selectedIcon: const Icon(
                Symbols.dashboard_rounded,
                fill: 1,
                weight: 600,
              ),
              label: 'Overview',
            ),
            NavigationRailM3EDestination(
              icon: const Icon(Symbols.task_alt_rounded, fill: 0, weight: 600),
              selectedIcon: const Icon(
                Symbols.task_alt_rounded,
                fill: 1,
                weight: 600,
              ),
              label: 'All Tasks',
            ),
            NavigationRailM3EDestination(
              icon: const Icon(Symbols.today_rounded, fill: 0, weight: 600),
              selectedIcon: const Icon(
                Symbols.today_rounded,
                fill: 1,
                weight: 600,
              ),
              label: 'Today',
            ),
            NavigationRailM3EDestination(
              icon: const Icon(
                Symbols.check_circle_rounded,
                fill: 0,
                weight: 600,
              ),
              selectedIcon: const Icon(
                Symbols.check_circle_rounded,
                fill: 1,
                weight: 600,
              ),
              label: 'Completed',
            ),
          ],
        ),
        NavigationRailM3ESection(
          header: const Text('More'),
          destinations: [
            NavigationRailM3EDestination(
              icon: const Icon(Symbols.category_rounded, fill: 0, weight: 600),
              selectedIcon: const Icon(
                Symbols.category_rounded,
                fill: 1,
                weight: 600,
              ),
              label: 'Categories',
            ),
            NavigationRailM3EDestination(
              icon: const Icon(Symbols.archive_rounded, fill: 0, weight: 600),
              selectedIcon: const Icon(
                Symbols.archive_rounded,
                fill: 1,
                weight: 600,
              ),
              label: 'Archive',
            ),
            NavigationRailM3EDestination(
              icon: const Icon(Symbols.delete_rounded, fill: 0, weight: 600),
              selectedIcon: const Icon(
                Symbols.delete_rounded,
                fill: 1,
                weight: 600,
              ),
              label: 'Trash',
            ),
            NavigationRailM3EDestination(
              icon: const Icon(Symbols.timer_rounded, fill: 0, weight: 600),
              selectedIcon: const Icon(
                Symbols.timer_rounded,
                fill: 1,
                weight: 600,
              ),
              label: 'Session',
            ),
            NavigationRailM3EDestination(
              icon: const Icon(Symbols.settings_rounded, fill: 0, weight: 600),
              selectedIcon: const Icon(
                Symbols.settings_rounded,
                fill: 1,
                weight: 600,
              ),
              label: 'Settings',
            ),
          ],
        ),
      ],
    );
  }
}
