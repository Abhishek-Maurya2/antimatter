import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/preferences_helper.dart';
import 'notification_service.dart';

class BlockerService {
  static final BlockerService _instance = BlockerService._internal();
  factory BlockerService() => _instance;
  BlockerService._internal();

  bool _isChecking = false;

  /// Call this inside the periodic timer to scan for blocked apps
  Future<void> checkBlocklist() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final List<String> blockedApps =
          PreferencesHelper.getStringList('blockedApps') ?? [];
      
      if (blockedApps.isEmpty) {
        _isChecking = false;
        return;
      }

      if (!kIsWeb) {
        if (Platform.isWindows) {
          await _enforceWindowsBlocklist(blockedApps);
        } else if (Platform.isAndroid) {
          await _enforceAndroidBlocklist(blockedApps);
        }
      }
    } catch (e) {
      debugPrint("Blocker Service Error: \$e");
    } finally {
      _isChecking = false;
    }
  }

  Future<void> _enforceWindowsBlocklist(List<String> blockedApps) async {
    for (String processName in blockedApps) {
      // Ensure the process name ends with .exe for matching if it doesn't already
      final exeName = processName.endsWith('.exe') ? processName : '$processName.exe';
      final baseName = exeName.split('.').first;
      
      try {
        // Use PowerShell to check if the process is running. 
        // This is more robust than tasklist as it allows easier filtering and case-insensitivity.
        final checkResult = await Process.run('powershell', [
          '-Command', 
          'Get-Process -Name "$baseName" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name'
        ]);
        
        final output = checkResult.stdout.toString().trim();
        if (output.toLowerCase().contains(baseName.toLowerCase())) {
          // The application is running, kill it!
          debugPrint("Attempting to terminate blocked application: $exeName");
          final killResult = await Process.run('taskkill', ['/F', '/IM', exeName]);
          
          if (killResult.exitCode == 0) {
            debugPrint("Successfully terminated: $exeName");
            await NotificationService().showBlockerNotification(baseName);
          } else {
            debugPrint("Taskkill failed for $exeName with exit code ${killResult.exitCode}: ${killResult.stderr}");
          }
        }
      } catch (e) {
        debugPrint("Error enforcing block for $exeName: $e");
      }
    }
  }

  Future<void> _enforceAndroidBlocklist(List<String> blockedApps) async {
    // Query usage stats from the last 15 minutes to find the current foreground app
    try {
      final bool isGranted = await UsageStats.checkUsagePermission() ?? false;
      if (!isGranted) {
        debugPrint("UsageStats permission not granted.");
        return;
      }

      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(const Duration(minutes: 5));
      List<EventUsageInfo> events = await UsageStats.queryEvents(startDate, endDate);

      if (events.isEmpty) return;

      // Find the most recent event where an app was moved to foreground (EventType 1 is ACTIVITY_RESUMED)
      events.sort((a, b) => (int.parse(b.timeStamp ?? "0")).compareTo(int.parse(a.timeStamp ?? "0")));
      
      EventUsageInfo? latestForegroundEvent;
      for (var event in events) {
        if (event.eventType == "1") { 
          latestForegroundEvent = event;
          break;
        }
      }

      if (latestForegroundEvent != null && latestForegroundEvent.packageName != null) {
        final currentPackage = latestForegroundEvent.packageName!;
        
        bool isBlocked = blockedApps.any((blocked) => 
            currentPackage.toLowerCase().contains(blocked.toLowerCase()));

        if (isBlocked) {
          debugPrint("Blocked application detected in foreground: $currentPackage");
          await NotificationService().showBlockerNotification(currentPackage.split('.').last);
          
          // Force launch AntiMatter app to overwrite the blocked app!
          // We can use the Deep Link mechanism or try to launch our own package.
          // Fallback: This URL scheme requires updating AndroidManifest.xml for the app if custom scheme is used.
          final url = Uri.parse('orches://blocker');
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        }
      }
    } catch (e) {
      debugPrint("Failed to enforce Android blocklist: \$e");
    }
  }
}
