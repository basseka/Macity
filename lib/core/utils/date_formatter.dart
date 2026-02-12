import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final _dayFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
  static final _shortFormat = DateFormat('dd/MM/yyyy', 'fr_FR');
  static final _timeFormat = DateFormat('HH:mm', 'fr_FR');
  static final _dayMonthFormat = DateFormat('d MMMM', 'fr_FR');

  static String formatFull(DateTime date) => _dayFormat.format(date);

  static String formatShort(DateTime date) => _shortFormat.format(date);

  static String formatTime(DateTime date) => _timeFormat.format(date);

  static String formatDayMonth(DateTime date) => _dayMonthFormat.format(date);

  static String formatDateRange(DateTime start, DateTime end) {
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return formatShort(start);
    }
    return '${formatShort(start)} → ${formatShort(end)}';
  }

  /// Format "Aujourd'hui" / "Demain" or date
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final diff = target.difference(today).inDays;
    if (diff == 0) return "Aujourd'hui";
    if (diff == 1) return 'Demain';
    if (diff < 7) return _dayFormat.format(date);
    return formatShort(date);
  }
}
