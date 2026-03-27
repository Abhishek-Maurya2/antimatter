import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class FloatingNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const FloatingNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final IconData? pageActionIcon;
  final String? pageActionTooltip;
  final VoidCallback? onPageActionTap;

  static const _items = [
    FloatingNavItem(
      icon: Symbols.dashboard_rounded,
      selectedIcon: Symbols.dashboard_rounded,
      label: 'Overview',
    ),
    FloatingNavItem(
      icon: Symbols.task_alt_rounded,
      selectedIcon: Symbols.task_alt_rounded,
      label: 'Tasks',
    ),
    FloatingNavItem(
      icon: Symbols.timer_rounded,
      selectedIcon: Symbols.timer_rounded,
      label: 'Session',
    ),
    FloatingNavItem(
      icon: Symbols.settings_rounded,
      selectedIcon: Symbols.settings_rounded,
      label: 'Settings',
    ),
  ];

  const FloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.pageActionIcon,
    this.pageActionTooltip,
    this.onPageActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding, left: 24, right: 24),
      child: Center(
        child: Material(
          elevation: 3,
          shadowColor: colorTheme.shadow.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(50),
          color: colorTheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children:
                  List.generate(_items.length, (index) {
                    return _NavBarItem(
                      item: _items[index],
                      isSelected: selectedIndex == index,
                      onTap: () => onItemSelected(index),
                      colorTheme: colorTheme,
                    );
                  })..addAll([
                    if (onPageActionTap != null && pageActionIcon != null) ...[
                      _PageActionButton(
                        icon: pageActionIcon!,
                        tooltip: pageActionTooltip,
                        onTap: onPageActionTap!,
                        colorTheme: colorTheme,
                      ),
                    ],
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageActionButton extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback onTap;
  final ColorScheme colorTheme;

  const _PageActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.colorTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        decoration: BoxDecoration(
          color: colorTheme.primary,
          borderRadius: BorderRadius.circular(50),
        ),
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, size: 28, weight: 800, color: colorTheme.onPrimary),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final FloatingNavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorTheme;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.colorTheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? colorTheme.surfaceContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? item.selectedIcon : item.icon,
                key: ValueKey(isSelected),
                fill: isSelected ? 1 : 0,
                weight: isSelected ? 900 : 950,
                size: 24,
                color: isSelected
                    ? colorTheme.onSurface
                    : colorTheme.onPrimaryContainer,
              ),
            ),
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: isSelected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          item.label,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: colorTheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1,
                          softWrap: false,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
