import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../utils/preferences_helper.dart';

part 'settings_provider.g.dart';

class SettingsState {
  final bool useVibrantVariant;
  final bool sortCompletedNewest;

  const SettingsState({
    this.useVibrantVariant = false,
    this.sortCompletedNewest = true,
  });

  SettingsState copyWith({bool? useVibrantVariant, bool? sortCompletedNewest}) {
    return SettingsState(
      useVibrantVariant: useVibrantVariant ?? this.useVibrantVariant,
      sortCompletedNewest: sortCompletedNewest ?? this.sortCompletedNewest,
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
}
