import 'package:window_manager/window_manager.dart';

Future<void> toggleFullscreen(bool enable) async {
  await windowManager.setFullScreen(enable);
}
