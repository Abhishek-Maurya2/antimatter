import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'dart:convert';
import 'dart:ui';
import '../utils/preferences_helper.dart';
import '../models/theme_preset.dart';

part 'theme_provider.g.dart';

class ThemeState {
  final Color seedColor;
  final CorePalette? corePalette;
  final ThemeMode themeMode;
  final bool isCustom;
  final bool isUsingDynamicColor;
  final List<ThemePreset> customPresets;
  final String? activePresetId;
  final bool isDynamicColorSupported;
  final bool useDynamicColors;

  const ThemeState({
    required this.seedColor,
    this.corePalette,
    required this.themeMode,
    this.isCustom = false,
    this.isUsingDynamicColor = false,
    this.customPresets = const [],
    this.activePresetId,
    this.isDynamicColorSupported = false,
    this.useDynamicColors = true,
  });

  ThemeState copyWith({
    Color? seedColor,
    CorePalette? corePalette,
    ThemeMode? themeMode,
    bool? isCustom,
    bool? isUsingDynamicColor,
    List<ThemePreset>? customPresets,
    String? activePresetId,
    bool? isDynamicColorSupported,
    bool? useDynamicColors,
  }) {
    return ThemeState(
      seedColor: seedColor ?? this.seedColor,
      corePalette: corePalette ?? this.corePalette,
      themeMode: themeMode ?? this.themeMode,
      isCustom: isCustom ?? this.isCustom,
      isUsingDynamicColor: isUsingDynamicColor ?? this.isUsingDynamicColor,
      customPresets: customPresets ?? this.customPresets,
      activePresetId:
          activePresetId ??
          this.activePresetId, // Note: activePresetId can't be cleared with copyWith this way but we're mostly setting it.
      isDynamicColorSupported:
          isDynamicColorSupported ?? this.isDynamicColorSupported,
      useDynamicColors: useDynamicColors ?? this.useDynamicColors,
    );
  }

  ThemeState clearActivePreset() {
    return ThemeState(
      seedColor: seedColor,
      corePalette: corePalette,
      themeMode: themeMode,
      isCustom: isCustom,
      isUsingDynamicColor: isUsingDynamicColor,
      customPresets: customPresets,
      activePresetId: null,
      isDynamicColorSupported: isDynamicColorSupported,
      useDynamicColors: useDynamicColors,
    );
  }
}

@Riverpod(keepAlive: true)
class ThemeController extends _$ThemeController {
  static CorePalette? _initialCorePalette;
  static Color? _initialAccentColor;

  /// Fetch dynamic colors before the app starts to avoid theme loading lag.
  static Future<void> prefetchDynamicColors() async {
    _initialCorePalette = await DynamicColorPlugin.getCorePalette();
    _initialAccentColor = await DynamicColorPlugin.getAccentColor();
  }

  @override
  ThemeState build() {
    final initState = _initializeSync();
    Future.microtask(() => initializeAsync());
    return initState;
  }

  ThemeState _initializeSync({Color fallbackColor = const Color(0xFF6750A4)}) {
    // 1. Load ThemeMode
    final String themePref = PreferencesHelper.getString("AppTheme") ?? "Auto";
    ThemeMode mode = themePref == "Light"
        ? ThemeMode.light
        : themePref == "Auto"
        ? ThemeMode.system
        : ThemeMode.dark;

    // 2. Load Presets
    List<ThemePreset> customP = [];
    final List<String>? savedPresets = PreferencesHelper.getStringList(
      "CustomThemePresets",
    );
    if (savedPresets != null) {
      customP = savedPresets
          .map((jsonStr) => ThemePreset.fromJson(jsonDecode(jsonStr)))
          .toList();
    }

    // 3. Other fields
    bool isCstm = PreferencesHelper.getBool("usingCustomSeed") ?? false;
    bool useDynC = PreferencesHelper.getBool("DynamicColors") ?? true;
    String? actId = PreferencesHelper.getString("ActivePresetId");

    Color initialSeed = fallbackColor;
    bool isUsingDyn = false;

    if (useDynC) {
      if (_initialCorePalette != null) {
        final brightness = _currentBrightnessSync(mode);
        final primaryTone = brightness == Brightness.light ? 40 : 80;
        initialSeed = Color(_initialCorePalette!.primary.get(primaryTone));
        isUsingDyn = true;
      } else if (_initialAccentColor != null) {
        initialSeed = _initialAccentColor!;
        isUsingDyn = true;
      }
    }

    if (!isUsingDyn) {
      if (actId != null) {
        ThemePreset? match;
        try {
          match = builtInPresets.firstWhere((p) => p.id == actId);
        } catch (_) {
          try {
            match = customP.firstWhere((p) => p.id == actId);
          } catch (_) {}
        }
        if (match != null) {
          initialSeed = match.seedColor;
        } else if (isCstm) {
          initialSeed =
              PreferencesHelper.getColor("CustomMaterialColor") ?? Colors.blue;
        }
      } else if (isCstm) {
        initialSeed =
            PreferencesHelper.getColor("CustomMaterialColor") ?? Colors.blue;
      }
    }

    return ThemeState(
      seedColor: initialSeed,
      corePalette: isUsingDyn ? _initialCorePalette : null,
      themeMode: mode,
      isCustom: isCstm,
      isUsingDynamicColor: isUsingDyn,
      useDynamicColors: useDynC,
      customPresets: customP,
      activePresetId: actId,
      isDynamicColorSupported:
          _initialCorePalette != null || _initialAccentColor != null,
    );
  }

  static Brightness _currentBrightnessSync(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return PlatformDispatcher.instance.platformBrightness;
    }
  }

  Future<void> initializeAsync() async {
    final coreP = await DynamicColorPlugin.getCorePalette();
    final accentC = await DynamicColorPlugin.getAccentColor();
    final isSupported = coreP != null || accentC != null;

    ThemeState newState = state.copyWith(isDynamicColorSupported: isSupported);
    if (newState.useDynamicColors) {
      if (coreP != null) {
        final brightness = _currentBrightness(newState.themeMode);
        int primaryTone = brightness == Brightness.light ? 40 : 80;
        final int argb = coreP.primary.get(primaryTone);
        newState = newState.copyWith(
          seedColor: Color(argb),
          corePalette: coreP,
          isUsingDynamicColor: true,
        );
      } else if (accentC != null) {
        newState = newState.copyWith(
          seedColor: accentC,
          isUsingDynamicColor: true,
        );
      }
    }
    state = newState;
  }

  Brightness _currentBrightness(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return PlatformDispatcher.instance.platformBrightness;
    }
  }

  void setUseDynamicColors(bool value) async {
    PreferencesHelper.setBool("DynamicColors", value);
    if (value) {
      state = state.copyWith(useDynamicColors: true);
      await initializeAsync();
    } else {
      Color newSeed;
      if (state.isCustom) {
        newSeed =
            PreferencesHelper.getColor("CustomMaterialColor") ?? Colors.blue;
      } else {
        newSeed = const Color(0xFF6750A4);
      }
      setSeedColor(newSeed);
    }
  }

  void setSeedColor(Color newColor) {
    state = state.copyWith(
      seedColor: newColor,
      corePalette: CorePalette.of(newColor.toARGB32()),
      isUsingDynamicColor: false,
    );
  }

  void applyPreset(ThemePreset preset) {
    PreferencesHelper.setString("ActivePresetId", preset.id);
    PreferencesHelper.setBool("DynamicColors", false);

    state = state.copyWith(
      activePresetId: preset.id,
      useDynamicColors: false,
      seedColor: preset.seedColor,
      corePalette: CorePalette.of(preset.seedColor.toARGB32()),
      isUsingDynamicColor: false,
    );
  }

  void saveCustomPreset(ThemePreset preset) {
    final newList = [...state.customPresets, preset];
    _savePresetsList(newList);
    state = state.copyWith(customPresets: newList);
  }

  void deleteCustomPreset(ThemePreset preset) {
    final newList = state.customPresets
        .where((p) => p.id != preset.id)
        .toList();
    _savePresetsList(newList);

    if (state.activePresetId == preset.id) {
      PreferencesHelper.remove("ActivePresetId");
      state = state.clearActivePreset().copyWith(customPresets: newList);
    } else {
      state = state.copyWith(customPresets: newList);
    }
  }

  void _savePresetsList(List<ThemePreset> list) {
    final jsonList = list.map((p) => jsonEncode(p.toJson())).toList();
    PreferencesHelper.setStringList("CustomThemePresets", jsonList);
  }

  void setSeedColorSilently(Color newColor) {
    state = state.copyWith(
      seedColor: newColor,
      corePalette: CorePalette.of(newColor.toARGB32()),
      isUsingDynamicColor: false,
    );
  }

  void setThemeMode(ThemeMode mode) {
    PreferencesHelper.setString(
      "AppTheme",
      mode == ThemeMode.light
          ? "Light"
          : mode == ThemeMode.dark
          ? "Dark"
          : "Auto",
    );
    state = state.copyWith(themeMode: mode);
  }
}

bool isMonochrome(Color c, {double tol = 1.0 / 255.0}) {
  final r = c.r, g = c.g, b = c.b;
  return (r - g).abs() <= tol && (g - b).abs() <= tol && (r - b).abs() <= tol;
}
