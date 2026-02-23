import 'package:flutter/material.dart';
import 'package:settings_tiles/settings_tiles.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'settings/appearance_screen.dart';
import 'settings/notifications_screen.dart';
import 'settings/categories_screen.dart';
import 'settings/backup_restore_screen.dart';
import 'settings/updates_screen.dart';
import 'settings/about_screen.dart';
import 'settings/wavy_demo_screen.dart';

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

    return Scaffold(
      backgroundColor: colorTheme.surfaceContainer,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text('Settings'),
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AppearanceScreen(),
                          ),
                        );
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CategoriesScreen(),
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BackupRestoreScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Updates & About section
                SettingSection(
                  styleTile: true,
                  tiles: [
                    SettingActionTile(
                      icon: iconContainer(
                        Symbols.system_update,
                        isLight ? Color(0xffc3f0d1) : Color(0xff0f5132),
                        isLight ? Color(0xff0f5132) : Color(0xffc3f0d1),
                      ),
                      title: Text('Updates'),
                      description: Text('Check for new versions'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UpdatesScreen(),
                          ),
                        );
                      },
                    ),
                    SettingActionTile(
                      icon: iconContainer(
                        Symbols.info,
                        isLight ? Color(0xffe6deff) : Color(0xff493e76),
                        isLight ? Color(0xff493e76) : Color(0xffe6deff),
                      ),
                      title: Text('About AntiMatter'),
                      description: Text('Version, licenses, and credits'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AboutScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Demos section
                SettingSection(
                  styleTile: true,
                  tiles: [
                    SettingActionTile(
                      icon: iconContainer(
                        Symbols.animation,
                        isLight ? Color(0xffffd8e4) : Color(0xff73293d),
                        isLight ? Color(0xff73293d) : Color(0xffffd8e4),
                      ),
                      title: Text('Wavy Indicators Demo'),
                      description: Text('Preview wavy progress indicators'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WavyDemoScreen(),
                          ),
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
