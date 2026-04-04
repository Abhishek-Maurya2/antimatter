import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:settings_tiles/src/tiles/setting_tile.dart';

/// Inline Slider setting tile.
class SettingInlineSliderTile extends SettingTile {
  /// A setting tile with an inline slider to choose a value between a [min] 
  /// value and a [max] value with a number of [divisions].
  const SettingInlineSliderTile({
    super.key,
    super.enabled = true,
    super.icon,
    super.title,
    super.description,
    super.visible = true,
    required this.sliderValue,
    required this.min,
    required this.max,
    required this.divisions,
    required this.label,
    required this.onChanged,
    required this.onChangeEnd,
  });

  /// The current value of the slider.
  final double sliderValue;

  /// The minimum value that can be selected in the slider.
  final double min;

  /// The maximum value that can be selected in the slider.
  final double max;

  /// The number of divisions of the slider between the [min] and the [max].
  final int divisions;

  /// The label of the slider.
  final String Function(double) label;

  /// Called when the slider value is changed.
  final ValueChanged<double> onChanged;

  /// Called when the slider value is finished changing.
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (icon != null) ...[icon!, const SizedBox(width: 16)],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          DefaultTextStyle(
                            style: textTheme.bodyLarge!.copyWith(
                              color: colorScheme.onSurface,
                            ),
                            child: title!,
                          ),
                        if (description != null) ...[
                          const SizedBox(height: 2),
                          DefaultTextStyle(
                            style: textTheme.bodyMedium!.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            child: description!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    label(sliderValue),
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (icon != null) const SizedBox(width: 56),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0),
                          child: ExcludeSemantics(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: SizedBox(
                                height: 16,
                                child: LinearProgressIndicatorM3E(
                                  value: (sliderValue - min) / (max - min),
                                  shape: ProgressM3EShape.wavy,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.transparent,
                            inactiveTrackColor: Colors.transparent,
                          ),
                          child: Slider(
                            value: sliderValue,
                            min: min,
                            max: max,
                            divisions: divisions,
                            label: label(sliderValue),
                            onChanged: enabled ? onChanged : null,
                            onChangeEnd: enabled ? onChangeEnd : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
