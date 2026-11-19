import '../core/date_utils.dart';
import '../core/slot_config.dart';
import 'entities/app_user.dart';
import 'entities/booking.dart';
import 'failures.dart';

/// Pure booking rules, shared by the Firestore transaction (data layer) and
/// the fake repository used in unit tests. No Flutter, no Firebase.
class BookingPolicy {
  BookingPolicy._();

  /// Checks that can be done before touching the database at all.
  static void validateSlot(DateTime slotStart, DateTime now) {
    if (!SlotConfig.isValidSlotStart(slotStart)) {
      throw const InvalidSlotFailure('That is not a valid slot time.');
    }
    if (!SlotConfig.slotEndFor(slotStart).isAfter(now)) {
      throw const InvalidSlotFailure('That slot has already ended.');
    }
    if (!isInBookableWindow(slotStart, now)) {
      throw const InvalidSlotFailure(
          'You can only book today or the next 6 days.');
    }
  }

  /// The checks that MUST run inside the atomic unit (transaction):
  ///
  /// * [bookingHoldingSlot] - the booking currently referenced by the
  ///   slot's lock (if any). Only blocks if it is still live-active.
  /// * [usersBookings] - the student's bookings that might be active.
  ///   Cancelled / expired ones are ignored, so the cap is
  ///   "at most 2 *live* active bookings across all dates".
  static void ensureCanBook({
    required Booking? bookingHoldingSlot,
    required Iterable<Booking> usersBookings,
    required DateTime now,
  }) {
    if (bookingHoldingSlot != null && bookingHoldingSlot.isLiveActive(now)) {
      throw const SlotAlreadyTakenFailure();
    }
    final active = usersBookings.where((b) => b.isLiveActive(now)).length;
    if (active >= SlotConfig.maxActiveBookings) {
      throw const BookingLimitFailure(SlotConfig.maxActiveBookings);
    }
  }

  /// Owner: only an active booking, only before it starts.
  /// Admin (force-cancel): any booking that is still active.
  static void ensureCanCancel({
    required Booking booking,
    required AppUser actor,
    required DateTime now,
    required bool force,
  }) {
    if (force) {
      if (!actor.isAdmin) {
        throw const NotAuthorizedFailure('Only admins can force-cancel.');
      }
    } else {
      if (booking.userId != actor.uid) {
        throw const NotAuthorizedFailure(
            'You can only cancel your own bookings.');
      }
      if (!now.isBefore(booking.slotStart)) {
        throw const CannotCancelFailure(
            'This booking has already started and can no longer be cancelled.');
      }
    }
    if (booking.effectiveStatus(now) != BookingStatus.active) {
      throw const CannotCancelFailure('This booking is no longer active.');
    }
  }
}
