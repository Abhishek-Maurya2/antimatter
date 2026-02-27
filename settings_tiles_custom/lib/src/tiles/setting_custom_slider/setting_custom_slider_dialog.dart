// ignore_for_file: public_member_api_docs private class

import 'package:flutter/material.dart';
import 'package:settings_tiles/src/tiles/widgets/cancel_button.dart';
import 'package:settings_tiles/src/tiles/widgets/ok_button.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';

class SettingCustomSliderDialog extends StatefulWidget {
  const SettingCustomSliderDialog({
    required this.title,
    required this.label,
    required this.values,
    required this.initialValue,
    required this.onChanged,
    super.key,
  });

  final String title;

  final String Function(double)? label;
  final List<double> values;
  final double initialValue;

  final void Function(double)? onChanged;

  @override
  State<SettingCustomSliderDialog> createState() => _SettingCustomSliderDialogState();
}

class _SettingCustomSliderDialogState extends State<SettingCustomSliderDialog> {
  /// The index of the current value.
  late int _index;

  /// The current value.
  double get _value => widget.values[_index];

  @override
  void initState() {
    super.initState();

    final valueIndex = widget.values.indexOf(widget.initialValue);

    assert(
      valueIndex != -1,
      'The initial value of the discrete slider is not allowed: '
      '${widget.initialValue} is not in ${widget.values}.',
    );

    _index = valueIndex;
  }

  void _onChanged(double value) {
    setState(() {
      _index = value.toInt();
    });

    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog.adaptive(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 14,
                  child: WavyLinearProgressIndicator(
                    value: _index / (widget.values.length - 1),
                    minHeight: 4.0,
                    waveAmplitude: 3.0,
                    waveLength: 24.0,
                  ),
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                ),
                child: Slider(
                  value: _index.toDouble(),
                  label: widget.label != null ? widget.label!(_value) : _value.toStringAsFixed(2),
                  max: (widget.values.length - 1).toDouble(),
                  divisions: widget.values.length - 1,
                  onChanged: _onChanged,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        const CancelButton(),
        OkButton(
          onPressed: () => Navigator.pop(context, _value),
        ),
      ],
    );
  }
}
