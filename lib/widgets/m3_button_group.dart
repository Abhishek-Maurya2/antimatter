import 'package:flutter/material.dart';

/// A single button item for the M3ButtonGroup.
class M3ButtonGroupItem {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  const M3ButtonGroupItem({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });
}

/// A Material 3 Extra-Large connected button group.
///
/// Renders a horizontal row of tonal buttons inside a shared pill-shaped
/// container. Buttons share inner edges (0 radius) while the first and last
/// buttons get the outer corner radius (20dp). Each button animates on press
/// with a spring scale effect, and icons/labels can be animated externally
/// using [AnimatedSwitcher].
///
/// Follows M3 extra-large button group specs:
/// - Height: 64dp
/// - Outer corner radius: 20dp
/// - Inner spacing (gap between buttons): 2dp (connected style)
/// - Button style: Tonal filled
class M3ButtonGroup extends StatelessWidget {
  final List<M3ButtonGroupItem> items;

  /// Optional: index of the "active/highlighted" button (e.g. during running state).
  final int? activeIndex;

  /// Whether the group is in an active/running state — changes the active button
  /// color from secondaryContainer to primaryContainer.
  final bool isActive;

  const M3ButtonGroup({
    super.key,
    required this.items,
    this.activeIndex,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isFirst = index == 0;
          final isLast = index == items.length - 1;
          final isActiveItem = activeIndex == index;

          return _M3GroupButton(
            item: item,
            isFirst: isFirst,
            isLast: isLast,
            isHighlighted: isActiveItem && isActive,
            colorScheme: colorScheme,
          );
        }),
      ),
    );
  }
}

class _M3GroupButton extends StatefulWidget {
  final M3ButtonGroupItem item;
  final bool isFirst;
  final bool isLast;
  final bool isHighlighted;
  final ColorScheme colorScheme;

  const _M3GroupButton({
    required this.item,
    required this.isFirst,
    required this.isLast,
    required this.isHighlighted,
    required this.colorScheme,
  });

  @override
  State<_M3GroupButton> createState() => _M3GroupButtonState();
}

class _M3GroupButtonState extends State<_M3GroupButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeOut,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.item.enabled) {
      _scaleController.forward();
    }
  }

  void _onTapUp(TapUpDetails _) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.colorScheme;

    // Determine colors
    final Color bgColor = widget.isHighlighted
        ? cs.primaryContainer
        : cs.secondaryContainer;
    final Color fgColor = widget.isHighlighted
        ? cs.onPrimaryContainer
        : cs.onSecondaryContainer;
    final Color disabledBg = cs.onSurface.withValues(alpha: 0.12);
    final Color disabledFg = cs.onSurface.withValues(alpha: 0.38);

    // Corner radii: outer edges get 18dp, inner edges get 4dp
    final borderRadius = BorderRadius.horizontal(
      left: widget.isFirst
          ? const Radius.circular(50)
          : const Radius.circular(4),
      right: widget.isLast
          ? const Radius.circular(50)
          : const Radius.circular(4),
    );

    return Padding(
      padding: EdgeInsets.only(
        left: widget.isFirst ? 2 : 1,
        right: widget.isLast ? 2 : 1,
        top: 2,
        bottom: 2,
      ),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.item.enabled ? widget.item.onPressed : null,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: widget.item.enabled ? bgColor : disabledBg,
              borderRadius: borderRadius,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 0),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    );
                  },
                  child: Icon(
                    widget.item.icon,
                    key: ValueKey(widget.item.icon),
                    color: widget.item.enabled ? fgColor : disabledFg,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    widget.item.label,
                    key: ValueKey(widget.item.label),
                    style: TextStyle(
                      color: widget.item.enabled ? fgColor : disabledFg,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
