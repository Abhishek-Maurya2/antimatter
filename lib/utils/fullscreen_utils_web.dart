import 'dart:html' as html;

void toggleFullscreen(bool enable) {
  if (enable) {
    html.window.document.documentElement?.requestFullscreen();
  } else {
    if (html.window.document.fullscreenElement != null) {
      html.window.document.exitFullscreen();
    }
  }
}
