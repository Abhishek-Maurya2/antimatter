import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:settings_tiles/settings_tiles.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'settings/appearance_screen.dart';
import 'settings/notifications_screen.dart';
import 'settings/categories_screen.dart';
import 'settings/backup_restore_screen.dart';
import 'settings/sessions_screen.dart';
import 'settings/updates_screen.dart';
import 'settings/about_screen.dart';
import 'settings/wavy_demo_screen.dart';
import '../utils/ui_utils.dart';
import '../utils/m3_motion.dart';

enum SettingsDetail {
  appearance,
  notifications,
  categories,
  backupRestore,
  sessions,
  updates,
  about,
  wavyDemo,
}

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const SettingsScreen({super.key, this.onBack});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SettingsDetail? _selectedDetail = SettingsDetail.appearance;

  void _handleTap(SettingsDetail detail, Widget Function() screenBuilder) {
    if (MediaQuery.sizeOf(context).width >= 800) {
      if (_selectedDetail != detail) {
        setState(() {
          _selectedDetail = detail;
        });
      }
    } else {
      Navigator.push(
        context,
        M3Motion.sharedAxisRoute(screenBuilder()),
      );
    }
  }

  Widget _getDetailScreen() {
    Widget detailScreen;
    switch (_selectedDetail) {
      case SettingsDetail.appearance:
        detailScreen = const AppearanceScreen(isEmbedded: true);
        break;
      case SettingsDetail.notifications:
        detailScreen = const NotificationsScreen(isEmbedded: true);
        break;
      case SettingsDetail.categories:
        detailScreen = const CategoriesScreen(isEmbedded: true);
        break;
      case SettingsDetail.backupRestore:
        detailScreen = const BackupRestoreScreen(isEmbedded: true);
        break;
      case SettingsDetail.sessions:
        detailScreen = const SessionsScreen(isEmbedded: true);
        break;
      case SettingsDetail.updates:
        detailScreen = const UpdatesScreen(isEmbedded: true);
        break;
      case SettingsDetail.about:
        detailScreen = const AboutScreen(isEmbedded: true);
        break;
      case SettingsDetail.wavyDemo:
        detailScreen = const WavyDemoScreen(isEmbedded: true);
        break;
      default:
        detailScreen = const Center(child: Text('Select a setting'));
        break;
    }

    final baseTheme = Theme.of(context);
    return Theme(
      data: baseTheme.copyWith(
        colorScheme: baseTheme.colorScheme.copyWith(
          surfaceContainerLow: baseTheme.colorScheme.surfaceBright,
          surface: baseTheme.colorScheme.surfaceContainerLowest,
        ),
      ),
      child: detailScreen,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final colorTheme = Theme.of(context).colorScheme;
    final bool isExpanded = MediaQuery.sizeOf(context).width >= 800;
    final bool isLarge = context.isLarge;

    final masterList = CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: Text('Settings'),
          titleSpacing: isExpanded ? 0 : 16,
          automaticallyImplyLeading: false,
          leadingWidth: isExpanded ? 80 : 0,
          leading: isExpanded
              ? IconButtonM3E(
                  onPressed: () {
                    if (widget.onBack != null) {
                      widget.onBack!();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Symbols.arrow_back_rounded, weight: 700),
                  tooltip: 'Back',
                  variant: IconButtonM3EVariant.tonal,
                  width: IconButtonM3EWidth.wide,
                )
              : null,
          backgroundColor: colorTheme.surfaceContainer,
          scrolledUnderElevation: 1,
          expandedHeight: 160,
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              // Appearance section
              SettingSection(
                title: Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Display',
                    style: TextStyle(
                      color: colorTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
                    onTap: () => _handleTap(
                      SettingsDetail.appearance,
                      () => const AppearanceScreen(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Task settings section
              SettingSection(
                title: Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Task Managment',
                    style: TextStyle(
                      color: colorTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
                    onTap: () => _handleTap(
                      SettingsDetail.notifications,
                      () => const NotificationsScreen(),
                    ),
                  ),
                  SettingActionTile(
                    icon: iconContainer(
                      Symbols.category,
                      isLight ? Color(0xffcdeda3) : Color(0xff354e16),
                      isLight ? Color(0xff354e16) : Color(0xffcdeda3),
                    ),
                    title: Text('Categories'),
                    description: Text('Manage task categories'),
                    onTap: () => _handleTap(
                      SettingsDetail.categories,
                      () => const CategoriesScreen(),
                    ),
                  ),
                  SettingActionTile(
                    icon: iconContainer(
                      Symbols.backup,
                      isLight ? Color(0xffd6e3ff) : Color(0xff284777),
                      isLight ? Color(0xff284777) : Color(0xffd6e3ff),
                    ),
                    title: Text('Backup & Restore'),
                    description: Text('Export and import your tasks'),
                    onTap: () => _handleTap(
                      SettingsDetail.backupRestore,
                      () => const BackupRestoreScreen(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              SettingSection(
                title: Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Productivity',
                    style: TextStyle(
                      color: colorTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                styleTile: true,
                tiles: [
                  SettingActionTile(
                    icon: iconContainer(
                      Symbols.timer,
                      isLight ? Color(0xffc3f0d1) : Color(0xff0f5132),
                      isLight ? Color(0xff0f5132) : Color(0xffc3f0d1),
                    ),
                    title: Text('Sessions'),
                    description: Text('Ambient mode and timer behavior'),
                    onTap: () => _handleTap(
                      SettingsDetail.sessions,
                      () => const SessionsScreen(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Updates & About section
              SettingSection(
                title: Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'About',
                    style: TextStyle(
                      color: colorTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
                    onTap: () => _handleTap(
                      SettingsDetail.updates,
                      () => const UpdatesScreen(),
                    ),
                  ),
                  SettingActionTile(
                    icon: iconContainer(
                      Symbols.info,
                      isLight ? Color(0xffe6deff) : Color(0xff493e76),
                      isLight ? Color(0xff493e76) : Color(0xffe6deff),
                    ),
                    title: Text('About AntiMatter'),
                    description: Text('Version, licenses, and credits'),
                    onTap: () => _handleTap(
                      SettingsDetail.about,
                      () => const AboutScreen(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Demos section
              SettingSection(
                title: Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Developer Options',
                    style: TextStyle(
                      color: colorTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
                    onTap: () => _handleTap(
                      SettingsDetail.wavyDemo,
                      () => const WavyDemoScreen(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 200),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: colorTheme.surfaceContainer,
      body: isExpanded
          ? Row(
              children: [
                SizedBox(width: 400, child: masterList),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: colorTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: PageTransitionSwitcher(
                        duration: M3Motion.durationMedium2,
                        transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
                          return FadeThroughTransition(
                            animation: primaryAnimation,
                            secondaryAnimation: secondaryAnimation,
                            child: child,
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey<SettingsDetail?>(_selectedDetail),
                          child: _getDetailScreen(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : masterList,
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
