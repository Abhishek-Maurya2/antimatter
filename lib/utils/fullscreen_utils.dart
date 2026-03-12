export 'fullscreen_utils_stub.dart'
    if (dart.library.html) 'fullscreen_utils_web.dart'
    if (dart.library.io) 'fullscreen_utils_desktop.dart';
