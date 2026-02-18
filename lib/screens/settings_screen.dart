import 'package:flutter/material.dart';
import 'package:settings_tiles/settings_tiles.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import '../utils/theme_controller.dart';
import '../notifiers/settings_notifier.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final colorTheme = Theme.of(context).colorScheme;
    final themeController = Provider.of<ThemeController>(context);

    return Scaffold(
      backgroundColor: colorTheme.surfaceContainer,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text('Settings'),
            titleSpacing: 0,
            backgroundColor: colorTheme.surfaceContainer,
            scrolledUnderElevation: 1,
            expandedHeight: 120,
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Appearance section
                SettingSection(
                  styleTile: true,
                  tiles: [
                    SettingActionTile(
                      icon: iconContainer(
                        Symbols.format_paint,
                        isLight ? Color(0xfff8e287) : Color(0xff534600),
                        isLight ? Color(0xff534600) : Color(0xfff8e287),
                      ),
                      title: Text('Appearance'),
                      description: Text('Theme, colors, and display'),
                      onTap: () {
                        _showThemeDialog(context, themeController);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Task settings section
                SettingSection(
                  styleTile: true,
                  tiles: [
                    SettingActionTile(
                      icon: iconContainer(
                        Symbols.notifications,
                        isLight ? Color(0xffffdbd1) : Color(0xff723523),
                        isLight ? Color(0xff723523) : Color(0xffffdbd1),
                      ),
                      title: Text('Notifications'),
                      description: Text('Task reminders and alerts'),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Coming soon!'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                    ),
                    SettingActionTile(
                      icon: iconContainer(
                        Symbols.category,
                        isLight ? Color(0xffcdeda3) : Color(0xff354e16),
                        isLight ? Color(0xff354e16) : Color(0xffcdeda3),
                      ),
                      title: Text('Categories'),
                      description: Text('Manage task categories'),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Coming soon!'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                    ),
                    SettingActionTile(
                      icon: iconContainer(
                        Symbols.backup,
                        isLight ? Color(0xffd6e3ff) : Color(0xff284777),
                        isLight ? Color(0xff284777) : Color(0xffd6e3ff),
                      ),
                      title: Text('Backup & Restore'),
                      description: Text('Export and import your tasks'),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Coming soon!'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // About section
                SettingSection(
                  styleTile: true,
                  tiles: [
                    SettingSwitchTile(
                      icon: iconContainer(
                        Symbols.palette,
                        isLight ? Color(0xffffd6f9) : Color(0xff633664),
                        isLight ? Color(0xff633664) : Color(0xffffd6f9),
                      ),
                      title: Text('Expressive colors'),
                      description: Text('Use vibrant M3 expressive variant'),
                      toggled: context
                          .watch<SettingsNotifier>()
                          .useExpressiveVariant,
                      onChanged: (value) {
                        context.read<SettingsNotifier>().updateColorVariant(
                          value,
                        );
                      },
                    ),
                    SettingActionTile(
                      icon: iconContainer(
                        Symbols.info,
                        isLight ? Color(0xffe6deff) : Color(0xff493e76),
                        isLight ? Color(0xff493e76) : Color(0xffe6deff),
                      ),
                      title: Text('About Orches'),
                      description: Text('Version, licenses, and credits'),
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'Orches',
                          applicationVersion: '0.1.0',
                          applicationIcon: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: colorTheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Symbols.task_alt,
                              fill: 1,
                              color: colorTheme.onPrimaryContainer,
                            ),
                          ),
                          children: [
                            Text(
                              'A beautiful task manager built with Material 3 Expressive design language.',
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 200),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, ThemeController themeController) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Choose theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: Text('System'),
                value: ThemeMode.system,
                groupValue: themeController.themeMode,
                onChanged: (value) {
                  themeController.setThemeMode(value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text('Light'),
                value: ThemeMode.light,
                groupValue: themeController.themeMode,
                onChanged: (value) {
                  themeController.setThemeMode(value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text('Dark'),
                value: ThemeMode.dark,
                groupValue: themeController.themeMode,
                onChanged: (value) {
                  themeController.setThemeMode(value!);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

Widget iconContainer(IconData icon, Color color, Color onColor) {
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(50),
      color: color,
    ),
    child: Icon(icon, fill: 1, weight: 500, color: onColor),
  );
}
