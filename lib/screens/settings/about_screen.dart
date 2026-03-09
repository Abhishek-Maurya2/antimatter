import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:button_m3e/button_m3e.dart';
import 'package:button_group_m3e/button_group_m3e.dart';

const String _githubUrl = 'https://github.com/Abhishek-Maurya2/antimatter';

class AboutScreen extends StatefulWidget {
  final bool isEmbedded;
  const AboutScreen({super.key, this.isEmbedded = false});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = info.version.isNotEmpty ? info.version : '1.4.0';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: widget.isEmbedded
          ? Colors.transparent
          : colorTheme.surfaceContainer,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('About'),
            titleSpacing: widget.isEmbedded ? 16 : 0,
            leadingWidth: widget.isEmbedded ? 0 : 80,
            automaticallyImplyLeading: !widget.isEmbedded,
            leading: widget.isEmbedded
                ? null
                : Center(
                    child: IconButtonM3E(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Symbols.arrow_back),
                      tooltip: 'Back',
                      variant: IconButtonM3EVariant.tonal,
                      width: IconButtonM3EWidth.wide,
                    ),
                  ),
            backgroundColor: widget.isEmbedded
                ? Colors.transparent
                : colorTheme.surfaceContainer,
            scrolledUnderElevation: 1,
            expandedHeight: 120,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // App Icon & Name
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: colorTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Icon(
                      Symbols.task_alt,
                      fill: 1,
                      size: 56,
                      color: colorTheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'AntiMatter',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'RobotoFlex',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorTheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'v$_appVersion',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorTheme.onSurface,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'A beautiful task manager built with Material 3 Expressive design language. '
                    'Stay organized, track your progress, and achieve your goals with style.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorTheme.onSurfaceVariant,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Info Cards Group
                  Column(
                    children: [
                      _infoTile(
                        context,
                        icon: Symbols.code,
                        title: 'Built with Flutter',
                        subtitle: 'Cross-platform, native performance',
                      ),
                      const SizedBox(height: 12),
                      _infoTile(
                        context,
                        icon: Symbols.palette,
                        title: 'Material 3 Expressive',
                        subtitle: 'Dynamic color, modern design tokens',
                      ),
                      const SizedBox(height: 12),
                      _infoTile(
                        context,
                        icon: Symbols.cloud_sync,
                        title: 'Cloud Sync',
                        subtitle: 'Powered by Supabase',
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // Action buttons
                  ButtonGroupM3E(
                    type: ButtonGroupM3EType.standard,
                    direction: Axis.vertical,
                    size: ButtonGroupM3ESize.lg,
                    style: ButtonM3EStyle.filled,
                    expanded: true,
                    equalizeWidths: true,
                    spacing: 0,
                    actions: [
                      ButtonGroupM3EAction(
                        icon: const Icon(Symbols.description),
                        label: const Text('Licenses'),
                        shape: ButtonM3EShape.round,
                        onPressed: () {
                          showLicensePage(
                            context: context,
                            applicationName: 'AntiMatter',
                            applicationVersion: _appVersion,
                            applicationIcon: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: colorTheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Symbols.task_alt,
                                  fill: 1,
                                  color: colorTheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      ButtonGroupM3EAction(
                        icon: const Icon(Symbols.open_in_new),
                        label: const Text('GitHub'),
                        style: ButtonM3EStyle.tonal,
                        shape: ButtonM3EShape.round,
                        onPressed: () async {
                          final uri = Uri.parse(_githubUrl);
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final colorTheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorTheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorTheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              fill: 1,
              size: 24,
              color: colorTheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colorTheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
