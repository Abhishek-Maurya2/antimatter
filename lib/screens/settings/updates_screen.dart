import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:package_info_plus/package_info_plus.dart';

const String _githubOwner = 'Abhishek-Maurya2';
const String _githubRepo = 'antimatter';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  bool _isLoading = true;
  String? _latestVersion;
  String? _releaseNotes;
  String? _downloadUrl;
  String? _error;

  // Download state
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _downloadError;
  String? _downloadedFilePath;
  String _currentVersion = '';

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
        final assets = data['assets'] as List<dynamic>? ?? [];
        for (final asset in assets) {
          final name = asset['name'] as String? ?? '';
          if (name.endsWith('.apk')) {
            apkUrl = asset['browser_download_url'] as String?;
            break;
          }
        }

        setState(() {
          _latestVersion = versionOnly;
          _releaseNotes = data['body'] as String? ?? 'No release notes.';
          _downloadUrl = apkUrl;
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
    if (_downloadUrl == null) return;

    // Request storage permission on older Android versions
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isDenied) {
        setState(() => _downloadError = 'Storage permission denied');
        return;
      }
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadError = null;
      _downloadedFilePath = null;
    });

    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/antimatter-update.apk';

      final dio = Dio();
      await dio.download(
        _downloadUrl!,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            setState(() {
              _downloadProgress = received / total;
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

  Widget _buildDownloadSection(ColorScheme colorTheme) {
    if (_isDownloading) {
      return Column(
        children: [
          SizedBox(
            width: 200,
            child: WavyLinearProgressIndicator(
              value: _downloadProgress,
              minHeight: 4.0,
              waveAmplitude: 3.0,
              waveLength: 24.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_downloadProgress * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorTheme.onPrimaryContainer,
            ),
          ),
        ],
      );
    }

    if (_downloadError != null) {
      return Column(
        children: [
          Text(
            _downloadError!,
            style: TextStyle(color: colorTheme.error, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _downloadAndInstall,
            icon: Icon(Symbols.refresh),
            label: Text('Retry Download'),
          ),
        ],
      );
    }

    if (_downloadedFilePath != null) {
      return FilledButton.icon(
        onPressed: () => OpenFilex.open(_downloadedFilePath!),
        icon: Icon(Symbols.install_mobile),
        label: Text('Install APK'),
      );
    }

    return FilledButton.icon(
      onPressed: _downloadAndInstall,
      icon: Icon(Symbols.download),
      label: Text('Download APK'),
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
      backgroundColor: colorTheme.surfaceContainer,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text('Updates'),
            titleSpacing: 0,
            leadingWidth: 80,
            leading: Center(
              child: Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  color: colorTheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Symbols.arrow_back,
                    color: colorTheme.onSurface,
                    size: 25,
                  ),
                  tooltip: 'Back',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
            backgroundColor: colorTheme.surfaceContainer,
            scrolledUnderElevation: 1,
            expandedHeight: 120,
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: WavyCircularProgressIndicator(
                              strokeWidth: 4.0,
                              waveAmplitude: 2.0,
                            ),
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
                            Symbols.cloud_off,
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
                          FilledButton.icon(
                            onPressed: _checkForUpdates,
                            icon: Icon(Symbols.refresh),
                            label: Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _latestVersion == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Symbols.info,
                            size: 64,
                            color: colorTheme.onSurfaceVariant.withOpacity(0.3),
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
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _isUpdateAvailable
                                ? colorTheme.primaryContainer
                                : colorTheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _isUpdateAvailable
                                    ? Symbols.system_update
                                    : Symbols.check_circle,
                                size: 56,
                                fill: 1,
                                color: _isUpdateAvailable
                                    ? colorTheme.onPrimaryContainer
                                    : colorTheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _isUpdateAvailable
                                    ? 'Update Available!'
                                    : 'You\'re up to date',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'RobotoFlex',
                                  color: _isUpdateAvailable
                                      ? colorTheme.onPrimaryContainer
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Current: v$_currentVersion',
                                style: TextStyle(
                                  color: _isUpdateAvailable
                                      ? colorTheme.onPrimaryContainer
                                            .withOpacity(0.7)
                                      : colorTheme.onSurfaceVariant,
                                ),
                              ),
                              if (_isUpdateAvailable) ...[
                                Text(
                                  'Latest: v$_latestVersion',
                                  style: TextStyle(
                                    color: colorTheme.onPrimaryContainer
                                        .withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                if (_downloadUrl != null)
                                  _buildDownloadSection(colorTheme),
                              ],
                            ],
                          ),
                        ),
                        // Release notes
                        if (_releaseNotes != null &&
                            _releaseNotes!.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Release Notes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colorTheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorTheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _releaseNotes!,
                              style: TextStyle(
                                color: colorTheme.onSurface,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        // Check again button
                        OutlinedButton.icon(
                          onPressed: _checkForUpdates,
                          icon: Icon(Symbols.refresh),
                          label: Text('Check again'),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
