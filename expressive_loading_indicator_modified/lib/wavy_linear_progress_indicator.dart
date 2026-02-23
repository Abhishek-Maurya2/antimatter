import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// A Material Design 3 Expressive Wavy Linear Progress Indicator.
class WavyLinearProgressIndicator extends ProgressIndicator {
  /// The minimum height of the indicator.
  final double minHeight;

  /// The amplitude of the wave.
  final double waveAmplitude;

  /// The wavelength (distance between two peaks) of the wave.
  final double waveLength;

  const WavyLinearProgressIndicator({
    super.key,
    super.value,
    super.color,
    super.backgroundColor,
    this.minHeight = 4.0,
    this.waveAmplitude = 3.0,
    this.waveLength = 40.0,
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
    );
    if (widget.value == null) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(WavyLinearProgressIndicator oldWidget) {
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
        indicatorTheme.linearTrackColor ??
        colorTheme.surfaceContainerHighest;

    return Semantics.fromProperties(
      properties: SemanticsProperties(
        label: widget.semanticsLabel,
        value: widget.semanticsValue,
      ),
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
                phase: _controller.value * 2 * math.pi,
                indicatorColor: indicatorColor,
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

class _WavyLinearPainter extends CustomPainter {
  final double? value;
  final double phase;
  final Color indicatorColor;
  final Color trackColor;
  final double strokeWidth;
  final double waveAmplitude;
  final double waveLength;

  _WavyLinearPainter({
    required this.value,
    required this.phase,
    required this.indicatorColor,
    required this.trackColor,
    required this.strokeWidth,
    required this.waveAmplitude,
    required this.waveLength,
  });

  Path _buildWavePath(
    double width,
    double centerY, {
    double startX = 0,
    double endX = 0,
  }) {
    final path = Path();
    if (endX <= startX) {
      return path;
    }

    path.moveTo(
      startX,
      centerY +
          waveAmplitude * math.sin((startX / waveLength) * 2 * math.pi + phase),
    );

    for (double x = startX; x <= endX; x += 1.0) {
      final y =
          centerY +
          waveAmplitude * math.sin((x / waveLength) * 2 * math.pi + phase);
      path.lineTo(x, y);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;

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
      final indicatorWidth = size.width * value!.clamp(0.0, 1.0);

      // Draw track
      if (indicatorWidth < size.width) {
        final trackPath = _buildWavePath(
          size.width,
          centerY,
          startX: indicatorWidth,
          endX: size.width,
        );
        canvas.drawPath(trackPath, trackPaint);
      }

      // Draw indicator
      if (indicatorWidth > 0) {
        final indicatorPath = _buildWavePath(
          size.width,
          centerY,
          startX: 0,
          endX: indicatorWidth,
        );
        canvas.drawPath(indicatorPath, indicatorPaint);
      }
    } else {
      // Indeterminate
      // In indeterminate mode, the track doesn't need to be wavy, but drawing it wavy looks consistent.
      // Alternatively, we could animate the width of the active segment.
      // For now, doing an active wave segment moving left to right.

      final head = (size.width + waveLength) * (phase / (2 * math.pi));
      final tail = head - size.width * 0.3; // 30% width

      final trackPath = _buildWavePath(
        size.width,
        centerY,
        startX: 0,
        endX: size.width,
      );
      canvas.drawPath(trackPath, trackPaint);

      if (head > 0 && tail < size.width) {
        final startX = math.max(0.0, tail);
        final endX = math.min(size.width, head);
        if (endX > startX) {
          final indicatorPath = _buildWavePath(
            size.width,
            centerY,
            startX: startX,
            endX: endX,
          );
          canvas.drawPath(indicatorPath, indicatorPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WavyLinearPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.phase != phase ||
        oldDelegate.indicatorColor != indicatorColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.waveAmplitude != waveAmplitude ||
        oldDelegate.waveLength != waveLength;
  }
}
