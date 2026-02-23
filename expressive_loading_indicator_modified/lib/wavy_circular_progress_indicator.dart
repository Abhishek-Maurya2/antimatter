import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// A Material Design 3 Expressive Wavy Circular Progress Indicator.
class WavyCircularProgressIndicator extends ProgressIndicator {
  /// The default stroke width of the indicator.
  final double strokeWidth;

  /// The amplitude of the wave.
  final double waveAmplitude;

  /// The number of waves in the full circle.
  final int waveCount;

  const WavyCircularProgressIndicator({
    super.key,
    super.value,
    super.color,
    super.backgroundColor,
    this.strokeWidth = 4.0,
    this.waveAmplitude = 2.0,
    this.waveCount = 10,
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
      duration: const Duration(
        milliseconds: 2000,
      ), // A full cycle rotation/phase animation
    );
    if (widget.value == null) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(WavyCircularProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == null && oldWidget.value != null) {
      _controller.repeat();
    } else if (widget.value != null && oldWidget.value == null) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final indicatorTheme = ProgressIndicatorTheme.of(context);
    final colorTheme = Theme.of(context).colorScheme;

    final Color indicatorColor =
        widget.color ?? indicatorTheme.color ?? colorTheme.primary;
    final Color trackColor =
        widget.backgroundColor ??
        indicatorTheme.circularTrackColor ??
        colorTheme.surfaceContainerHighest;

    return Semantics.fromProperties(
      properties: SemanticsProperties(
        label: widget.semanticsLabel,
        value: widget.semanticsValue,
      ),
      child: Container(
        constraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _WavyCircularPainter(
                value: widget.value,
                phase:
                    _controller.value *
                    2 *
                    math.pi, // Controls the wave moving smoothly
                rotation:
                    _controller.value *
                    2 *
                    math.pi, // Controls the overall rotation (for indeterminate)
                indicatorColor: indicatorColor,
                trackColor: trackColor,
                strokeWidth: widget.strokeWidth,
                waveAmplitude: widget.waveAmplitude,
                waveCount: widget.waveCount,
              ),
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
    );
  }
}

class _WavyCircularPainter extends CustomPainter {
  final double? value;
  final double phase;
  final double rotation;
  final Color indicatorColor;
  final Color trackColor;
  final double strokeWidth;
  final double waveAmplitude;
  final int waveCount;

  _WavyCircularPainter({
    required this.value,
    required this.phase,
    required this.rotation,
    required this.indicatorColor,
    required this.trackColor,
    required this.strokeWidth,
    required this.waveAmplitude,
    required this.waveCount,
  });

  Path _buildWavePath(
    double baseRadius,
    Offset center, {
    double startAngle = 0,
    double sweepAngle = 2 * math.pi,
  }) {
    final path = Path();
    if (sweepAngle <= 0) {
      return path;
    }

    const int points = 100; // Resolution of the curve drawing
    final double angleStep = sweepAngle / points;

    for (int i = 0; i <= points; i++) {
      final double theta = startAngle + (i * angleStep);

      // Radius varies by sin(waveCount * theta + phase)
      final double currentRadius =
          baseRadius + waveAmplitude * math.sin(waveCount * theta + phase);

      final double x = center.dx + currentRadius * math.cos(theta);
      final double y = center.dy + currentRadius * math.sin(theta);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double baseRadius =
        (math.min(size.width, size.height) / 2) - strokeWidth - waveAmplitude;

    final Paint trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Paint indicatorPaint = Paint()
      ..color = indicatorColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (value != null) {
      // Determinate
      // Draw smooth circular track
      canvas.drawCircle(center, baseRadius, trackPaint);

      final sweepAngle = 2 * math.pi * value!.clamp(0.0, 1.0);
      if (sweepAngle > 0) {
        final indicatorPath = _buildWavePath(
          baseRadius,
          center,
          startAngle: -math.pi / 2,
          sweepAngle: sweepAngle,
        );
        canvas.drawPath(indicatorPath, indicatorPaint);
      }
    } else {
      // Indeterminate
      // Draw smooth circular track
      canvas.drawCircle(center, baseRadius, trackPaint);

      // We animate an arc growing and shrinking over rotation
      // Standard indeterminate circular indicator logic mapped to wavy path
      final sweepAngle =
          math.pi * 0.75 +
          math.sin(rotation * 2) * (math.pi * 0.5); // Arc pulsing
      final startAngle = rotation * 2 - math.pi / 2; // Spinning

      final indicatorPath = _buildWavePath(
        baseRadius,
        center,
        startAngle: startAngle,
        sweepAngle: sweepAngle,
      );
      canvas.drawPath(indicatorPath, indicatorPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavyCircularPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.phase != phase ||
        oldDelegate.rotation != rotation ||
        oldDelegate.indicatorColor != indicatorColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.waveAmplitude != waveAmplitude ||
        oldDelegate.waveCount != waveCount;
  }
}
