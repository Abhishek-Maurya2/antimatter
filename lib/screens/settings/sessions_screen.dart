import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:settings_tiles/settings_tiles.dart';
import 'package:m3e_collection/m3e_collection.dart'
    hide ExpressiveLoadingIndicator;

import '../../utils/preferences_helper.dart';
import '../settings_screen.dart';

class SessionsScreen extends StatefulWidget {
  final bool isEmbedded;
  const SessionsScreen({super.key, this.isEmbedded = false});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  bool _ambientModeEnabled = true;
  int _ambientIntervalSeconds = 5;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _ambientModeEnabled =
        PreferencesHelper.getBool('ambientModeEnabled') ?? true;
    final savedInterval =
        PreferencesHelper.getInt('ambientModeIntervalSeconds') ?? 5;
    _ambientIntervalSeconds = savedInterval.clamp(1, 60);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: widget.isEmbedded
          ? Colors.transparent
          : colorTheme.surfaceContainer,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text('Sessions'),
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
                ? Colors.transparent
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
                      'Ambient Mode',
                      style: TextStyle(
                        color: colorTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  tiles: [
                    SettingSwitchTile(
                      icon: iconContainer(
                        Symbols.dark_mode,
                        isLight ? Color(0xffe6deff) : Color(0xff493e76),
                        isLight ? Color(0xff493e76) : Color(0xffe6deff),
                      ),
                      title: Text('Enable Ambient Mode'),
                      description: Text('Auto-enter immersive focus mode'),
                      toggled: _ambientModeEnabled,
                      onChanged: (value) {
                        setState(() => _ambientModeEnabled = value);
                        PreferencesHelper.setBool('ambientModeEnabled', value);
                      },
                    ),
                    SettingInlineSliderTile(
                      enabled: _ambientModeEnabled,
                      icon: iconContainer(
                        Symbols.timer,
                        isLight ? Color(0xffd6e3ff) : Color(0xff284777),
                        isLight ? Color(0xff284777) : Color(0xffd6e3ff),
                      ),
                      title: const Text('Ambient Interval'),
                      description: const Text(
                        'Time before ambient mode starts',
                      ),
                      sliderValue: _ambientIntervalSeconds.toDouble(),
                      min: 1.0,
                      max: 60.0,
                      divisions: 59,
                      label: (val) => '${val.round()} sec',
                      onChanged: (val) {
                        setState(() => _ambientIntervalSeconds = val.round());
                      },
                      onChangeEnd: (val) {
                        PreferencesHelper.setInt(
                          'ambientModeIntervalSeconds',
                          val.round(),
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

class SettingInlineSliderTile extends SettingTile {
  final double sliderValue;
  final double min;
  final double max;
  final int divisions;
  final String Function(double) label;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  const SettingInlineSliderTile({
    super.key,
    super.enabled = true,
    super.icon,
    super.title,
    super.description,
    super.visible = true,
    required this.sliderValue,
    required this.min,
    required this.max,
    required this.divisions,
    required this.label,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (icon != null) ...[icon!, const SizedBox(width: 16)],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          DefaultTextStyle(
                            style: textTheme.bodyLarge!.copyWith(
                              color: colorScheme.onSurface,
                            ),
                            child: title!,
                          ),
                        if (description != null) ...[
                          const SizedBox(height: 2),
                          DefaultTextStyle(
                            style: textTheme.bodyMedium!.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            child: description!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    label(sliderValue),
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (icon != null) const SizedBox(width: 56),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: SizedBox(
                              height: 16,
                              child: LinearProgressIndicatorM3E(
                                value: (sliderValue - min) / (max - min),
                                shape: ProgressM3EShape.wavy,
                              ),
                            ),
                          ),
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.transparent,
                            inactiveTrackColor: Colors.transparent,
                          ),
                          child: Slider(
                            value: sliderValue,
                            min: min,
                            max: max,
                            divisions: divisions,
                            label: label(sliderValue),
                            onChanged: onChanged,
                            onChangeEnd: onChangeEnd,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
