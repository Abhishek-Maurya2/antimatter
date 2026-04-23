import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class SettingsAppBar extends StatelessWidget {
  final String title;
  final bool isEmbedded;
  final PreferredSizeWidget? bottom;
  final double expandedHeight;
  final bool pinned;

  const SettingsAppBar({
    super.key,
    required this.title,
    this.isEmbedded = false,
    this.bottom,
    this.expandedHeight = 120,
    this.pinned = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;

    return SliverAppBar.large(
      title: Text(title),
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
      expandedHeight: 150,
    );
  }
}
