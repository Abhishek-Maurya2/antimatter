import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:button_m3e/button_m3e.dart';
import 'package:button_group_m3e/button_group_m3e.dart';
import 'package:material_new_shapes/material_new_shapes.dart';
import 'package:orches/utils/ui_utils.dart';

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
          ? colorTheme.surfaceContainerLow
          : colorTheme.surfaceContainer,
      body: Stack(
        children: [
          CustomScrollView(
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
                    ? colorTheme.surfaceContainerLow
                    : colorTheme.surfaceContainer,
                scrolledUnderElevation: 1,
                expandedHeight: 120,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: ClipPath(
                          clipper: PolygonClipper(MaterialShapes.sunny),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorTheme.primary,
                                  colorTheme.primaryContainer,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Symbols.task_alt,
                                fill: 1,
                                size: 64,
                                color: colorTheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'ANTIMATTER',
                        style: TextStyle(
                          fontSize: 36,
                          fontFamily: 'GoogleSansFlex',
                          letterSpacing: -0.5,
                          fontVariations: [
                            FontVariation('wght', 800),
                            FontVariation('wdth', 100),
                            FontVariation('opsz', 36),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colorTheme.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          'VERSION $_appVersion',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: colorTheme.primary,
                            fontSize: 11,
                            letterSpacing: 1.0,
                            fontFamily: 'GoogleSansFlex',
                            fontVariations: const [FontVariation('wght', 700)],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'A beautiful task manager built with Material 3 Expressive design language. '
                          'Stay organized, track your progress, and achieve your goals with style.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colorTheme.onSurfaceVariant.withOpacity(0.8),
                            fontSize: 15,
                            height: 1.6,
                            letterSpacing: 0.2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Tech Stack Section
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'TECH STACK',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            fontFamily: 'GoogleSansFlex',
                            fontVariations: [FontVariation('wght', 700)],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _techCard(
                            context,
                            icon: Symbols.code,
                            title: 'Flutter',
                            subtitle: 'Cross-platform',
                            widthFactor: 0.48,
                          ),
                          _techCard(
                            context,
                            icon: Symbols.palette,
                            title: 'Material 3',
                            subtitle: 'Expressive UI',
                            widthFactor: 0.48,
                          ),
                          _techCard(
                            context,
                            icon: Symbols.cloud_sync,
                            title: 'Supabase',
                            subtitle: 'Realtime Backend & Sync',
                            widthFactor: 1.0,
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomButtonGroup(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtonGroup() {
    final colorTheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: SafeArea(
        child: ButtonGroupM3E(
          type: ButtonGroupM3EType.connected,
          size: ButtonGroupM3ESize.lg,
          style: ButtonM3EStyle.filled,
          expanded: true,
          linearMainAxisAlignment: MainAxisAlignment.center,
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
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _techCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required double widthFactor,
  }) {
    final colorTheme = Theme.of(context).colorScheme;
    final fullWidth = MediaQuery.of(context).size.width - 48; // Padding
    final cardWidth = (fullWidth * widthFactor) - (widthFactor < 1.0 ? 6 : 0);

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorTheme.outlineVariant.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment:
            widthFactor < 1.0 ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipPath(
            clipper: PolygonClipper(
              title.contains('Flutter')
                  ? MaterialShapes.softBurst
                  : (title.contains('Material')
                      ? MaterialShapes.sunny
                      : MaterialShapes.gem),
            ),
            child: Container(
              width: 56,
              height: 56,
              color: colorTheme.primaryContainer.withOpacity(0.5),
              child: Icon(
                icon,
                fill: 1,
                size: 24,
                color: colorTheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'GoogleSansFlex',
              fontVariations: [FontVariation('wght', 700)],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: widthFactor < 1.0 ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              color: colorTheme.onSurfaceVariant.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
