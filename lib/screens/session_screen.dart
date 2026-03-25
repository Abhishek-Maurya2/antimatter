import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:button_m3e/button_m3e.dart';
import 'package:button_group_m3e/button_group_m3e.dart';
import '../utils/preferences_helper.dart';
import '../utils/fullscreen_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/session.dart';

class SessionScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final ValueChanged<bool>? onAmbientModeChanged;
  const SessionScreen({super.key, this.onBack, this.onAmbientModeChanged});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;
  DateTime? _currentStartTime;

  // Ambient mode state
  bool _isAmbient = false;
  bool _ambientModeEnabled = true;
  int _ambientIntervalSeconds = 5;
  Timer? _ambientTimer;
  bool _stayAwakeEnabled = true;
  late AnimationController _ambientFadeController;
  late Animation<double> _ambientFadeAnimation;

  // Weight animation
  late AnimationController _weightController;
  late Animation<double> _weightAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize all animation variables first
    _weightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _weightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _weightController, curve: Curves.easeInOutCubic),
    );

    _ambientFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _ambientFadeAnimation = CurvedAnimation(
      parent: _ambientFadeController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addObserver(this);
    _loadAmbientSettings();
    _loadTimerState();

    // Sync the animation state with the current timer state
    _weightController.value = _isRunning ? 1.0 : 0.0;
  }

  void _loadTimerState() {
    final savedSeconds = PreferencesHelper.getInt('session_seconds') ?? 0;
    // We only persist the count, we don't resume automatically or calculate elapsed time
    // as per user request "when app is closed timer pause"
    _seconds = savedSeconds;
    _isRunning = false;
  }

  void _saveTimerState() {
    PreferencesHelper.setInt('session_seconds', _seconds);
    PreferencesHelper.setBool('session_is_running', _isRunning);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _saveTimerState();
    }
  }

  void _loadAmbientSettings() {
    _ambientModeEnabled =
        PreferencesHelper.getBool('ambientModeEnabled') ?? true;
    _stayAwakeEnabled = PreferencesHelper.getBool('stayAwakeEnabled') ?? true;
    final savedInterval =
        PreferencesHelper.getInt('ambientModeIntervalSeconds') ?? 5;
    _ambientIntervalSeconds = savedInterval.clamp(1, 60);
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      _cancelAmbientTimer();
      _saveTimerState();
      _weightController.reverse();
    } else {
      _startTimer();
      _weightController.forward();

      // Enable wakelock if starting and enabled in settings
      if (_stayAwakeEnabled) {
        WakelockPlus.enable();
      }
    }
    setState(() {
      _isRunning = !_isRunning;

      // If we just paused, disable wakelock
      if (!_isRunning) {
        WakelockPlus.disable();
      }
    });
    _saveTimerState(); // Save state on toggle
    if (_isRunning && _ambientModeEnabled) {
      _startAmbientTimer();
      if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
        toggleFullscreen(true);
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _currentStartTime ??= DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
      // Save every 10 seconds to avoid too many IO writes while still being reliable
      if (_seconds % 10 == 0) {
        _saveTimerState();
      }
    });
  }

  void _resetTimer() {
    if (_seconds > 0) {
      _saveSession();
    }

    _timer?.cancel();
    _cancelAmbientTimer();
    _exitAmbientMode();
    _weightController.reverse();
    WakelockPlus.disable(); // Always disable on reset
    setState(() {
      _seconds = 0;
      _isRunning = false;
      _currentStartTime = null;
    });
    // Clear persisted state
    PreferencesHelper.remove('session_seconds');
    PreferencesHelper.remove('session_is_running');

    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      toggleFullscreen(false);
    }
  }

  void _saveSession() {
    final session = Session(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: _currentStartTime ?? DateTime.now(),
      durationSeconds: _seconds,
    );

    final box = Hive.box<Session>('sessionsBox');
    box.put(session.id, session);
    // sessionSyncService will push automatically via startListening() in main.dart
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
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      toggleFullscreen(true);
    }
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
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      toggleFullscreen(false);
    }
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
            if (!isLast) Positioned(right: -40, child: Text(':', style: style)),
          ],
        );
      }).toList(),
    );
  }

  TextStyle _getTimerTextStyle({
    required double fontSize,
    required Color color,
    required double progress,
  }) {
    // Explicitly clamp and handle nulls for robustness
    final t = progress.clamp(0.0, 1.0);

    // Manual lerping with rounding to avoid precision issues
    double l(double a, double b) => a + (b - a) * t;

    return TextStyle(
      fontFamily: 'GoogleSansFlex',
      fontSize: fontSize,
      height: .9,
      fontWeight: FontWeight.w500,
      color: color,
      fontVariations: <FontVariation>[
        FontVariation('wght', l(120.0, 920.0)),
        FontVariation('wdth', l(200.0, 150.0)),
        FontVariation('ROND', l(-10.0, 80.0)),
        FontVariation('CNTR', l(40.0, 100.0)),
        FontVariation('XTRA', l(468.0, 600.0)),
        const FontVariation('opsz', 98.0),
        const FontVariation('YOPQ', 36.0),
        const FontVariation('YTPQ', 105.0),
      ],
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveTimerState();
    _timer?.cancel();
    _ambientTimer?.cancel();
    _ambientFadeController.dispose();
    _weightController.dispose();
    WakelockPlus.disable(); // Clean up wakelock
    // Restore system UI on dispose
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      toggleFullscreen(false);
    }
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
                      onPressed: () {
                        if (widget.onBack != null) {
                          widget.onBack!();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
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
                        child: AnimatedBuilder(
                          animation: _weightAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scaleY: 1.8,
                              child: _buildTimerDisplay(
                                _getTimerTextStyle(
                                  fontSize: 84,
                                  color: colorTheme.primary,
                                  progress: _weightAnimation.value,
                                ),
                              ),
                            );
                          },
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
                      child: AnimatedBuilder(
                        animation: _weightAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scaleY: 1.8,
                            child: _buildTimerDisplay(
                              _getTimerTextStyle(
                                fontSize: 94,
                                color: Colors.white.withOpacity(0.5),
                                progress: _weightAnimation.value,
                              ),
                            ),
                          );
                        },
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
