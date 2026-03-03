import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';

class WavyDemoScreen extends StatefulWidget {
  const WavyDemoScreen({super.key});

  @override
  State<WavyDemoScreen> createState() => _WavyDemoScreenState();
}

class _WavyDemoScreenState extends State<WavyDemoScreen> {
  double _sliderValue = 0.5;
  bool _isDeterminate = true;

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorTheme.surfaceContainer,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text('Wavy Indicators'),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Mode toggle ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: Text('Determinate'),
                        selected: _isDeterminate,
                        onSelected: (v) =>
                            setState(() => _isDeterminate = true),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text('Indeterminate'),
                        selected: !_isDeterminate,
                        onSelected: (v) =>
                            setState(() => _isDeterminate = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Progress slider (only for determinate) ---
                  if (_isDeterminate) ...[
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

                  // --- Circular Indicator ---
                  _DemoCard(
                    title: 'Wavy Circular',
                    colorTheme: colorTheme,
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: WavyCircularProgressIndicator(
                        value: _isDeterminate ? _sliderValue : null,
                        strokeWidth: 5.0,
                        waveAmplitude: 3.0,
                        waveLength: 20.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Linear Indicator ---
                  _DemoCard(
                    title: 'Wavy Linear',
                    colorTheme: colorTheme,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        height: 14,
                        child: WavyLinearProgressIndicator(
                          value: _isDeterminate ? _sliderValue : null,
                          minHeight: 4.0,
                          waveAmplitude: 3.0,
                          waveLength: 24.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Larger amplitude variants ---
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
                        value: _isDeterminate ? _sliderValue : null,
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
                          value: _isDeterminate ? _sliderValue : null,
                          minHeight: 4.0,
                          waveAmplitude: 5.0,
                          waveLength: 32.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Buttons section ---
                  Text(
                    'Buttons',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DemoCard(
                    title: 'Spring Motion Button',
                    colorTheme: colorTheme,
                    child: Center(
                      child: _SpringPhysicsButton(
                        icon: Symbols.play_arrow,
                        label: 'Animate',
                        onPressed: () {},
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpringPhysicsButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _SpringPhysicsButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  State<_SpringPhysicsButton> createState() => _SpringPhysicsButtonState();
}

class _SpringPhysicsButtonState extends State<_SpringPhysicsButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;

  final SpringDescription _spring = SpringDescription.withDampingRatio(
    ratio: 0.6,
    stiffness: 200.0,
    mass: 1.0,
  );

  bool _pressedVisual = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController.unbounded(vsync: this)..value = 0.0;
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _animateTo(double target, double velocity) {
    _pressController.animateWith(
      SpringSimulation(
        _spring,
        _pressController.value,
        target,
        velocity,
        snapToEnd: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressedVisual = true);
        _animateTo(1.0, 0.0);
      },
      onTapUp: (_) {
        setState(() => _pressedVisual = false);
        _animateTo(0.0, 0.0);
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() => _pressedVisual = false);
        _animateTo(0.0, 0.0);
      },
      child: AnimatedBuilder(
        animation: _pressController,
        builder: (context, _) {
          final motion = _pressController.value;
          final scale = (1 - (0.08 * motion)).clamp(0.90, 1.04);
          final radius = (24 - (10 * motion)).clamp(12.0, 28.0);

          return Transform.scale(
            scale: scale,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: _pressedVisual
                    ? colorTheme.primary
                    : colorTheme.primaryContainer,
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    fill: 1,
                    size: 20,
                    color: _pressedVisual
                        ? colorTheme.onPrimary
                        : colorTheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _pressedVisual
                          ? colorTheme.onPrimary
                          : colorTheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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
