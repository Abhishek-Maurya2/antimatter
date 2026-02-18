import 'package:flutter/material.dart';
import '../utils/preferences_helper.dart';

class SettingsNotifier extends ChangeNotifier {
  bool _useExpressiveVariant = false;

  bool get useExpressiveVariant => _useExpressiveVariant;

  SettingsNotifier() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _useExpressiveVariant =
        PreferencesHelper.getBool("useExpressiveVariant") ?? false;
    notifyListeners();
  }

  void updateColorVariant(bool value) {
    _useExpressiveVariant = value;
    PreferencesHelper.setBool("useExpressiveVariant", value);
    notifyListeners();
  }
}
