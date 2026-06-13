import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Session;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../models/session.dart';
import '../../widgets/settings_app_bar.dart';
import '../../main.dart'; // import syncService & sessionSyncService
import '../../utils/m3_motion.dart';
import '../../utils/preferences_helper.dart';
import '../../utils/ui_utils.dart';
import '../login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isEmbedded;
  const ProfileScreen({super.key, this.isEmbedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isManualSyncing = false;

  Future<void> _handleSync() async {
    setState(() {
      _isManualSyncing = true;
    });
    try {
      await syncService.uploadLocalData();
      await sessionSyncService.uploadLocalData();
      await syncService.pullTasks();
      await sessionSyncService.pullSessions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Data synchronised with cloud!'),
            behavior: SnackBarBehavior.floating,
            width: 320,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            behavior: SnackBarBehavior.floating,
            width: 320,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isManualSyncing = false;
        });
      }
    }
  }

  Future<void> _connectGoogleAccount() async {
    setState(() {
      _isManualSyncing = true;
    });
    try {
      final redirectUrl = kIsWeb 
          ? 'http://localhost:3000' 
          : 'antimatter://login-callback';
              
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
        scopes: 'https://www.googleapis.com/auth/calendar',
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isManualSyncing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: $e'),
            behavior: SnackBarBehavior.floating,
            width: 320,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    final colorTheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text(
          'Are you sure you want to sign out? '
          'Your local tasks and sessions will be cleared from this device, and you will be routed back to the login screen.',
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
            backgroundColor: colorTheme.error,
            foregroundColor: colorTheme.onError,
            label: const Text('Sign Out'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        _isManualSyncing = true;
      });
      try {
        await Supabase.instance.client.auth.signOut();
        await PreferencesHelper.remove('offline_mode');
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            M3Motion.sharedAxisRoute(const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sign out failed: $e'),
              behavior: SnackBarBehavior.floating,
              width: 320,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isManualSyncing = false;
          });
        }
      }
    }
  }

  Future<void> _resetAllDataAndAccount() async {
    final colorTheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Account & Data?'),
        content: const Text(
          'This will permanently delete all your tasks and sessions from BOTH the cloud and this device. '
          'This action is irreversible. Are you absolutely sure you want to proceed?',
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
            backgroundColor: colorTheme.error,
            foregroundColor: colorTheme.onError,
            label: const Text('Reset & Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isManualSyncing = true;
      });
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          // Delete remote tasks and sessions (if table exists)
          await Supabase.instance.client.from('tasks').delete().eq('user_id', user.id);
          try {
            await Supabase.instance.client.from('sessions').delete().eq('user_id', user.id);
          } catch (_) {}
        }
        
        // Clear local Hive data
        await syncService.clearLocalData();
        await sessionSyncService.clearLocalData();
        
        // Sign out
        await Supabase.instance.client.auth.signOut();
        await PreferencesHelper.remove('offline_mode');
        
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            M3Motion.sharedAxisRoute(const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reset account data: $e'),
              behavior: SnackBarBehavior.floating,
              width: 320,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isManualSyncing = false;
          });
        }
      }
    }
  }

  Future<void> _clearLocalData() async {
    final colorTheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Local Data?'),
        content: const Text(
          'This will permanently delete all your local tasks and sessions from this device. '
          'This action cannot be undone. Are you sure?',
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
            backgroundColor: colorTheme.error,
            foregroundColor: colorTheme.onError,
            label: const Text('Delete Local Data'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Hive.box<Task>('tasksBox').clear();
      await Hive.box<Session>('sessionsBox').clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Local database cleared!'),
            behavior: SnackBarBehavior.floating,
            width: 320,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;
    final user = Supabase.instance.client.auth.currentUser;
    final isOnline = user != null;

    return Scaffold(
      backgroundColor: widget.isEmbedded
          ? colorTheme.surfaceContainerLow
          : colorTheme.surfaceContainer,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SettingsAppBar(title: 'Profile', isEmbedded: widget.isEmbedded),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    children: [
                      // --- Header / Avatar ---
                      _buildHeaderSection(context, user, isOnline),
                      const SizedBox(height: 32),

                      // --- Productivity Statistics Grid ---
                      _buildStatisticsSection(context),
                      const SizedBox(height: 24),

                      // --- Sync Status & Actions ---
                      _buildSyncCard(context, user, isOnline),
                      const SizedBox(height: 24),

                      // --- Account Details Card ---
                      _buildAccountDetailsCard(context, user, isOnline),
                      const SizedBox(height: 24),

                      // --- Danger Zone ---
                      _buildDangerZone(context, isOnline),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isManualSyncing)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: LoadingIndicatorM3E(variant: LoadingIndicatorM3EVariant.contained),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Header & Avatar Section ───────────────────────────────────
  Widget _buildHeaderSection(BuildContext context, User? user, bool isOnline) {
    final colorTheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget avatarWidget;
    if (isOnline && user?.userMetadata?['avatar_url'] != null) {
      avatarWidget = Image.network(
        user!.userMetadata!['avatar_url'] as String,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          Symbols.account_circle,
          size: 72,
          color: colorTheme.onPrimaryContainer,
        ),
      );
    } else {
      avatarWidget = Icon(
        Symbols.account_circle,
        size: 72,
        color: colorTheme.onPrimaryContainer,
      );
    }

    return Column(
      children: [
        Center(
          child: SizedBox(
            width: 140,
            height: 140,
            child: ClipPath(
              clipper: PolygonClipper(MaterialShapes.sunny),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorTheme.primary, colorTheme.tertiary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(4),
                child: ClipPath(
                  clipper: PolygonClipper(MaterialShapes.sunny),
                  child: Container(
                    color: colorTheme.primaryContainer,
                    child: Center(
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child: ClipPath(
                          clipper: PolygonClipper(MaterialShapes.sunny),
                          child: avatarWidget,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          isOnline
              ? (user?.userMetadata?['full_name'] as String? ?? 'User Profile')
              : 'Local User',
          style: textTheme.headlineSmall?.copyWith(
            fontFamily: 'GoogleSansFlex',
            letterSpacing: -0.5,
            fontWeight: FontWeight.w800,
            color: colorTheme.onSurface,
            fontVariations: const [FontVariation('wght', 800)],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isOnline ? (user?.email ?? '') : 'Offline Mode Enabled',
          style: textTheme.bodyMedium?.copyWith(
            color: colorTheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: ShapeDecoration(
            color: isOnline ? colorTheme.primaryContainer : colorTheme.tertiaryContainer,
            shape: const StadiumBorder(),
          ),
          child: Text(
            isOnline ? 'CLOUD SYNC CONNECTED' : 'OFFLINE STORAGE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: isOnline ? colorTheme.onPrimaryContainer : colorTheme.onTertiaryContainer,
              fontFamily: 'GoogleSansFlex',
              fontVariations: const [FontVariation('wght', 800)],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Statistics Grid ──────────────────────────────────────────
  Widget _buildStatisticsSection(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<Box<Task>>(
      valueListenable: Hive.box<Task>('tasksBox').listenable(),
      builder: (context, tasksBox, _) {
        return ValueListenableBuilder<Box<Session>>(
          valueListenable: Hive.box<Session>('sessionsBox').listenable(),
          builder: (context, sessionsBox, _) {
            // Compute active and completed tasks
            final activeCount = tasksBox.values.where((t) => !t.isCompleted && !t.isDeleted && !t.isArchived).length;
            final completedCount = tasksBox.values.where((t) => t.isCompleted && !t.isDeleted && !t.isArchived).length;
            final totalCount = activeCount + completedCount;
            final completionRate = totalCount > 0 ? (completedCount / totalCount) : 0.0;

            // Compute focus sessions and total duration
            final totalSessions = sessionsBox.values.length;
            int totalSeconds = 0;
            for (final session in sessionsBox.values) {
              totalSeconds += session.durationSeconds;
            }
            final focusHours = totalSeconds / 3600.0;

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 500;
                final childWidth = isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;

                final cards = [
                  _statCard(
                    context,
                    icon: Symbols.checklist_rounded,
                    title: 'Active Tasks',
                    value: '$activeCount',
                    color: colorTheme.primary,
                    width: childWidth,
                  ),
                  _statCard(
                    context,
                    icon: Symbols.task_alt_rounded,
                    title: 'Completed Tasks',
                    value: '$completedCount',
                    color: colorTheme.tertiary,
                    width: childWidth,
                    extraWidget: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: completionRate,
                            backgroundColor: colorTheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(colorTheme.primary),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${(completionRate * 100).toStringAsFixed(0)}% Completion rate',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: colorTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statCard(
                    context,
                    icon: Symbols.timer_rounded,
                    title: 'Sessions Focused',
                    value: '$totalSessions',
                    color: const Color(0xff4caf50),
                    width: childWidth,
                  ),
                  _statCard(
                    context,
                    icon: Symbols.schedule_rounded,
                    title: 'Focus Duration',
                    value: focusHours >= 0.1 
                        ? '${focusHours.toStringAsFixed(1)} hrs'
                        : '${(totalSeconds / 60).toStringAsFixed(0)} mins',
                    color: const Color(0xffff9800),
                    width: childWidth,
                  ),
                ];

                if (isWide) {
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: cards,
                  );
                } else {
                  return Column(
                    children: cards.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: c,
                    )).toList(),
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _statCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required double width,
    Widget? extraWidget,
  }) {
    final colorTheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorTheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorTheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                  color: colorTheme.onSurfaceVariant,
                ),
              ),
              ClipPath(
                clipper: PolygonClipper(MaterialShapes.softBurst),
                child: Container(
                  width: 38,
                  height: 38,
                  color: color.withValues(alpha: 0.12),
                  child: Icon(
                    icon,
                    fill: 1,
                    size: 20,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontFamily: 'GoogleSansFlex',
              fontWeight: FontWeight.w900,
              fontVariations: [FontVariation('wght', 900)],
            ),
          ),
          if (extraWidget != null) extraWidget,
        ],
      ),
    );
  }

  // ─── Cloud Sync Banner/Card ──────────────────────────────────────
  Widget _buildSyncCard(BuildContext context, User? user, bool isOnline) {
    final colorTheme = Theme.of(context).colorScheme;
    final lastSyncString = PreferencesHelper.getString('tasks_last_sync');
    String formattedSync = 'Never synced';
    if (lastSyncString != null) {
      try {
        final parsed = DateTime.parse(lastSyncString).toLocal();
        formattedSync = DateFormat('MMMM d, h:mm a').format(parsed);
      } catch (_) {}
    }

    if (isOnline) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorTheme.primaryContainer.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: colorTheme.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Symbols.cloud_done_rounded,
                        color: colorTheme.primary,
                        weight: 800,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Cloud Backup Sync',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colorTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your data is safely synchronised with cloud servers.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorTheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Last sync: $formattedSync',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorTheme.onSurfaceVariant.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ButtonM3E(
              onPressed: _handleSync,
              style: ButtonM3EStyle.filled,
              size: ButtonM3ESize.md,
              shape: ButtonM3EShape.round,
              label: const Text('Sync Now'),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorTheme.tertiaryContainer.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: colorTheme.tertiary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.cloud_off_rounded,
                  color: colorTheme.tertiary,
                  weight: 800,
                ),
                const SizedBox(width: 10),
                Text(
                  'Cloud Sync Inactive',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colorTheme.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Sign in to synchronize tasks and sessions across all your devices and back them up securely.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: colorTheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ButtonM3E(
                onPressed: _connectGoogleAccount,
                style: ButtonM3EStyle.filled,
                size: ButtonM3ESize.lg,
                shape: ButtonM3EShape.round,
                label: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Symbols.login_rounded),
                    const SizedBox(width: 12),
                    const Text(
                      'Sign In with Google',
                      style: TextStyle(fontWeight: FontWeight.bold),
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

  // ─── Account Details Card ──────────────────────────────────────
  Widget _buildAccountDetailsCard(BuildContext context, User? user, bool isOnline) {
    final colorTheme = Theme.of(context).colorScheme;

    String createdString = 'Unknown';
    if (isOnline && user?.createdAt != null) {
      try {
        final date = DateTime.parse(user!.createdAt).toLocal();
        createdString = DateFormat('MMMM d, yyyy').format(date);
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colorTheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorTheme.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          _detailRow(
            context,
            icon: Symbols.database_rounded,
            label: 'Storage Provider',
            value: isOnline ? 'Google Cloud & Local' : 'Local Sandbox (Device Only)',
          ),
          const Divider(height: 1, indent: 56, endIndent: 20),
          _detailRow(
            context,
            icon: Symbols.key_rounded,
            label: 'Account UID',
            value: isOnline ? (user?.id ?? 'N/A') : 'Local Sandbox User',
            onTrailingTap: isOnline 
                ? () {
                    Clipboard.setData(ClipboardData(text: user?.id ?? ''));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Account UID copied!'),
                        behavior: SnackBarBehavior.floating,
                        width: 200,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                : null,
          ),
          const Divider(height: 1, indent: 56, endIndent: 20),
          _detailRow(
            context,
            icon: Symbols.calendar_month_rounded,
            label: 'Member Since',
            value: isOnline ? createdString : 'First app setup',
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTrailingTap,
  }) {
    final colorTheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: colorTheme.onSurfaceVariant.withValues(alpha: 0.8),
            weight: 700,
            size: 20,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.1,
                    color: colorTheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorTheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          if (onTrailingTap != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Symbols.content_copy_rounded, size: 18, color: colorTheme.primary),
              onPressed: onTrailingTap,
              tooltip: 'Copy',
            ),
          ],
        ],
      ),
    );
  }

  // ─── Danger Zone Card ──────────────────────────────────────────
  Widget _buildDangerZone(BuildContext context, bool isOnline) {
    final colorTheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorTheme.errorContainer.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorTheme.error.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Symbols.warning_rounded,
                color: colorTheme.error,
                weight: 800,
              ),
              const SizedBox(width: 10),
              Text(
                'Danger Zone',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colorTheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isOnline) ...[
            SizedBox(
              width: double.infinity,
              child: ButtonM3E(
                onPressed: _signOut,
                style: ButtonM3EStyle.tonal,
                size: ButtonM3ESize.md,
                shape: ButtonM3EShape.round,
                label: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Symbols.logout_rounded, color: colorTheme.error),
                    const SizedBox(width: 8),
                    Text('Sign Out Account', style: TextStyle(color: colorTheme.error, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ButtonM3E(
                onPressed: _resetAllDataAndAccount,
                style: ButtonM3EStyle.text,
                size: ButtonM3ESize.md,
                shape: ButtonM3EShape.round,
                label: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Symbols.delete_forever_rounded, color: colorTheme.error),
                    const SizedBox(width: 8),
                    Text('Reset Cloud & Local Data', style: TextStyle(color: colorTheme.error, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ButtonM3E(
                onPressed: _clearLocalData,
                style: ButtonM3EStyle.tonal,
                size: ButtonM3ESize.md,
                shape: ButtonM3EShape.round,
                label: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Symbols.delete_forever_rounded, color: colorTheme.error),
                    const SizedBox(width: 8),
                    Text('Wipe Local Data', style: TextStyle(color: colorTheme.error, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
