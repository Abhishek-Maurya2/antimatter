import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../utils/preferences_helper.dart';

part 'settings_provider.g.dart';

class SettingsState {
  final bool useVibrantVariant;
  final bool sortCompletedNewest;
  final bool navHapticFeedbackEnabled;
  final String navHapticFeedback;

  const SettingsState({
    this.useVibrantVariant = false,
    this.sortCompletedNewest = true,
    this.navHapticFeedbackEnabled = true,
    this.navHapticFeedback = "Light",
  });

  SettingsState copyWith({
    bool? useVibrantVariant,
    bool? sortCompletedNewest,
    bool? navHapticFeedbackEnabled,
    String? navHapticFeedback,
  }) {
    return SettingsState(
      useVibrantVariant: useVibrantVariant ?? this.useVibrantVariant,
      sortCompletedNewest: sortCompletedNewest ?? this.sortCompletedNewest,
      navHapticFeedbackEnabled: navHapticFeedbackEnabled ?? this.navHapticFeedbackEnabled,
      navHapticFeedback: navHapticFeedback ?? this.navHapticFeedback,
    );
  }
}

@Riverpod(keepAlive: true)
class SettingsController extends _$SettingsController {
  @override
  SettingsState build() {
    return SettingsState(
      useVibrantVariant:
          PreferencesHelper.getBool("useVibrantVariant") ?? false,
      sortCompletedNewest:
          PreferencesHelper.getBool("sortCompletedNewest") ?? true,
      navHapticFeedbackEnabled:
          PreferencesHelper.getBool("navHapticFeedbackEnabled") ?? true,
      navHapticFeedback:
          PreferencesHelper.getString("navHapticFeedback") ?? "Light",
    );
  }

  void updateColorVariant(bool value) {
    PreferencesHelper.setBool("useVibrantVariant", value);
    state = state.copyWith(useVibrantVariant: value);
  }

  void setSortCompletedNewest(bool value) {
    PreferencesHelper.setBool("sortCompletedNewest", value);
    state = state.copyWith(sortCompletedNewest: value);
  }

  void setNavHapticFeedbackEnabled(bool value) {
    PreferencesHelper.setBool("navHapticFeedbackEnabled", value);
    state = state.copyWith(navHapticFeedbackEnabled: value);
  }

  void setNavHapticFeedback(String value) {
    PreferencesHelper.setString("navHapticFeedback", value);
    state = state.copyWith(navHapticFeedback: value);
  }
}
