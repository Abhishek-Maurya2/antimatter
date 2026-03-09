import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:settings_tiles/settings_tiles.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import '../../utils/theme_controller.dart';
import '../../notifiers/settings_notifier.dart';
import '../settings_screen.dart'; // For iconContainer helper if we keep it there, or better to duplicate/move. I'll duplicate for now to be self-contained or import if public.
import '../../models/theme_preset.dart';
import 'package:flex_color_picker/flex_color_picker.dart';

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
              child: IconButtonM3E(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Symbols.arrow_back),
                tooltip: 'Back',
                variant: IconButtonM3EVariant.tonal,
                width: IconButtonM3EWidth.wide,
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
                const SizedBox(height: 16),
                _buildThemePresetsSection(context, themeController, colorTheme),
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
                      'Lists',
                      style: TextStyle(
                        color: colorTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  tiles: [
                    SettingSwitchTile(
                      icon: iconContainer(
                        Symbols.sort,
                        isLight ? Color(0xffcce8e0) : Color(0xff334943),
                        isLight ? Color(0xff334943) : Color(0xffcce8e0),
                      ),
                      title: Text('Completed tasks sort'),
                      description: Text('Show newest completed first'),
                      toggled: context
                          .watch<SettingsNotifier>()
                          .sortCompletedNewest,
                      onChanged: (value) {
                        context.read<SettingsNotifier>().setSortCompletedNewest(
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

  Widget _buildThemePresetsSection(
    BuildContext context,
    ThemeController themeController,
    ColorScheme colorTheme,
  ) {
    final allPresets = [...builtInPresets, ...themeController.customPresets];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 16,
            bottom: 8,
            top: 24,
          ),
          child: Text(
            'Theme Presets',
            style: TextStyle(
              color: colorTheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ...allPresets.map((preset) {
                final isActive =
                    themeController.activePresetId == preset.id &&
                    !themeController.useDynamicColors;
                return _buildPresetChip(
                  context,
                  preset,
                  isActive,
                  themeController,
                );
              }),
              _buildAddPresetButton(context, themeController),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(
    BuildContext context,
    ThemePreset preset,
    bool isActive,
    ThemeController themeController,
  ) {
    final colorTheme = Theme.of(context).colorScheme;
    final isCustom = themeController.customPresets.contains(preset);

    return GestureDetector(
      onTap: () {
        themeController.applyPreset(preset);
      },
      onLongPress: isCustom
          ? () {
              // Confirm deletion
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Preset'),
                  content: Text('Delete the custom preset "${preset.name}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        themeController.deleteCustomPreset(preset);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            }
          : null,
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive
              ? colorTheme.primaryContainer
              : colorTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? colorTheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: preset.seedColor,
                shape: BoxShape.circle,
              ),
              child: isActive
                  ? Icon(
                      Symbols.check,
                      color: preset.seedColor.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white,
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              preset.name,
              style: TextStyle(
                fontSize: 12,
                color: isActive
                    ? colorTheme.onPrimaryContainer
                    : colorTheme.onSurface,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPresetButton(
    BuildContext context,
    ThemeController themeController,
  ) {
    final colorTheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () async {
        Color? pickedColor;
        await ColorPicker(
          color: Colors.blue,
          onColorChanged: (Color color) {
            pickedColor = color;
          },
          heading: Text(
            'Select Preset Color',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          subheading: Text(
            'Select color shade',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          pickersEnabled: const <ColorPickerType, bool>{
            ColorPickerType.both: false,
            ColorPickerType.primary: true,
            ColorPickerType.accent: true,
            ColorPickerType.bw: false,
            ColorPickerType.custom: false,
            ColorPickerType.wheel: true,
          },
        ).showPickerDialog(
          context,
          constraints: const BoxConstraints(
            minHeight: 460,
            minWidth: 300,
            maxWidth: 320,
          ),
        );

        if (pickedColor != null) {
          if (!context.mounted) return;
          // Prompt for name
          final nameController = TextEditingController();
          final name = await showDialog<String>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Preset Name'),
              content: TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: 'Enter preset name',
                ),
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, nameController.text),
                  child: const Text('Save'),
                ),
              ],
            ),
          );

          if (name != null && name.trim().isNotEmpty) {
            final newPreset = ThemePreset(
              id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
              name: name.trim(),
              seedColor: pickedColor!,
            );
            themeController.saveCustomPreset(newPreset);
            themeController.applyPreset(newPreset);
          }
        }
      },
      child: Container(
        width: 80,
        height: 100, // Matching roughly the height of the preset chips
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorTheme.outlineVariant,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Symbols.add, size: 32, color: colorTheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(
              'Add New',
              style: TextStyle(
                fontSize: 12,
                color: colorTheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
