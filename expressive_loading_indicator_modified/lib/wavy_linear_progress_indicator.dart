import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A Material Design 3 Expressive Wavy Linear Progress Indicator.
///
/// Track is a straight line. The active indicator is a wavy path that flows
/// smoothly. Uses the cubic-bezier wave algorithm from Android Material
/// Components.
class WavyLinearProgressIndicator extends ProgressIndicator {
  final double minHeight;
  final double waveAmplitude;
  final double waveLength;

  const WavyLinearProgressIndicator({
    super.key,
    super.value,
    super.color,
    super.backgroundColor,
    this.minHeight = 4.0,
    this.waveAmplitude = 3.0,
    this.waveLength = 24.0,
    super.semanticsLabel,
    super.semanticsValue,
  });

  @override
  State<WavyLinearProgressIndicator> createState() =>
      _WavyLinearProgressIndicatorState();
}

class _WavyLinearProgressIndicatorState
    extends State<WavyLinearProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final indicatorTheme = ProgressIndicatorTheme.of(context);
    final cs = Theme.of(context).colorScheme;

    final Color activeColor =
        widget.color ?? indicatorTheme.color ?? cs.primary;
    final Color trackColor =
        widget.backgroundColor ??
        indicatorTheme.linearTrackColor ??
        cs.surfaceContainerHighest;

    return Semantics(
      label: widget.semanticsLabel,
      value: widget.semanticsValue,
      child: Container(
        constraints: BoxConstraints(
          minWidth: double.infinity,
          minHeight: widget.minHeight + widget.waveAmplitude * 2,
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _WavyLinearPainter(
                value: widget.value,
                t: _controller.value,
                activeColor: activeColor,
                trackColor: trackColor,
                strokeWidth: widget.minHeight,
                waveAmplitude: widget.waveAmplitude,
                waveLength: widget.waveLength,
              ),
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
    );
  }
}

// Android's WAVE_SMOOTHNESS constant.
const double _kSmoothness = 0.48;

class _WavyLinearPainter extends CustomPainter {
  final double? value;
  final double t;
  final Color activeColor;
  final Color trackColor;
  final double strokeWidth;
  final double waveAmplitude;
  final double waveLength;

  _WavyLinearPainter({
    required this.value,
    required this.t,
    required this.activeColor,
    required this.trackColor,
    required this.strokeWidth,
    required this.waveAmplitude,
    required this.waveLength,
  });

  /// Builds the full wavy path in world coordinates following Android's
  /// LinearDrawingDelegate.invalidateCachedPaths().
  ///
  /// We build (cycleCount + 1) cycles so there is extra length to scroll
  /// through for the phase animation. The wave is:
  ///   y = amplitude * cos(2π * x / adjWaveLength)
  /// built from half-cycle cubic beziers.
  Path _buildWavyLinePath(double trackWidth, double centerY) {
    final int cycleCount = math.max(1, (trackWidth / waveLength).round());
    final double adjWave = trackWidth / cycleCount;
    // Build one extra cycle for smooth phase scrolling.
    final int totalHalves = (cycleCount + 1) * 2;

    final path = Path();

    for (int i = 0; i <= totalHalves; i++) {
      final double x = i * adjWave / 2;
      // y = amplitude * cos(2π * x / adjWave)
      // At x=0 → y = +amplitude (peak)
      // At x = adjWave/2 → y = -amplitude (trough)
      // Simplifies: at even i → peak, at odd i → trough
      final double y =
          centerY + ((i % 2 == 0) ? waveAmplitude : -waveAmplitude);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final double prevX = (i - 1) * adjWave / 2;
        final double prevY =
            centerY + (((i - 1) % 2 == 0) ? waveAmplitude : -waveAmplitude);

        // Control handles along the x-axis (tangent at peaks/troughs is horizontal).
        final double ctrlDx = adjWave / 2 * _kSmoothness;

        path.cubicTo(prevX + ctrlDx, prevY, x - ctrlDx, y, x, y);
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;

    // Draw straight track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      trackPaint,
    );

    // Active paint
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Build the full wavy path (with one extra cycle for phase scrolling)
    final wavyPath = _buildWavyLinePath(size.width, centerY);
    final metricsList = wavyPath.computeMetrics().toList();
    if (metricsList.isEmpty) return;
    final metrics = metricsList.first;
    final totalLen = metrics.length;

    // One cycle's worth of path length (for the phase scroll range)
    final int cycleCount = math.max(1, (size.width / waveLength).round());
    final double adjWave = size.width / cycleCount;
    // The "real" track occupies the first `cycleCount` cycles.
    // The extra cycle is for smooth phase wrapping.
    // Path length of the base track portion:
    final double baseLen = totalLen * cycleCount / (cycleCount + 1);
    // Path length of one cycle:
    final double oneCycleLen = totalLen / (cycleCount + 1);

    // Phase offset: scrolls smoothly through one full cycle over the animation.
    final double phaseShift = t * oneCycleLen;

    if (value != null) {
      // Determinate
      final double fraction = value!.clamp(0.0, 1.0);
      final double arcLen = baseLen * fraction;
      if (arcLen > 0) {
        final segment = metrics.extractPath(phaseShift, phaseShift + arcLen);
        // Translate so that the wave starts at x=0
        // The phase shift moves the path to the right; we compensate.
        canvas.save();
        canvas.translate(-t * adjWave, 0);
        canvas.drawPath(segment, activePaint);
        canvas.restore();
      }
    } else {
      // Indeterminate: a 30% segment sweeping across
      final double segFraction = 0.3;
      final double segLen = baseLen * segFraction;
      final double totalTravel = baseLen + segLen;
      final double headDist = totalTravel * t - segLen;
      final double startDist = math.max(0.0, headDist);
      final double endDist = math.min(baseLen, headDist + segLen);
      if (endDist > startDist) {
        final segment = metrics.extractPath(
          phaseShift + startDist,
          phaseShift + endDist,
        );
        canvas.save();
        canvas.translate(-t * adjWave, 0);
        canvas.drawPath(segment, activePaint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WavyLinearPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.t != t ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.waveAmplitude != waveAmplitude ||
        oldDelegate.waveLength != waveLength;
  }
}
