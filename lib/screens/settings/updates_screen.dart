import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:loading_indicator_m3e/loading_indicator_m3e.dart';
import 'package:button_m3e/button_m3e.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../widgets/settings_app_bar.dart';

const String _githubOwner = 'Abhishek-Maurya2';
const String _githubRepo = 'antimatter';

class UpdatesScreen extends StatefulWidget {
  final bool isEmbedded;
  const UpdatesScreen({super.key, this.isEmbedded = false});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  bool _isLoading = true;
  String? _latestVersion;
  String? _releaseNotes;
  String? _apkDownloadUrl;
  String? _exeDownloadUrl;
  String? _error;

  // Download state
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _downloadError;
  String? _downloadedFilePath;
  String _currentVersion = '';
  DateTime? _downloadStartTime;
  double _downloadSpeedKbps = 0.0;

  @override
  void initState() {
    super.initState();
    _loadVersionAndCheck();
  }

  Future<void> _loadVersionAndCheck() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _currentVersion = info.version.isNotEmpty ? info.version : '1.4.0';
    });
    await _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.github.com/repos/$_githubOwner/$_githubRepo/releases/latest',
        ),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final tagName =
            (data['tag_name'] as String?)?.replaceAll('v', '') ?? '';
        // Strip build number suffix like "0.1.0+1-build.5" -> "0.1.0+1"
        final versionOnly = tagName.split('-build').first;

        String? apkUrl;
        String? exeUrl;
        final assets = data['assets'] as List<dynamic>? ?? [];
        for (final asset in assets) {
          final name = (asset['name'] as String? ?? '').toLowerCase();
          if (name.endsWith('.apk')) {
            apkUrl = asset['browser_download_url'] as String?;
          } else if (name.endsWith('.exe')) {
            exeUrl = asset['browser_download_url'] as String?;
          }
        }

        setState(() {
          _latestVersion = versionOnly;
          _releaseNotes = data['body'] as String? ?? 'No release notes.';
          _apkDownloadUrl = apkUrl;
          _exeDownloadUrl = exeUrl;
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _error = null;
          _latestVersion = null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to check for updates (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Could not connect to GitHub';
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadAndInstall() async {
    final isWindows = Theme.of(context).platform == TargetPlatform.windows;
    final downloadUrl = isWindows ? _exeDownloadUrl : _apkDownloadUrl;

    if (downloadUrl == null) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadSpeedKbps = 0.0;
      _downloadError = null;
      _downloadedFilePath = null;
      _downloadStartTime = DateTime.now();
    });

    try {
      final dir = isWindows
          ? await getDownloadsDirectory() ?? await getTemporaryDirectory()
          : await getTemporaryDirectory();

      final extension = isWindows ? 'exe' : 'apk';
      final fileName = 'antimatter-update-$_latestVersion.$extension';
      final filePath = '${dir.path}/$fileName';

      final dio = Dio();
      await dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && _downloadStartTime != null) {
            final now = DateTime.now();
            final elapsedSeconds =
                now.difference(_downloadStartTime!).inMilliseconds / 1000.0;

            double speed = 0.0;
            if (elapsedSeconds > 0) {
              // Speed in KB/s
              speed = (received / 1024) / elapsedSeconds;
            }

            setState(() {
              _downloadProgress = received / total;
              _downloadSpeedKbps = speed;
            });
          }
        },
      );

      setState(() {
        _isDownloading = false;
        _downloadedFilePath = filePath;
      });

      // Open/install the APK
      await OpenFilex.open(filePath);
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _downloadError = 'Download failed: ${e.toString()}';
      });
    }
  }

  Widget? _buildDownloadSection(ColorScheme colorTheme) {
    if (_isDownloading) {
      String speedText = '';
      if (_downloadSpeedKbps > 1024) {
        speedText = '${(_downloadSpeedKbps / 1024).toStringAsFixed(1)} MB/s';
      } else if (_downloadSpeedKbps > 0) {
        speedText = '${_downloadSpeedKbps.toStringAsFixed(0)} KB/s';
      } else {
        speedText = 'Calculating...';
      }

      return Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Column(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CircularProgressIndicatorM3E(
                      value: _downloadProgress,
                      shape: ProgressM3EShape.wavy,
                    ),
                  ),
                  Text(
                    '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'RobotoFlex',
                      color: colorTheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Downloading update...',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: colorTheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              speedText,
              style: TextStyle(
                fontSize: 13,
                color: colorTheme.onPrimaryContainer.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    if (_downloadError != null) {
      return Column(
        children: [
          const SizedBox(height: 16),
          Text(
            _downloadError!,
            style: TextStyle(color: colorTheme.error, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return null;
  }

  Widget? _buildBottomButtonGroup() {
    if (_isLoading) return null;

    final actions = <ButtonGroupM3EAction>[];

    if (_error != null) {
      actions.add(
        ButtonGroupM3EAction(
          icon: const Icon(Symbols.refresh_rounded, weight: 800),
          label: const Text('Retry'),
          shape: ButtonM3EShape.round,
          onPressed: _checkForUpdates,
        ),
      );
    } else if (_downloadError != null) {
      actions.add(
        ButtonGroupM3EAction(
          icon: const Icon(Symbols.refresh_rounded, weight: 800),
          label: const Text('Retry Download'),
          shape: ButtonM3EShape.round,
          onPressed: _downloadAndInstall,
        ),
      );
    } else if (_isDownloading) {
      return null;
    } else if (_downloadedFilePath != null) {
      final isWindows = Theme.of(context).platform == TargetPlatform.windows;
      actions.add(
        ButtonGroupM3EAction(
          icon: Icon(
            isWindows
                ? Symbols.download_done_rounded
                : Symbols.install_mobile_rounded,
            weight: 700,
          ),
          label: Text(isWindows ? 'Open Installer' : 'Install'),
          shape: ButtonM3EShape.round,
          onPressed: () => OpenFilex.open(_downloadedFilePath!),
        ),
      );
    } else if (_isUpdateAvailable) {
      actions.add(
        ButtonGroupM3EAction(
          icon: const Icon(Symbols.download_rounded, weight: 800),
          label: const Text('Download'),
          shape: ButtonM3EShape.round,
          onPressed: _downloadAndInstall,
        ),
      );
      actions.add(
        ButtonGroupM3EAction(
          icon: const Icon(Symbols.refresh_rounded, weight: 800),
          width: 100,
          contentPadding: EdgeInsets.zero,
          style: ButtonM3EStyle.tonal,
          shape: ButtonM3EShape.round,
          onPressed: _checkForUpdates,
        ),
      );
    } else {
      actions.add(
        ButtonGroupM3EAction(
          icon: const Icon(Symbols.refresh_rounded, weight: 800),
          label: const Text('Check again'),
          shape: ButtonM3EShape.round,
          onPressed: _checkForUpdates,
        ),
      );
    }

    if (actions.isEmpty) return null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 0, 5, 24),
      child: SafeArea(
        child: ButtonGroupM3E(
          type: ButtonGroupM3EType.standard,
          size: ButtonGroupM3ESize.lg,
          style: ButtonM3EStyle.filled,
          density: ButtonGroupM3EDensity.compact,
          expanded: true,
          linearMainAxisAlignment: MainAxisAlignment.center,
          equalizeWidths: actions.length == 1,
          actions: actions,
        ),
      ),
    );
  }

  bool get _isUpdateAvailable {
    if (_latestVersion == null) return false;
    return _latestVersion != _currentVersion;
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: widget.isEmbedded
          ? colorTheme.surfaceContainerLow
          : colorTheme.surfaceContainer,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SettingsAppBar(title: 'Updates', isEmbedded: widget.isEmbedded),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                  child: _isLoading
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width:
                                    64, // Slightly larger for ExpressiveLoadingIndicator
                                height: 64,
                                child: LoadingIndicatorM3E(),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Checking for updates...',
                                style: TextStyle(
                                  color: colorTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Symbols.cloud_off_rounded,
                                size: 64,
                                color: colorTheme.error.withOpacity(0.6),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                style: TextStyle(
                                  color: colorTheme.onSurfaceVariant,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        )
                      : _latestVersion == null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Symbols.info_rounded,
                                size: 64,
                                color: colorTheme.onSurfaceVariant.withOpacity(
                                  0.3,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No releases found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Push your code to GitHub to create your first release.',
                                style: TextStyle(
                                  color: colorTheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            // Status card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 32,
                                horizontal: 24,
                              ),
                              decoration: BoxDecoration(
                                color: _isUpdateAvailable
                                    ? colorTheme.primaryContainer
                                    : colorTheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: _isUpdateAvailable
                                          ? colorTheme.primary
                                          : colorTheme.secondaryContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isUpdateAvailable
                                          ? Symbols.system_update_rounded
                                          : Symbols.check_circle_rounded,
                                      size: 48,
                                      weight: 600,
                                      color: _isUpdateAvailable
                                          ? colorTheme.onPrimary
                                          : colorTheme.onSecondaryContainer,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    _isUpdateAvailable
                                        ? 'Update Available!'
                                        : 'You\'re up to date',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'RobotoFlex',
                                      color: _isUpdateAvailable
                                          ? colorTheme.onPrimaryContainer
                                          : colorTheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Column(
                                        children: [
                                          Text(
                                            'Current',
                                            style: TextStyle(
                                              color:
                                                  (_isUpdateAvailable
                                                          ? colorTheme
                                                                .onPrimaryContainer
                                                          : colorTheme
                                                                .onSurfaceVariant)
                                                      .withOpacity(0.7),
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _isUpdateAvailable
                                                  ? colorTheme.surface
                                                        .withOpacity(0.5)
                                                  : colorTheme
                                                        .surfaceContainerHighest,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              'v$_currentVersion',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: _isUpdateAvailable
                                                    ? colorTheme
                                                          .onPrimaryContainer
                                                    : colorTheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_isUpdateAvailable) ...[
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: Icon(
                                            Symbols.arrow_forward_rounded,
                                            color: colorTheme.onPrimaryContainer
                                                .withOpacity(0.5),
                                            weight: 800,
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            Text(
                                              'Latest',
                                              style: TextStyle(
                                                color: colorTheme
                                                    .onPrimaryContainer
                                                    .withOpacity(0.7),
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: colorTheme.primary,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                'v$_latestVersion',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: colorTheme.onPrimary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (_isUpdateAvailable &&
                                      (_apkDownloadUrl != null ||
                                          _exeDownloadUrl != null))
                                    Builder(
                                      builder: (context) {
                                        final section = _buildDownloadSection(
                                          colorTheme,
                                        );
                                        if (section == null) {
                                          return const SizedBox.shrink();
                                        }
                                        return section;
                                      },
                                    ),
                                ],
                              ),
                            ),
                            // Release notes
                            if (_releaseNotes != null &&
                                _releaseNotes!.isNotEmpty) ...[
                              const SizedBox(height: 32),
                              Row(
                                children: [
                                  Icon(
                                    Symbols.description_rounded,
                                    size: 20,
                                    color: colorTheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Release Notes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: colorTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: colorTheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: colorTheme.outlineVariant
                                        .withOpacity(0.4),
                                  ),
                                ),
                                child: SelectableText(
                                  _releaseNotes!,
                                  style: TextStyle(
                                    color: colorTheme.onSurface,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 25),
                            ],
                          ],
                        ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomButtonGroup() ?? const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
