import 'dart:math' as math;
import 'package:flutter/material.dart';

class WavySliderTrackShapeM3E extends SliderTrackShape with BaseSliderTrackShape {
  final double gap;
  final double waveAmplitude;
  final double waveLength;
  final double phase; // 0..1
  final bool isWavy;

  const WavySliderTrackShapeM3E({
    required this.gap,
    required this.waveAmplitude,
    required this.waveLength,
    required this.phase,
    this.isWavy = true,
  });

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0,
  }) {
    if (sliderTheme.trackHeight == null || sliderTheme.trackHeight! <= 0) return;

    final canvas = context.canvas;
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Paint activePaint = Paint()
      ..color = sliderTheme.activeTrackColor ?? Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = sliderTheme.trackHeight!
      ..strokeCap = StrokeCap.round;

    final Paint inactivePaint = Paint()
      ..color = sliderTheme.inactiveTrackColor ?? Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = sliderTheme.trackHeight!
      ..strokeCap = StrokeCap.round;

    final double thumbX = thumbCenter.dx;
    final double centerY = thumbCenter.dy;

    // --- Inactive Track (Right) ---
    final double inactiveStart = (thumbX + gap).clamp(trackRect.left, trackRect.right);
    if (inactiveStart < trackRect.right) {
      canvas.drawLine(
        Offset(inactiveStart, centerY),
        Offset(trackRect.right, centerY),
        inactivePaint,
      );
    }

    // --- Active Track (Left) ---
    final double activeEnd = (thumbX - gap).clamp(trackRect.left, trackRect.right);
    if (activeEnd > trackRect.left) {
      if (isWavy && waveAmplitude > 0) {
        _paintWavyPath(canvas, trackRect.left, activeEnd, centerY, activePaint);
      } else {
        canvas.drawLine(
          Offset(trackRect.left, centerY),
          Offset(activeEnd, centerY),
          activePaint,
        );
      }
    }
  }

  void _paintWavyPath(Canvas canvas, double startX, double endX, double centerY, Paint paint) {
    final double width = endX - startX;
    if (width <= 0) return;

    // We build a base path that is longer than the segment to allow for phase shifting
    // but here we can just use the sin logic or the cubicTo logic.
    // Restoration: Using cubicTo logic with smoothness = 0.48 for premium aesthetics.
    final path = Path();
    const double smoothness = 0.48;
    final int cycleCount = math.max(1, (width / waveLength).round());
    final double adjWave = width / cycleCount;
    // Build one extra cycle for smooth phase scrolling.
    final int totalHalves = (cycleCount + 1) * 2;

    for (int i = 0; i <= totalHalves; i++) {
        final double x = startX + i * adjWave / 2;
        // Peak at i=0, Trough at i=1, etc.
        final double py = centerY + ((i % 2 == 0) ? waveAmplitude : -waveAmplitude);
        
        if (i == 0) {
            path.moveTo(x, py);
        } else {
            final double prevX = startX + (i - 1) * adjWave / 2;
            final double prevY = centerY + (((i - 1) % 2 == 0) ? waveAmplitude : -waveAmplitude);
            final double ctrlDx = adjWave / 2 * smoothness;
            path.cubicTo(prevX + ctrlDx, prevY, x - ctrlDx, py, x, py);
        }
    }

    final double phaseValue = phase.clamp(0.0, 1.0);
    final metrics = path.computeMetrics().first;
    final double totalLen = metrics.length;
    final double oneCycleLen = totalLen / (cycleCount + 1);
    final double baseLen = totalLen * cycleCount / (cycleCount + 1);
    
    // Extract exact arc length for the required horizontal width
    final double phaseShift = phaseValue * oneCycleLen;
    final segment = metrics.extractPath(phaseShift, phaseShift + baseLen);

    // Compensate for the shift horizontally to keep start and end points fixed
    canvas.save();
    canvas.translate(-phaseValue * adjWave, 0);
    canvas.drawPath(segment, paint);
    canvas.restore();
  }

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 4.0;
    final double trackLeft = offset.dx;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}

class WavySliderThumbShapeM3E extends SliderComponentShape {
  final double width;
  final double height;
  final double radius;
  final bool isWavy;

  const WavySliderThumbShapeM3E({
    required this.width,
    required this.height,
    required this.radius,
    this.isWavy = true,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size(width, height);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter? labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    if (!isWavy) {
      // Fallback to standard round thumb if not wavy? 
      // No, let's keep the tall design but maybe different proportions.
    }

    final canvas = context.canvas;
    
    // Scale properties based on activation (press)
    // Matching demo: Width -1, Height +4, Radius +2
    final double anim = activationAnimation.value;
    final double currentWidth = width - (anim * 1.0);
    final double currentHeight = height + (anim * 4.0);
    final double currentRadius = radius + (anim * 2.0);

    final rect = Rect.fromCenter(
      center: center,
      width: currentWidth,
      height: currentHeight,
    );
    
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(currentRadius));
    
    final paint = Paint()
      ..color = sliderTheme.thumbColor ?? Colors.blue
      ..style = PaintingStyle.fill;
      
    // Draw shadow
    // Draw shadow matching demo
    if (true) { // Always show shadow as in demo (idle has shadow 8, 50 alpha)
        final double alpha = 50 + (30 * anim); // 50 idle -> 80 pressed
        final double blur = 8 + (4 * anim);   // 8 idle -> 12 pressed
        
        canvas.drawRRect(
            rrect.shift(Offset(0, 2 + 2 * anim)), // 2 idle -> 4 pressed
            Paint()
                ..color = paint.color.withValues(alpha: alpha / 255)
                ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
        );
    }

    canvas.drawRRect(rrect, paint);
  }
}

class WavySliderTickMarkShapeM3E extends SliderTickMarkShape {
  const WavySliderTickMarkShapeM3E({
    this.tickMarkRadius,
    required this.isWavy,
  });

  final double? tickMarkRadius;
  final bool isWavy;

  @override
  Size getPreferredSize({
    required SliderThemeData sliderTheme,
    required bool isEnabled,
  }) {
    return Size.fromRadius(tickMarkRadius ?? (sliderTheme.trackHeight ?? 4.0) / 4);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    required bool isEnabled,
  }) {
    // If it's wavy, only paint if it's on the right side of the thumb (inactive side)
    // We add a tiny buffer to account for rounding/gap.
    if (isWavy && center.dx < thumbCenter.dx - 2.0) {
      return;
    }

    final double radius = tickMarkRadius ?? (sliderTheme.trackHeight ?? 4.0) / 4;
    final Paint paint = Paint()
      ..color = isEnabled
          ? (center.dx <= thumbCenter.dx + 0.1
              ? sliderTheme.activeTickMarkColor ?? Colors.blue
              : sliderTheme.inactiveTickMarkColor ?? Colors.grey)
          : (center.dx <= thumbCenter.dx + 0.1
              ? sliderTheme.disabledActiveTickMarkColor ?? Colors.blue
              : sliderTheme.disabledInactiveTickMarkColor ?? Colors.grey);

    context.canvas.drawCircle(center, radius, paint);
  }
}
