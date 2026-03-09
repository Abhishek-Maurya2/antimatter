import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import '../utils/preferences_helper.dart';
import 'package:dynamic_color/dynamic_color.dart';
import '../models/theme_preset.dart';

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

  List<ThemePreset> _customPresets = [];
  String? _activePresetId;

  bool _isDynamicColorSupported = false;

  bool get isDynamicColorSupported => _isDynamicColorSupported;

  Future<void> checkDynamicColorSupport() async {
    _isDynamicColorSupported =
        (await DynamicColorPlugin.getCorePalette()) != null ||
        (await DynamicColorPlugin.getAccentColor()) != null;
  }

  ThemeController();

  Future<void> initialize({
    Color fallbackColor = const Color(0xFF6750A4),
  }) async {
    _loadCustomPresets();

    bool useDynamicColors = PreferencesHelper.getBool("DynamicColors") ?? true;

    if (useDynamicColors) {
      await loadDynamicColors();
    } else {
      _activePresetId = PreferencesHelper.getString("ActivePresetId");
      if (_activePresetId != null) {
        final preset = getPresetById(_activePresetId!);
        if (preset != null) {
          setSeedColor(preset.seedColor);
        } else if (isCustom) {
          setSeedColor(
            PreferencesHelper.getColor("CustomMaterialColor") ?? Colors.blue,
          );
        } else {
          setSeedColor(fallbackColor);
        }
      } else if (isCustom) {
        setSeedColor(
          PreferencesHelper.getColor("CustomMaterialColor") ?? Colors.blue,
        );
      } else {
        setSeedColor(fallbackColor);
      }
    }
  }

  void _loadCustomPresets() {
    final List<String>? savedPresets = PreferencesHelper.getStringList(
      "CustomThemePresets",
    );
    if (savedPresets != null) {
      _customPresets = savedPresets
          .map((jsonStr) => ThemePreset.fromJson(jsonDecode(jsonStr)))
          .toList();
    } else {
      _customPresets = [];
    }
  }

  void _saveCustomPresets() {
    final List<String> jsonList = _customPresets
        .map((p) => jsonEncode(p.toJson()))
        .toList();
    PreferencesHelper.setStringList("CustomThemePresets", jsonList);
  }

  Color get seedColor => _seedColor ?? const Color(0xFF6750A4);
  CorePalette? get corePalette => _corePalette;
  ThemeMode get themeMode => _themeMode;
  bool get isUsingDynamicColor => _isUsingDynamicColor;
  bool get useDynamicColors =>
      PreferencesHelper.getBool("DynamicColors") ?? true;

  List<ThemePreset> get customPresets => _customPresets;
  String? get activePresetId => _activePresetId;

  ThemePreset? getPresetById(String id) {
    try {
      return builtInPresets.firstWhere((p) => p.id == id);
    } catch (_) {
      try {
        return _customPresets.firstWhere((p) => p.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  void setUseDynamicColors(bool value) async {
    PreferencesHelper.setBool("DynamicColors", value);
    if (value) {
      await loadDynamicColors();
    } else {
      if (isCustom) {
        setSeedColor(
          PreferencesHelper.getColor("CustomMaterialColor") ?? Colors.blue,
        );
      } else {
        setSeedColor(const Color(0xFF6750A4));
      }
    }
  }

  void setSeedColor(Color newColor) {
    _seedColor = newColor;
    _corePalette = CorePalette.of(newColor.toARGB32());
    _isUsingDynamicColor = false;
    notifyListeners();
  }

  void applyPreset(ThemePreset preset) {
    _activePresetId = preset.id;
    PreferencesHelper.setString("ActivePresetId", preset.id);

    // Disable dynamic colors if applying a preset manually
    PreferencesHelper.setBool("DynamicColors", false);

    setSeedColor(preset.seedColor);
  }

  void saveCustomPreset(ThemePreset preset) {
    _customPresets.add(preset);
    _saveCustomPresets();
    notifyListeners();
  }

  void deleteCustomPreset(ThemePreset preset) {
    _customPresets.removeWhere((p) => p.id == preset.id);
    _saveCustomPresets();

    if (_activePresetId == preset.id) {
      _activePresetId = null;
      PreferencesHelper.remove("ActivePresetId");
    }

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
    try {
      final corePalette = await DynamicColorPlugin.getCorePalette();
      if (corePalette != null) {
        _corePalette = corePalette;

        final brightness = currentBrightness;
        int primaryTone = brightness == Brightness.light ? 40 : 80;

        final int argb = corePalette.primary.get(primaryTone);
        _seedColor = Color(argb);
        _isUsingDynamicColor = true;
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint("Failed to get core palette: $e");
    }

    try {
      final accentColor = await DynamicColorPlugin.getAccentColor();
      if (accentColor != null) {
        _seedColor = accentColor;
        _isUsingDynamicColor = true;
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint("Failed to get accent color: $e");
    }
  }
}

bool isMonochrome(Color c, {double tol = 1.0 / 255.0}) {
  final r = c.r, g = c.g, b = c.b;
  return (r - g).abs() <= tol && (g - b).abs() <= tol && (r - b).abs() <= tol;
}
