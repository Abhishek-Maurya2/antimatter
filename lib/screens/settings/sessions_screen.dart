import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:settings_tiles/settings_tiles.dart';

import '../../utils/preferences_helper.dart';
import '../settings_screen.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

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
    _ambientModeEnabled = PreferencesHelper.getBool('ambientModeEnabled') ?? true;
    final savedInterval = PreferencesHelper.getInt('ambientModeIntervalSeconds') ??
        5;
    _ambientIntervalSeconds = savedInterval.clamp(1, 60);
    setState(() {});
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
            title: Text('Sessions'),
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
                    SettingSliderTile(
                      enabled: _ambientModeEnabled,
                      icon: iconContainer(
                        Symbols.timer,
                        isLight ? Color(0xffd6e3ff) : Color(0xff284777),
                        isLight ? Color(0xff284777) : Color(0xffd6e3ff),
                      ),
                      title: Text('Ambient Interval'),
                      description: Text('Time before ambient mode starts'),
                      dialogTitle: 'Ambient Interval (seconds)',
                      value: SettingTileValue('$_ambientIntervalSeconds sec'),
                      min: 1,
                      max: 60,
                      divisions: 59,
                      initialValue: _ambientIntervalSeconds.toDouble(),
                      label: (value) => '${value.round()} sec',
                      onSubmitted: (value) {
                        final seconds = value.round();
                        setState(() => _ambientIntervalSeconds = seconds);
                        PreferencesHelper.setInt(
                          'ambientModeIntervalSeconds',
                          seconds,
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