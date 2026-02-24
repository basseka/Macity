import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DateRangePreset { all, days7, days30, custom }

class DateRangeFilter {
  final DateRangePreset preset;
  final DateTime? customStart;
  final DateTime? customEnd;

  const DateRangeFilter({
    this.preset = DateRangePreset.all,
    this.customStart,
    this.customEnd,
  });

  bool isInRange(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (preset) {
      case DateRangePreset.all:
        return !date.isBefore(today);
      case DateRangePreset.days7:
        return !date.isBefore(today) &&
            date.isBefore(today.add(const Duration(days: 7)));
      case DateRangePreset.days30:
        return !date.isBefore(today) &&
            date.isBefore(today.add(const Duration(days: 30)));
      case DateRangePreset.custom:
        if (customStart == null || customEnd == null) {
          return !date.isBefore(today);
        }
        return !date.isBefore(customStart!) &&
            date.isBefore(customEnd!.add(const Duration(days: 1)));
    }
  }
}

final dateRangeFilterProvider =
    StateProvider<DateRangeFilter>((_) => const DateRangeFilter());
