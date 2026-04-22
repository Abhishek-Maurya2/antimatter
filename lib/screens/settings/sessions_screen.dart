import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:settings_tiles/settings_tiles.dart';
import 'package:m3e_collection/m3e_collection.dart'
    hide ExpressiveLoadingIndicator;

import '../../utils/preferences_helper.dart';
import '../settings_screen.dart';
import '../../widgets/settings_app_bar.dart';

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
  bool _ambientTaskEnabled = true;
  String _ambientTaskPosition = 'bottom-right';

  static const List<String> _positionOptions = [
    'top-left',
    'top-center',
    'top-right',
    'bottom-left',
    'bottom-center',
    'bottom-right',
  ];

  static const Map<String, String> _positionLabels = {
    'top-left': 'Top Left',
    'top-center': 'Top Center',
    'top-right': 'Top Right',
    'bottom-left': 'Bottom Left',
    'bottom-center': 'Bottom Center',
    'bottom-right': 'Bottom Right',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _ambientModeEnabled =
        PreferencesHelper.getBool('ambientModeEnabled') ?? true;
    _stayAwakeEnabled = PreferencesHelper.getBool('stayAwakeEnabled') ?? true;
    _ambientTaskEnabled =
        PreferencesHelper.getBool('ambientTaskEnabled') ?? true;
    _ambientTaskPosition =
        PreferencesHelper.getString('ambientTaskPosition') ?? 'bottom-right';
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
          SettingsAppBar(title: 'Sessions', isEmbedded: widget.isEmbedded),
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
                    SettingSwitchTile(
                      enabled: _ambientModeEnabled,
                      icon: iconContainer(
                        Symbols.task_alt,
                        isLight ? const Color(0xffd7f5d3) : const Color(0xff1b5e20).withValues(alpha: 0.3),
                        isLight ? const Color(0xff1b5e20) : const Color(0xffd7f5d3),
                      ),
                      title: const Text('Show Current Task'),
                      description: const Text(
                        'Display your next task during ambient mode',
                      ),
                      toggled: _ambientTaskEnabled,
                      onChanged: (value) {
                        setState(() => _ambientTaskEnabled = value);
                        PreferencesHelper.setBool('ambientTaskEnabled', value);
                      },
                    ),
                    SettingSingleOptionTile<String>.detailed(
                      enabled: _ambientModeEnabled && _ambientTaskEnabled,
                      icon: iconContainer(
                        Symbols.drag_pan,
                        isLight ? const Color(0xfffff3e0) : const Color(0xffe65100).withValues(alpha: 0.2),
                        isLight ? const Color(0xffe65100) : const Color(0xfffff3e0),
                      ),
                      title: const Text('Task Position'),
                      description: Text(_positionLabels[_ambientTaskPosition] ?? 'Bottom Right'),
                      dialogTitle: 'Task Position',
                      options: _positionOptions.map((pos) => (
                        value: pos as Object,
                        title: _positionLabels[pos]!,
                        subtitle: null as String?,
                      )).toList(),
                      initialOption: _ambientTaskPosition,
                      onSubmitted: (pos) {
                        setState(() => _ambientTaskPosition = pos);
                        PreferencesHelper.setString('ambientTaskPosition', pos);
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
