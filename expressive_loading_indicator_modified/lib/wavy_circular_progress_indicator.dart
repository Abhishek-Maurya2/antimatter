import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A Material Design 3 Expressive Wavy Circular Progress Indicator.
///
/// Track is a smooth circle. The active indicator is a wavy path that flows
/// smoothly around the circle. Uses the cubic-bezier wave algorithm from
/// Android Material Components.
class WavyCircularProgressIndicator extends ProgressIndicator {
  final double strokeWidth;
  final double waveAmplitude;
  final double waveLength;
  final bool showTrack;

  const WavyCircularProgressIndicator({
    super.key,
    super.value,
    super.color,
    super.backgroundColor,
    this.strokeWidth = 4.0,
    this.waveAmplitude = 3.0,
    this.waveLength = 20.0,
    this.showTrack = true,
    super.semanticsLabel,
    super.semanticsValue,
  });

  @override
  State<WavyCircularProgressIndicator> createState() =>
      _WavyCircularProgressIndicatorState();
}

class _WavyCircularProgressIndicatorState
    extends State<WavyCircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
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
        indicatorTheme.circularTrackColor ??
        cs.surfaceContainerHighest;

    return Semantics(
      label: widget.semanticsLabel,
      value: widget.semanticsValue,
      child: SizedBox(
        width: 48,
        height: 48,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _WavyCircularPainter(
                value: widget.value,
                t: _controller.value,
                activeColor: activeColor,
                trackColor: trackColor,
                strokeWidth: widget.strokeWidth,
                waveAmplitude: widget.waveAmplitude,
                waveLength: widget.waveLength,
                showTrack: widget.showTrack,
              ),
            );
          },
        ),
      ),
    );
  }
}

// Android's WAVE_SMOOTHNESS constant.
const double _kSmoothness = 0.48;

class _WavyCircularPainter extends CustomPainter {
  final double? value;
  final double t; // animation value 0..1
  final Color activeColor;
  final Color trackColor;
  final double strokeWidth;
  final double waveAmplitude;
  final double waveLength;
  final bool showTrack;

  _WavyCircularPainter({
    required this.value,
    required this.t,
    required this.activeColor,
    required this.trackColor,
    required this.strokeWidth,
    required this.waveAmplitude,
    required this.waveLength,
    required this.showTrack,
  });

  /// Builds TWO copies of a wavy circle path so that we can extract any
  /// contiguous segment up to one full circumference starting from any point.
  /// This is the same trick Android uses (two copies of the base circle).
  Path _buildFullWavyCirclePath(double radius, Offset center) {
    final double circumference = 2 * math.pi * radius;
    final int cycleCount = math.max(3, (circumference / waveLength).round());
    final double adjWave = circumference / cycleCount;
    final int halfCycles = cycleCount * 2; // per copy

    // For each half-cycle anchor:
    //   even index → on the circle (no shift)
    //   odd index  → shifted inward by amplitude
    // Then connected with cubic beziers using _kSmoothness.

    final path = Path();

    // We build 2 copies (like Android) for seamless wrapping.
    for (int copy = 0; copy < 2; copy++) {
      for (int i = 0; i <= halfCycles; i++) {
        // arc distance from start of this copy
        final double dist = i * adjWave / 2;
        final double theta = (copy * circumference + dist) / radius;
        // Shift: odd half-cycle anchors are pushed inward
        final double shift = (i % 2 == 1) ? -waveAmplitude : 0.0;
        final double r = radius + shift;

        final double px = center.dx + r * math.cos(theta - math.pi / 2);
        final double py = center.dy + r * math.sin(theta - math.pi / 2);

        if (copy == 0 && i == 0) {
          path.moveTo(px, py);
        } else {
          // Previous anchor
          final double prevDist = (copy == 0 && i == 0)
              ? 0
              : (i > 0 ? (i - 1) * adjWave / 2 : halfCycles * adjWave / 2);
          final double prevTheta =
              (i > 0
                  ? (copy * circumference + prevDist)
                  : ((copy - 1) * circumference + halfCycles * adjWave / 2)) /
              radius;
          final double prevShift = ((i > 0 ? i - 1 : halfCycles) % 2 == 1)
              ? -waveAmplitude
              : 0.0;
          final double prevR = radius + prevShift;

          final double prevPx =
              center.dx + prevR * math.cos(prevTheta - math.pi / 2);
          final double prevPy =
              center.dy + prevR * math.sin(prevTheta - math.pi / 2);

          // Tangent at prev point (perpendicular to radius, clockwise)
          final double prevTx = -math.sin(prevTheta - math.pi / 2);
          final double prevTy = math.cos(prevTheta - math.pi / 2);
          // Tangent at current point
          final double tx = -math.sin(theta - math.pi / 2);
          final double ty = math.cos(theta - math.pi / 2);

          final double ctrlLen = adjWave / 2 * _kSmoothness;

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

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw smooth track circle
    if (showTrack) {
      canvas.drawCircle(center, radius, trackPaint);
    }

    // Build the full wavy path (2 copies for wrapping)
    final wavyPath = _buildFullWavyCirclePath(radius, center);
    final metrics = wavyPath.computeMetrics().first;
    final totalLen = metrics.length; // ~2x circumference
    final halfLen = totalLen / 2; // ~1x circumference

    // Phase: smoothly shift where we start extracting from.
    // t goes 0→1 continuously, so phase scrolls the wave smoothly.
    final double phaseShift = t * halfLen;

    if (value != null) {
      // Determinate: extract an arc of length proportional to value
      final double arcLen = halfLen * value!.clamp(0.0, 1.0);
      if (arcLen > 0) {
        final start = phaseShift;
        final end = phaseShift + arcLen;
        final segment = metrics.extractPath(start, math.min(end, totalLen));
        canvas.drawPath(segment, activePaint);
      }
    } else {
      // Indeterminate: pulsing arc that spins
      final double spinPhase = t * halfLen * 2; // spins faster
      final double pulseFraction =
          0.2 + 0.15 * math.sin(t * 2 * math.pi); // 20-35% of circumference
      final double arcLen = halfLen * pulseFraction;
      final start = (spinPhase + phaseShift) % halfLen;
      final end = start + arcLen;
      final segment = metrics.extractPath(start, math.min(end, totalLen));
      canvas.drawPath(segment, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavyCircularPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.t != t ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.waveAmplitude != waveAmplitude ||
        oldDelegate.waveLength != waveLength ||
        oldDelegate.showTrack != showTrack;
  }
}
