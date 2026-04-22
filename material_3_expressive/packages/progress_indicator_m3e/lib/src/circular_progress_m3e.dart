import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'enums.dart';

const double _kSmoothness = 0.48;

class CircularProgressIndicatorM3E extends StatefulWidget {
  const CircularProgressIndicatorM3E({
    super.key,
    this.value,
    this.size = CircularProgressM3ESize.md,
    this.shape = ProgressM3EShape.wavy,
    this.activeColor,
    this.trackColor,
    this.rotation = 0.0,
    this.strokeWidth,
    this.gap,
    this.waveAmplitude,
    this.waveLength,
    this.animationSpeed,
  });

  final double? value; // 0..1 (null => indeterminate)
  final CircularProgressM3ESize size;
  final ProgressM3EShape shape;
  final Color? activeColor;
  final Color? trackColor;
  final double rotation;
  final double? strokeWidth;
  final double? gap;
  final double? waveAmplitude;
  final double? waveLength;
  final double? animationSpeed;

  @override
  State<CircularProgressIndicatorM3E> createState() =>
      _CircularProgressIndicatorM3EState();
}

class _CircularProgressIndicatorM3EState
    extends State<CircularProgressIndicatorM3E>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _applySpeed();
  }

  @override
  void didUpdateWidget(covariant CircularProgressIndicatorM3E oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationSpeed != widget.animationSpeed ||
        oldWidget.size != widget.size) {
      _applySpeed();
    }
  }

  void _applySpeed() {
    final speed = widget.animationSpeed ??
        (widget.value == null
            ? widget.size.defaultIndeterminateSpeed(widget.shape)
            : widget.size.defaultSpeed);
    if (speed <= 0) {
      _controller.stop();
    } else {
      final int durationMs = (3000 / speed).round();
      _controller.duration = Duration(milliseconds: durationMs);
      if (!_controller.isAnimating) _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = widget.activeColor ?? cs.primary;
    final track =
        widget.trackColor ?? cs.onSurfaceVariant.withValues(alpha: 0.24);
    final wantsWavy = widget.shape == ProgressM3EShape.wavy;
    final diameter =
        wantsWavy ? widget.size.diameterWavy : widget.size.diameterFlat;

    // Resolve size-based defaults
    final effectiveStrokeWidth = widget.strokeWidth ??
        (widget.value == null
            ? widget.size.defaultIndeterminateStrokeWidth
            : widget.size.defaultStrokeWidth);
    final rawGap = widget.gap ?? widget.size.defaultGap;
    final effectiveGap =
        (widget.value != null && widget.value! >= 1.0) ? 0.0 : rawGap;
    final effectiveWaveLength =
        widget.waveLength ?? widget.size.defaultWaveLength;
    final rawAmplitude =
        widget.waveAmplitude ?? widget.size.defaultWaveAmplitude;

    // Flatten amplitude at 100%
    final effectiveAmplitude =
        (widget.value != null && widget.value! >= 1.0) ? 0.0 : rawAmplitude;

    return RepaintBoundary(
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: CustomPaint(
          painter: wantsWavy
              ? _BrokenWavyCircularPainter(
                  value: widget.value,
                  t: _controller.value,
                  active: active,
                  track: track,
                  strokeWidth: effectiveStrokeWidth,
                  gap: effectiveGap,
                  waveAmplitude: effectiveAmplitude,
                  waveLength: effectiveWaveLength,
                )
              : _CircularFlatPainter(
                  value: widget.value,
                  active: active,
                  track: track,
                  rotation: widget.rotation != 0.0
                      ? widget.rotation
                      : _controller.value * 2 * math.pi,
                  size: widget.size,
                  gap: effectiveGap,
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Flat painter (unchanged from original)
// ---------------------------------------------------------------------------

class _CircularFlatPainter extends CustomPainter {
  _CircularFlatPainter({
    required this.value,
    required this.active,
    required this.track,
    required this.rotation,
    required this.size,
    required this.gap,
  });

  final double? value;
  final Color active;
  final Color track;
  final double rotation;
  final CircularProgressM3ESize size;
  final double gap;

  @override
  void paint(Canvas canvas, Size s) {
    final stroke = 4.0;
    final center = s.center(Offset.zero);
    final radius = (math.min(s.width, s.height) - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final gapAngle = gap / radius;

    final sweep =
        value == null ? math.pi * 1.5 : (value!.clamp(0.0, 1.0) * math.pi * 2);

    final start = -math.pi / 2 + rotation;
    final activeStart = start;
    final activeEnd = start + sweep;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..color = track;

    final total = math.pi * 2;
    final a1 = (activeEnd + gapAngle);
    final a2 = (activeStart - gapAngle);
    double sweep1 = (a2 - a1);
    while (sweep1 <= 0) sweep1 += total;
    canvas.drawArc(rect, a1, sweep1, false, trackPaint);

    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..color = active;
    canvas.drawArc(rect, activeStart, sweep, false, activePaint);
  }

  @override
  bool shouldRepaint(covariant _CircularFlatPainter old) =>
      value != old.value ||
      active != old.active ||
      track != old.track ||
      rotation != old.rotation ||
      size != old.size ||
      gap != old.gap;
}

// ---------------------------------------------------------------------------
// Broken Wavy Circular painter (ported from BrokenWavyCircularProgressIndicator)
// ---------------------------------------------------------------------------

class _BrokenWavyCircularPainter extends CustomPainter {
  final double? value;
  final double t; // animation value 0..1
  final Color active;
  final Color track;
  final double strokeWidth;
  final double gap;
  final double waveAmplitude;
  final double waveLength;

  _BrokenWavyCircularPainter({
    required this.value,
    required this.t,
    required this.active,
    required this.track,
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
          final double prevTheta = (i > 0
                  ? (copy * circumference + prevDist)
                  : ((copy - 1) * circumference + (halfCycles * adjWave / 2))) /
              radius;
          final double prevShift =
              ((i > 0 ? i - 1 : halfCycles) % 2 == 1) ? -waveAmplitude : 0.0;
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
      ..color = active
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final trackPaint = Paint()
      ..color = track
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
      // Determinate mode
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
      final double baseRotation = t * math.pi * 6;

      final double sweepFraction =
          0.15 + 0.65 * (0.5 * (1 - math.cos(t * math.pi * 4)));
      final double currentSweepAngle = sweepFraction * totalSweep;

      // Draw the Active Sweeping Arc
      final double arcLen = sweepFraction * halfLen;
      final double startExtract = pathGapLen;
      final double endExtract = math.max(startExtract, arcLen - pathGapLen);

      if (endExtract > startExtract) {
        final segment = metrics.extractPath(startExtract, endExtract);

        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(baseRotation);
        canvas.translate(-center.dx, -center.dy);

        canvas.drawPath(segment, activePaint);
        canvas.restore();
      }

      // Broken Tracking Inactive Rail
      final double startRail = currentSweepAngle + gapAngle;
      final double endRail = totalSweep - gapAngle;
      final double sweepRail = endRail - startRail;

      if (sweepRail > 0) {
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(baseRotation);
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
  bool shouldRepaint(covariant _BrokenWavyCircularPainter old) =>
      value != old.value ||
      t != old.t ||
      active != old.active ||
      track != old.track ||
      strokeWidth != old.strokeWidth ||
      gap != old.gap ||
      waveAmplitude != old.waveAmplitude ||
      waveLength != old.waveLength;
}
