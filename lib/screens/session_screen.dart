import 'dart:async';
import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:button_m3e/button_m3e.dart';
import 'package:button_group_m3e/button_group_m3e.dart';
import '../utils/preferences_helper.dart';

class SessionScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final ValueChanged<bool>? onAmbientModeChanged;
  const SessionScreen({super.key, this.onBack, this.onAmbientModeChanged});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;

  // Ambient mode state
  bool _isAmbient = false;
  bool _ambientModeEnabled = true;
  int _ambientIntervalSeconds = 5;
  Timer? _ambientTimer;
  late AnimationController _ambientFadeController;
  late Animation<double> _ambientFadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadAmbientSettings();
    _ambientFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _ambientFadeAnimation = CurvedAnimation(
      parent: _ambientFadeController,
      curve: Curves.easeInOut,
    );
  }

  void _loadAmbientSettings() {
    _ambientModeEnabled =
        PreferencesHelper.getBool('ambientModeEnabled') ?? true;
    final savedInterval =
        PreferencesHelper.getInt('ambientModeIntervalSeconds') ?? 5;
    _ambientIntervalSeconds = savedInterval.clamp(1, 60);
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      _cancelAmbientTimer();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _seconds++;
        });
      });
      if (_ambientModeEnabled) {
        _startAmbientTimer();
      }
    }
    setState(() {
      _isRunning = !_isRunning;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _cancelAmbientTimer();
    _exitAmbientMode();
    setState(() {
      _seconds = 0;
      _isRunning = false;
    });
  }

  // ===== Ambient Mode Logic =====

  void _startAmbientTimer() {
    if (!_ambientModeEnabled) return;
    _cancelAmbientTimer();
    _ambientTimer = Timer(Duration(seconds: _ambientIntervalSeconds), () {
      _enterAmbientMode();
    });
  }

  void _cancelAmbientTimer() {
    _ambientTimer?.cancel();
    _ambientTimer = null;
  }

  void _enterAmbientMode() {
    if (!_isRunning || _isAmbient || !_ambientModeEnabled) return;
    setState(() => _isAmbient = true);
    widget.onAmbientModeChanged?.call(true);
    _ambientFadeController.forward();
    // Go fullscreen immersive
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitAmbientMode() {
    if (!_isAmbient) return;
    _ambientFadeController.reverse().then((_) {
      if (mounted) {
        setState(() => _isAmbient = false);
        widget.onAmbientModeChanged?.call(false);
      }
    });
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // Restart ambient timer if still running
    if (_isRunning && _ambientModeEnabled) {
      _startAmbientTimer();
    }
  }

  List<String> _getTimeParts() {
    final int hours = _seconds ~/ 3600;
    final int minutes = (_seconds % 3600) ~/ 60;
    final int seconds = _seconds % 60;

    if (hours > 0) {
      return [
        hours.toString().padLeft(2, '0'),
        minutes.toString().padLeft(2, '0'),
        seconds.toString().padLeft(2, '0'),
      ];
    }
    return [
      minutes.toString().padLeft(2, '0'),
      seconds.toString().padLeft(2, '0'),
    ];
  }

  Widget _buildTimerDisplay(TextStyle style) {
    final parts = _getTimeParts();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: parts.asMap().entries.map((entry) {
        final isLast = entry.key == parts.length - 1;
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Text(entry.value, style: style),
            if (!isLast) Positioned(right: -34, child: Text(':', style: style)),
          ],
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ambientTimer?.cancel();
    _ambientFadeController.dispose();
    // Restore system UI on dispose
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;
    final bool isExpanded = MediaQuery.sizeOf(context).width >= 840;

    return Scaffold(
      backgroundColor: colorTheme.surfaceContainer,
      body: Stack(
        children: [
          // === Normal Session UI ===
          CustomScrollView(
            slivers: [
              if (isExpanded)
                SliverAppBar.large(
                  title: const Text('Session'),
                  titleSpacing: 0,
                  automaticallyImplyLeading: false,
                  leadingWidth: 80,
                  leading: Center(
                    child: IconButtonM3E(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Symbols.arrow_back),
                      tooltip: 'Back',
                      variant: IconButtonM3EVariant.tonal,
                      width: IconButtonM3EWidth.wide,
                    ),
                  ),
                  backgroundColor: colorTheme.surfaceContainer,
                  scrolledUnderElevation: 1,
                  expandedHeight: 120,
                )
              else
                SliverAppBar(
                  title: const Text('Session'),
                  titleSpacing: 16,
                  automaticallyImplyLeading: false,
                  leadingWidth: 0,
                  leading: null,
                  backgroundColor: colorTheme.surfaceContainer,
                  scrolledUnderElevation: 1,
                ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 98),
                      SizedBox(
                        width: 270,
                        height: 270,
                        child: Transform.scale(
                          scaleY: 1.8,
                          child: _buildTimerDisplay(
                            TextStyle(
                              fontFamily: 'GoogleSansFlex',
                              fontSize: 84,
                              height: 0.9,
                              fontWeight: FontWeight.w500,
                              color: colorTheme.primary,
                              fontVariations: const [
                                FontVariation('wdth', 150),
                                FontVariation('wght', 920),
                                FontVariation('opsz', 98),
                                FontVariation('ROND', -10),
                                FontVariation('CNTR', 70),
                                FontVariation('YOPQ', 36),
                                FontVariation('YTPQ', 105),
                                FontVariation('XTRA', 520),
                              ],
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: ButtonGroupM3E(
                          size: ButtonGroupM3ESize.lg,
                          style: ButtonM3EStyle.filled,
                          overflow: ButtonGroupM3EOverflow.none,
                          actions: [
                            ButtonGroupM3EAction(
                              icon: Icon(
                                _isRunning
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                              ),
                              label: Text(_isRunning ? 'Pause' : 'Start'),
                              shape: ButtonM3EShape.round,
                              selected: _isRunning || _seconds > 0,
                              onPressed: _toggleTimer,
                            ),
                            ButtonGroupM3EAction(
                              icon: const Icon(Icons.stop_rounded),
                              label: const Text('Stop'),
                              onPressed: _resetTimer,
                              shape: ButtonM3EShape.round,
                              enabled: _isRunning || _seconds > 0,
                              width: 134, // Custom width
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              backgroundColor: (_isRunning || _seconds > 0)
                                  ? colorTheme.errorContainer
                                  : null,
                              foregroundColor: (_isRunning || _seconds > 0)
                                  ? colorTheme.onErrorContainer
                                  : colorTheme.onPrimaryContainer,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // === Ambient Mode Overlay ===
          if (_isAmbient || _ambientFadeController.isAnimating)
            AnimatedBuilder(
              animation: _ambientFadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _ambientFadeAnimation.value,
                  child: child,
                );
              },
              child: GestureDetector(
                onTap: _exitAmbientMode,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black,
                  child: Center(
                    child: SizedBox(
                      width: 270,
                      height: 270,
                      child: Transform.scale(
                        scaleY: 1.8,
                        child: _buildTimerDisplay(
                          TextStyle(
                            fontFamily: 'GoogleSansFlex',
                            fontSize: 94,
                            height: 0.9,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.5),
                            fontVariations: const [
                              FontVariation('wdth', 150),
                              FontVariation('wght', 920),
                              FontVariation('opsz', 98),
                              FontVariation('ROND', -10),
                              FontVariation('CNTR', 70),
                              FontVariation('YOPQ', 36),
                              FontVariation('YTPQ', 105),
                              FontVariation('XTRA', 520),
                            ],
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
