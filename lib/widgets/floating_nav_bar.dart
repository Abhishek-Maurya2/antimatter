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

  static const _items = [
    FloatingNavItem(
      icon: Symbols.dashboard,
      selectedIcon: Symbols.dashboard,
      label: 'Overview',
    ),
    FloatingNavItem(
      icon: Symbols.task_alt,
      selectedIcon: Symbols.task_alt,
      label: 'Tasks',
    ),
    FloatingNavItem(
      icon: Symbols.timer,
      selectedIcon: Symbols.timer,
      label: 'Session',
    ),
    FloatingNavItem(
      icon: Symbols.settings,
      selectedIcon: Symbols.settings,
      label: 'Settings',
    ),
  ];

  const FloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding + 16, left: 24, right: 24),
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
              spacing: 4,
              children: List.generate(_items.length, (index) {
                return _NavBarItem(
                  item: _items[index],
                  isSelected: selectedIndex == index,
                  onTap: () => onItemSelected(index),
                  colorTheme: colorTheme,
                );
              }),
            ),
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? item.selectedIcon : item.icon,
                key: ValueKey(isSelected),
                fill: isSelected ? 1 : 0,
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
                        padding: const EdgeInsets.only(left: 8),
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
