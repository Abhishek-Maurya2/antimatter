import 'package:flutter/material.dart';

/// Data model for a button within the M3 connected button group.
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

/// Material 3 Expressive Connected Button Group (Extra Large).
///
/// Follows the M3 connected button group spec from `material-components-android`:
///
/// **Shape**:
/// - Outer corners: fully round (stadium / 50%)
/// - Inner corners: 8dp default → 4dp on press (corner morph animation)
/// - Spacing between buttons: 2dp
///
/// **Size (XL)**:
/// - Vertical padding: 48dp (content-driven height)
/// - Icon size: 24dp, label: titleMedium
///
/// **Colors** (tonal):
/// - Default: `secondaryContainer` / `onSecondaryContainer`
/// - Active/highlighted: `primaryContainer` / `onPrimaryContainer`
///
/// **Motion**:
/// - Inner corner morph: 8dp → 4dp on press (200ms spring)
/// - Color transition: 350ms ease
/// - Icon/label crossfade via AnimatedSwitcher
/// - No width expansion on press (connected groups use `buttonSizeChange=null`)
class M3ButtonGroup extends StatelessWidget {
  final List<M3ButtonGroupItem> items;

  /// Index of the highlighted/active button (uses primaryContainer).
  final int? activeIndex;

  /// Whether the group is in an active state (e.g. timer running).
  final bool isActive;

  const M3ButtonGroup({
    super.key,
    required this.items,
    this.activeIndex,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(items.length, (index) {
        final item = items[index];
        final isFirst = index == 0;
        final isLast = index == items.length - 1;
        final isActiveItem = activeIndex == index && isActive;

        return Padding(
          // 2dp spacing between buttons (connected group spec)
          padding: EdgeInsets.only(right: isLast ? 0 : 2),
          child: _M3ConnectedButton(
            item: item,
            isFirst: isFirst,
            isLast: isLast,
            isHighlighted: isActiveItem,
          ),
        );
      }),
    );
  }
}

class _M3ConnectedButton extends StatefulWidget {
  final M3ButtonGroupItem item;
  final bool isFirst;
  final bool isLast;
  final bool isHighlighted;

  const _M3ConnectedButton({
    required this.item,
    required this.isFirst,
    required this.isLast,
    required this.isHighlighted,
  });

  @override
  State<_M3ConnectedButton> createState() => _M3ConnectedButtonState();
}

class _M3ConnectedButtonState extends State<_M3ConnectedButton> {
  bool _isPressed = false;

  // M3 Connected Button Group inner corner sizes:
  // Default: shapeCornerSizeSmall = 8dp
  // Pressed: shapeCornerSizeExtraSmall = 4dp
  static const double _innerCornerDefault = 8.0;
  static const double _innerCornerPressed = 4.0;

  // Outer corners: fully round (stadium shape)
  static const double _outerCorner = 50.0;

  void _onTapDown(TapDownDetails _) {
    if (widget.item.enabled) {
      setState(() => _isPressed = true);
    }
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Colors: tonal spec
    final Color bgColor = widget.isHighlighted
        ? cs.primaryContainer
        : cs.secondaryContainer;
    final Color fgColor = widget.isHighlighted
        ? cs.onPrimaryContainer
        : cs.onSecondaryContainer;
    final Color disabledBg = cs.onSurface.withValues(alpha: 0.12);
    final Color disabledFg = cs.onSurface.withValues(alpha: 0.38);

    final bool enabled = widget.item.enabled;

    // Inner corner morph: 8dp default → 4dp pressed
    final double innerCorner = _isPressed
        ? _innerCornerPressed
        : _innerCornerDefault;

    // Connected group shape: outer edges fully round, inner edges use innerCornerSize
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(widget.isFirst ? _outerCorner : innerCorner),
      bottomLeft: Radius.circular(widget.isFirst ? _outerCorner : innerCorner),
      topRight: Radius.circular(widget.isLast ? _outerCorner : innerCorner),
      bottomRight: Radius.circular(widget.isLast ? _outerCorner : innerCorner),
    );

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: enabled ? widget.item.onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: enabled ? bgColor : disabledBg,
          borderRadius: borderRadius,
        ),
        // XL size: 48dp vertical padding
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated icon crossfade (fade + scale)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
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
                color: enabled ? fgColor : disabledFg,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            // Animated label crossfade (fade + slide up)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
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
                  color: enabled ? fgColor : disabledFg,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
