import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:settings_tiles/settings_tiles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/task.dart';
import '../settings_screen.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _isSyncing = false;
  bool? _isSyncWorking;

  @override
  void initState() {
    super.initState();
    _checkSyncStatus();
  }

  Future<void> _checkSyncStatus() async {
    setState(() {
      _isSyncing = true;
    });
    try {
      await Supabase.instance.client.from('tasks').select().limit(1);
      if (mounted) {
        setState(() {
          _isSyncWorking = true;
          _isSyncing = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSyncWorking = false;
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: colorTheme.surfaceContainer,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text('Backup & Restore'),
            titleSpacing: 0,
            leadingWidth: 80,
            leading: Center(
              child: Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  color: colorTheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Symbols.arrow_back,
                    color: colorTheme.onSurface,
                    size: 25,
                  ),
                  tooltip: 'Back',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
            backgroundColor: colorTheme.surfaceContainer,
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
                      'Backup',
                      style: TextStyle(
                        color: colorTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  tiles: [
                    SettingActionTile(
                      icon: iconContainer(
                        Symbols.upload,
                        isLight ? Color(0xffd6e3ff) : Color(0xff284777),
                        isLight ? Color(0xff284777) : Color(0xffd6e3ff),
                      ),
                      title: Text('Export Tasks'),
                      description: Text('Copy all tasks as JSON to clipboard'),
                      onTap: () => _exportTasks(context),
                    ),
                    SettingActionTile(
                      icon: iconContainer(
                        Symbols.download,
                        isLight ? Color(0xffcdeda3) : Color(0xff354e16),
                        isLight ? Color(0xff354e16) : Color(0xffcdeda3),
                      ),
                      title: Text('Import Tasks'),
                      description: Text('Restore tasks from JSON in clipboard'),
                      onTap: () => _importTasks(context),
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
                      'Sync',
                      style: TextStyle(
                        color: colorTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  tiles: [
                    SettingActionTile(
                      icon: iconContainer(
                        _isSyncWorking == true
                            ? Symbols.cloud_done
                            : Symbols.cloud_off,
                        isLight ? Color(0xffe6deff) : Color(0xff493e76),
                        isLight ? Color(0xff493e76) : Color(0xffe6deff),
                      ),
                      title: Text('Cloud Sync'),
                      description: Text(
                        _isSyncing
                            ? 'Checking sync status...'
                            : (_isSyncWorking == true
                                  ? 'Supabase sync is active and working'
                                  : 'Supabase sync is currently unavailable'),
                      ),
                      onTap: () {
                        if (!_isSyncing) {
                          _checkSyncStatus();
                        }
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
                      'Danger Zone',
                      style: TextStyle(
                        color: colorTheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  tiles: [
                    SettingActionTile(
                      icon: iconContainer(
                        Symbols.delete_forever,
                        isLight ? Color(0xffffdbd1) : Color(0xff723523),
                        isLight ? Color(0xff723523) : Color(0xffffdbd1),
                      ),
                      title: Text('Clear All Data'),
                      description: Text('Permanently delete all local tasks'),
                      onTap: () => _clearAllData(context),
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

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _exportTasks(BuildContext context) async {
    try {
      final tasksBox = Hive.box<Task>('tasksBox');
      final tasks = tasksBox.values.map((t) => t.toJson()).toList();
      final jsonString = const JsonEncoder.withIndent('  ').convert(tasks);
      await Clipboard.setData(ClipboardData(text: jsonString));
      if (context.mounted) {
        _showSnackBar(context, '${tasks.length} tasks exported to clipboard!');
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Export failed: $e');
      }
    }
  }

  Future<void> _importTasks(BuildContext context) async {
    try {
      final clipData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipData?.text == null || clipData!.text!.isEmpty) {
        if (context.mounted) {
          _showSnackBar(context, 'Clipboard is empty');
        }
        return;
      }

      final List<dynamic> json = jsonDecode(clipData.text!);
      final tasksBox = Hive.box<Task>('tasksBox');
      int imported = 0;

      for (final item in json) {
        final task = Task.fromJson(item as Map<String, dynamic>);
        await tasksBox.put(task.id, task);
        imported++;
      }

      if (context.mounted) {
        _showSnackBar(context, '$imported tasks imported successfully!');
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Import failed: Invalid JSON data');
      }
    }
  }

  void _clearAllData(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear All Data?'),
        content: Text(
          'This will permanently delete all your local tasks. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final tasksBox = Hive.box<Task>('tasksBox');
              await tasksBox.clear();
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                _showSnackBar(context, 'All local data cleared');
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorTheme.error,
              foregroundColor: colorTheme.onError,
            ),
            child: Text('Delete All'),
          ),
        ],
      ),
    );
  }
}
