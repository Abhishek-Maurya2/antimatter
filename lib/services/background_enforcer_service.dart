import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'ai_coach_service.dart';
import 'blocker_service.dart';
import 'notification_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../models/session.dart';
import '../utils/preferences_helper.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Only available for flutter_background_service
  WidgetsFlutterBinding.ensureInitialized();
  await PreferencesHelper.init();
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(SessionAdapter());
  await NotificationService().init();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Schedule AI coach every 30 minutes
  Timer.periodic(const Duration(minutes: 30), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "AntiMatter Focus Mode",
          content: "Enforcing productivity...",
        );
      }
    }
    await BackgroundEnforcerService._executeAiCoachTask();
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

class BackgroundEnforcerService {
  static final BackgroundEnforcerService _instance =
      BackgroundEnforcerService._internal();
  factory BackgroundEnforcerService() => _instance;
  BackgroundEnforcerService._internal();

  /// Abstracted execution call used by both native mobile and desktop timers
  static Future<void> _executeAiCoachTask() async {
    await AiCoachService().triggerCoach();
  }

  static Future<void> _executeBlockerTask() async {
    await BlockerService().checkBlocklist();
  }

  Future<void> initialize() async {
    if (kIsWeb) return; 

    if (Platform.isAndroid || Platform.isIOS) {
      final service = FlutterBackgroundService();
      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          autoStart: true,
          isForegroundMode: true,
          notificationChannelId: 'ai_coach_channel', 
          initialNotificationTitle: 'AntiMatter Focus',
          initialNotificationContent: 'Protecting your focus...',
          foregroundServiceNotificationId: 888,
        ),
        iosConfiguration: IosConfiguration(
          autoStart: true,
          onForeground: onStart,
          onBackground: onIosBackground,
        ),
      );
      
      // The AI coach is triggered inside onStart for foreground service,
      // but the blocker needs to actively monitor every few seconds in the main isolate too
      Timer.periodic(const Duration(seconds: 3), (timer) async {
        await _executeBlockerTask();
      });
      
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // AI Coach Loop (30 mins)
      Timer.periodic(const Duration(minutes: 30), (timer) async {
        await _executeAiCoachTask();
      });
      
      // Blocker Loop (3 seconds)
      Timer.periodic(const Duration(seconds: 3), (timer) async {
        await _executeBlockerTask();
      });
    }
  }
}
