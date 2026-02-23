import 'package:flutter/material.dart';
import '../utils/preferences_helper.dart';

class SettingsNotifier extends ChangeNotifier {
  bool _useVibrantVariant = false;

  bool get useVibrantVariant => _useVibrantVariant;

  SettingsNotifier() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _useVibrantVariant =
        PreferencesHelper.getBool("useVibrantVariant") ?? false;
    notifyListeners();
  }

  void updateColorVariant(bool value) {
    _useVibrantVariant = value;
    PreferencesHelper.setBool("useVibrantVariant", value);
    notifyListeners();
  }
}
