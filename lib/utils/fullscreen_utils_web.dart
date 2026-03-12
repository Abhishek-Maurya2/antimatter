import 'dart:html' as html;

Future<void> toggleFullscreen(bool enable) async {
  if (enable) {
    html.window.document.documentElement?.requestFullscreen();
  } else {
    if (html.window.document.fullscreenElement != null) {
      html.window.document.exitFullscreen();
    }
  }
}
