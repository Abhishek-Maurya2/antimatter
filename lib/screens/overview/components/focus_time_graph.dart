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

    // Initialize last 365 days with 0
    for (int i = 364; i >= 0; i--) {
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
  late DateTime _currentWeekStart;
  bool _isStatsExpanded = false;
  final ScrollController _barsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Start with the week ending today
    _currentWeekStart = today.subtract(const Duration(days: 6));

    // Auto-scroll to the end after the first frame to show the most recent day (today)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_barsScrollController.hasClients) {
        _barsScrollController.jumpTo(
          _barsScrollController.position.maxScrollExtent,
        );
      }
    });
  }

  @override
  void dispose() {
    _barsScrollController.dispose();
    super.dispose();
  }

  void _goToPreviousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
  }

  void _goToNextWeek() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextWeekStart = _currentWeekStart.add(const Duration(days: 7));

    if (nextWeekStart.isBefore(today)) {
      setState(() {
        _currentWeekStart = nextWeekStart;
      });
    }
  }

  bool get _canGoNext {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _currentWeekStart.add(const Duration(days: 7)).isBefore(today);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Filter to current 7-day window
    final List<DateTime> visibleDates = [];
    for (int i = 0; i < 7; i++) {
      visibleDates.add(_currentWeekStart.add(Duration(days: i)));
    }

    final maxSeconds = visibleDates.fold<int>(
      600, // min 10 mins for scale
      (prev, date) {
        final val = widget.dailyFocus[date] ?? 0;
        return val > prev ? val : prev;
      },
    );

    // Calculate windowed stats
    int windowedTotal = 0;
    int activeDaysInWindow = 0;
    DateTime? windowBestDay;
    int windowBestSeconds = 0;

    for (final date in visibleDates) {
      final seconds = widget.dailyFocus[date] ?? 0;
      windowedTotal += seconds;
      if (seconds > 0) activeDaysInWindow++;
      if (seconds >= windowBestSeconds) {
        windowBestSeconds = seconds;
        windowBestDay = date;
      }
    }

    final int averageFocus = windowedTotal ~/ 7;
    final String bestDayLabel = windowBestDay != null
        ? DateFormat('d MMM').format(windowBestDay).toUpperCase()
        : 'N/A';

    final isCurrentWeek = _isSameDay(
      _currentWeekStart.add(const Duration(days: 6)),
      today,
    );

    final weekFormat = DateFormat('d MMM');
    final weekRangeText =
        '${weekFormat.format(_currentWeekStart)} - ${weekFormat.format(visibleDates.last)}'
            .toUpperCase();

    const double chartHeight = 320;
    const double xAxisBottomOffset = 34;
    const double scrollbarBottomInset = 12;
    final double maxBarHeight =
        chartHeight - xAxisBottomOffset - scrollbarBottomInset;
    final double drawableMaxBarHeight = maxBarHeight - 1;

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
                              isCurrentWeek ? 'Today Focused' : 'Day Peak',
                              style: TextStyle(
                                fontFamily: 'GoogleSansFlex',
                                fontSize: 18,
                                fontVariations: const [
                                  FontVariation('wght', 500),
                                  FontVariation('wdth', 110),
                                ],
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _formatDuration(
                                isCurrentWeek
                                    ? (widget.dailyFocus[today] ?? 0)
                                    : windowBestSeconds,
                              ),
                              style: TextStyle(
                                fontFamily: 'GoogleSansFlex',
                                fontSize: 32,
                                fontVariations: const [
                                  FontVariation('wght', 600),
                                  FontVariation('wdth', 80),
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
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            weight: 800,
                            size: 32,
                          ),
                          selectedIcon: const Icon(
                            Icons.keyboard_arrow_up_rounded,
                            weight: 800,
                            size: 32,
                          ),
                          isSelected: _isStatsExpanded,
                          variant: IconButtonM3EVariant.tonal,
                          backgroundColor: colorScheme.surfaceContainer,
                          width: IconButtonM3EWidth.narrow,
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
                                const SizedBox(height: 20),
                                Text(
                                  'Average Focus',
                                  style: TextStyle(
                                    fontFamily: 'GoogleSansFlex',
                                    fontSize: 14,
                                    fontVariations: const [
                                      FontVariation('wght', 500),
                                      FontVariation('wdth', 110),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatDuration(averageFocus),
                                  style: TextStyle(
                                    fontFamily: 'GoogleSansFlex',
                                    fontSize: 38,
                                    fontVariations: const [
                                      FontVariation('wght', 700),
                                      FontVariation('wdth', 100),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'WINDOW TOTAL: ${_formatDuration(windowedTotal)}',
                                  style: textTheme.labelMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ACTIVE DAYS: $activeDaysInWindow/7',
                                  style: textTheme.labelMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'WINDOW BEST: ${_formatDuration(windowBestSeconds)} · $bestDayLabel',
                                  style: textTheme.labelMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w400,
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
            height: chartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Y-Axis Labels
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: xAxisBottomOffset + scrollbarBottomInset,
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
                // Bars
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      bottom: scrollbarBottomInset,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const double minBarWidth = 55;
                        final double totalMinWidth =
                            minBarWidth * visibleDates.length;
                        final bool needsScroll =
                            constraints.maxWidth < totalMinWidth;

                        Widget barsRow = Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(visibleDates.length, (index) {
                            final date = visibleDates[index];
                            final seconds = widget.dailyFocus[date] ?? 0;
                            final heightFactor = seconds / maxSeconds;
                            final isToday = _isSameDay(date, today);
                            final isLowFocus =
                                seconds < 3600; // less than 30 minutes
                            final isLessFocus =
                                windowBestSeconds > 0 &&
                                seconds < (windowBestSeconds * 0.7);

                            final barChild = Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Tooltip(
                                  message: _formatDuration(seconds),
                                  triggerMode: TooltipTriggerMode.tap,
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      maxWidth: 60,
                                    ),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    height:
                                        (heightFactor * drawableMaxBarHeight)
                                            .clamp(4.0, drawableMaxBarHeight),
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
                                                        : MaterialShapes
                                                              .softBurst),
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
                                  DateFormat(
                                    'E',
                                  ).format(date).substring(0, 1).toUpperCase(),
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 10,
                                    fontWeight: isToday
                                        ? FontWeight.bold
                                        : null,
                                  ),
                                ),
                                // Date Number
                                Text(
                                  DateFormat(
                                    'd MMM',
                                  ).format(date).toUpperCase(),
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant
                                        .withOpacity(0.6),
                                    fontSize: 8,
                                    fontWeight: isToday
                                        ? FontWeight.bold
                                        : null,
                                  ),
                                ),
                              ],
                            );

                            if (needsScroll) {
                              return SizedBox(
                                width: minBarWidth,
                                child: barChild,
                              );
                            }
                            return Expanded(child: barChild);
                          }),
                        );

                        if (needsScroll) {
                          return Scrollbar(
                            controller: _barsScrollController,
                            child: SingleChildScrollView(
                              controller: _barsScrollController,
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: totalMinWidth,
                                child: barsRow,
                              ),
                            ),
                          );
                        }
                        return barsRow;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selection range',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    weekRangeText,
                    style: TextStyle(
                      fontFamily: 'GoogleSansFlex',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurfaceVariant,
                      fontVariations: const [FontVariation('wght', 700)],
                    ),
                  ),
                ],
              ),
              ButtonGroupM3E(
                type: ButtonGroupM3EType.standard,
                size: ButtonGroupM3ESize.sm,
                style: ButtonM3EStyle.tonal,
                actions: [
                  ButtonGroupM3EAction(
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      weight: 800,
                      size: 40,
                    ),
                    onPressed: _goToPreviousWeek,
                    shape: ButtonM3EShape.round,
                    width: 50,
                    height: 60,
                    contentPadding: EdgeInsets.zero,
                  ),
                  ButtonGroupM3EAction(
                    icon: const Icon(
                      Icons.chevron_right_rounded,
                      weight: 800,
                      size: 40,
                    ),
                    onPressed: _canGoNext ? _goToNextWeek : null,
                    enabled: _canGoNext,
                    shape: ButtonM3EShape.round,
                    width: 50,
                    height: 60,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
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
    final hours = minutes ~/ 60;
    final remainingMins = minutes % 60;
    if (remainingMins == 0) return '${hours}h';
    return '${hours}h ${remainingMins}m';
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
