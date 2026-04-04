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

  // Wavy Slider Demo state
  double _wavySliderValue = 0.5;
  double _wavySliderGap = 6.0;
  double _wavySliderAmplitude = 5.0;
  double _wavySliderWavelength = 30.0;
  double _wavySliderWidth = 4.0;

  // Broken Wavy Linear Controls State
  double _brokenLinearGap = 10.0;
  double _brokenLinearAmplitude = 4.0;
  double _brokenLinearWavelength = 30.0;
  double _brokenLinearStrokeWidth = 4.0;
  double _brokenLinearSpeed = 1.0;

  // Broken Wavy Circular Controls State
  double _brokenGap = 10.0;
  double _brokenAmplitude = 4.0;
  double _brokenWavelength = 30.0;
  double _brokenStrokeWidth = 4.0;
  double _brokenSpeed = 1.0;
  
  // Official M3E Demo State
  double _m3eProgress = 0.5;

  Widget _buildSliderControl(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text('$label:', style: const TextStyle(fontSize: 12)),
          ),
          Text(
            value.toStringAsFixed(1),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: WavySlider(
                value: (value - min) / (max - min),
                onChanged: (v) => onChanged(min + v * (max - min)),
                thumbHeight: 22.0,
                thumbWidth: 3.0,
                trackHeight: 2.5,
                gap: 6.0,
                waveAmplitude: 3.0,
                waveLength: 20.0,
              ),
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
                  Tab(text: 'Official M3E'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _buildIndicatorsList(colorTheme, true),
              _buildIndicatorsList(colorTheme, false),
              _buildOfficialM3EList(colorTheme),
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
            title: 'Broken Wavy Slider',
            colorTheme: colorTheme,
            child: Column(
              children: [
                WavySlider(
                  value: _wavySliderValue,
                  onChanged: (v) => setState(() => _wavySliderValue = v),
                  thumbHeight: 30.0,
                  thumbWidth: 4.0,
                  thumbRadius: 4,
                  gap: _wavySliderGap,
                  waveAmplitude: _wavySliderAmplitude,
                  waveLength: _wavySliderWavelength,
                  trackHeight: _wavySliderWidth,
                ),
                const SizedBox(height: 16),
                _buildSliderControl(
                  'Gap',
                  _wavySliderGap,
                  0,
                  30,
                  (v) => setState(() => _wavySliderGap = v),
                ),
                _buildSliderControl(
                  'Amplitude',
                  _wavySliderAmplitude,
                  0,
                  15,
                  (v) => setState(() => _wavySliderAmplitude = v),
                ),
                _buildSliderControl(
                  'Wavelength',
                  _wavySliderWavelength,
                  10,
                  80,
                  (v) => setState(() => _wavySliderWavelength = v),
                ),
                _buildSliderControl(
                  'Width',
                  _wavySliderWidth,
                  1,
                  15,
                  (v) => setState(() => _wavySliderWidth = v),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        _DemoCard(
          title: isDeterminate
              ? 'Broken Wavy Linear (Determinate)'
              : 'Broken Wavy Linear (Indeterminate)',
          colorTheme: colorTheme,
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 30,
                child: BrokenWavyLinearProgressIndicator(
                  value: isDeterminate ? _wavySliderValue : null,
                  strokeWidth: _brokenLinearStrokeWidth,
                  gap: _brokenLinearGap,
                  waveAmplitude: _brokenLinearAmplitude,
                  waveLength: _brokenLinearWavelength,
                  animationSpeed: _brokenLinearSpeed,
                ),
              ),
              const SizedBox(height: 16),
              _buildSliderControl(
                'Gap',
                _brokenLinearGap,
                0,
                30,
                (v) => setState(() => _brokenLinearGap = v),
              ),
              _buildSliderControl(
                'Amplitude',
                _brokenLinearAmplitude,
                0,
                15,
                (v) => setState(() => _brokenLinearAmplitude = v),
              ),
              _buildSliderControl(
                'Wavelength',
                _brokenLinearWavelength,
                10,
                80,
                (v) => setState(() => _brokenLinearWavelength = v),
              ),
              _buildSliderControl(
                'Width',
                _brokenLinearStrokeWidth,
                1,
                15,
                (v) => setState(() => _brokenLinearStrokeWidth = v),
              ),
              _buildSliderControl(
                'Speed',
                _brokenLinearSpeed,
                0,
                5,
                (v) => setState(() => _brokenLinearSpeed = v),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _DemoCard(
          title: isDeterminate
              ? 'Broken Wavy Circular (Determinate)'
              : 'Broken Wavy Circular (Indeterminate)',
          colorTheme: colorTheme,
          child: Column(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: BrokenWavyCircularProgressIndicator(
                  value: isDeterminate ? _wavySliderValue : null,
                  strokeWidth: _brokenStrokeWidth,
                  gap: _brokenGap,
                  waveAmplitude: _brokenAmplitude,
                  waveLength: _brokenWavelength,
                  animationSpeed: _brokenSpeed,
                ),
              ),
              const SizedBox(height: 16),
              _buildSliderControl(
                'Gap',
                _brokenGap,
                0,
                30,
                (v) => setState(() => _brokenGap = v),
              ),
              _buildSliderControl(
                'Amplitude',
                _brokenAmplitude,
                0,
                15,
                (v) => setState(() => _brokenAmplitude = v),
              ),
              _buildSliderControl(
                'Wavelength',
                _brokenWavelength,
                10,
                80,
                (v) => setState(() => _brokenWavelength = v),
              ),
              _buildSliderControl(
                'Width',
                _brokenStrokeWidth,
                1,
                15,
                (v) => setState(() => _brokenStrokeWidth = v),
              ),
              _buildSliderControl(
                'Speed',
                _brokenSpeed,
                0,
                5,
                (v) => setState(() => _brokenSpeed = v),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOfficialM3EList(ColorScheme colorTheme) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Slider M3E',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorTheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        _DemoCard(
          title: 'Official M3E Slider',
          colorTheme: colorTheme,
          child: Column(
            children: [
              SliderM3E(
                value: _m3eProgress,
                onChanged: (v) => setState(() => _m3eProgress = v),
                label: '${(_m3eProgress * 100).round()}%',
                startIcon: const Icon(Symbols.volume_down),
                endIcon: const Icon(Symbols.volume_up),
              ),
              const SizedBox(height: 16),
              SliderM3E(
                value: _m3eProgress,
                onChanged: (v) => setState(() => _m3eProgress = v),
                emphasis: SliderM3EEmphasis.secondary,
                size: SliderM3ESize.large,
              ),
              const SizedBox(height: 16),
              _buildSliderControl(
                'Value',
                _m3eProgress,
                0,
                1,
                (v) => setState(() => _m3eProgress = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Progress Indicators M3E',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorTheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        _DemoCard(
          title: 'Linear Progress (Official)',
          colorTheme: colorTheme,
          child: Column(
            children: [
              const Text('Wavy Shape', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              LinearProgressIndicatorM3E(
                value: _m3eProgress,
                shape: ProgressM3EShape.wavy,
              ),
              const SizedBox(height: 24),
              const Text('Flat Shape', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              LinearProgressIndicatorM3E(
                value: _m3eProgress,
                shape: ProgressM3EShape.flat,
              ),
              const SizedBox(height: 24),
              const Text('Indeterminate', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              const LinearProgressIndicatorM3E(
                value: null,
                shape: ProgressM3EShape.wavy,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _DemoCard(
          title: 'Circular Progress (Official)',
          colorTheme: colorTheme,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  CircularProgressIndicatorM3E(
                    value: _m3eProgress,
                    shape: ProgressM3EShape.wavy,
                  ),
                  const SizedBox(height: 8),
                  const Text('Wavy', style: TextStyle(fontSize: 10)),
                ],
              ),
              Column(
                children: [
                  CircularProgressIndicatorM3E(
                    value: _m3eProgress,
                    shape: ProgressM3EShape.flat,
                  ),
                  const SizedBox(height: 8),
                  const Text('Flat', style: TextStyle(fontSize: 10)),
                ],
              ),
              const Column(
                children: [
                  CircularProgressIndicatorM3E(
                    value: null,
                    shape: ProgressM3EShape.wavy,
                  ),
                  SizedBox(height: 8),
                  Text('Indet.', style: TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
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
  final double waveAmplitude;
  final double waveLength;

  const WavySlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.thumbWidth = 8.0,
    this.thumbHeight = 30.0,
    this.thumbRadius = 2.0,
    this.gap = 6,
    this.trackHeight = 4.0,
    this.waveAmplitude = 5.0,
    this.waveLength = 28.0,
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
    final effectiveAmplitude = widget.value >= 1.0 ? 0.0 : widget.waveAmplitude;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final thumbPosition = widget.value * totalWidth;

        // Calculate available space for tracks
        final leftTrackWidth = (thumbPosition - widget.gap).clamp(
          0.0,
          totalWidth,
        );
        final rightTrackStart = (thumbPosition + widget.gap).clamp(
          0.0,
          totalWidth,
        );
        final rightTrackWidth = (totalWidth - rightTrackStart).clamp(
          0.0,
          totalWidth,
        );

        // Animation offsets
        final currentThumbWidth = _isPressed
            ? widget.thumbWidth - 1
            : widget.thumbWidth;
        final currentThumbHeight = _isPressed
            ? widget.thumbHeight + 4
            : widget.thumbHeight;
        final currentThumbRadius = _isPressed
            ? widget.thumbRadius + 2
            : widget.thumbRadius;

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
            height:
                widget.thumbHeight +
                10, // constant height to avoid layout shift
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
                          borderRadius: BorderRadius.circular(
                            widget.trackHeight,
                          ),
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
                          waveAmplitude: effectiveAmplitude,
                          waveLength: widget.waveLength,
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
                          color: colorTheme.primary.withAlpha(
                            _isPressed ? 80 : 50,
                          ),
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
  final double? value;
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
  State<BrokenWavyCircularProgressIndicator> createState() =>
      _BrokenWavyCircularProgressIndicatorState();
}

class _BrokenWavyCircularProgressIndicatorState
    extends State<BrokenWavyCircularProgressIndicator>
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
    final trackColor =
        widget.backgroundColor ?? colorTheme.surfaceContainerHighest;
    final effectiveAmplitude = (widget.value != null && widget.value! >= 1.0) ? 0.0 : widget.waveAmplitude;

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
            waveAmplitude: effectiveAmplitude,
            waveLength: widget.waveLength,
          ),
        );
      },
    );
  }
}

class _BrokenWavyCircularIndicatorPainter extends CustomPainter {
  final double? value;
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
          final double prevDist = (copy == 0 && i == 0)
              ? 0
              : (i > 0 ? (i - 1) * adjWave / 2 : halfCycles * adjWave / 2);
          final double prevTheta =
              (i > 0
                  ? (copy * circumference + prevDist)
                  : ((copy - 1) * circumference + (halfCycles * adjWave / 2))) /
              radius;
          final double prevShift = ((i > 0 ? i - 1 : halfCycles) % 2 == 1)
              ? -waveAmplitude
              : 0.0;
          final double prevR = radius + prevShift;
          final double prevPx =
              center.dx + prevR * math.cos(prevTheta - math.pi / 2);
          final double prevPy =
              center.dy + prevR * math.sin(prevTheta - math.pi / 2);

          final double prevTx = -math.sin(prevTheta - math.pi / 2);
          final double prevTy = math.cos(prevTheta - math.pi / 2);
          final double tx = -math.sin(theta - math.pi / 2);
          final double ty = math.cos(theta - math.pi / 2);
          final double ctrlLen = (adjWave / 2) * _kSmoothness;

          path.cubicTo(
            prevPx + ctrlLen * prevTx,
            prevPy + ctrlLen * prevTy,
            px - ctrlLen * tx,
            py - ctrlLen * ty,
            px,
            py,
          );
        }
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        (math.min(size.width, size.height) / 2) - strokeWidth - waveAmplitude;
    final circumference = 2 * math.pi * radius;

    final int cycleCount = math.max(3, (circumference / waveLength).round());
    final double adjWave = circumference / cycleCount;

    final gapAngle = gap / radius;
    final totalSweep = 2 * math.pi;

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
    if (metricsList.isEmpty) return;

    final metrics = metricsList.first;
    final totalLen = metrics.length;
    final halfLen = totalLen / 2;

    final double oneCycleLen = halfLen / cycleCount;
    final double pathGapLen = (gap / circumference) * halfLen;

    if (value != null) {
      // Determinate mode (uses 'value')
      final double progressSweep = (value! * totalSweep).clamp(0.0, totalSweep);

      final double arcLen = (progressSweep / totalSweep) * halfLen;
      final double startExtract = pathGapLen;
      final double endExtract = math.max(startExtract, arcLen - pathGapLen);

      if (endExtract > startExtract) {
        final double phaseShiftPathLen = t * oneCycleLen;
        final double phaseShiftAngular = (t * adjWave) / radius;

        final segment = metrics.extractPath(
          phaseShiftPathLen + startExtract,
          phaseShiftPathLen + endExtract,
        );

        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(-phaseShiftAngular);
        canvas.translate(-center.dx, -center.dy);

        canvas.drawPath(segment, activePaint);
        canvas.restore();
      }

      // Inactive track
      final double startRail = progressSweep + gapAngle;
      final double endRail = totalSweep - gapAngle;
      final double sweepRail = endRail - startRail;

      if (sweepRail > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startRail - (math.pi / 2),
          sweepRail,
          false,
          trackPaint,
        );
      }
    } else {
      // Indeterminate mode (sweeping and expanding)
      final double baseRotation =
          t * math.pi * 6; // Spins 3 times completely across the 3s period

      // Sweep angle smoothly expands and shrinks: 15% to 80% coverage
      final double sweepFraction =
          0.15 + 0.65 * (0.5 * (1 - math.cos(t * math.pi * 4)));
      final double currentSweepAngle = sweepFraction * totalSweep;

      // Draw the Active Sweeping Arc
      final double arcLen = sweepFraction * halfLen;
      final double startExtract = pathGapLen;
      final double endExtract = math.max(startExtract, arcLen - pathGapLen);

      if (endExtract > startExtract) {
        // We directly extract from the start (0), effectively anchoring the waves to the arc itself
        // So no phaseShift is internally applied, and waves don't "shimmy", they just sweep.
        final segment = metrics.extractPath(startExtract, endExtract);

        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(baseRotation);
        canvas.translate(-center.dx, -center.dy);

        canvas.drawPath(segment, activePaint);
        canvas.restore();
      }

      // Draw the Broken Tracking Inactive Rail
      final double startRail = currentSweepAngle + gapAngle;
      final double endRail = totalSweep - gapAngle;
      final double sweepRail = endRail - startRail;

      if (sweepRail > 0) {
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(
          baseRotation,
        ); // Spin it exactly identically to the active arc!
        canvas.translate(-center.dx, -center.dy);

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startRail - (math.pi / 2),
          sweepRail,
          false,
          trackPaint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(
    covariant _BrokenWavyCircularIndicatorPainter oldDelegate,
  ) {
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

class BrokenWavyLinearProgressIndicator extends StatefulWidget {
  final double? value;
  final double strokeWidth;
  final double gap;
  final double waveAmplitude;
  final double waveLength;
  final double animationSpeed;
  final Color? color;
  final Color? backgroundColor;

  const BrokenWavyLinearProgressIndicator({
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
  State<BrokenWavyLinearProgressIndicator> createState() =>
      _BrokenWavyLinearProgressIndicatorState();
}

class _BrokenWavyLinearIndicatorPainter extends CustomPainter {
  final double? value;
  final double t; // animation value 0..1
  final Color activeColor;
  final Color trackColor;
  final double strokeWidth;
  final double gap;
  final double waveAmplitude;
  final double waveLength;

  _BrokenWavyLinearIndicatorPainter({
    required this.value,
    required this.t,
    required this.activeColor,
    required this.trackColor,
    required this.strokeWidth,
    required this.gap,
    required this.waveAmplitude,
    required this.waveLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0) return;
    final centerY = size.height / 2;

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

    double startX = 0;
    double endX = 0;

    if (value != null) {
      // Determinate
      startX = 0;
      endX = (value! * size.width).clamp(0.0, size.width);
    } else {
      // Indeterminate
      final double progress = t;
      final double pulse = 0.5 * (1 - math.cos(progress * math.pi * 6));
      final double currentWidth = (0.15 + 0.3 * pulse) * size.width;

      final double travelTotal = size.width + currentWidth;
      endX = progress * travelTotal; // sweeps linearly from 0 to bounds!
      startX = endX - currentWidth;
    }

    // Adjust render bounds to firmly define active area within visual component
    final double boundedStart = startX.clamp(0.0, size.width);
    final double boundedEnd = endX.clamp(0.0, size.width);

    // Build the global immutable wave track spanning the entire width perfectly
    final int cycleCount = math.max(1, (size.width / waveLength).round());
    final double adjWave = size.width / cycleCount;
    final int totalPoints = (cycleCount + 1) * 2;
    final double extendedWidth = size.width + adjWave;

    final basePath = Path();
    for (int i = 0; i <= totalPoints; i++) {
      final double x = i * adjWave / 2;
      final double py = (i % 2 == 1) ? centerY - waveAmplitude : centerY;
      if (i == 0) {
        basePath.moveTo(x, py);
      } else {
        final double prevX = (i - 1) * adjWave / 2;
        final double prevPy = ((i - 1) % 2 == 1)
            ? centerY - waveAmplitude
            : centerY;
        final double ctrlX = adjWave / 2 * _kSmoothness;
        basePath.cubicTo(prevX + ctrlX, prevPy, x - ctrlX, py, x, py);
      }
    }

    final metricsList = basePath.computeMetrics().toList();
    if (metricsList.isEmpty) return;
    final metrics = metricsList.first;

    final double ratio = metrics.length / extendedWidth;
    final double phaseShift = t * adjWave;

    // The physical active wave logic: starts after the gap, ends before the gap
    final double activeWaveStartX = boundedStart + gap;
    final double activeWaveEndX = boundedEnd - gap;

    if (activeWaveEndX > activeWaveStartX) {
      final double startL = (activeWaveStartX + phaseShift) * ratio;
      final double endL = (activeWaveEndX + phaseShift) * ratio;

      final segment = metrics.extractPath(startL, endL);
      
      canvas.save();
      canvas.translate(-phaseShift, 0);
      canvas.drawPath(segment, activePaint);
      canvas.restore();
    }

    // Draw Broken Inactive Rail perfectly respecting the exact bounded regions
    // Back track from 0 to boundedStart
    if (boundedStart > 0) {
      canvas.drawLine(
        Offset(0, centerY),
        Offset(boundedStart, centerY),
        trackPaint,
      );
    }

    // Front track from boundedEnd to size.width
    if (boundedEnd < size.width) {
      canvas.drawLine(
        Offset(boundedEnd, centerY),
        Offset(size.width, centerY),
        trackPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BrokenWavyLinearIndicatorPainter oldDelegate) {
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

class _BrokenWavyLinearProgressIndicatorState
    extends State<BrokenWavyLinearProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _applySpeed();
  }

  @override
  void didUpdateWidget(BrokenWavyLinearProgressIndicator oldWidget) {
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
    final trackColor =
        widget.backgroundColor ?? colorTheme.surfaceContainerHighest;
    final effectiveAmplitude = (widget.value != null && widget.value! >= 1.0) ? 0.0 : widget.waveAmplitude;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          // Remove manual size so it automatically adopts parent SizedBox scale
          painter: _BrokenWavyLinearIndicatorPainter(
            value: widget.value,
            t: _controller.value,
            activeColor: activeColor,
            trackColor: trackColor,
            strokeWidth: widget.strokeWidth,
            gap: widget.gap,
            waveAmplitude: effectiveAmplitude,
            waveLength: widget.waveLength,
          ),
        );
      },
    );
  }
}
