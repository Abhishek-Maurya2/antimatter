import 'dart:math' as math;
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

  // Wavy Slider Demo state
  double _wavySliderValue = 0.5;

  // Broken Wavy Circular Controls State
  double _brokenGap = 10.0;
  double _brokenAmplitude = 4.0;
  double _brokenWavelength = 30.0;
  double _brokenStrokeWidth = 4.0;
  double _brokenSpeed = 1.0;

  Widget _buildSliderControl(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text('$label:', style: const TextStyle(fontSize: 12))),
          Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: widget.isEmbedded
            ? colorTheme.surfaceContainerLow
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
                        icon: const Icon(
                          Symbols.arrow_back_rounded,
                          weight: 800,
                        ),
                        tooltip: 'Back',
                        variant: IconButtonM3EVariant.tonal,
                        width: IconButtonM3EWidth.wide,
                      ),
                    ),
              backgroundColor: widget.isEmbedded
                  ? colorTheme.surfaceContainerLow
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
        const SizedBox(height: 32),
        if (isDeterminate) ...[
          Text(
            'Custom Wavy Slider',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorTheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          _DemoCard(
            title: 'Wavy Slider (Locked to 30x4)',
            colorTheme: colorTheme,
            child: Column(
              children: [
                WavySlider(
                  value: _wavySliderValue,
                  onChanged: (v) => setState(() => _wavySliderValue = v),
                  thumbHeight: 30.0,
                  thumbWidth: 4.0,
                  thumbRadius: 4,
                  gap: 6.0,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _DemoCard(
            title: 'Broken Wavy Circular Indicator',
            colorTheme: colorTheme,
            child: Column(
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: BrokenWavyCircularProgressIndicator(
                    value: _wavySliderValue,
                    strokeWidth: _brokenStrokeWidth,
                    gap: _brokenGap,
                    waveAmplitude: _brokenAmplitude,
                    waveLength: _brokenWavelength,
                    animationSpeed: _brokenSpeed,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSliderControl('Gap', _brokenGap, 0, 30, (v) => setState(() => _brokenGap = v)),
                _buildSliderControl('Amplitude', _brokenAmplitude, 0, 15, (v) => setState(() => _brokenAmplitude = v)),
                _buildSliderControl('Wavelength', _brokenWavelength, 10, 80, (v) => setState(() => _brokenWavelength = v)),
                _buildSliderControl('Width', _brokenStrokeWidth, 1, 15, (v) => setState(() => _brokenStrokeWidth = v)),
                _buildSliderControl('Speed', _brokenSpeed, 0, 5, (v) => setState(() => _brokenSpeed = v)),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
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

class WavySlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double thumbWidth;
  final double thumbHeight;
  final double thumbRadius;
  final double gap;
  final double trackHeight;

  const WavySlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.thumbWidth = 4.0,
    this.thumbHeight = 30.0,
    this.thumbRadius = 2.0,
    this.gap = 6.0,
    this.trackHeight = 4.0,
  });

  @override
  State<WavySlider> createState() => _WavySliderState();
}

class _WavySliderState extends State<WavySlider> {
  bool _isPressed = false;

  void _handleDragUpdate(DragUpdateDetails details, double width) {
    double newValue = details.localPosition.dx / width;
    widget.onChanged(newValue.clamp(0.0, 1.0));
  }

  void _handleTap(TapDownDetails details, double width) {
    double newValue = details.localPosition.dx / width;
    widget.onChanged(newValue.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final thumbPosition = widget.value * totalWidth;

        // Calculate available space for tracks
        final leftTrackWidth = (thumbPosition - widget.gap).clamp(0.0, totalWidth);
        final rightTrackStart = (thumbPosition + widget.gap).clamp(0.0, totalWidth);
        final rightTrackWidth = (totalWidth - rightTrackStart).clamp(0.0, totalWidth);

        // Animation offsets
        final currentThumbWidth = _isPressed ? widget.thumbWidth - 1 : widget.thumbWidth;
        final currentThumbHeight = _isPressed ? widget.thumbHeight + 4 : widget.thumbHeight;
        final currentThumbRadius = _isPressed ? widget.thumbRadius + 2 : widget.thumbRadius;

        return GestureDetector(
          onHorizontalDragStart: (_) => setState(() => _isPressed = true),
          onHorizontalDragUpdate: (details) =>
              _handleDragUpdate(details, totalWidth),
          onHorizontalDragEnd: (_) => setState(() => _isPressed = false),
          onHorizontalDragCancel: () => setState(() => _isPressed = false),
          onTapDown: (details) {
            setState(() => _isPressed = true);
            _handleTap(details, totalWidth);
          },
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: widget.thumbHeight + 10, // constant height to avoid layout shift
            width: double.infinity,
            child: Stack(
              alignment: Alignment.centerLeft,
              clipBehavior: Clip.none,
              children: [
                // Right side - Flat Rail
                if (rightTrackWidth > 0)
                  Positioned(
                    left: rightTrackStart,
                    right: 0,
                    child: Center(
                      child: Container(
                        height: widget.trackHeight,
                        decoration: BoxDecoration(
                          color: colorTheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(widget.trackHeight),
                        ),
                      ),
                    ),
                  ),

                // Left side - Wavy Track
                if (leftTrackWidth > 0)
                  Positioned(
                    left: 0,
                    width: leftTrackWidth,
                    child: Center(
                      child: SizedBox(
                        height: widget.trackHeight + 10,
                        child: WavyLinearProgressIndicator(
                          value: 1.0,
                          minHeight: widget.trackHeight,
                          color: colorTheme.primary,
                          backgroundColor: Colors.transparent,
                          waveAmplitude: 5,
                          waveLength: 28.0,
                        ),
                      ),
                    ),
                  ),

                // Thin & Long Thumb (Animated)
                Positioned(
                  left: thumbPosition - (currentThumbWidth / 2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOutCubic,
                    width: currentThumbWidth,
                    height: currentThumbHeight,
                    decoration: BoxDecoration(
                      color: colorTheme.primary,
                      borderRadius: BorderRadius.circular(currentThumbRadius),
                      boxShadow: [
                        BoxShadow(
                          color: colorTheme.primary.withAlpha(_isPressed ? 80 : 50),
                          blurRadius: _isPressed ? 12 : 8,
                          offset: Offset(0, _isPressed ? 4 : 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class BrokenWavyCircularProgressIndicator extends StatefulWidget {
  final double value;
  final double strokeWidth;
  final double gap;
  final double waveAmplitude;
  final double waveLength;
  final double animationSpeed;
  final Color? color;
  final Color? backgroundColor;

  const BrokenWavyCircularProgressIndicator({
    super.key,
    required this.value,
    this.strokeWidth = 4.0,
    this.gap = 8.0,
    this.waveAmplitude = 4.0,
    this.waveLength = 22.0,
    this.animationSpeed = 1.0,
    this.color,
    this.backgroundColor,
  });

  @override
  State<BrokenWavyCircularProgressIndicator> createState() => _BrokenWavyCircularProgressIndicatorState();
}

class _BrokenWavyCircularProgressIndicatorState extends State<BrokenWavyCircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _applySpeed();
  }

  @override
  void didUpdateWidget(BrokenWavyCircularProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationSpeed != widget.animationSpeed) {
      _applySpeed();
    }
  }

  void _applySpeed() {
    if (widget.animationSpeed <= 0) {
      _controller.stop();
    } else {
      final int durationMs = (3000 / widget.animationSpeed).round();
      _controller.duration = Duration(milliseconds: durationMs);
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;
    final activeColor = widget.color ?? colorTheme.primary;
    final trackColor = widget.backgroundColor ?? colorTheme.surfaceContainerHighest;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _BrokenWavyCircularIndicatorPainter(
            value: widget.value,
            t: _controller.value,
            activeColor: activeColor,
            trackColor: trackColor,
            strokeWidth: widget.strokeWidth,
            gap: widget.gap,
            waveAmplitude: widget.waveAmplitude,
            waveLength: widget.waveLength,
          ),
        );
      },
    );
  }
}

class _BrokenWavyCircularIndicatorPainter extends CustomPainter {
  final double value;
  final double t; // animation value 0..1
  final Color activeColor;
  final Color trackColor;
  final double strokeWidth;
  final double gap;
  final double waveAmplitude;
  final double waveLength;

  _BrokenWavyCircularIndicatorPainter({
    required this.value,
    required this.t,
    required this.activeColor,
    required this.trackColor,
    required this.strokeWidth,
    required this.gap,
    required this.waveAmplitude,
    required this.waveLength,
  });

  Path _buildWavyCirclePath(double radius, Offset center) {
    final double circumference = 2 * math.pi * radius;
    final int cycleCount = math.max(3, (circumference / waveLength).round());
    final double adjWave = circumference / cycleCount;
    final int halfCycles = cycleCount * 2;
    final path = Path();

    for (int copy = 0; copy < 2; copy++) {
      for (int i = 0; i <= halfCycles; i++) {
        final double dist = i * adjWave / 2;
        final double theta = (copy * circumference + dist) / radius;
        final double shift = (i % 2 == 1) ? -waveAmplitude : 0.0;
        final double r = radius + shift;

        final double px = center.dx + r * math.cos(theta - math.pi / 2);
        final double py = center.dy + r * math.sin(theta - math.pi / 2);

        if (copy == 0 && i == 0) {
          path.moveTo(px, py);
        } else {
          final double prevDist = (copy == 0 && i == 0) ? 0 : (i > 0 ? (i - 1) * adjWave / 2 : halfCycles * adjWave / 2);
          final double prevTheta = (i > 0 ? (copy * circumference + prevDist) : ((copy - 1) * circumference + (halfCycles * adjWave / 2))) / radius;
          final double prevShift = ((i > 0 ? i - 1 : halfCycles) % 2 == 1) ? -waveAmplitude : 0.0;
          final double prevR = radius + prevShift;
          final double prevPx = center.dx + prevR * math.cos(prevTheta - math.pi / 2);
          final double prevPy = center.dy + prevR * math.sin(prevTheta - math.pi / 2);

          final double prevTx = -math.sin(prevTheta - math.pi / 2);
          final double prevTy = math.cos(prevTheta - math.pi / 2);
          final double tx = -math.sin(theta - math.pi / 2);
          final double ty = math.cos(theta - math.pi / 2);
          final double ctrlLen = (adjWave / 2) * _kSmoothness;

          path.cubicTo(prevPx + ctrlLen * prevTx, prevPy + ctrlLen * prevTy, px - ctrlLen * tx, py - ctrlLen * ty, px, py);
        }
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - strokeWidth - waveAmplitude;
    final circumference = 2 * math.pi * radius;

    final int cycleCount = math.max(3, (circumference / waveLength).round());
    final double adjWave = circumference / cycleCount;

    final gapAngle = gap / radius;
    final totalSweep = 2 * math.pi;
    final progressSweep = (value * totalSweep).clamp(0.0, totalSweep);

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Build the STATIC wavy path
    final wavyPath = _buildWavyCirclePath(radius, center);
    final metricsList = wavyPath.computeMetrics().toList();
    
    if (metricsList.isNotEmpty) {
      final metrics = metricsList.first;
      final totalLen = metrics.length;
      final halfLen = totalLen / 2;

      // Extract shift based on true path length
      final double oneCycleLen = halfLen / cycleCount;
      final double phaseShiftPathLen = t * oneCycleLen;
      // Rotation shift based on geometric arc
      final double phaseShiftAngular = (t * adjWave) / radius;

      // Convert visual gap to path metric gap approximating scale
      final double pathGapLen = (gap / circumference) * halfLen;

      // Active Wavy Arc (Double-Broken: gap at start and end)
      final arcLen = (progressSweep / totalSweep) * halfLen;
      final double startExtract = pathGapLen;
      final double endExtract = math.max(startExtract, arcLen - pathGapLen);

      if (endExtract > startExtract) {
        final segment = metrics.extractPath(
          phaseShiftPathLen + startExtract, 
          phaseShiftPathLen + endExtract
        );
        
        // Temporarily rotate the canvas so the first extracted point lands exactly at its fixed visual spot.
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(-phaseShiftAngular);
        canvas.translate(-center.dx, -center.dy);
        
        canvas.drawPath(segment, activePaint);
        
        canvas.restore();
      }
    }

    // Inactive Flat Rail (value+gap up to 2pi - gap)
    final startRail = progressSweep + gapAngle;
    final endRail = totalSweep - gapAngle;
    final sweepRail = endRail - startRail;

    if (sweepRail > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startRail - (math.pi / 2),
        sweepRail,
        false,
        trackPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BrokenWavyCircularIndicatorPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.t != t ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.waveAmplitude != waveAmplitude ||
        oldDelegate.waveLength != waveLength;
  }
}

const double _kSmoothness = 0.48;

