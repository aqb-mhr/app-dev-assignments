import 'slot_config.dart';

/// Midnight (local) of [d].
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// The `date` field stored on a booking: `yyyy-MM-dd`.
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Today plus the next [SlotConfig.bookableDays] - 1 days.
List<DateTime> bookableDates(DateTime now) {
  final today = dateOnly(now);
  return List.generate(
    SlotConfig.bookableDays,
    (i) => DateTime(today.year, today.month, today.day + i),
  );
}

/// Whether [slotStart]'s calendar day is inside the bookable window.
bool isInBookableWindow(DateTime slotStart, DateTime now) {
  final day = dateOnly(slotStart);
  final today = dateOnly(now);
  final lastDay =
      DateTime(today.year, today.month, today.day + SlotConfig.bookableDays - 1);
  return !day.isBefore(today) && !day.isAfter(lastDay);
}

/// `09:30` style label.
String hhmm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
