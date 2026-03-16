import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:material_new_shapes/material_new_shapes.dart';
import 'package:m3e_collection/m3e_collection.dart';
import '../../../models/session.dart';

class FocusTimeGraph extends StatelessWidget {
  const FocusTimeGraph({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionsBox = Hive.box<Session>('sessionsBox');

    return ValueListenableBuilder(
      valueListenable: sessionsBox.listenable(),
      builder: (context, Box<Session> box, _) {
        final dailyFocus = _calculateDailyFocus(box);
        return _FocusGraphCard(dailyFocus: dailyFocus);
      },
    );
  }

  Map<DateTime, int> _calculateDailyFocus(Box<Session> box) {
    final map = <DateTime, int>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Initialize last 30 days with 0
    for (int i = 29; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      map[date] = 0;
    }

    for (final session in box.values) {
      final sessionDate = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      if (map.containsKey(sessionDate)) {
        map[sessionDate] = (map[sessionDate] ?? 0) + session.durationSeconds;
      }
    }
    return map;
  }
}

class _FocusGraphCard extends StatefulWidget {
  final Map<DateTime, int> dailyFocus;

  const _FocusGraphCard({required this.dailyFocus});

  @override
  State<_FocusGraphCard> createState() => _FocusGraphCardState();
}

class _FocusGraphCardState extends State<_FocusGraphCard> {
  final ScrollController _scrollController = ScrollController();
  bool _isStatsExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final sortedDates = widget.dailyFocus.keys.toList()..sort();
    final maxSeconds = widget.dailyFocus.values.fold<int>(
      600, // min 10 mins for scale
      (prev, curr) => curr > prev ? curr : prev,
    );

    // Calculate today's total and 7-day average
    final now = DateTime.now();
    int todayTotal = 0;
    int sevenDayTotal = 0;

    for (int i = 0; i < 7; i++) {
      final targetDate = now.subtract(Duration(days: i));
      for (final entry in widget.dailyFocus.entries) {
        if (_isSameDay(entry.key, targetDate)) {
          sevenDayTotal += entry.value;
          if (i == 0) todayTotal = entry.value;
          break;
        }
      }
    }
    final int averageFocus = sevenDayTotal ~/ 7;

    const barDefaultColor = Color(0xFF80DA88);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics_rounded,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Focus Time',
                          style: TextStyle(
                            fontFamily: 'GoogleSansFlex',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                            fontVariations: const [
                              FontVariation('wght', 600),
                              FontVariation('wdth', 100),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Today Focused',
                              style: TextStyle(
                                fontFamily: 'GoogleSansFlex',
                                fontSize: 14,
                                fontVariations: const [
                                  FontVariation('wght', 500),
                                  FontVariation('wdth', 110),
                                  FontVariation('wght', 600),
                                  FontVariation('wdth', 100),
                                  FontVariation('ROND', 100),
                                  FontVariation('CNTR', 100),
                                  FontVariation('XTRA', 100),
                                ],
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _formatDuration(todayTotal).toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'GoogleSansFlex',
                                fontSize: 24,
                                fontVariations: const [
                                  FontVariation('wght', 600),
                                  FontVariation('wdth', 100),
                                  FontVariation('ROND', 200),
                                  FontVariation('CNTR', 100),
                                  FontVariation('XTRA', 100),
                                ],
                              ),
                            ),
                          ],
                        ),
                        IconButtonM3E(
                          onPressed: () {
                            setState(() {
                              _isStatsExpanded = !_isStatsExpanded;
                            });
                          },
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          selectedIcon: const Icon(
                            Icons.keyboard_arrow_up_rounded,
                          ),
                          isSelected: _isStatsExpanded,
                          variant: IconButtonM3EVariant.tonal,
                          backgroundColor: colorScheme.surfaceContainer,
                          width: IconButtonM3EWidth.wide,
                        ),
                      ],
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                      child: _isStatsExpanded
                          ? Column(
                              key: const ValueKey('expanded_stats'),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
                                Text(
                                  'Average Focus',
                                  style: TextStyle(
                                    fontFamily: 'GoogleSansFlex',
                                    fontSize: 14,
                                    fontVariations: const [
                                      FontVariation('wght', 500),
                                      FontVariation('wdth', 110),
                                      FontVariation('wght', 600),
                                      FontVariation('wdth', 100),
                                      FontVariation('ROND', 100),
                                      FontVariation('CNTR', 100),
                                      FontVariation('XTRA', 100),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _formatDuration(averageFocus).toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: 'GoogleSansFlex',
                                    fontSize: 34,
                                    fontVariations: const [
                                      FontVariation('wght', 700),
                                      FontVariation('wdth', 100),
                                      FontVariation('ROND', 200),
                                      FontVariation('CNTR', 100),
                                      FontVariation('XTRA', 500),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(key: ValueKey('empty_stats')),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180, // Increased height
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Y-Axis Labels
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 34.0, // Adjusted for new label block height
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildYLabel(_formatYLabel(maxSeconds)),
                      _buildYLabel(_formatYLabel(maxSeconds ~/ 1.5)),
                      _buildYLabel(_formatYLabel(maxSeconds ~/ 2)),
                      _buildYLabel(_formatYLabel(maxSeconds ~/ 3)),
                      _buildYLabel('0m'),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Scrollable Bars
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(sortedDates.length, (index) {
                        final date = sortedDates[index];
                        final seconds = widget.dailyFocus[date] ?? 0;
                        final heightFactor = seconds / maxSeconds;
                        final isToday = _isSameDay(date, DateTime.now());
                        final isLowFocus =
                            averageFocus > 0 && seconds < (averageFocus / 2);
                        final isLessFocus =
                            averageFocus > 0 && seconds < (averageFocus / 1.2);

                        return SizedBox(
                          width: 48,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Tooltip(
                                message: _formatDuration(seconds),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  height: (heightFactor * 120).clamp(
                                    4,
                                    120,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isLowFocus
                                        ? colorScheme.error
                                        : (isLessFocus
                                            ? colorScheme.primary
                                            : barDefaultColor),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  alignment: Alignment.topCenter,
                                  padding: const EdgeInsets.all(4),
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: Center(
                                      child: FractionallySizedBox(
                                        widthFactor: 1,
                                        heightFactor: 1,
                                        child: CustomPaint(
                                          painter: _ShapePainter(
                                            polygon: isLowFocus
                                                ? MaterialShapes.arrow
                                                : (isLessFocus
                                                    ? MaterialShapes.gem
                                                    : MaterialShapes.softBurst),
                                            color: colorScheme.surface
                                                .withOpacity(0.7),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Day Name
                              Text(
                                DateFormat('E')
                                    .format(date)
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 10,
                                  fontWeight: isToday ? FontWeight.bold : null,
                                ),
                              ),
                              // Date Number
                              Text(
                                DateFormat('d MMM').format(date).toUpperCase(),
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant
                                      .withOpacity(0.6),
                                  fontSize: 8,
                                  fontWeight: isToday ? FontWeight.bold : null,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        color: Colors.grey,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  String _formatYLabel(int seconds) {
    if (seconds <= 0) return '0m';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '${minutes}m';
    final hours = minutes / 60;
    if (hours == hours.toInt()) return '${hours.toInt()}h';
    return '${hours.toStringAsFixed(1)}h';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds seconds';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '$minutes mins';
    final hours = minutes ~/ 60;
    final remainingMins = minutes % 60;
    return '${hours}h ${remainingMins}m';
  }
}

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
