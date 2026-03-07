import 'package:audioplayers/audioplayers.dart';
import '../utils/preferences_helper.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> playTickSound() async {
    final bool shouldPlay =
        PreferencesHelper.getBool('taskCompletionSound') ?? true;
    if (!shouldPlay) return;

    try {
      // Play tick sound from assets
      await _audioPlayer.play(AssetSource('tick.mp3'));
    } catch (e) {
      // Ignore errors (e.g., sound playing failed, or missing asset)
    }
  }
}
