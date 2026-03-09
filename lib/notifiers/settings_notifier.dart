import 'package:flutter/material.dart';
import '../utils/preferences_helper.dart';

class SettingsNotifier extends ChangeNotifier {
  bool _useVibrantVariant = false;
  bool _sortCompletedNewest = true;

  bool get useVibrantVariant => _useVibrantVariant;
  bool get sortCompletedNewest => _sortCompletedNewest;

  SettingsNotifier() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _useVibrantVariant =
        PreferencesHelper.getBool("useVibrantVariant") ?? false;
    _sortCompletedNewest =
        PreferencesHelper.getBool("sortCompletedNewest") ?? true;
    notifyListeners();
  }

  void updateColorVariant(bool value) {
    _useVibrantVariant = value;
    PreferencesHelper.setBool("useVibrantVariant", value);
    notifyListeners();
  }

  void setSortCompletedNewest(bool value) {
    _sortCompletedNewest = value;
    PreferencesHelper.setBool("sortCompletedNewest", value);
    notifyListeners();
  }
}
