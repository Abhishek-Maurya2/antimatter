import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';

class WavyDemoScreen extends StatefulWidget {
  final bool isEmbedded;
  const WavyDemoScreen({super.key, this.isEmbedded = false});

  @override
  State<WavyDemoScreen> createState() => _WavyDemoScreenState();
}

class _WavyDemoScreenState extends State<WavyDemoScreen> {
  double _sliderValue = 0.5;
  bool _isToggleSelected = false;

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: widget.isEmbedded
            ? Colors.transparent
            : colorTheme.surfaceContainer,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar.large(
              title: const Text('Wavy Indicators'),
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
              expandedHeight: 160, // slightly taller for tabs
              pinned: true,
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Determinate'),
                  Tab(text: 'Indeterminate'),
                  Tab(text: 'Buttons'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _buildIndicatorsList(colorTheme, true),
              _buildIndicatorsList(colorTheme, false),
              _buildButtonsList(colorTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicatorsList(ColorScheme colorTheme, bool isDeterminate) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (isDeterminate) ...[
          Row(
            children: [
              Text(
                'Progress: ${(_sliderValue * 100).round()}%',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorTheme.onSurface,
                ),
              ),
            ],
          ),
          Slider(
            value: _sliderValue,
            onChanged: (v) => setState(() => _sliderValue = v),
          ),
          const SizedBox(height: 16),
        ],
        _DemoCard(
          title: 'Wavy Circular',
          colorTheme: colorTheme,
          child: SizedBox(
            width: 64,
            height: 64,
            child: WavyCircularProgressIndicator(
              value: isDeterminate ? _sliderValue : null,
              strokeWidth: 5.0,
              waveAmplitude: 3.0,
              waveLength: 20.0,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _DemoCard(
          title: 'Wavy Linear',
          colorTheme: colorTheme,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 14,
              child: WavyLinearProgressIndicator(
                value: isDeterminate ? _sliderValue : null,
                minHeight: 4.0,
                waveAmplitude: 3.0,
                waveLength: 24.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Larger Amplitude',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorTheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        _DemoCard(
          title: 'Circular (amp: 5)',
          colorTheme: colorTheme,
          child: SizedBox(
            width: 64,
            height: 64,
            child: WavyCircularProgressIndicator(
              value: isDeterminate ? _sliderValue : null,
              strokeWidth: 4.0,
              waveAmplitude: 5.0,
              waveLength: 24.0,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _DemoCard(
          title: 'Linear (amp: 5)',
          colorTheme: colorTheme,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 18,
              child: WavyLinearProgressIndicator(
                value: isDeterminate ? _sliderValue : null,
                minHeight: 4.0,
                waveAmplitude: 5.0,
                waveLength: 32.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButtonsList(ColorScheme colorTheme) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // --- Toggles & Shape Morphing ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Toggle Switch Demo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorTheme.primary,
              ),
            ),
            Switch(
              value: _isToggleSelected,
              onChanged: (v) => setState(() => _isToggleSelected = v),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DemoCard(
          title: 'Toggle Buttons (Shape Morphs on Select)',
          colorTheme: colorTheme,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              SpringButton(
                icon: _isToggleSelected ? Symbols.check : Symbols.add,
                label: 'Subscribe',
                onPressed: () =>
                    setState(() => _isToggleSelected = !_isToggleSelected),
                variant: SpringButtonVariant.toggle,
                isSelected: _isToggleSelected,
                shape: SpringButtonShape.round,
              ),
              SpringIconButton(
                icon: _isToggleSelected
                    ? Symbols.favorite
                    : Symbols.favorite_border,
                onPressed: () =>
                    setState(() => _isToggleSelected = !_isToggleSelected),
                variant: SpringIconButtonVariant.toggle,
                isSelected: _isToggleSelected,
                colorStyle: SpringIconButtonColorStyle.tonal,
                shape:
                    SpringButtonShape.square, // Morphs to round when selected
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // --- Standard Buttons by Style ---
        Text(
          'Button Styles',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorTheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        _DemoCard(
          title: 'SpringButton Styles',
          colorTheme: colorTheme,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              SpringButton(
                icon: Symbols.play_arrow,
                label: 'Filled',
                onPressed: () {},
                colorStyle: SpringButtonColorStyle.filled,
              ),
              SpringButton(
                icon: Symbols.flight,
                label: 'Elevated',
                onPressed: () {},
                colorStyle: SpringButtonColorStyle.elevated,
              ),
              SpringButton(
                icon: Symbols.edit,
                label: 'Tonal',
                onPressed: () {},
                colorStyle: SpringButtonColorStyle.tonal,
              ),
              SpringButton(
                icon: Symbols.search,
                label: 'Outlined',
                onPressed: () {},
                colorStyle: SpringButtonColorStyle.outlined,
              ),
              SpringButton(
                label: 'Text',
                onPressed: () {},
                colorStyle: SpringButtonColorStyle.text,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _DemoCard(
          title: 'SpringIconButton Styles',
          colorTheme: colorTheme,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              SpringIconButton(
                icon: Symbols.settings,
                onPressed: () {},
                colorStyle: SpringIconButtonColorStyle.filled,
              ),
              SpringIconButton(
                icon: Symbols.notifications,
                onPressed: () {},
                colorStyle: SpringIconButtonColorStyle.tonal,
              ),
              SpringIconButton(
                icon: Symbols.share,
                onPressed: () {},
                colorStyle: SpringIconButtonColorStyle.outlined,
              ),
              SpringIconButton(
                icon: Symbols.more_vert,
                onPressed: () {},
                colorStyle: SpringIconButtonColorStyle.standard,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // --- Sizes ---
        Text(
          'Sizes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorTheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        _DemoCard(
          title: 'Button Sizes',
          colorTheme: colorTheme,
          child: Column(
            children: [
              SpringButton(
                icon: Symbols.add,
                label: 'Extra Small',
                onPressed: () {},
                size: SpringButtonSize.extraSmall,
                colorStyle: SpringButtonColorStyle.tonal,
              ),
              const SizedBox(height: 8),
              SpringButton(
                icon: Symbols.add,
                label: 'Small (Default)',
                onPressed: () {},
                size: SpringButtonSize.small,
              ),
              const SizedBox(height: 8),
              SpringButton(
                icon: Symbols.add,
                label: 'Medium',
                onPressed: () {},
                size: SpringButtonSize.medium,
              ),
              const SizedBox(height: 8),
              SpringButton(
                icon: Symbols.add,
                label: 'Large',
                onPressed: () {},
                size: SpringButtonSize.large,
              ),
              const SizedBox(height: 8),
              SpringButton(
                icon: Symbols.add,
                label: 'Extra Large',
                onPressed: () {},
                size: SpringButtonSize.extraLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _DemoCard(
          title: 'Icon Button Widths',
          colorTheme: colorTheme,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SpringIconButton(
                icon: Symbols.bookmark,
                onPressed: () {},
                width: SpringIconButtonWidth.narrow,
                colorStyle: SpringIconButtonColorStyle.tonal,
              ),
              SpringIconButton(
                icon: Symbols.bookmark,
                onPressed: () {},
                width: SpringIconButtonWidth.defaultWidth,
                colorStyle: SpringIconButtonColorStyle.tonal,
              ),
              SpringIconButton(
                icon: Symbols.bookmark,
                onPressed: () {},
                width: SpringIconButtonWidth.wide,
                colorStyle: SpringIconButtonColorStyle.tonal,
              ),
            ],
          ),
        ),
        const SizedBox(height: 100), // Bottom padding
      ],
    );
  }
}

class _DemoCard extends StatelessWidget {
  final String title;
  final ColorScheme colorTheme;
  final Widget child;

  const _DemoCard({
    required this.title,
    required this.colorTheme,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
