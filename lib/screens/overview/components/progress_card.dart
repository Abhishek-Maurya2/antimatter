import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:m3e_collection/m3e_collection.dart'
    hide ExpressiveLoadingIndicator;
import 'package:material_new_shapes/material_new_shapes.dart';
import 'package:orches/utils/ui_utils.dart';

class ProgressCard extends StatelessWidget {
  final String title;
  final int total;
  final int completed;
  final Color? containerColor;
  final VoidCallback? onTap;

  const ProgressCard({
    super.key,
    required this.title,
    required this.total,
    required this.completed,
    this.containerColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;
    final bgColor = containerColor ?? colorTheme.surface;
    final progress = total == 0 ? 0.0 : completed / total;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'GoogleSansFlex',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: colorTheme.onSurface,
                  fontVariations: const [
                    FontVariation('wght', 800),
                    FontVariation('wdth', 100),
                    FontVariation('ROND', 80),
                    FontVariation('GRAD', 0),
                    FontVariation('opsz', 22),
                    FontVariation('slnt', 0),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (total == 0)
              // Empty state
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: ClipPath(
                          clipper: PolygonClipper(MaterialShapes.pill),
                          child: ColoredBox(
                            color: colorTheme.secondaryContainer,
                            child: Center(
                              child: Icon(
                                Symbols.event_available,
                                fill: 1,
                                weight: 300,
                                size: 35,
                                color: colorTheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No tasks for today',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorTheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              )
            else
              // Circular wavy progress indicator + count
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 4),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, animatedProgress, _) {
                        return SizedBox(
                          width: 85,
                          height: 85,
                          child: CircularProgressIndicatorM3E(
                            value: animatedProgress,
                            shape: ProgressM3EShape.wavy,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$completed / $total',
                        style: TextStyle(
                          fontFamily: 'GoogleSansFlex',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colorTheme.primary,
                          fontVariations: const [
                            FontVariation('wght', 700),
                            FontVariation('wdth', 100),
                            FontVariation('ROND', 100),
                            FontVariation('GRAD', 0),
                            FontVariation('opsz', 14),
                            FontVariation('slnt', 0),
                          ],
                        ),
                      ),
                    ),
                    if (progress == 1.0) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Symbols.celebration,
                            fill: 1,
                            size: 16,
                            color: colorTheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'All done!',
                            style: TextStyle(
                              fontFamily: 'GoogleSansFlex',
                              fontSize: 12,
                              color: colorTheme.primary,
                              fontWeight: FontWeight.w600,
                              fontVariations: const [
                                FontVariation('wght', 600),
                                FontVariation('wdth', 100),
                                FontVariation('ROND', 100),
                                FontVariation('GRAD', 0),
                                FontVariation('opsz', 12),
                                FontVariation('slnt', 0),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
