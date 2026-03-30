import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:m3e_collection/m3e_collection.dart';
import '../../providers/settings_provider.dart';
import '../settings_screen.dart';

class BlacklistScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  const BlacklistScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<BlacklistScreen> createState() => _BlacklistScreenState();
}

class _BlacklistScreenState extends ConsumerState<BlacklistScreen> {
  List<AppInfo> _androidApps = [];
  List<AppInfo> _filteredAndroidApps = [];
  List<Map<String, String>> _windowsApps = [];
  List<Map<String, String>> _filteredWindowsApps = [];
  
  bool _isLoading = true;
  bool _showSystemApps = false;
  bool _isUsagePermissionGranted = true;
  String _searchQuery = "";
  
  final TextEditingController _manualInputController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadApplications();
    _checkUsagePermission();
  }

  Future<void> _checkUsagePermission() async {
    if (Platform.isAndroid) {
      final isGranted = await UsageStats.checkUsagePermission() ?? false;
      if (mounted) {
        setState(() => _isUsagePermissionGranted = isGranted);
      }
    }
  }

  Future<void> _requestUsagePermission() async {
    if (Platform.isAndroid) {
      await UsageStats.grantUsagePermission();
      // After returning from settings, check again
      Future.delayed(const Duration(seconds: 1), _checkUsagePermission);
    }
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    try {
      if (!kIsWeb) {
        if (Platform.isAndroid) {
          final apps = await InstalledApps.getInstalledApps(
            excludeSystemApps: !_showSystemApps, 
            withIcon: true
          );
          // Filter out system apps if desired, but for now show everything
          _androidApps = apps.toList();
          _androidApps.sort((a, b) => a.name.compareTo(b.name));
        } else if (Platform.isWindows) {
          // 1. Fetch Start Apps (Installed names)
          final startAppsResult = await Process.run('powershell', ['-Command', 'Get-StartApps | Select-Object Name, AppID | ConvertTo-Json']);
          final String stdout = startAppsResult.stdout.toString();
          final List<Map<String, String>> discoveredApps = [];
          
          try {
            if (stdout.isNotEmpty && stdout != 'null') {
              final List<dynamic> appsArray = jsonDecode(stdout);
              for (var app in appsArray) {
                final name = app['Name'] as String? ?? 'Unknown App';
                final appId = app['AppID'] as String? ?? '';
                
                // If AppID looks like a path to an EXE, extract the name
                String exeName = '';
                if (appId.toLowerCase().endsWith('.exe')) {
                  exeName = appId.split('\\').last;
                } else {
                  // Fallback: guess exe name from friendly name (not always accurate but helpfuL)
                  exeName = '$name.exe'.replaceAll(' ', '');
                }
                
                discoveredApps.add({'name': name, 'exe': exeName, 'id': appId});
              }
            }
          } catch (e) {
            debugPrint("Error parsing StartApps: $e");
          }

          // 2. Fetch currently running processes (to ensure we have exact exe names)
          final result = await Process.run('tasklist', ['/FO', 'CSV', '/NH']);
          final lines = result.stdout.toString().split('\n');
          final Set<String> runningExes = {};
          
          for (var line in lines) {
            final parts = line.split('","');
            if (parts.isNotEmpty) {
              String exeName = parts[0].replaceAll('"', '').trim();
              if (exeName.isNotEmpty && exeName != 'svchost.exe' && exeName != 'explorer.exe') {
                runningExes.add(exeName);
              }
            }
          }

          // Merge: Show Start Apps as primary, and any other running EXEs not in Start Apps
          _windowsApps = discoveredApps;
          for (var exe in runningExes) {
            bool alreadyInList = _windowsApps.any((app) => app['exe']?.toLowerCase() == exe.toLowerCase());
            if (!alreadyInList) {
              _windowsApps.add({'name': exe.split('.').first, 'exe': exe, 'id': exe});
            }
          }
          
          _windowsApps.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
        }
      }
    } catch (e) {
      debugPrint("Error loading apps: $e");
    } finally {
      if (mounted) {
        _applyFilter();
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilter() {
    final query = _searchQuery.toLowerCase();
    final settingsState = ref.read(settingsControllerProvider);
    final blocked = settingsState.blockedApps;
    
    if (Platform.isAndroid) {
      _filteredAndroidApps = _androidApps.where((app) {
        final matchesSearch = app.name.toLowerCase().contains(query) || 
                             app.packageName.toLowerCase().contains(query);
        return matchesSearch;
      }).toList();
      
      // Sort to put blocked apps at the very top
      _filteredAndroidApps.sort((a, b) {
        final aBlocked = blocked.contains(a.packageName);
        final bBlocked = blocked.contains(b.packageName);
        if (aBlocked && !bBlocked) return -1;
        if (!aBlocked && bBlocked) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    } else if (Platform.isWindows) {
      _filteredWindowsApps = _windowsApps.where((app) {
        final name = (app['name'] ?? '').toLowerCase();
        final exe = (app['exe'] ?? '').toLowerCase();
        return name.contains(query) || exe.contains(query);
      }).toList();
      
      // Sort to put blocked apps at the very top
      _filteredWindowsApps.sort((a, b) {
        final aBlocked = blocked.contains(a['exe']);
        final bBlocked = blocked.contains(b['exe']);
        if (aBlocked && !bBlocked) return -1;
        if (!aBlocked && bBlocked) return 1;
        return (a['name'] ?? '').toLowerCase().compareTo((b['name'] ?? '').toLowerCase());
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _applyFilter();
    });
  }

  void _toggleApp(String identifier, bool block, List<String> currentBlocked) {
    final notifier = ref.read(settingsControllerProvider.notifier);
    if (block && !currentBlocked.contains(identifier)) {
      notifier.updateBlockedApps([...currentBlocked, identifier]);
    } else if (!block && currentBlocked.contains(identifier)) {
      final updated = List<String>.from(currentBlocked)..remove(identifier);
      notifier.updateBlockedApps(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;
    final typography = Theme.of(context).textTheme;
    final settingsState = ref.watch(settingsControllerProvider);
    final blocked = settingsState.blockedApps;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: widget.isEmbedded
          ? colorTheme.surfaceContainerLow
          : colorTheme.surfaceContainer,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                if (Platform.isAndroid && !_isUsagePermissionGranted)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorTheme.errorContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorTheme.error.withOpacity(0.5)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Symbols.warning, color: colorTheme.error),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Usage Stats Permission Required',
                                  style: typography.titleMedium?.copyWith(
                                    color: colorTheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'To block apps, AntiMatter needs to know which app is currently open. Please enable "Usage Access" for AntiMatter in Settings.',
                            style: typography.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _requestUsagePermission,
                            icon: const Icon(Symbols.settings),
                            label: const Text('Allow Access'),
                            style: FilledButton.styleFrom(
                              backgroundColor: colorTheme.error,
                              foregroundColor: colorTheme.onError,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SliverAppBar.large(
                  title: const Text('App Blacklist'),
                  titleSpacing: widget.isEmbedded ? 16 : 0,
                  leadingWidth: widget.isEmbedded ? 0 : 80,
                  automaticallyImplyLeading: !widget.isEmbedded,
                  leading: widget.isEmbedded
                      ? null
                      : Center(
                          child: IconButtonM3E(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Symbols.arrow_back_rounded, weight: 700),
                            tooltip: 'Back',
                            variant: IconButtonM3EVariant.tonal,
                            width: IconButtonM3EWidth.wide,
                          ),
                        ),
                  backgroundColor: widget.isEmbedded
                      ? colorTheme.surfaceContainerLow
                      : colorTheme.surfaceContainer,
                  scrolledUnderElevation: 1,
                  expandedHeight: 120,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Bar
                        TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Search apps...',
                            prefixIcon: const Icon(Symbols.search),
                            suffixIcon: _searchQuery.isNotEmpty 
                              ? IconButton(
                                  icon: const Icon(Symbols.close), 
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged("");
                                  }
                                ) 
                              : null,
                            filled: true,
                            fillColor: colorTheme.surfaceContainerLow,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Manual input
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _manualInputController,
                                decoration: InputDecoration(
                                  hintText: 'Add by process name (e.g. game.exe)',
                                  filled: true,
                                  isDense: true,
                                  fillColor: colorTheme.surfaceContainerLowest,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              onPressed: () {
                                final val = _manualInputController.text.trim();
                                if (val.isNotEmpty) {
                                  _toggleApp(val, true, blocked);
                                  _manualInputController.clear();
                                  _loadApplications(); // Refresh list to show new manual entry if running
                                }
                              },
                              icon: const Icon(Symbols.add),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (Platform.isAndroid)
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Show System Apps', style: TextStyle(fontSize: 14)),
                            value: _showSystemApps,
                            onChanged: (val) {
                              setState(() {
                                _showSystemApps = val;
                              });
                              _loadApplications();
                            },
                          ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              Platform.isAndroid ? 'Installed Apps' : 'Currently Running Apps',
                              style: TextStyle(
                                color: colorTheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                _loadApplications();
                              },
                              icon: const Icon(Symbols.refresh, size: 18),
                              label: Text(
                                '${Platform.isAndroid ? _filteredAndroidApps.length : _filteredWindowsApps.length} items',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (Platform.isAndroid)
                  SliverList.builder(
                    itemCount: _filteredAndroidApps.length,
                    itemBuilder: (context, index) {
                      final app = _filteredAndroidApps[index];
                      final pkg = app.packageName;
                      final isBlocked = blocked.contains(pkg);
                      
                      // Show header for Blocked section if it's the first blocked item
                      final isFirstBlocked = index == 0 && isBlocked;
                      // Show header for "Other Apps" if it's the first non-blocked item after blocked items
                      final isFirstOther = index > 0 && !isBlocked && blocked.contains(_filteredAndroidApps[index-1].packageName);
                      // Or if it's the first item and not blocked
                      final isFirstItemNotBlocked = index == 0 && !isBlocked;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isFirstBlocked)
                            _buildSectionHeader(context, 'Blocked Apps', Symbols.block),
                          if (isFirstOther || isFirstItemNotBlocked)
                            _buildSectionHeader(context, 'Other Apps', Symbols.list),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            child: Material(
                              color: isBlocked ? colorTheme.errorContainer.withOpacity(0.1) : colorTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              clipBehavior: Clip.antiAlias,
                              child: SwitchListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                title: Text(app.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                                subtitle: Text(pkg, style: TextStyle(fontSize: 12, color: colorTheme.onSurfaceVariant)),
                                value: isBlocked,
                                activeColor: colorTheme.error,
                                secondary: app.icon != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(app.icon!, width: 40, height: 40),
                                      )
                                    : iconContainer(
                                        Symbols.android,
                                        isLight ? const Color(0xffd6e2ff) : const Color(0xff004a77),
                                        isLight ? const Color(0xff004a77) : const Color(0xffd6e2ff),
                                      ),
                                onChanged: (val) {
                                  _toggleApp(pkg, val, blocked);
                                  _applyFilter(); // Immediate re-sort
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  )
                else if (Platform.isWindows)
                  SliverList.builder(
                    itemCount: _filteredWindowsApps.length,
                    itemBuilder: (context, index) {
                      final app = _filteredWindowsApps[index];
                      final name = app['name'] ?? 'Unknown App';
                      final exe = app['exe'] ?? '';
                      final isBlocked = blocked.contains(exe);
                      
                      final isFirstBlocked = index == 0 && isBlocked;
                      final isFirstOther = index > 0 && !isBlocked && blocked.contains(_filteredWindowsApps[index-1]['exe']);
                      final isFirstItemNotBlocked = index == 0 && !isBlocked;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isFirstBlocked)
                            _buildSectionHeader(context, 'Blocked Apps', Symbols.block),
                          if (isFirstOther || isFirstItemNotBlocked)
                            _buildSectionHeader(context, 'Other Apps', Symbols.list),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            child: Material(
                              color: isBlocked ? colorTheme.errorContainer.withOpacity(0.1) : colorTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              clipBehavior: Clip.antiAlias,
                              child: SwitchListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                                subtitle: Text(exe, style: TextStyle(fontSize: 12, color: colorTheme.onSurfaceVariant)),
                                value: isBlocked,
                                activeColor: colorTheme.error,
                                secondary: iconContainer(
                                  Symbols.desktop_windows,
                                  isLight ? const Color(0xffd6e2ff) : const Color(0xff004a77),
                                  isLight ? const Color(0xff004a77) : const Color(0xffd6e2ff),
                                ),
                                onChanged: (val) {
                                  _toggleApp(exe, val, blocked);
                                  _applyFilter();
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  )
                else
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Blocker UI not supported on this platform.'),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 50)),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final colorTheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorTheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: colorTheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
