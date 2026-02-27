import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> playTickSound() async {
    try {
      // Play tick sound from assets
      await _audioPlayer.play(AssetSource('tick.mp3'));
    } catch (e) {
      // Ignore errors (e.g., sound playing failed, or missing asset)
    }
  }
}
