import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import '../utils/preferences_helper.dart';
import 'package:dynamic_color/dynamic_color.dart';

class ThemeController extends ChangeNotifier {
  Color? _seedColor;
  CorePalette? _corePalette;

  ThemeMode _themeMode = PreferencesHelper.getString("AppTheme") == "Light"
      ? ThemeMode.light
      : PreferencesHelper.getString("AppTheme") == "Auto"
      ? ThemeMode.system
      : ThemeMode.dark;

  bool isCustom = PreferencesHelper.getBool("usingCustomSeed") ?? false;
  bool _isUsingDynamicColor = false;

  bool _isDynamicColorSupported = false;

  bool get isDynamicColorSupported => _isDynamicColorSupported;

  Future<void> checkDynamicColorSupport() async {
    _isDynamicColorSupported =
        (await DynamicColorPlugin.getCorePalette()) != null;
  }

  ThemeController();

  Future<void> initialize({
    Color fallbackColor = const Color(0xFF6750A4),
  }) async {
    bool useDynamicColors = PreferencesHelper.getBool("DynamicColors") ?? false;

    if (useDynamicColors) {
      await loadDynamicColors();
    } else if (isCustom) {
      setSeedColor(
        PreferencesHelper.getColor("CustomMaterialColor") ?? Colors.blue,
      );
    } else {
      setSeedColor(fallbackColor);
    }
  }

  Color get seedColor => _seedColor ?? const Color(0xFF6750A4);
  CorePalette? get corePalette => _corePalette;
  ThemeMode get themeMode => _themeMode;
  bool get isUsingDynamicColor => _isUsingDynamicColor;

  void setSeedColor(Color newColor) {
    _seedColor = newColor;
    _corePalette = CorePalette.of(newColor.toARGB32());
    _isUsingDynamicColor = false;
    notifyListeners();
  }

  void setSeedColorSilently(Color newColor) {
    _seedColor = newColor;
    _corePalette = CorePalette.of(newColor.toARGB32());
    _isUsingDynamicColor = false;
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    PreferencesHelper.setString(
      "AppTheme",
      mode == ThemeMode.light
          ? "Light"
          : mode == ThemeMode.dark
          ? "Dark"
          : "Auto",
    );
    notifyListeners();
  }

  Brightness get currentBrightness {
    switch (_themeMode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return PlatformDispatcher.instance.platformBrightness;
    }
  }

  Future<void> loadDynamicColors() async {
    final corePalette = await DynamicColorPlugin.getCorePalette();
    if (corePalette != null) {
      _corePalette = corePalette;

      final brightness = currentBrightness;

      int primaryTone = brightness == Brightness.light ? 40 : 80;

      final int argb = corePalette.primary.get(primaryTone);
      _seedColor = Color.from(
        alpha: ((argb >> 24) & 0xFF) / 255.0,
        red: ((argb >> 16) & 0xFF) / 255.0,
        green: ((argb >> 8) & 0xFF) / 255.0,
        blue: (argb & 0xFF) / 255.0,
      );
      _isUsingDynamicColor = true;
      notifyListeners();
    }
  }
}

bool isMonochrome(Color c, {double tol = 1.0 / 255.0}) {
  final r = c.r, g = c.g, b = c.b;
  return (r - g).abs() <= tol && (g - b).abs() <= tol && (r - b).abs() <= tol;
}
