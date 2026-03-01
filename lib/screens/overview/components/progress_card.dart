import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';

class ProgressCard extends StatelessWidget {
  final String title;
  final int total;
  final int completed;
  final Color? containerColor;

  const ProgressCard({
    super.key,
    required this.title,
    required this.total,
    required this.completed,
    this.containerColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;
    final bgColor = containerColor ?? colorTheme.surfaceContainerHighest;
    final progress = total == 0 ? 0.0 : completed / total;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorTheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),

          if (total == 0)
            // Empty state
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colorTheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Symbols.event_available,
                        fill: 1,
                        weight: 300,
                        size: 28,
                        color: colorTheme.onSecondaryContainer,
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
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedProgress, _) {
                      return SizedBox(
                        width: 100,
                        height: 100,
                        child: WavyCircularProgressIndicator(
                          value: animatedProgress,
                          color: colorTheme.primary,
                          backgroundColor: colorTheme.primary.withValues(
                            alpha: 0.15,
                          ),
                          strokeWidth: 5.0,
                          waveAmplitude: 4.0,
                          waveLength: 20.0,
                          showTrack: false,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$completed / $total',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorTheme.primary,
                      ),
                    ),
                  ),
                  if (progress == 1.0) ...[
                    const SizedBox(height: 8),
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
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: colorTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
