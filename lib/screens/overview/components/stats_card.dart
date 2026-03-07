import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:material_new_shapes/material_new_shapes.dart';

/// A combined stats card that displays All Tasks, Completed, and Pending
/// counts in a single card with a decorative sunny shape background.
class StatsCard extends StatelessWidget {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final VoidCallback? onTap;

  const StatsCard({
    super.key,
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Determine item width. If there's plenty of space, let them be wide.
          // Otherwise, constrain them so they can wrap.
          final isWide = constraints.maxWidth >= 500;
          final double itemWidth = isWide
              ? (constraints.maxWidth - 32) /
                    3 // 3 items, 16px gap * 2
              : (constraints.maxWidth - 16) / 2; // 2 items, 16px gap

          final double minWidth = 140.0;
          final double finalWidth = itemWidth < minWidth ? minWidth : itemWidth;

          return Wrap(
            spacing: 16.0,
            runSpacing: 16.0,
            alignment: WrapAlignment.start,
            children: [
              // All Tasks
              SizedBox(
                width: finalWidth,
                child: _StatItem(
                  icon: Symbols.task_alt,
                  label: 'All Tasks',
                  count: totalTasks,
                  color: colorTheme.primary,
                  textColor: colorTheme.onPrimaryContainer,
                  shape: MaterialShapes.softBurst,
                  shapeColor: colorTheme.primaryContainer,
                ),
              ),
              // Completed
              SizedBox(
                width: finalWidth,
                child: _StatItem(
                  icon: Symbols.check_circle,
                  label: 'Completed',
                  count: completedTasks,
                  color: colorTheme.tertiary,
                  textColor: colorTheme.onTertiaryContainer,
                  shape: MaterialShapes.sunny,
                  shapeColor: colorTheme.tertiaryContainer,
                ),
              ),
              // Pending
              SizedBox(
                width: finalWidth,
                child: _StatItem(
                  icon: Symbols.pending,
                  label: 'Pending',
                  count: pendingTasks,
                  color: colorTheme.error,
                  textColor: colorTheme.onErrorContainer,
                  shape: MaterialShapes.cookie4Sided,
                  shapeColor: colorTheme.errorContainer,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final Color textColor;
  final RoundedPolygon shape;
  final Color shapeColor;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.textColor,
    required this.shape,
    required this.shapeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Full background shape painted behind the content
          Positioned.fill(
            child: CustomPaint(
              painter: _ShapePainter(polygon: shape, color: shapeColor),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, fill: 1, weight: 400, size: 28, color: color),
                const SizedBox(height: 12),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: count),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Text(
                      value.toString(),
                      style: TextStyle(
                        fontFamily: 'GoogleSansFlex',
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: textColor,
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
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'GoogleSansFlex',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: textColor.withValues(alpha: 0.8),
                    fontVariations: const [
                      FontVariation('wght', 1000),
                      FontVariation('wdth', 100),
                      FontVariation('ROND', 900),
                      FontVariation('GRAD', 0),
                      FontVariation('opsz', 119),
                      FontVariation('slnt', 0),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints a [RoundedPolygon] as a filled shape (no clipping).
class _ShapePainter extends CustomPainter {
  final RoundedPolygon polygon;
  final Color color;

  const _ShapePainter({required this.polygon, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final normalizedPath = polygon.toPath();
    final side = size.width < size.height ? size.width : size.height;
    final matrix = Matrix4.diagonal3Values(side, side, 1);
    final scaled = normalizedPath.transform(matrix.storage);
    final bounds = scaled.getBounds();
    final dx = (size.width - bounds.width) / 2 - bounds.left;
    final dy = (size.height - bounds.height) / 2 - bounds.top;
    final finalPath = scaled.shift(Offset(dx, dy));

    canvas.drawPath(
      finalPath,
      Paint()
        ..style = PaintingStyle.fill
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_ShapePainter oldDelegate) =>
      oldDelegate.polygon != polygon || oldDelegate.color != color;
}
