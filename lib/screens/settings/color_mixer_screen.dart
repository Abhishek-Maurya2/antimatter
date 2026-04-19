import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../../providers/theme_provider.dart';
import '../../models/theme_preset.dart';

class ColorMixerScreen extends ConsumerStatefulWidget {
  const ColorMixerScreen({super.key});

  @override
  ConsumerState<ColorMixerScreen> createState() => _ColorMixerScreenState();
}

class _ColorMixerScreenState extends ConsumerState<ColorMixerScreen> {
  late Color _seedColor;
  bool _previewDark = false;

  @override
  void initState() {
    super.initState();
    _seedColor = ref.read(themeControllerProvider).seedColor;
  }

  ColorScheme get _lightScheme =>
      ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.light);

  ColorScheme get _darkScheme =>
      ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.dark);

  ColorScheme get _previewScheme => _previewDark ? _darkScheme : _lightScheme;

  void _applyTheme() {
    final themeController = ref.read(themeControllerProvider.notifier);
    final preset = ThemePreset(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Custom Mix',
      seedColor: _seedColor,
    );
    themeController.saveCustomPreset(preset);
    themeController.applyPreset(preset);
    Navigator.of(context).pop();
  }

  Future<void> _saveAsPreset() async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preset Name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Enter preset name'),
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
      final themeController = ref.read(themeControllerProvider.notifier);
      final preset = ThemePreset(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim(),
        seedColor: _seedColor,
      );
      themeController.saveCustomPreset(preset);
      themeController.applyPreset(preset);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.sizeOf(context).width >= 700;

    return Scaffold(
      backgroundColor: colorTheme.surfaceContainer,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Color Mixer'),
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
          ),
          SliverToBoxAdapter(
            child: isWide
                ? _buildWideLayout(colorTheme)
                : _buildNarrowLayout(colorTheme),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildWideLayout(ColorScheme colorTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Controls
          Expanded(
            flex: 5,
            child: _buildColorControls(colorTheme),
          ),
          const SizedBox(width: 32),
          // Phone preview
          Expanded(
            flex: 4,
            child: Center(child: _buildPhonePreview()),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(ColorScheme colorTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Phone preview
          Center(child: _buildPhonePreview()),
          const SizedBox(height: 24),
          // Controls
          _buildColorControls(colorTheme),
        ],
      ),
    );
  }

  Widget _buildColorControls(ColorScheme colorTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Text(
          'Seed Color',
          style: TextStyle(
            fontFamily: 'GoogleSansFlex',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorTheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        // Color picker
        Container(
          decoration: BoxDecoration(
            color: colorTheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(16),
          child: ColorPicker(
            color: _seedColor,
            onColorChanged: (Color color) {
              setState(() => _seedColor = color);
            },
            heading: null,
            subheading: Text(
              'Shade',
              style: TextStyle(
                fontSize: 14,
                color: colorTheme.onSurfaceVariant,
              ),
            ),
            wheelDiameter: 200,
            wheelWidth: 20,
            wheelSquarePadding: 8,
            wheelSquareBorderRadius: 12,
            enableShadesSelection: true,
            pickersEnabled: const <ColorPickerType, bool>{
              ColorPickerType.both: false,
              ColorPickerType.primary: true,
              ColorPickerType.accent: true,
              ColorPickerType.bw: false,
              ColorPickerType.custom: false,
              ColorPickerType.wheel: true,
            },
            width: 36,
            height: 36,
            borderRadius: 18,
            spacing: 6,
            runSpacing: 6,
            columnSpacing: 16,
            showColorCode: true,
            colorCodeHasColor: true,
            colorCodeReadOnly: false,
          ),
        ),
        const SizedBox(height: 20),
        // Preview mode toggle
        Container(
          decoration: BoxDecoration(
            color: colorTheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SwitchListTile(
            title: Text(
              'Preview Dark Mode',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorTheme.onSurface,
              ),
            ),
            secondary: Icon(
              _previewDark ? Symbols.dark_mode_rounded : Symbols.light_mode_rounded,
              weight: 700,
              color: colorTheme.primary,
            ),
            value: _previewDark,
            onChanged: (value) => setState(() => _previewDark = value),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Generated palette preview
        _buildPalettePreview(),
        const SizedBox(height: 24),
        // Action buttons
        Row(
          children: [
            Expanded(
              child: FilledButton.tonal(
                onPressed: _saveAsPreset,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Save as Preset'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _applyTheme,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Apply & Close'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPalettePreview() {
    final cs = _previewScheme;
    final roles = <_PaletteRole>[
      _PaletteRole('Primary', cs.primary, cs.onPrimary),
      _PaletteRole('Secondary', cs.secondary, cs.onSecondary),
      _PaletteRole('Tertiary', cs.tertiary, cs.onTertiary),
      _PaletteRole('Error', cs.error, cs.onError),
      _PaletteRole('Surface', cs.surface, cs.onSurface),
      _PaletteRole('Container', cs.primaryContainer, cs.onPrimaryContainer),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Generated Palette',
          style: TextStyle(
            fontFamily: 'GoogleSansFlex',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: roles.map((role) {
            return Container(
              width: 80,
              height: 56,
              decoration: BoxDecoration(
                color: role.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withAlpha(80),
                ),
              ),
              child: Center(
                child: Text(
                  role.name,
                  style: TextStyle(
                    color: role.onColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────
  //  Phone wireframe
  // ──────────────────────────────────────────

  Widget _buildPhonePreview() {
    final cs = _previewScheme;
    final isDark = _previewDark;

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
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(30),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Status bar
            _buildStatusBar(cs, isDark),
            // App bar
            _buildMockAppBar(cs),
            // Search bar
            _buildMockSearchBar(cs),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Column(
                  children: [
                    // Stats card
                    _buildMockStatsCard(cs),
                    const SizedBox(height: 8),
                    // Task items
                    _buildMockTaskItem(cs, 'Design review', true),
                    const SizedBox(height: 5),
                    _buildMockTaskItem(cs, 'Update docs', false),
                    const SizedBox(height: 5),
                    _buildMockTaskItem(cs, 'Team meeting', false),
                    const SizedBox(height: 5),
                    _buildMockTaskItem(cs, 'Code review', false),
                    const Spacer(),
                    // FAB
                    _buildMockFAB(cs),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            // Bottom nav bar
            _buildMockNavBar(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(ColorScheme cs, bool isDark) {
    final barColor = isDark ? Colors.white.withAlpha(140) : Colors.black.withAlpha(140);
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '9:41',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: barColor),
          ),
          Row(
            children: [
              Icon(Icons.signal_cellular_alt, size: 12, color: barColor),
              const SizedBox(width: 4),
              Icon(Icons.wifi, size: 12, color: barColor),
              const SizedBox(width: 4),
              Icon(Icons.battery_full, size: 12, color: barColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMockAppBar(ColorScheme cs) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Symbols.person, size: 16, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tasks',
              style: TextStyle(
                fontFamily: 'GoogleSansFlex',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Symbols.more_vert_rounded, size: 16, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildMockSearchBar(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(Symbols.search_rounded, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              'Search Tasks',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: cs.onSurfaceVariant.withAlpha(150),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockStatsCard(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_rounded, size: 14, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                'Progress',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '75%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.75,
              minHeight: 8,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat(cs, '12', 'Total'),
              _buildMiniStat(cs, '9', 'Done'),
              _buildMiniStat(cs, '3', 'Left'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(ColorScheme cs, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: cs.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildMockTaskItem(ColorScheme cs, String title, bool completed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Checkbox
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: completed ? cs.primary : Colors.transparent,
              border: Border.all(
                color: completed ? cs.primary : cs.outline,
                width: 1.5,
              ),
            ),
            child: completed
                ? Icon(Icons.check, size: 12, color: cs.onPrimary)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: completed
                    ? cs.onSurfaceVariant.withAlpha(120)
                    : cs.onSurface,
                decoration: completed ? TextDecoration.lineThrough : null,
                decorationColor: cs.onSurfaceVariant.withAlpha(100),
              ),
            ),
          ),
          if (!completed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: cs.tertiaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Today',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: cs.onTertiaryContainer,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMockFAB(ColorScheme cs) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withAlpha(40),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(Icons.add_rounded, color: cs.onPrimaryContainer, size: 24),
      ),
    );
  }

  Widget _buildMockNavBar(ColorScheme cs) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withAlpha(60)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(cs, Symbols.overview_rounded, 'Overview', false),
          _buildNavItem(cs, Symbols.task_alt_rounded, 'Tasks', true),
          _buildNavItem(cs, Symbols.timer_rounded, 'Session', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(ColorScheme cs, IconData icon, String label, bool active) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
          decoration: BoxDecoration(
            color: active ? cs.secondaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            size: 18,
            color: active ? cs.onSecondaryContainer : cs.onSurfaceVariant,
            weight: active ? 700 : 400,
            fill: active ? 1 : 0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? cs.onSurface : cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PaletteRole {
  final String name;
  final Color color;
  final Color onColor;
  const _PaletteRole(this.name, this.color, this.onColor);
}
