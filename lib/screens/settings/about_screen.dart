import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// TODO: Replace with your actual GitHub repo URL
const String _githubUrl = 'https://github.com/Abhishek-Maurya2/antimatter';
const String _appVersion = '1.4.0';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorTheme.surfaceContainer,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text('About'),
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // App Icon & Name
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colorTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Symbols.task_alt,
                      fill: 1,
                      size: 44,
                      color: colorTheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'AntiMatter',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'RobotoFlex',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version $_appVersion',
                    style: TextStyle(
                      color: colorTheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'A beautiful task manager built with Material 3 Expressive design language. '
                    'Stay organized, track your progress, and achieve your goals with style.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorTheme.onSurfaceVariant,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Info Cards
                  _infoCard(
                    context,
                    icon: Symbols.code,
                    title: 'Built with Flutter',
                    subtitle: 'Cross-platform, native performance',
                  ),
                  const SizedBox(height: 8),
                  _infoCard(
                    context,
                    icon: Symbols.palette,
                    title: 'Material 3 Expressive',
                    subtitle: 'Dynamic color, modern design tokens',
                  ),
                  const SizedBox(height: 8),
                  _infoCard(
                    context,
                    icon: Symbols.cloud_sync,
                    title: 'Cloud Sync',
                    subtitle: 'Powered by Supabase',
                  ),

                  const SizedBox(height: 32),

                  // Action buttons
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
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
                      icon: Icon(Symbols.description),
                      label: Text('Open Source Licenses'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(_githubUrl);
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      icon: Icon(Symbols.open_in_new),
                      label: Text('View on GitHub'),
                    ),
                  ),
                  const SizedBox(height: 200),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final colorTheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorTheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorTheme.primaryContainer,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Icon(
            icon,
            fill: 1,
            size: 20,
            color: colorTheme.onPrimaryContainer,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
