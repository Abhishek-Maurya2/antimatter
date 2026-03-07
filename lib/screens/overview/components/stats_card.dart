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
      child: Container(
        decoration: BoxDecoration(
          color: colorTheme.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // All Tasks
            Expanded(
              child: _StatItem(
                icon: Symbols.task_alt,
                label: 'All',
                count: totalTasks,
                color: colorTheme.primary,
                textColor: colorTheme.onSurface,
                shape: MaterialShapes.softBurst,
                shapeColor: colorTheme.primaryContainer.withValues(alpha: 0.5),
              ),
            ),
            // Divider
            Container(
              width: 1,
              height: 60,
              color: colorTheme.outlineVariant.withValues(alpha: 0.4),
            ),
            // Completed
            Expanded(
              child: _StatItem(
                icon: Symbols.check_circle,
                label: 'Done',
                count: completedTasks,
                color: colorTheme.tertiary,
                textColor: colorTheme.onSurface,
                shape: MaterialShapes.sunny,
                shapeColor: colorTheme.tertiaryContainer.withValues(alpha: 0.5),
              ),
            ),
            // Divider
            Container(
              width: 1,
              height: 60,
              color: colorTheme.outlineVariant.withValues(alpha: 0.4),
            ),
            // Pending
            Expanded(
              child: _StatItem(
                icon: Symbols.pending,
                label: 'Pending',
                count: pendingTasks,
                color: colorTheme.error,
                textColor: colorTheme.onSurface,
                shape: MaterialShapes.cookie4Sided,
                shapeColor: colorTheme.errorContainer.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon with shape background
        SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(48, 48),
                painter: _ShapePainter(polygon: shape, color: shapeColor),
              ),
              Icon(icon, fill: 1, weight: 400, size: 24, color: color),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: count),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Text(
              value.toString(),
              style: TextStyle(
                fontFamily: 'GoogleSansFlex',
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: textColor,
                fontVariations: const [
                  FontVariation('wght', 800),
                  FontVariation('wdth', 100),
                  FontVariation('ROND', 100),
                  FontVariation('GRAD', 0),
                  FontVariation('opsz', 32),
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
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor.withValues(alpha: 0.6),
            fontVariations: const [
              FontVariation('wght', 600),
              FontVariation('wdth', 100),
              FontVariation('ROND', 80),
              FontVariation('GRAD', 0),
              FontVariation('opsz', 13),
              FontVariation('slnt', 0),
            ],
          ),
        ),
      ],
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
