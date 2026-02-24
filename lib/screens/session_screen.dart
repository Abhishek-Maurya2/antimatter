import 'dart:async';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:orches/widgets/m3_button_group.dart';

class SessionScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const SessionScreen({super.key, this.onBack});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _seconds++;
        });
      });
    }
    setState(() {
      _isRunning = !_isRunning;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _seconds = 0;
      _isRunning = false;
    });
  }

  String _formatTime() {
    final int hours = _seconds ~/ 3600;
    final int minutes = (_seconds % 3600) ~/ 60;
    final int seconds = _seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorTheme.surfaceContainer,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text('Session'),
            titleSpacing: 0,
            leadingWidth: 80,
            leading: Center(
              child: Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  color: colorTheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: IconButton(
                  onPressed: () {
                    if (widget.onBack != null) {
                      widget.onBack!();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: Icon(
                    Symbols.arrow_back,
                    color: colorTheme.onSurface,
                    size: 25,
                  ),
                  tooltip: 'Back',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
            backgroundColor: colorTheme.surfaceContainer,
            scrolledUnderElevation: 1,
            expandedHeight: 120,
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 220,
                          height: 220,
                          child: WavyCircularProgressIndicator(
                            value: _isRunning ? 0.3 : 0.0,
                            strokeWidth: 8.0,
                            waveAmplitude: 6,
                            waveLength: 22.0,
                          ),
                        ),
                        Text(
                          _formatTime(),
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.bold,
                            color: colorTheme.primary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  M3ButtonGroup(
                    isActive: _isRunning,
                    activeIndex: 0,
                    items: [
                      M3ButtonGroupItem(
                        icon: _isRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        label: _isRunning ? 'Pause' : 'Start',
                        onPressed: _toggleTimer,
                      ),
                      M3ButtonGroupItem(
                        icon: Icons.stop_rounded,
                        label: 'Stop',
                        onPressed: _resetTimer,
                        enabled: _isRunning || _seconds > 0,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
