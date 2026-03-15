import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
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

    // Initialize last 7 days with 0
    for (int i = 6; i >= 0; i--) {
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

class _FocusGraphCard extends StatelessWidget {
  final Map<DateTime, int> dailyFocus;

  const _FocusGraphCard({required this.dailyFocus});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final sortedDates = dailyFocus.keys.toList()..sort();
    final maxSeconds = dailyFocus.values.fold<int>(
      600, // min 10 mins for scale
      (prev, curr) => curr > prev ? curr : prev,
    );

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
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: sortedDates.map((date) {
                final seconds = dailyFocus[date] ?? 0;
                final heightFactor = seconds / maxSeconds;
                final isToday = _isSameDay(date, DateTime.now());

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Tooltip(
                          message: _formatDuration(seconds),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            height: (heightFactor * 80).clamp(4, 80),
                            decoration: BoxDecoration(
                              color: isToday
                                  ? colorScheme.primary
                                  : colorScheme.primaryContainer.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('E').format(date).toUpperCase(),
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: isToday ? FontWeight.bold : null,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
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
