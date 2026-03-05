import 'package:intl/intl.dart';

class SystemDateUtils {
  static String formatRelativeDeadline(DateTime deadline) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);

    final difference = deadlineDate.difference(today).inDays;

    final timeStr = DateFormat('h:mm a').format(deadline);

    if (difference == 0) {
      return 'Today, $timeStr';
    } else if (difference == 1) {
      return 'Tomorrow, $timeStr';
    } else if (difference == -1) {
      return 'Yesterday, $timeStr';
    } else {
      // For dates beyond tomorrow or before yesterday
      final dayStr = DateFormat('E d').format(deadline);
      return '$timeStr, $dayStr';
    }
  }
}
