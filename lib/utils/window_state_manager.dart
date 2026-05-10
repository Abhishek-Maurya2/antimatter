import 'dart:ui';

import 'package:window_manager/window_manager.dart';
import 'preferences_helper.dart';

/// Persists and restores the desktop window's size, position, and
/// maximized state across app launches using SharedPreferences.
class WindowStateManager with WindowListener {
  // Preference keys
  static const String _keyWidth = 'window_width';
  static const String _keyHeight = 'window_height';
  static const String _keyX = 'window_x';
  static const String _keyY = 'window_y';
  static const String _keyMaximized = 'window_maximized';

  // Default window dimensions
  static const double _defaultWidth = 1100;
  static const double _defaultHeight = 700;
  static const double _minWidth = 400;
  static const double _minHeight = 500;

  /// Call once during app startup, after `windowManager.ensureInitialized()`
  /// and `PreferencesHelper.init()`.
  static Future<void> init() async {
    final manager = WindowStateManager._();

    // Restore saved state
    final isMaximized = PreferencesHelper.getBool(_keyMaximized) ?? false;
    final width = PreferencesHelper.getDouble(_keyWidth) ?? _defaultWidth;
    final height = PreferencesHelper.getDouble(_keyHeight) ?? _defaultHeight;
    final x = PreferencesHelper.getDouble(_keyX);
    final y = PreferencesHelper.getDouble(_keyY);

    final windowOptions = WindowOptions(
      size: Size(width, height),
      center: x == null || y == null, // Center only if no saved position
      minimumSize: const Size(_minWidth, _minHeight),
      titleBarStyle: TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      // Restore position if previously saved
      if (x != null && y != null) {
        await windowManager.setPosition(Offset(x, y));
      }

      // Restore maximized state
      if (isMaximized) {
        await windowManager.maximize();
      }

      await windowManager.show();
      await windowManager.focus();
    });

    // Start listening for future window changes
    windowManager.addListener(manager);
  }

  WindowStateManager._();

  /// Save current window geometry to preferences.
  Future<void> _saveState() async {
    final isMaximized = await windowManager.isMaximized();
    await PreferencesHelper.setBool(_keyMaximized, isMaximized);

    // Only save size/position when not maximized, so restoring from
    // maximized returns to the previous "normal" geometry.
    if (!isMaximized) {
      final size = await windowManager.getSize();
      final position = await windowManager.getPosition();

      await PreferencesHelper.setDouble(_keyWidth, size.width);
      await PreferencesHelper.setDouble(_keyHeight, size.height);
      await PreferencesHelper.setDouble(_keyX, position.dx);
      await PreferencesHelper.setDouble(_keyY, position.dy);
    }
  }

  // ─── WindowListener callbacks ──────────────────────────────────

  @override
  void onWindowResized() => _saveState();

  @override
  void onWindowMoved() => _saveState();

  @override
  void onWindowMaximize() => _saveState();

  @override
  void onWindowUnmaximize() => _saveState();

  @override
  void onWindowClose() => _saveState();
}
