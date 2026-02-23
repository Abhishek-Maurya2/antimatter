import 'package:flutter/material.dart';
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
