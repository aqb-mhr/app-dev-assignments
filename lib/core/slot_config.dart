/// Every number that defines the booking calendar lives here.
///
/// If the slot length changes (e.g. 30 -> 20 minutes) this is the only file
/// that needs editing: slot count, slot start/end times, the UI strip and
/// the slot-lock document ids are all derived from these values.
class SlotConfig {
  SlotConfig._();

  /// First slot starts at 09:00.
  static const int openHour = 9;

  /// Last slot ends at 21:00.
  static const int closeHour = 21;

  static const Duration slotLength = Duration(minutes: 30);

  /// Max simultaneously-active bookings per student, across ALL dates.
  static const int maxActiveBookings = 2;

  /// Today + the next 6 days.
  static const int bookableDays = 7;

  /// Past bookings page size (startAfter pagination).
  static const int pastPageSize = 10;

  /// 24 for 09:00-21:00 with 30-minute slots.
  static int get slotsPerDay =>
      ((closeHour - openHour) * 60) ~/ slotLength.inMinutes;

  /// Start time of slot [index] (0-based) on [day].
  static DateTime slotStart(DateTime day, int index) =>
      DateTime(day.year, day.month, day.day, openHour)
          .add(slotLength * index);

  static DateTime slotEndFor(DateTime slotStart) => slotStart.add(slotLength);

  /// All slot start times for [day], in order.
  static List<DateTime> slotStartsFor(DateTime day) =>
      List.generate(slotsPerDay, (i) => slotStart(day, i));

  /// True when [time] is exactly on a slot boundary inside opening hours.
  static bool isValidSlotStart(DateTime time) {
    final open = DateTime(time.year, time.month, time.day, openHour);
    final minutes = time.difference(open).inMinutes;
    return time.second == 0 &&
        time.millisecond == 0 &&
        minutes >= 0 &&
        minutes % slotLength.inMinutes == 0 &&
        minutes ~/ slotLength.inMinutes < slotsPerDay;
  }
}
