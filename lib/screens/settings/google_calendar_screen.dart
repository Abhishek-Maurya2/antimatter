import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:settings_tiles/settings_tiles.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/task.dart';
import '../../utils/preferences_helper.dart';
import '../../services/google_calendar_service.dart';
import '../../widgets/settings_app_bar.dart';
import '../settings_screen.dart';

class GoogleCalendarScreen extends StatefulWidget {
  final bool isEmbedded;
  const GoogleCalendarScreen({super.key, this.isEmbedded = false});

  @override
  State<GoogleCalendarScreen> createState() => _GoogleCalendarScreenState();
}

class _GoogleCalendarScreenState extends State<GoogleCalendarScreen> {
  final _googleCalendarService = GoogleCalendarService();
  final _clientIdController = TextEditingController();
  final _clientSecretController = TextEditingController();

  bool _isConnecting = false;
  bool _syncCompleted = true;
  String? _connectedEmail;
  bool _isLoadingEmail = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _clientIdController.dispose();
    _clientSecretController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    _clientIdController.text = PreferencesHelper.getString('google_calendar_client_id') ?? '';
    _clientSecretController.text = PreferencesHelper.getString('google_calendar_client_secret') ?? '';
    _syncCompleted = PreferencesHelper.getBool('gcal_sync_completed') ?? true;

    if (_googleCalendarService.isConnected) {
      setState(() => _isLoadingEmail = true);
      final email = await _googleCalendarService.getConnectedEmail();
      if (mounted) {
        setState(() {
          _connectedEmail = email;
          _isLoadingEmail = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _connectCalendar() async {
    final clientId = _clientIdController.text.trim();
    final clientSecret = _clientSecretController.text.trim();

    if (clientId.isEmpty) {
      _showSnackBar('Please enter your Google OAuth Client ID');
      return;
    }

    setState(() {
      _isConnecting = true;
    });

    String? authUrl;

    // Show custom dialog that informs the user to check their browser
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            const Text('Awaiting Consent'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A Google Sign-In page is opening in your default web browser.\n\n'
              'Please complete the sign-in flow there and grant permissions to access your calendar.',
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ButtonM3E(
                  onPressed: () {
                    if (authUrl != null) {
                      Clipboard.setData(ClipboardData(text: authUrl!));
                      _showSnackBar('Link copied to clipboard!');
                    }
                  },
                  style: ButtonM3EStyle.text,
                  label: const Text('Copy Link'),
                ),
                const SizedBox(width: 8),
                ButtonM3E(
                  onPressed: () {
                    // Close the browser / server by signing out
                    _googleCalendarService.signOut();
                    Navigator.of(dialogCtx).pop();
                    if (mounted) {
                      setState(() {
                        _isConnecting = false;
                      });
                    }
                  },
                  style: ButtonM3EStyle.text,
                  foregroundColor: Theme.of(context).colorScheme.error,
                  label: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    try {
      await _googleCalendarService.signIn(
        clientIdStr: clientId,
        clientSecretStr: clientSecret,
        onUrlReady: (url) async {
          authUrl = url;
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            _showSnackBar('Could not launch browser. Click Copy Link below.');
          }
        },
      );

      // If sign-in succeeds, the dialog should be popped
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss consent dialog
      }

      _showSnackBar('Google Calendar connected successfully!');
      await _loadSettings();

      // Trigger initial sync automatically to push existing tasks
      final tasksBox = Hive.box<Task>('tasksBox');
      await _googleCalendarService.initialSync(tasksBox);
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss consent dialog
      }
      _showSnackBar('Connection failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  Future<void> _disconnectCalendar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect Calendar?'),
        content: const Text(
          'Are you sure you want to disconnect Google Calendar? '
          'Task deadlines will no longer be synced, and local credentials will be cleared.',
        ),
        actions: [
          ButtonM3E(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: ButtonM3EStyle.text,
            label: const Text('Cancel'),
          ),
          ButtonM3E(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ButtonM3EStyle.filled,
            backgroundColor: Theme.of(ctx).colorScheme.error,
            foregroundColor: Theme.of(ctx).colorScheme.onError,
            label: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _googleCalendarService.signOut();
      setState(() {
        _connectedEmail = null;
      });
      _showSnackBar('Google Calendar disconnected.');
    }
  }

  Future<void> _triggerManualSync() async {
    setState(() => _isLoadingEmail = true);
    try {
      final tasksBox = Hive.box<Task>('tasksBox');
      await _googleCalendarService.initialSync(tasksBox);
      _showSnackBar('Google Calendar synchronization completed!');
    } catch (e) {
      _showSnackBar('Sync failed: $e');
    } finally {
      setState(() => _isLoadingEmail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final isConnected = _googleCalendarService.isConnected;

    return Scaffold(
      backgroundColor: widget.isEmbedded ? colorTheme.surfaceContainerLow : colorTheme.surfaceContainer,
      body: CustomScrollView(
        slivers: [
          SettingsAppBar(title: 'Google Calendar', isEmbedded: widget.isEmbedded),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  if (isConnected) _buildConnectedUI(colorTheme, isLight) else _buildDisconnectedUI(colorTheme, isLight),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedUI(ColorScheme colorTheme, bool isLight) {
    return Column(
      children: [
        SettingSection(
          styleTile: true,
          title: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 16),
            child: Text(
              'Status',
              style: TextStyle(
                color: colorTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          tiles: [
            SettingActionTile(
              icon: iconContainer(
                Symbols.cloud_done,
                isLight ? const Color(0xffc2ebd3) : const Color(0xff2d4d3a),
                isLight ? const Color(0xff2d4d3a) : const Color(0xffc2ebd3),
              ),
              title: const Text('Connected'),
              description: Text(_isLoadingEmail ? 'Loading account...' : (_connectedEmail ?? 'Successfully authenticated')),
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 16),
        SettingSection(
          styleTile: true,
          title: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 16),
            child: Text(
              'Sync Options',
              style: TextStyle(
                color: colorTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          tiles: [
            SettingSwitchTile(
              icon: iconContainer(
                Symbols.task_alt,
                isLight ? const Color(0xffe6deff) : const Color(0xff493e76),
                isLight ? const Color(0xff493e76) : const Color(0xffe6deff),
              ),
              title: const Text('Sync Completed Tasks'),
              description: const Text('Prepend completed tasks with ✓ on Google Calendar'),
              toggled: _syncCompleted,
              onChanged: (value) async {
                setState(() => _syncCompleted = value);
                await PreferencesHelper.setBool('gcal_sync_completed', value);
                // Trigger an initial sync to update existing completed tasks representation
                final tasksBox = Hive.box<Task>('tasksBox');
                await _googleCalendarService.initialSync(tasksBox);
              },
            ),
            SettingActionTile(
              icon: iconContainer(
                Symbols.sync,
                isLight ? const Color(0xffd6e3ff) : const Color(0xff284777),
                isLight ? const Color(0xff284777) : const Color(0xffd6e3ff),
              ),
              title: const Text('Sync Existing Tasks Now'),
              description: const Text('Push all tasks with deadlines to Google Calendar'),
              onTap: _isLoadingEmail ? () {} : () { _triggerManualSync(); },
            ),
          ],
        ),
        const SizedBox(height: 16),
        SettingSection(
          styleTile: true,
          title: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 16),
            child: Text(
              'Disconnect',
              style: TextStyle(
                color: colorTheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          tiles: [
            SettingActionTile(
              icon: iconContainer(
                Symbols.logout,
                isLight ? const Color(0xffffdbd1) : const Color(0xff723523),
                isLight ? const Color(0xff723523) : const Color(0xffffdbd1),
              ),
              title: Text(
                'Disconnect Google Account',
                style: TextStyle(color: colorTheme.error),
              ),
              description: const Text('Revoke calendar sync permissions'),
              onTap: _disconnectCalendar,
            ),
          ],
        ),
        const SizedBox(height: 200),
      ],
    );
  }

  Widget _buildDisconnectedUI(ColorScheme colorTheme, bool isLight) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Elegant info card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorTheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Symbols.info, color: colorTheme.primary, fill: 1),
                    const SizedBox(width: 8),
                    Text(
                      'Google Workspace Sync Setup',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: colorTheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'AntiMatter syncs deadlines directly with Google Calendar. Because this is a desktop client, you must configure your own OAuth credentials to establish a private, direct link to your Google account.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Step-by-step Setup Guide:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                _buildGuideStep('1. Go to Google Cloud Console (console.cloud.google.com).'),
                _buildGuideStep('2. Create a new project, search for "Google Calendar API", and click Enable.'),
                _buildGuideStep('3. Configure the OAuth Consent Screen (Internal for Workspace or External for personal accounts).'),
                _buildGuideStep('4. Add the scope: ".../auth/calendar.events".'),
                _buildGuideStep('5. Go to Credentials -> Create Credentials -> OAuth client ID.'),
                _buildGuideStep('6. Choose Application Type: Desktop app.'),
                _buildGuideStep('7. Copy the Client ID and Client Secret, paste them below, and click Connect!'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Credentials Fields
          Text(
            'OAuth Client Credentials',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorTheme.primary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _clientIdController,
            style: TextStyle(color: colorTheme.onSurface, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Client ID',
              hintText: 'Enter OAuth Client ID',
              filled: true,
              fillColor: colorTheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colorTheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colorTheme.primary, width: 2),
              ),
              prefixIcon: const Icon(Symbols.key),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _clientSecretController,
            style: TextStyle(color: colorTheme.onSurface, fontSize: 14),
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Client Secret (Optional)',
              hintText: 'Enter OAuth Client Secret',
              filled: true,
              fillColor: colorTheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colorTheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colorTheme.primary, width: 2),
              ),
              prefixIcon: const Icon(Symbols.password),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ButtonM3E(
              onPressed: _isConnecting ? null : _connectCalendar,
              style: ButtonM3EStyle.filled,
              size: ButtonM3ESize.lg,
              shape: ButtonM3EShape.round,
              label: _isConnecting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Connect Google Calendar'),
            ),
          ),
          const SizedBox(height: 200),
        ],
      ),
    );
  }

  Widget _buildGuideStep(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, left: 4.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, height: 1.3),
      ),
    );
  }
}
