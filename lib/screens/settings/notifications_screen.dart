import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:settings_tiles/settings_tiles.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive/hive.dart';
import '../../models/task.dart';
import '../../utils/preferences_helper.dart';
import '../../services/notification_service.dart';
import '../../main.dart';
import '../settings_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final bool isEmbedded;
  const NotificationsScreen({super.key, this.isEmbedded = false});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _notificationsEnabled = false;
  bool _taskCompletionSound = true;
  bool _deadlineReminders = true;
  bool _dailySummary = false;
  String _reminderTime = '30 min before';

  final Map<String, String> _reminderOptions = {
    '15min': '15 minutes before',
    '30min': '30 minutes before',
    '1hr': '1 hour before',
    '1day': '1 day before',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _notificationsEnabled =
        PreferencesHelper.getBool('notificationsEnabled') ?? false;
    _taskCompletionSound =
        PreferencesHelper.getBool('taskCompletionSound') ?? true;
    _deadlineReminders = PreferencesHelper.getBool('deadlineReminders') ?? true;
    _dailySummary = PreferencesHelper.getBool('dailySummary') ?? false;
    final savedKey = PreferencesHelper.getString('reminderTime') ?? '30min';
    _reminderTime = _reminderOptions[savedKey] ?? '30 minutes before';
    setState(() {});
  }

  Future<void> _rescheduleAll() async {
    if (!_notificationsEnabled) {
      await NotificationService().cancelAllNotifications();
      return;
    }

    await NotificationService().cancelAllNotifications();
    final tasksBox = Hive.box<Task>('tasksBox');

    // Reschedule deadline reminders
    if (_deadlineReminders) {
      final tasks = tasksBox.values
          .where((t) => !t.isCompleted && !t.isDeleted)
          .toList();
      final key = _reminderOptions.entries
          .firstWhere((e) => e.value == _reminderTime)
          .key;
      int minutes = 30;
      if (key == '15min')
        minutes = 15;
      else if (key == '1hr')
        minutes = 60;
      else if (key == '1day')
        minutes = 1440;

      for (var task in tasks) {
        await NotificationService().scheduleDeadlineReminder(task, minutes);
      }
    }

    // Reschedule daily summary
    if (_dailySummary) {
      final tasks = tasksBox.values
          .where((t) => !t.isCompleted && !t.isDeleted)
          .toList();
      await NotificationService().scheduleDailySummary(tasks.length);
    }
  }

  Future<void> _handleNotificationToggle(bool value) async {
    if (value) {
      // Requesting to enable — check permission first
      final status = await Permission.notification.status;

      if (status.isGranted) {
        _enableNotifications();
      } else {
        final result = await Permission.notification.request();
        if (result.isGranted) {
          _enableNotifications();
        } else if (result.isPermanentlyDenied) {
          if (mounted) {
            _showPermissionDeniedDialog();
          }
        } else {
          // Denied but not permanently — show a snackbar
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Notification permission is required to enable this feature',
                ),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        }
      }
    } else {
      // Turning off — no permission needed
      setState(() => _notificationsEnabled = false);
      PreferencesHelper.setBool('notificationsEnabled', false);
      await _rescheduleAll();
    }
  }

  void _enableNotifications() {
    setState(() => _notificationsEnabled = true);
    PreferencesHelper.setBool('notificationsEnabled', true);
    _rescheduleAll();
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Permission Required'),
        content: Text(
          'Notification permission was permanently denied. '
          'Please enable it from your device Settings to use this feature.',
        ),
        actions: [
          ButtonM3E(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ButtonM3EStyle.text,
            label: const Text('Cancel'),
          ),
          ButtonM3E(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            style: ButtonM3EStyle.text,
            label: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: widget.isEmbedded
          ? colorTheme.surfaceContainerLow
          : colorTheme.surfaceContainer,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text('Notifications'),
            titleSpacing: widget.isEmbedded ? 16 : 0,
            leadingWidth: widget.isEmbedded ? 0 : 80,
            automaticallyImplyLeading: !widget.isEmbedded,
            leading: widget.isEmbedded
                ? null
                : Center(
                    child: IconButtonM3E(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Symbols.arrow_back),
                      tooltip: 'Back',
                      variant: IconButtonM3EVariant.tonal,
                      width: IconButtonM3EWidth.wide,
                    ),
                  ),
            backgroundColor: widget.isEmbedded
                ? colorTheme.surfaceContainerLow
                : colorTheme.surfaceContainer,
            scrolledUnderElevation: 1,
            expandedHeight: 120,
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                SettingSection(
                  styleTile: true,
                  title: Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 8,
                      top: 16,
                    ),
                    child: Text(
                      'General',
                      style: TextStyle(
                        color: colorTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  tiles: [
                    SettingSwitchTile(
                      icon: iconContainer(
                        Symbols.notifications_active,
                        isLight ? Color(0xffffdbd1) : Color(0xff723523),
                        isLight ? Color(0xff723523) : Color(0xffffdbd1),
                      ),
                      title: Text('Enable Notifications'),
                      description: Text('Master toggle for all notifications'),
                      toggled: _notificationsEnabled,
                      onChanged: (value) => _handleNotificationToggle(value),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SettingSection(
                  styleTile: true,
                  title: Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 8,
                      top: 16,
                    ),
                    child: Text(
                      'Tasks',
                      style: TextStyle(
                        color: colorTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  tiles: [
                    SettingSwitchTile(
                      icon: iconContainer(
                        Symbols.check_circle,
                        isLight ? Color(0xffc2ebd3) : Color(0xff2d4d3a),
                        isLight ? Color(0xff2d4d3a) : Color(0xffc2ebd3),
                      ),
                      title: Text('Task Completion Sound'),
                      description: Text('Play sound when completing task'),
                      toggled: _taskCompletionSound,
                      onChanged: (value) {
                        setState(() => _taskCompletionSound = value);
                        PreferencesHelper.setBool('taskCompletionSound', value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SettingSection(
                  styleTile: true,
                  title: Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 8,
                      top: 16,
                    ),
                    child: Text(
                      'Reminders',
                      style: TextStyle(
                        color: colorTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  tiles: [
                    SettingSwitchTile(
                      icon: iconContainer(
                        Symbols.alarm,
                        isLight ? Color(0xfffff0c3) : Color(0xff534600),
                        isLight ? Color(0xff534600) : Color(0xfffff0c3),
                      ),
                      title: Text('Deadline Reminders'),
                      description: Text('Get notified before task deadlines'),
                      toggled: _deadlineReminders,
                      onChanged: _notificationsEnabled
                          ? (value) {
                              setState(() => _deadlineReminders = value);
                              PreferencesHelper.setBool(
                                'deadlineReminders',
                                value,
                              );
                              _rescheduleAll();
                            }
                          : null,
                    ),
                    SettingSingleOptionTile(
                      icon: iconContainer(
                        Symbols.schedule,
                        isLight ? Color(0xffd6e3ff) : Color(0xff284777),
                        isLight ? Color(0xff284777) : Color(0xffd6e3ff),
                      ),
                      title: Text('Reminder Time'),
                      dialogTitle: 'Remind me',
                      value: SettingTileValue(_reminderTime),
                      options: _reminderOptions.values.toList(),
                      initialOption: _reminderTime,
                      onSubmitted: (value) {
                        setState(() => _reminderTime = value);
                        final key = _reminderOptions.entries
                            .firstWhere((e) => e.value == value)
                            .key;
                        PreferencesHelper.setString('reminderTime', key);
                        if (_notificationsEnabled && _deadlineReminders) {
                          _rescheduleAll();
                        }
                      },
                    ),
                    SettingSwitchTile(
                      icon: iconContainer(
                        Symbols.summarize,
                        isLight ? Color(0xffcdeda3) : Color(0xff354e16),
                        isLight ? Color(0xff354e16) : Color(0xffcdeda3),
                      ),
                      title: Text('Daily Summary'),
                      description: Text('Daily overview of pending tasks'),
                      toggled: _dailySummary,
                      onChanged: _notificationsEnabled
                          ? (value) {
                              setState(() => _dailySummary = value);
                              PreferencesHelper.setBool('dailySummary', value);
                              _rescheduleAll();
                            }
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 200),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
