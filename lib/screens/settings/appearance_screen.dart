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

    final Map<String, String> optionsTheme = {
      "Auto": "System Default",
      "Light": "Light",
      "Dark": "Dark",
    };
    final currentMode = themeController.themeMode;

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
                    SettingSingleOptionTile(
                      icon: const Icon(Symbols.routine),
                      title: const Text('Theme'),
                      dialogTitle: 'Theme',
                      value: SettingTileValue(
                        optionsTheme[currentMode == ThemeMode.light
                            ? "Light"
                            : currentMode == ThemeMode.system
                            ? "Auto"
                            : "Dark"]!,
                      ),
                      options: optionsTheme.values.toList(),
                      initialOption:
                          optionsTheme[currentMode == ThemeMode.light
                              ? "Light"
                              : currentMode == ThemeMode.system
                              ? "Auto"
                              : "Dark"]!,
                      onSubmitted: (value) {
                        final selectedKey = optionsTheme.entries
                            .firstWhere((e) => e.value == value)
                            .key;
                        themeController.setThemeMode(
                          selectedKey == "Dark"
                              ? ThemeMode.dark
                              : selectedKey == "Auto"
                              ? ThemeMode.system
                              : ThemeMode.light,
                        );
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
                        Symbols.format_paint,
                        isLight ? Color(0xffd6e2ff) : Color(0xff004a77),
                        isLight ? Color(0xff004a77) : Color(0xffd6e2ff),
                      ),
                      title: Text('Device colors'),
                      description: Text('Use device accent colors'),
                      toggled: themeController.useDynamicColors,
                      onChanged: (value) {
                        themeController.setUseDynamicColors(value);
                      },
                    ),
                    SettingSwitchTile(
                      icon: iconContainer(
                        Symbols.palette,
                        isLight ? Color(0xffffd6f9) : Color(0xff633664),
                        isLight ? Color(0xff633664) : Color(0xffffd6f9),
                      ),
                      title: Text('Vibrant colors'),
                      description: Text('Use vibrant M3 variant'),
                      toggled: context
                          .watch<SettingsNotifier>()
                          .useVibrantVariant,
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
