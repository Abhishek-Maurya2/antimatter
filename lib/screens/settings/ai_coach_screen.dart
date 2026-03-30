import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:settings_tiles/settings_tiles.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../settings_screen.dart';
import 'blacklist_screen.dart';

class AiCoachScreen extends ConsumerWidget {
  final bool isEmbedded;
  const AiCoachScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorTheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final settingsState = ref.watch(settingsControllerProvider);
    final settingsNotifier = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: isEmbedded
          ? colorTheme.surfaceContainerLow
          : colorTheme.surfaceContainer,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text('AI Productivity Coach'),
            titleSpacing: isEmbedded ? 16 : 0,
            leadingWidth: isEmbedded ? 0 : 80,
            automaticallyImplyLeading: !isEmbedded,
            leading: isEmbedded
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
            backgroundColor: isEmbedded
                ? colorTheme.surfaceContainerLow
                : colorTheme.surfaceContainer,
            scrolledUnderElevation: 1,
            expandedHeight: 120,
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                SettingSection(
                  styleTile: true,
                  title: Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 8,
                      top: 16,
                    ),
                    child: Text(
                      'AI Coach Configuration',
                      style: TextStyle(
                        color: colorTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  tiles: [
                    SettingSwitchTile(
                      icon: iconContainer(
                        Symbols.smart_toy,
                        isLight ? Color(0xffd6e2ff) : Color(0xff004a77),
                        isLight ? Color(0xff004a77) : Color(0xffd6e2ff),
                      ),
                      title: Text('Enable Ruthless AI Coach'),
                      description: Text('Receive aggressive motivation & reality checks'),
                      toggled: settingsState.enableAiCoach,
                      onChanged: (value) {
                        settingsNotifier.setEnableAiCoach(value);
                      },
                    ),
                    SettingActionTile(
                      icon: iconContainer(
                        Symbols.key,
                        isLight ? Color(0xffffd6f9) : Color(0xff633664),
                        isLight ? Color(0xff633664) : Color(0xffffd6f9),
                      ),
                      title: Text('Groq API Key'),
                      description: Text(settingsState.groqApiKey.isEmpty ? 'Not configred' : 'Configured (Tap to edit)'),
                      onTap: () async {
                        final controller = TextEditingController(text: settingsState.groqApiKey);
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Enter Groq API Key'),
                            content: TextField(
                              controller: controller,
                              decoration: const InputDecoration(
                                hintText: 'gsk_...',
                              ),
                              obscureText: true,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  settingsNotifier.setGroqApiKey(controller.text);
                                  Navigator.pop(context);
                                },
                                child: const Text('Save'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SettingSection(
                  styleTile: true,
                  title: Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 8,
                      top: 16,
                    ),
                    child: Text(
                      'App Blocker',
                      style: TextStyle(
                        color: colorTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  tiles: [
                    SettingActionTile(
                      icon: iconContainer(
                        Symbols.block,
                        isLight ? Color(0xffffd9d1) : Color(0xff8c1d00),
                        isLight ? Color(0xff8c1d00) : Color(0xffffd9d1),
                      ),
                      title: Text('Manage Blacklist'),
                      description: Text('${settingsState.blockedApps.length} apps currently blacklisted'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BlacklistScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
