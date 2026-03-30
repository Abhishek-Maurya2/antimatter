import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../utils/preferences_helper.dart';

part 'settings_provider.g.dart';

class SettingsState {
  final bool useVibrantVariant;
  final bool sortCompletedNewest;
  final bool enableAiCoach;
  final String groqApiKey;
  final List<String> blockedApps;

  const SettingsState({
    this.useVibrantVariant = false,
    this.sortCompletedNewest = true,
    this.enableAiCoach = false,
    this.groqApiKey = '',
    this.blockedApps = const [],
  });

  SettingsState copyWith({
    bool? useVibrantVariant,
    bool? sortCompletedNewest,
    bool? enableAiCoach,
    String? groqApiKey,
    List<String>? blockedApps,
  }) {
    return SettingsState(
      useVibrantVariant: useVibrantVariant ?? this.useVibrantVariant,
      sortCompletedNewest: sortCompletedNewest ?? this.sortCompletedNewest,
      enableAiCoach: enableAiCoach ?? this.enableAiCoach,
      groqApiKey: groqApiKey ?? this.groqApiKey,
      blockedApps: blockedApps ?? this.blockedApps,
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
      enableAiCoach: PreferencesHelper.getBool("enableAiCoach") ?? false,
      groqApiKey: PreferencesHelper.getString("groqApiKey") ?? '',
      blockedApps: PreferencesHelper.getStringList("blockedApps") ?? [],
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

  void setEnableAiCoach(bool value) {
    PreferencesHelper.setBool("enableAiCoach", value);
    state = state.copyWith(enableAiCoach: value);
  }

  void setGroqApiKey(String value) {
    PreferencesHelper.setString("groqApiKey", value);
    state = state.copyWith(groqApiKey: value);
  }

  void updateBlockedApps(List<String> apps) {
    PreferencesHelper.setStringList("blockedApps", apps);
    state = state.copyWith(blockedApps: apps);
  }
}
