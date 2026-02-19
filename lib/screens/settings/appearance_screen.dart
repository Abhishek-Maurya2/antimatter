import 'package:flutter/material.dart';
import 'package:settings_tiles/settings_tiles.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import '../../utils/theme_controller.dart';
import '../../notifiers/settings_notifier.dart';
import '../settings_screen.dart'; // For iconContainer helper if we keep it there, or better to duplicate/move. I'll duplicate for now to be self-contained or import if public.

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;
    final themeController = Provider.of<ThemeController>(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: colorTheme.surfaceContainer,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text('Appearance'),
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
                      'Theme',
                      style: TextStyle(
                        color: colorTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  tiles: [
                    SettingActionTile(
                      title: Text('System Default'),
                      trailing: themeController.themeMode == ThemeMode.system
                          ? Icon(Symbols.check, color: colorTheme.primary)
                          : null,
                      onTap: () {
                        themeController.setThemeMode(ThemeMode.system);
                      },
                    ),
                    SettingActionTile(
                      title: Text('Light'),
                      trailing: themeController.themeMode == ThemeMode.light
                          ? Icon(Symbols.check, color: colorTheme.primary)
                          : null,
                      onTap: () {
                        themeController.setThemeMode(ThemeMode.light);
                      },
                    ),
                    SettingActionTile(
                      title: Text('Dark'),
                      trailing: themeController.themeMode == ThemeMode.dark
                          ? Icon(Symbols.check, color: colorTheme.primary)
                          : null,
                      onTap: () {
                        themeController.setThemeMode(ThemeMode.dark);
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
                      'Colors',
                      style: TextStyle(
                        color: colorTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
