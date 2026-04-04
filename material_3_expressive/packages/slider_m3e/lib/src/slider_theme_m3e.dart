import 'package:flutter/material.dart';

import 'enums.dart';
import 'slider_tokens_adapter.dart';
import 'wavy_slider_shapes.dart';

SliderThemeData sliderThemeM3E(
  BuildContext context, {
  SliderM3ESize size = SliderM3ESize.medium,
  SliderM3EEmphasis emphasis = SliderM3EEmphasis.primary,
  SliderM3EShapeFamily shapeFamily = SliderM3EShapeFamily.round,
  SliderM3EDensity density = SliderM3EDensity.regular,
  SliderM3EShape shape = SliderM3EShape.flat,
  bool showValueIndicator = false,
  double? gap,
  double? waveAmplitude,
  double? waveLength,
  double? phase,
  double? thumbWidth,
  double? thumbHeight,
  double? thumbRadius,
}) {
  final t = SliderTokensAdapter(context);
  final m = t.metrics(density);
  final isWavy = shape == SliderM3EShape.wavy;

  final effectiveGap = gap ?? size.defaultGap;
  final effectiveWaveAmplitude = waveAmplitude ?? size.defaultWaveAmplitude;
  final effectiveWaveLength = waveLength ?? size.defaultWaveLength;
  final effectivePhase = phase ?? 0.0;
  final effectiveThumbWidth = thumbWidth ?? size.defaultThumbWidth;
  final effectiveThumbHeight = thumbHeight ?? size.defaultThumbHeight;
  final effectiveThumbRadius = thumbRadius ?? size.defaultThumbRadius;

  final trackHeight = switch (size) {
    SliderM3ESize.small => m.trackSmall,
    SliderM3ESize.medium => m.trackMedium,
    SliderM3ESize.large => m.trackLarge,
  };



  final SliderComponentShape thumbShape = WavySliderThumbShapeM3E(
    width: effectiveThumbWidth,
    height: effectiveThumbHeight,
    radius: effectiveThumbRadius,
    isWavy: isWavy, // Pass the same isWavy flag for tracking
  );

  final SliderTrackShape trackShape = isWavy
      ? WavySliderTrackShapeM3E(
          gap: effectiveGap,
          waveAmplitude: effectiveWaveAmplitude,
          waveLength: effectiveWaveLength,
          phase: effectivePhase,
          isWavy: true,
        )
      : const RoundedRectSliderTrackShape();

  return SliderTheme.of(context).copyWith(
    trackHeight: trackHeight,
    trackShape: trackShape,
    activeTrackColor: t.activeColor(emphasis),
    inactiveTrackColor: t.inactiveColor(),
    disabledActiveTrackColor: t.inactiveColor(),
    disabledInactiveTrackColor: t.inactiveColor(),
    activeTickMarkColor: t.tickColorActive(emphasis),
    inactiveTickMarkColor: t.tickColorInactive(),
    thumbColor: t.thumbColor(emphasis),
    disabledThumbColor: t.inactiveColor(),
    overlayColor: t.overlayColor(emphasis),
    valueIndicatorColor: t.valueIndicatorColor(),
    valueIndicatorTextStyle: t.valueIndicatorTextStyle(),
    showValueIndicator: showValueIndicator
        ? ShowValueIndicator.onDrag
        : ShowValueIndicator.onlyForDiscrete,
    thumbShape: thumbShape,
    overlayShape: RoundSliderOverlayShape(overlayRadius: m.overlayRadius),
    rangeThumbShape: shapeFamily == SliderM3EShapeFamily.round
        ? const RoundRangeSliderThumbShape()
        : const _SquareRangeThumbShape(),
    rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
    rangeValueIndicatorShape: const PaddleRangeSliderValueIndicatorShape(),
    valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
  );
}


class _SquareRangeThumbShape extends RangeSliderThumbShape {
  const _SquareRangeThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(24, 24);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = true,
    bool isOnTop = false,
    bool isPressed = false,
    required SliderThemeData sliderTheme,
    TextDirection textDirection = TextDirection.ltr,
    Thumb thumb = Thumb.start,
  }) {
    final canvas = context.canvas;
    final side = 24.0;
    final rect = Rect.fromCenter(center: center, width: side, height: side);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    final paint = Paint()..color = sliderTheme.thumbColor ?? Colors.blue;
    canvas.drawRRect(rrect, paint);
  }
}
