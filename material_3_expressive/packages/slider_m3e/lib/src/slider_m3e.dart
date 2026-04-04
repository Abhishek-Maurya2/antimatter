import 'package:flutter/material.dart';

import 'enums.dart';
import 'slider_theme_m3e.dart';

class SliderM3E extends StatefulWidget {
  const SliderM3E({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.label,
    this.semanticLabel,
    this.size = SliderM3ESize.medium,
    this.emphasis = SliderM3EEmphasis.primary,
    this.shapeFamily = SliderM3EShapeFamily.round,
    this.density = SliderM3EDensity.regular,
    this.shape = SliderM3EShape.flat,
    this.showValueIndicator,
    this.startIcon,
    this.endIcon,
    this.gap,
    this.waveAmplitude,
    this.waveLength,
    this.animationSpeed,
    this.thumbWidth,
    this.thumbHeight,
    this.thumbRadius,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final String? semanticLabel;

  final SliderM3ESize size;
  final SliderM3EEmphasis emphasis;
  final SliderM3EShapeFamily shapeFamily;
  final SliderM3EDensity density;
  final SliderM3EShape shape;
  final bool? showValueIndicator;

  final Widget? startIcon;
  final Widget? endIcon;

  // Wavy specific
  final double? gap;
  final double? waveAmplitude;
  final double? waveLength;
  final double? animationSpeed;
  final double? thumbWidth;
  final double? thumbHeight;
  final double? thumbRadius;

  @override
  State<SliderM3E> createState() => _SliderM3EState();
}

class _SliderM3EState extends State<SliderM3E>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _updateAnimation();
  }

  @override
  void didUpdateWidget(SliderM3E oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shape != widget.shape ||
        oldWidget.animationSpeed != widget.animationSpeed) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    final bool isWavy = widget.shape == SliderM3EShape.wavy;
    if (!isWavy) {
      _controller.stop();
      return;
    }

    final speed = widget.animationSpeed ?? widget.size.defaultAnimationSpeed;
    if (speed <= 0) {
      _controller.stop();
    } else {
      _controller.duration = Duration(milliseconds: (2000 / speed).round());
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double normalizedValue =
            ((widget.value - widget.min) / (widget.max - widget.min))
                .clamp(0.0, 1.0);
        
        final double effectiveAmplitude =
            (widget.shape == SliderM3EShape.wavy && normalizedValue >= 0.99)
                ? 0.0
                : (widget.waveAmplitude ?? widget.size.defaultWaveAmplitude);

        final theme = sliderThemeM3E(
          context,
          size: widget.size,
          emphasis: widget.emphasis,
          shapeFamily: widget.shapeFamily,
          density: widget.density,
          shape: widget.shape,
          showValueIndicator: widget.showValueIndicator ?? false,
          gap: widget.gap,
          waveAmplitude: effectiveAmplitude,
          waveLength: widget.waveLength,
          phase: _controller.value,
          thumbWidth: widget.thumbWidth,
          thumbHeight: widget.thumbHeight,
          thumbRadius: widget.thumbRadius,
        );

        final slider = Slider(
          value: widget.value.clamp(widget.min, widget.max),
          onChanged: widget.onChanged,
          onChangeStart: widget.onChangeStart,
          onChangeEnd: widget.onChangeEnd,
          min: widget.min,
          max: widget.max,
          divisions: widget.divisions,
          label: widget.label,
          semanticFormatterCallback: widget.semanticLabel != null
              ? (v) =>
                  '${widget.semanticLabel} ${(100 * ((v - widget.min) / (widget.max - widget.min))).toStringAsFixed(0)}%'
              : null,
        );

        Widget result;
        if (widget.startIcon == null && widget.endIcon == null) {
          result = SliderTheme(data: theme, child: slider);
        } else {
          result = SliderTheme(
            data: theme,
            child: Row(
              children: [
                if (widget.startIcon != null) ...[
                  widget.startIcon!,
                  const SizedBox(width: 8)
                ],
                Expanded(child: slider),
                if (widget.endIcon != null) ...[
                  const SizedBox(width: 8),
                  widget.endIcon!
                ],
              ],
            ),
          );
        }
        return result;
      },
    );
  }
}
