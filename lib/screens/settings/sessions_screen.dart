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
  bool _stayAwakeEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _ambientModeEnabled =
        PreferencesHelper.getBool('ambientModeEnabled') ?? true;
    _stayAwakeEnabled = PreferencesHelper.getBool('stayAwakeEnabled') ?? true;
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
          ? colorTheme.surfaceContainerLow
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
                      min: 1,
                      max: 30,
                      divisions: 10,
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
                    SettingSwitchTile(
                      icon: iconContainer(
                        Symbols.keep,
                        isLight
                            ? const Color(0xfffce4ec)
                            : const Color(0xff880e4f).withValues(alpha: 0.2),
                        isLight
                            ? const Color(0xff880e4f)
                            : const Color(0xfffce4ec),
                      ),
                      title: const Text('Stay Awake'),
                      description: const Text(
                        'Prevent device from sleeping during sessions',
                      ),
                      toggled: _stayAwakeEnabled,
                      onChanged: (value) {
                        setState(() => _stayAwakeEnabled = value);
                        PreferencesHelper.setBool('stayAwakeEnabled', value);
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
