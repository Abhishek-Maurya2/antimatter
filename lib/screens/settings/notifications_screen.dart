import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:settings_tiles/settings_tiles.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
// import 'package:permission_handler/permission_handler.dart'; // Removed to avoid location usage on Windows
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
  int _reminderMinutes = 30;

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
    
    // Migration logic for reminder time
    final savedKey = PreferencesHelper.getString('reminderTime');
    if (savedKey != null) {
      if (savedKey == '15min') _reminderMinutes = 15;
      else if (savedKey == '30min') _reminderMinutes = 30;
      else if (savedKey == '1hr') _reminderMinutes = 60;
      else if (savedKey == '1day') _reminderMinutes = 1440;
      
      // Save as NEW format and remove OLD format
      PreferencesHelper.setInt('reminderMinutes', _reminderMinutes);
      PreferencesHelper.remove('reminderTime');
    } else {
      _reminderMinutes = PreferencesHelper.getInt('reminderMinutes') ?? 30;
    }
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

      for (var task in tasks) {
        await NotificationService()
            .scheduleDeadlineReminder(task, _reminderMinutes);
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
      final isGranted = await NotificationService().isPermissionGranted();

      if (isGranted) {
        _enableNotifications();
      } else {
        final result = await NotificationService().requestPermission();
        if (result) {
          _enableNotifications();
        } else {
          // Denied — show a snackbar
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
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
        title: const Text('Permission Required'),
        content: const Text(
          'Notification permission was denied. '
          'Please enable it from your device settings to use this feature.',
        ),
        actions: [
          ButtonM3E(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ButtonM3EStyle.text,
            label: const Text('OK'),
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
                      icon: const Icon(Symbols.arrow_back_rounded, weight: 700),
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
                    SettingInlineSliderTile(
                      enabled: _notificationsEnabled && _deadlineReminders,
                      icon: iconContainer(
                        Symbols.schedule,
                        isLight ? const Color(0xffd6e3ff) : const Color(0xff284777),
                        isLight ? const Color(0xff284777) : const Color(0xffd6e3ff),
                      ),
                      title: const Text('Reminder Time'),
                      description: const Text(
                        'How long before the deadline to notify',
                      ),
                      sliderValue: _reminderMinutes.toDouble(),
                      min: 5,
                      max: 120, // 2 hours
                      divisions: 23, // (120 - 5) / 5 = 23 steps
                      label: (val) {
                        final mins = val.round();
                        if (mins < 60) return '$mins min before';
                        final hrs = mins ~/ 60;
                        final remaining = mins % 60;
                        if (remaining == 0) return '$hrs hr before';
                        return '$hrs hr $remaining min before';
                      },
                      onChanged: (val) {
                        setState(() => _reminderMinutes = val.round());
                      },
                      onChangeEnd: (val) {
                        PreferencesHelper.setInt(
                          'reminderMinutes',
                          val.round(),
                        );
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
