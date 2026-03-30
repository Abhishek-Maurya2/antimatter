import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:settings_tiles/settings_tiles.dart';
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
  bool _isOverlayPermissionGranted = true;
  String _searchQuery = "";

  final TextEditingController _manualInputController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadApplications();
    _checkUsagePermission();
    _checkOverlayPermission();
  }

  Future<void> _checkUsagePermission() async {
    if (Platform.isAndroid) {
      final isGranted = await UsageStats.checkUsagePermission() ?? false;
      if (mounted) {
        setState(() => _isUsagePermissionGranted = isGranted);
      }
    }
  }

  Future<void> _checkOverlayPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.systemAlertWindow.status;
      if (mounted) {
        setState(() => _isOverlayPermissionGranted = status.isGranted);
      }
    }
  }

  Future<void> _requestUsagePermission() async {
    if (Platform.isAndroid) {
      await UsageStats.grantUsagePermission();
      Future.delayed(const Duration(seconds: 1), _checkUsagePermission);
    }
  }

  Future<void> _requestOverlayPermission() async {
    if (Platform.isAndroid) {
      await Permission.systemAlertWindow.request();
      Future.delayed(const Duration(seconds: 1), _checkOverlayPermission);
    }
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    try {
      if (!kIsWeb) {
        if (Platform.isAndroid) {
          final apps = await InstalledApps.getInstalledApps(
            excludeSystemApps: !_showSystemApps,
            withIcon: true,
          );
          _androidApps = apps.toList();
          _androidApps.sort((a, b) => a.name.compareTo(b.name));
        } else if (Platform.isWindows) {
          final startAppsResult = await Process.run('powershell', [
            '-Command',
            'Get-StartApps | Select-Object Name, AppID | ConvertTo-Json',
          ]);
          final String stdout = startAppsResult.stdout.toString();
          final List<Map<String, String>> discoveredApps = [];

          try {
            if (stdout.isNotEmpty && stdout != 'null') {
              final List<dynamic> appsArray = jsonDecode(stdout);
              for (var app in appsArray) {
                final name = app['Name'] as String? ?? 'Unknown App';
                final appId = app['AppID'] as String? ?? '';
                String exeName = '';
                if (appId.toLowerCase().endsWith('.exe')) {
                  exeName = appId.split('\\').last;
                } else {
                  exeName = '$name.exe'.replaceAll(' ', '');
                }
                discoveredApps.add({'name': name, 'exe': exeName, 'id': appId});
              }
            }
          } catch (e) {
            debugPrint("Error parsing StartApps: $e");
          }

          final result = await Process.run('tasklist', ['/FO', 'CSV', '/NH']);
          final lines = result.stdout.toString().split('\n');
          final Set<String> runningExes = {};

          for (var line in lines) {
            final parts = line.split('","');
            if (parts.isNotEmpty) {
              String exeName = parts[0].replaceAll('"', '').trim();
              if (exeName.isNotEmpty &&
                  exeName != 'svchost.exe' &&
                  exeName != 'explorer.exe') {
                runningExes.add(exeName);
              }
            }
          }

          _windowsApps = discoveredApps;
          for (var exe in runningExes) {
            bool alreadyInList = _windowsApps.any(
              (app) => app['exe']?.toLowerCase() == exe.toLowerCase(),
            );
            if (!alreadyInList) {
              _windowsApps.add({
                'name': exe.split('.').first,
                'exe': exe,
                'id': exe,
              });
            }
          }
          _windowsApps.sort(
            (a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''),
          );
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
        return app.name.toLowerCase().contains(query) ||
            app.packageName.toLowerCase().contains(query);
      }).toList();

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

      _filteredWindowsApps.sort((a, b) {
        final aBlocked = blocked.contains(a['exe']);
        final bBlocked = blocked.contains(b['exe']);
        if (aBlocked && !bBlocked) return -1;
        if (!aBlocked && bBlocked) return 1;
        return (a['name'] ?? '').toLowerCase().compareTo(
          (b['name'] ?? '').toLowerCase(),
        );
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
    final settingsState = ref.watch(settingsControllerProvider);
    final blocked = settingsState.blockedApps;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: widget.isEmbedded
          ? colorTheme.surfaceContainerLow
          : colorTheme.surfaceContainer,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LoadingIndicatorM3E(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading applications...',
                    style: TextStyle(color: colorTheme.onSurfaceVariant),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
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
                            icon: const Icon(
                              Symbols.arrow_back_rounded,
                              weight: 700,
                            ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'Search apps...',
                              prefixIcon: const Icon(Symbols.search),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButtonM3E(
                                      onPressed: () {
                                        _searchController.clear();
                                        _onSearchChanged("");
                                      },
                                      icon: const Icon(Symbols.close),
                                      variant: IconButtonM3EVariant.standard,
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
                        ),

                        if (Platform.isAndroid &&
                            (!_isUsagePermissionGranted ||
                                !_isOverlayPermissionGranted))
                          _buildPermissionGroup(context),

                        const SizedBox(height: 16),

                        SettingSection(
                          styleTile: true,
                          title: _buildSectionTitle(
                            context,
                            'Blacklist Settings',
                          ),
                          tiles: [
                            if (Platform.isAndroid)
                              SettingSwitchTile(
                                icon: iconContainer(
                                  Symbols.android,
                                  isLight
                                      ? const Color(0xffd6e2ff)
                                      : const Color(0xff004a77),
                                  isLight
                                      ? const Color(0xff004a77)
                                      : const Color(0xffd6e2ff),
                                ),
                                title: const Text('Show System Apps'),
                                toggled: _showSystemApps,
                                onChanged: (val) {
                                  setState(() => _showSystemApps = val);
                                  _loadApplications();
                                },
                              ),
                            _buildManualAddTile(context, blocked),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                if (Platform.isAndroid)
                  ..._buildAndroidSlivers(context, blocked)
                else if (Platform.isWindows)
                  ..._buildWindowsSlivers(context, blocked)
                else
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'Blocker UI not supported on this platform.',
                        ),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final colorTheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
      child: Text(
        title,
        style: TextStyle(
          color: colorTheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPermissionGroup(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        if (!_isUsagePermissionGranted)
          _buildExpressiveBanner(
            context,
            icon: Symbols.warning,
            title: 'Usage Access Required',
            description:
                'To detect and block apps, please enable "Usage Access" in system settings.',
            color: colorTheme.error,
            onAction: _requestUsagePermission,
            actionLabel: 'Allow Access',
          ),
        if (!_isOverlayPermissionGranted)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildExpressiveBanner(
              context,
              icon: Symbols.layers,
              title: 'Overlay Permission Required',
              description:
                  'AntiMatter needs to display itself over other apps to block them successfully.',
              color: colorTheme.primary,
              onAction: _requestOverlayPermission,
              actionLabel: 'Grant Overlay',
            ),
          ),
      ],
    );
  }

  Widget _buildExpressiveBanner(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onAction,
    required String actionLabel,
  }) {
    final typography = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: typography.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: typography.bodyMedium),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ButtonM3E(
                  onPressed: onAction,
                  label: Text(actionLabel),
                  icon: const Icon(Symbols.settings_rounded),
                  style: ButtonM3EStyle.filled,
                  foregroundColor: color.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                  backgroundColor: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  SettingTile _buildManualAddTile(BuildContext context, List<String> blocked) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return SettingActionTile(
      icon: iconContainer(
        Symbols.keyboard,
        isLight ? const Color(0xfff8e287) : const Color(0xff534600),
        isLight ? const Color(0xff534600) : const Color(0xfff8e287),
      ),
      title: const Text('Add Manually'),
      description: const Text('Add by process or package name'),
      onTap: () => _showManualAddDialog(context, blocked),
    );
  }

  void _showManualAddDialog(BuildContext context, List<String> blocked) {
    final colorTheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colorTheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorTheme.onSurfaceVariant.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Manual Blacklist',
                style: TextStyle(
                  fontFamily: 'GoogleSansFlex',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colorTheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _manualInputController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g. com.android.chrome or game.exe',
                  filled: true,
                  fillColor: colorTheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ButtonM3E(
                      onPressed: () {
                        final val = _manualInputController.text.trim();
                        if (val.isNotEmpty) {
                          _toggleApp(val, true, blocked);
                          _manualInputController.clear();
                          _loadApplications();
                          Navigator.pop(context);
                        }
                      },
                      label: const Text('Add to Blacklist'),
                      style: ButtonM3EStyle.filled,
                      size: ButtonM3ESize.lg,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAndroidSlivers(
    BuildContext context,
    List<String> blocked,
  ) {
    final blockedApps = _filteredAndroidApps
        .where((a) => blocked.contains(a.packageName))
        .toList();
    final otherApps = _filteredAndroidApps
        .where((a) => !blocked.contains(a.packageName))
        .toList();

    return [
      if (blockedApps.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSectionTitle(context, 'Blocked Apps'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.builder(
            itemCount: blockedApps.length,
            itemBuilder: (context, index) => _buildAppTile(
              context,
              blockedApps[index],
              true,
              blocked,
              isFirst: index == 0,
              isLast: index == blockedApps.length - 1,
            ),
          ),
        ),
      ],
      if (otherApps.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: _buildSectionTitle(context, 'Other Apps'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.builder(
            itemCount: otherApps.length,
            itemBuilder: (context, index) => _buildAppTile(
              context,
              otherApps[index],
              false,
              blocked,
              isFirst: index == 0,
              isLast: index == otherApps.length - 1,
            ),
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildWindowsSlivers(
    BuildContext context,
    List<String> blocked,
  ) {
    final blockedApps = _filteredWindowsApps
        .where((a) => blocked.contains(a['exe']))
        .toList();
    final otherApps = _filteredWindowsApps
        .where((a) => !blocked.contains(a['exe']))
        .toList();

    return [
      if (blockedApps.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSectionTitle(context, 'Blocked Apps'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.builder(
            itemCount: blockedApps.length,
            itemBuilder: (context, index) => _buildWindowsAppTile(
              context,
              blockedApps[index],
              true,
              blocked,
              isFirst: index == 0,
              isLast: index == blockedApps.length - 1,
            ),
          ),
        ),
      ],
      if (otherApps.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: _buildSectionTitle(context, 'Running Apps'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.builder(
            itemCount: otherApps.length,
            itemBuilder: (context, index) => _buildWindowsAppTile(
              context,
              otherApps[index],
              false,
              blocked,
              isFirst: index == 0,
              isLast: index == otherApps.length - 1,
            ),
          ),
        ),
      ],
    ];
  }

  Widget _buildAppTile(
    BuildContext context,
    AppInfo app,
    bool isBlocked,
    List<String> blocked, {
    required bool isFirst,
    required bool isLast,
  }) {
    final colorTheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return _styledTileWrapper(
      context,
      isFirst: isFirst,
      isLast: isLast,
      child: SettingSwitchTile(
        toggled: isBlocked,
        onChanged: (val) {
          _toggleApp(app.packageName, val, blocked);
          _applyFilter();
          setState(() {});
        },
        icon: app.icon != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(app.icon!, width: 40, height: 40),
              )
            : iconContainer(
                Symbols.android,
                isLight ? const Color(0xffd6e2ff) : const Color(0xff004a77),
                isLight ? const Color(0xff004a77) : const Color(0xffd6e2ff),
              ),
        title: Text(
          app.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        description: Text(
          app.packageName,
          style: TextStyle(fontSize: 12, color: colorTheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildWindowsAppTile(
    BuildContext context,
    Map<String, String> app,
    bool isBlocked,
    List<String> blocked, {
    required bool isFirst,
    required bool isLast,
  }) {
    final colorTheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final exe = app['exe'] ?? '';

    return _styledTileWrapper(
      context,
      isFirst: isFirst,
      isLast: isLast,
      child: SettingSwitchTile(
        toggled: isBlocked,
        onChanged: (val) {
          _toggleApp(exe, val, blocked);
          _applyFilter();
          setState(() {});
        },
        icon: iconContainer(
          Symbols.desktop_windows,
          isLight ? const Color(0xffd6e2ff) : const Color(0xff004a77),
          isLight ? const Color(0xff004a77) : const Color(0xffd6e2ff),
        ),
        title: Text(
          app['name'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        description: Text(
          exe,
          style: TextStyle(fontSize: 12, color: colorTheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _styledTileWrapper(
    BuildContext context, {
    required Widget child,
    required bool isFirst,
    required bool isLast,
  }) {
    final colorTheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isFirst ? 24 : 4),
      topRight: Radius.circular(isFirst ? 24 : 4),
      bottomLeft: Radius.circular(isLast ? 24 : 4),
      bottomRight: Radius.circular(isLast ? 24 : 4),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: colorTheme.surfaceContainerLowest,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
