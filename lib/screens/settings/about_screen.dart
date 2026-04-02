import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
                          icon: const Icon(
                            Symbols.arrow_back_rounded,
                            weight: 800,
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
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                  child: Column(
                    children: [
                      // --- Hero / Branding ---
                      _buildHeroSection(colorTheme),
                      const SizedBox(height: 48),

                      // --- Built With ---
                      _buildBuiltWithSection(colorTheme),
                      const SizedBox(height: 40),

                      // --- Made with ❤ ---
                      _buildCreditSection(colorTheme),
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

  // ─── Hero Section ─────────────────────────────────────────────

  Widget _buildHeroSection(ColorScheme colorTheme) {
    return Column(
      children: [
        // Expressive app icon
        SizedBox(
          width: 160,
          height: 160,
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
              child: Center(
                child: Icon(
                  Symbols.task_alt_rounded,
                  weight: 800,
                  fill: 1,
                  size: 72,
                  color: colorTheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Gradient app name
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [colorTheme.primary, colorTheme.tertiary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: const Text(
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
        ),
        const SizedBox(height: 12),

        // Version badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: ShapeDecoration(
            color: colorTheme.primaryContainer,
            shape: const StadiumBorder(),
          ),
          child: Text(
            'VERSION $_appVersion',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colorTheme.onPrimaryContainer,
              fontSize: 11,
              letterSpacing: 1.0,
              fontFamily: 'GoogleSansFlex',
              fontVariations: const [FontVariation('wght', 700)],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Tagline
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'A beautiful task manager built with Material 3 Expressive design language. '
            'Stay organized, track your progress, and achieve your goals with style.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorTheme.onSurfaceVariant,
              fontSize: 15,
              height: 1.6,
              letterSpacing: 0.2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Built With Section ───────────────────────────────────────

  Widget _buildBuiltWithSection(ColorScheme colorTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Symbols.code_rounded,
              weight: 800,
              size: 20,
              fill: 1,
              color: colorTheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'BUILT WITH',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: colorTheme.primary,
                fontFamily: 'GoogleSansFlex',
                fontVariations: const [FontVariation('wght', 700)],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final fullWidth = constraints.maxWidth;
            final halfWidth = (fullWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _techCard(
                  context,
                  icon: Symbols.code,
                  title: 'Flutter',
                  subtitle: 'Cross-platform',
                  shape: MaterialShapes.softBurst,
                  width: halfWidth,
                ),
                _techCard(
                  context,
                  icon: Symbols.palette,
                  title: 'Material 3',
                  subtitle: 'Expressive UI',
                  shape: MaterialShapes.sunny,
                  width: halfWidth,
                ),
                _techCard(
                  context,
                  icon: Symbols.cloud_sync,
                  title: 'Supabase',
                  subtitle: 'Realtime Backend & Sync',
                  shape: MaterialShapes.gem,
                  width: fullWidth,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _techCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required RoundedPolygon shape,
    required double width,
  }) {
    final colorTheme = Theme.of(context).colorScheme;
    final isFullWidth = width > 200;

    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorTheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: isFullWidth
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipPath(
            clipper: PolygonClipper(shape),
            child: Container(
              width: 56,
              height: 56,
              color: colorTheme.primaryContainer,
              child: Icon(
                icon,
                fill: 1,
                size: 28,
                color: colorTheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'GoogleSansFlex',
              fontVariations: [FontVariation('wght', 800)],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: isFullWidth ? TextAlign.start : TextAlign.center,
            style: TextStyle(
              color: colorTheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Credit Section ───────────────────────────────────────────

  Widget _buildCreditSection(ColorScheme colorTheme) {
    return Column(
      children: [
        Text(
          'Crafted with ❤ by',
          style: TextStyle(
            color: colorTheme.onSurfaceVariant,
            fontSize: 13,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Abhishek Maurya',
          style: TextStyle(
            color: colorTheme.primary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            fontFamily: 'GoogleSansFlex',
            fontVariations: const [FontVariation('wght', 700)],
          ),
        ),
      ],
    );
  }

  // ─── Bottom Buttons ───────────────────────────────────────────

  Widget _buildBottomButtonGroup() {
    final colorTheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 24),
      child: SafeArea(
        child: ButtonGroupM3E(
          type: ButtonGroupM3EType.standard,
          size: ButtonGroupM3ESize.lg,
          style: ButtonM3EStyle.filled,
          expanded: true,
          linearMainAxisAlignment: MainAxisAlignment.center,
          actions: [
            ButtonGroupM3EAction(
              icon: Icon(Symbols.description_rounded, weight: 800),
              label: Text('Licenses'),
              shape: ButtonM3EShape.round,
              onPressed: () {
                showLicensePage(
                  context: context,
                  applicationName: 'AntiMatter',
                  applicationVersion: _appVersion,
                  applicationIcon: Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Symbols.task_alt_rounded,
                        weight: 800,
                        fill: 1,
                        color: colorTheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                );
              },
            ),
            ButtonGroupM3EAction(
              icon: const Icon(Symbols.open_in_new_rounded, weight: 800),
              width: 100,
              style: ButtonM3EStyle.tonal,
              shape: ButtonM3EShape.round,
              contentPadding: EdgeInsets.zero,
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
}
