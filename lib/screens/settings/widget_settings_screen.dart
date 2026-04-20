import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:settings_tiles/settings_tiles.dart';

import '../../providers/theme_provider.dart';
import 'package:home_widget/home_widget.dart';
import '../../services/home_widget_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/task.dart';

class WidgetSettingsScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;

  const WidgetSettingsScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<WidgetSettingsScreen> createState() =>
      _WidgetSettingsScreenState();
}

class _WidgetSettingsScreenState extends ConsumerState<WidgetSettingsScreen> {
  double _opacity = 0.8;
  bool _showCompleted = true;
  String _themeMode = 'system'; // 'system', 'light', 'dark'

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final opacity = await HomeWidget.getWidgetData<double>('widget_opacity');
    final showCompleted = await HomeWidget.getWidgetData<bool>(
      'widget_show_completed',
    );
    final theme = await HomeWidget.getWidgetData<String>('widget_theme');

    if (mounted) {
      setState(() {
        if (opacity != null) _opacity = opacity;
        if (showCompleted != null) _showCompleted = showCompleted;
        if (theme != null) _themeMode = theme;
      });
    }
  }

  Future<void> _saveSettings() async {
    await HomeWidget.saveWidgetData<double>('widget_opacity', _opacity);
    await HomeWidget.saveWidgetData<bool>(
      'widget_show_completed',
      _showCompleted,
    );
    await HomeWidget.saveWidgetData<String>('widget_theme', _themeMode);

    try {
      final box = Hive.box<Task>('tasks');
      await HomeWidgetService.updateTasksWidget(box.values.toList());
    } catch (_) {
      // Box might not be open
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.sizeOf(context).width >= 700;

    final content = CustomScrollView(
      slivers: [
        if (!widget.isEmbedded)
          SliverAppBar.large(
            title: const Text('Home Screen Widget'),
            titleSpacing: 0,
            leadingWidth: 80,
            leading: Center(
              child: IconButtonM3E(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Symbols.arrow_back_rounded, weight: 700),
                tooltip: 'Back',
                variant: IconButtonM3EVariant.tonal,
                width: IconButtonM3EWidth.wide,
              ),
            ),
            backgroundColor: colorTheme.surfaceContainer,
            scrolledUnderElevation: 1,
            expandedHeight: 120,
          )
        else
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 24, bottom: 24),
              child: Text(
                'Home Screen Widget',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorTheme.onSurface,
                ),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: isWide
              ? _buildWideLayout(colorTheme)
              : _buildNarrowLayout(colorTheme),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: colorTheme.surfaceContainer,
      body: content,
    );
  }

  Widget _buildWideLayout(ColorScheme colorTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: _buildControls(colorTheme)),
          const SizedBox(width: 32),
          Expanded(flex: 4, child: Center(child: _buildPhonePreview())),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(ColorScheme colorTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Center(child: _buildPhonePreview()),
          const SizedBox(height: 24),
          _buildControls(colorTheme),
        ],
      ),
    );
  }

  Widget _buildControls(ColorScheme colorTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customizations',
          style: TextStyle(
            fontFamily: 'GoogleSansFlex',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorTheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colorTheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              SettingTextTile(
                icon: const Icon(Symbols.opacity),
                title: const Text('Background Opacity'),
                description: Slider(
                  value: _opacity,
                  onChanged: (val) {
                    setState(() {
                      _opacity = val;
                    });
                    _saveSettings();
                  },
                ),
              ),
              SettingTextTile(
                icon: const Icon(Symbols.palette),
                title: const Text('Widget Theme'),
                description: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'system', label: Text('System')),
                    ButtonSegment(value: 'light', label: Text('Light')),
                    ButtonSegment(value: 'dark', label: Text('Dark')),
                  ],
                  selected: {_themeMode},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _themeMode = newSelection.first;
                    });
                    _saveSettings();
                  },
                ),
              ),
              SettingActionTile(
                icon: const Icon(Symbols.task_alt),
                title: const Text('Show Completed Tasks'),
                trailing: Switch(
                  value: _showCompleted,
                  onChanged: (val) {
                    setState(() {
                      _showCompleted = val;
                    });
                    _saveSettings();
                  },
                ),
                onTap: () {
                  setState(() {
                    _showCompleted = !_showCompleted;
                  });
                  _saveSettings();
                },
              ),
              SettingActionTile(
                icon: const Icon(Symbols.add_to_home_screen),
                title: const Text('Add to Home Screen'),
                onTap: () async {
                  try {
                    await HomeWidget.requestPinWidget(
                      androidName: HomeWidgetService.androidWidgetName,
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not pin widget automatically'),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────
  //  Phone / Widget Preview
  // ──────────────────────────────────────────

  Widget _buildPhonePreview() {
    final bool isAppDark = Theme.of(context).brightness == Brightness.dark;
    final bool isWidgetDark =
        _themeMode == 'dark' || (_themeMode == 'system' && isAppDark);

    // We generate a scheme for the widget based on the current seed
    final seed = ref.read(themeControllerProvider).seedColor;
    final widgetCs = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: isWidgetDark ? Brightness.dark : Brightness.light,
    );

    return Container(
      width: 280,
      height: 560,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Container(
        decoration: BoxDecoration(
          color: isAppDark
              ? Colors.blueGrey.shade900
              : Colors.blueGrey.shade100, // mock wallpaper
          borderRadius: BorderRadius.circular(30),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Mock app icons on the wallpaper
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(4, (index) => _buildMockAppIcon()),
              ),
            ),
            // The Widget itself
            Positioned(
              top: 130,
              left: 20,
              right: 20,
              child: _buildMockWidget(widgetCs),
            ),
            // Bottom dock
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(4, (index) => _buildMockAppIcon()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockAppIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(120),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildMockWidget(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: _opacity),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withAlpha(60), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tasks',
                style: TextStyle(
                  fontFamily: 'GoogleSansFlex',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMockTaskItem(cs, 'Design review', false),
          const SizedBox(height: 6),
          _buildMockTaskItem(cs, 'Update docs', false),
          if (_showCompleted) ...[
            const SizedBox(height: 6),
            _buildMockTaskItem(cs, 'Team meeting', true),
          ],
        ],
      ),
    );
  }

  Widget _buildMockTaskItem(ColorScheme cs, String title, bool completed) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed ? cs.primary : Colors.transparent,
            border: Border.all(
              color: completed ? cs.primary : cs.outline,
              width: 1.5,
            ),
          ),
          child: completed
              ? Icon(Icons.check, size: 10, color: cs.onPrimary)
              : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: completed
                  ? cs.onSurfaceVariant.withAlpha(120)
                  : cs.onSurface,
              decoration: completed ? TextDecoration.lineThrough : null,
              decorationColor: cs.onSurfaceVariant.withAlpha(100),
            ),
          ),
        ),
      ],
    );
  }
}
