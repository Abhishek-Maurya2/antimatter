import 'package:flutter/material.dart';
import 'package:material_new_shapes/material_new_shapes.dart';
import 'package:antimatter/utils/ui_utils.dart';

class StatusCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final int count;
  final Color? containerColor;
  final Color? contentColor;
  final VoidCallback? onTap;
  final RoundedPolygon? shape;

  const StatusCard({
    super.key,
    required this.icon,
    required this.title,
    required this.count,
    this.containerColor,
    this.contentColor,
    this.onTap,
    this.shape,
  });

  @override
  State<StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<StatusCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;
    final bgColor = widget.containerColor ?? colorTheme.surface;
    final fgColor = widget.contentColor ?? colorTheme.onSurface;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: ClipPath(
          clipper: widget.shape != null ? PolygonClipper(widget.shape!) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: widget.shape == null
                  ? BorderRadius.circular(_isPressed ? 28 : 20)
                  : null,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon
                Icon(
                  widget.icon,
                  fill: 1,
                  weight: 400,
                  size: 28,
                  color: fgColor,
                ),
                const Spacer(),
                // Title
                Text(
                  widget.title,
                  style: TextStyle(
                    fontFamily: 'GoogleSansFlex',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: fgColor.withValues(alpha: 0.8),
                    fontVariations: const [
                      FontVariation('wght', 800),
                      FontVariation('wdth', 100),
                      FontVariation('ROND', 80),
                      FontVariation('GRAD', 0),
                      FontVariation('opsz', 20),
                      FontVariation('slnt', 0),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // Count
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: widget.count),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Text(
                      value.toString(),
                      style: TextStyle(
                        fontFamily: 'GoogleSansFlex',
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: fgColor,
                        fontVariations: const [
                          FontVariation('wght', 800),
                          FontVariation('wdth', 100),
                          FontVariation('ROND', 100),
                          FontVariation('GRAD', 0),
                          FontVariation('opsz', 36),
                          FontVariation('slnt', 0),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
