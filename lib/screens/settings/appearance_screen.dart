import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:settings_tiles/settings_tiles.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';
import '../../providers/settings_provider.dart';
import '../settings_screen.dart'; // For iconContainer helper if we keep it there, or better to duplicate/move. I'll duplicate for now to be self-contained or import if public.
import '../../models/theme_preset.dart';
import 'package:flex_color_picker/flex_color_picker.dart';

class AppearanceScreen extends ConsumerWidget {
  final bool isEmbedded;
  const AppearanceScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorTheme = Theme.of(context).colorScheme;
    final themeState = ref.watch(themeControllerProvider);
    final themeControllerNotifier = ref.read(themeControllerProvider.notifier);
    final isLight = Theme.of(context).brightness == Brightness.light;

    final Map<String, String> optionsTheme = {
      "Auto": "System Default",
      "Light": "Light",
      "Dark": "Dark",
    };
    final currentMode = themeState.themeMode;

    return Scaffold(
      backgroundColor: isEmbedded
          ? colorTheme.surfaceContainerLow
          : colorTheme.surfaceContainer,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text('Appearance'),
            titleSpacing: isEmbedded ? 16 : 0,
            leadingWidth: isEmbedded ? 0 : 80,
            automaticallyImplyLeading: !isEmbedded,
            leading: isEmbedded
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
            backgroundColor: isEmbedded
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
                      'Theme',
                      style: TextStyle(
                        color: colorTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  tiles: [
                    SettingSingleOptionTile(
                      icon: iconContainer(
                        Symbols.routine_rounded,
                        isLight
                            ? const Color.fromARGB(193, 255, 224, 130)
                            : const Color(0xff6a5113),
                        isLight
                            ? const Color(0xff6a5113)
                            : const Color(0xffffe082),
                      ),
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
                        themeControllerNotifier.setThemeMode(
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
                      toggled: themeState.useDynamicColors,
                      onChanged: (value) =>
                          themeControllerNotifier.setUseDynamicColors(value),
                    ),
                    SettingSwitchTile(
                      icon: iconContainer(
                        Symbols.palette,
                        isLight ? Color(0xffffd6f9) : Color(0xff633664),
                        isLight ? Color(0xff633664) : Color(0xffffd6f9),
                      ),
                      title: Text('Vibrant colors'),
                      description: Text('Use vibrant M3 variant'),
                      toggled: ref
                          .watch(settingsControllerProvider)
                          .useVibrantVariant,
                      onChanged: (value) {
                        ref
                            .read(settingsControllerProvider.notifier)
                            .updateColorVariant(value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildThemePresetsSection(context, ref, colorTheme),
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
                      toggled: ref
                          .watch(settingsControllerProvider)
                          .sortCompletedNewest,
                      onChanged: (value) {
                        ref
                            .read(settingsControllerProvider.notifier)
                            .setSortCompletedNewest(value);
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
    WidgetRef ref,
    ColorScheme colorTheme,
  ) {
    final themeState = ref.watch(themeControllerProvider);
    final themeControllerNotifier = ref.read(themeControllerProvider.notifier);
    final allPresets = [...builtInPresets, ...themeState.customPresets];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: 12,
            top: 24,
          ),
          child: Text(
            'Theme Presets',
            style: TextStyle(
              color: colorTheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            scrollDirection: Axis.horizontal,
            itemCount: allPresets.length + 1,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index < allPresets.length) {
                final preset = allPresets[index];
                final isActive =
                    themeState.activePresetId == preset.id &&
                    !themeState.useDynamicColors;
                return _buildPresetCard(
                  context,
                  preset,
                  isActive,
                  themeState,
                  themeControllerNotifier,
                );
              } else {
                return _buildAddPresetButton(context, themeControllerNotifier);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPresetCard(
    BuildContext context,
    ThemePreset preset,
    bool isActive,
    ThemeState themeState,
    ThemeController themeControllerNotifier,
  ) {
    final colorTheme = Theme.of(context).colorScheme;
    final isCustom = themeState.customPresets.contains(preset);

    return GestureDetector(
      onTap: () {
        themeControllerNotifier.applyPreset(preset);
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
                        themeControllerNotifier.deleteCustomPreset(preset);
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive
              ? colorTheme.primaryContainer.withAlpha(200)
              : colorTheme.surfaceContainerHighest.withAlpha(150),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? colorTheme.primary : colorTheme.outlineVariant.withAlpha(100),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: colorTheme.primary.withAlpha(40),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      preset.seedColor,
                      preset.seedColor.withAlpha(150),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: preset.seedColor.withAlpha(100),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedScale(
                    scale: isActive ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Symbols.check,
                        color: Colors.white,
                        size: 24,
                        weight: 800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              preset.name,
              style: TextStyle(
                fontSize: 13,
                color: isActive
                    ? colorTheme.onPrimaryContainer
                    : colorTheme.onSurface,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPresetButton(
    BuildContext context,
    ThemeController themeControllerNotifier,
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
            themeControllerNotifier.saveCustomPreset(newPreset);
            themeControllerNotifier.applyPreset(newPreset);
          }
        }
      },
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorTheme.surfaceContainerHighest.withAlpha(100),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorTheme.outlineVariant.withAlpha(80),
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorTheme.surfaceContainerHigh.withAlpha(150),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(
                    Symbols.add,
                    size: 32,
                    color: colorTheme.onSurfaceVariant,
                    weight: 600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add New',
              style: TextStyle(
                fontSize: 13,
                color: colorTheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
